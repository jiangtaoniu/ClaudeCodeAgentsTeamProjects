#include "tensorrt_infer.h"
#include <fstream>
#include <iostream>
#include <cuda_runtime.h>

#define CHECK_CUDA(status) \
    do { \
        auto ret = (status); \
        if (ret != 0) { \
            std::cerr << "Cuda failure: " << ret << " at line " << __LINE__ << std::endl; \
            abort(); \
        } \
    } while (0)

TensorRTInfer::TensorRTInfer() {}

TensorRTInfer::~TensorRTInfer() {
    if (buffer_voxels_) cudaFree(buffer_voxels_);
    if (buffer_num_points_) cudaFree(buffer_num_points_);
    if (buffer_coords_) cudaFree(buffer_coords_);
    if (buffer_cls_) cudaFree(buffer_cls_);
    if (buffer_box_) cudaFree(buffer_box_);
    if (buffer_dir_) cudaFree(buffer_dir_);
}

bool TensorRTInfer::loadEngine(const std::string& engine_path) {
    std::ifstream file(engine_path, std::ios::binary);
    if (!file.good()) {
        std::cerr << "Error reading engine file: " << engine_path << std::endl;
        return false;
    }

    file.seekg(0, file.end);
    size_t size = file.tellg();
    file.seekg(0, file.beg);
    
    std::vector<char> engine_data(size);
    file.read(engine_data.data(), size);
    file.close();

    runtime_.reset(nvinfer1::createInferRuntime(gLogger));
    if (!runtime_) return false;

    engine_.reset(runtime_->deserializeCudaEngine(engine_data.data(), size));
    if (!engine_) return false;

    context_.reset(engine_->createExecutionContext());
    if (!context_) return false;

    // Allocate Max Size CUDA Buffers (Assuming max 40000 voxels)
    const int MAX_VOXELS = 40000;
    
    CHECK_CUDA(cudaMalloc(&buffer_voxels_, MAX_VOXELS * 32 * 4 * sizeof(float)));
    CHECK_CUDA(cudaMalloc(&buffer_num_points_, MAX_VOXELS * sizeof(int)));
    CHECK_CUDA(cudaMalloc(&buffer_coords_, MAX_VOXELS * 4 * sizeof(int)));
    
    // TRT 10 dynamic output allocation
    // For output arrays, max possible size is derived from max batch size and fixed grid.
    // For pointpillars, grid is fixed. We assume max possible is the grid size.
    // Grid: 248x216. cls: 18, box: 42, dir: 12
    size_t max_cls_size = 248 * 216 * 18;
    size_t max_box_size = 248 * 216 * 42;
    size_t max_dir_size = 248 * 216 * 12;

    CHECK_CUDA(cudaMalloc(&buffer_cls_, max_cls_size * sizeof(float)));
    CHECK_CUDA(cudaMalloc(&buffer_box_, max_box_size * sizeof(float)));
    CHECK_CUDA(cudaMalloc(&buffer_dir_, max_dir_size * sizeof(float)));

    return true;
}

bool TensorRTInfer::doInference(const float* voxels, const int* voxel_num_points, const int* voxel_coords, int num_voxels,
                                float* cls_preds, float* box_preds, float* dir_cls_preds) {
    if (!context_) return false;

    // Set dynamic shapes for TRT 10
    context_->setInputShape("voxels", nvinfer1::Dims3{num_voxels, 32, 4});
    context_->setInputShape("voxel_num_points", nvinfer1::Dims{1, {num_voxels}});
    context_->setInputShape("voxel_coords", nvinfer1::Dims2{num_voxels, 4});

    // Copy to Device
    CHECK_CUDA(cudaMemcpy(buffer_voxels_, voxels, num_voxels * 32 * 4 * sizeof(float), cudaMemcpyHostToDevice));
    CHECK_CUDA(cudaMemcpy(buffer_num_points_, voxel_num_points, num_voxels * sizeof(int), cudaMemcpyHostToDevice));
    CHECK_CUDA(cudaMemcpy(buffer_coords_, voxel_coords, num_voxels * 4 * sizeof(int), cudaMemcpyHostToDevice));

    // Set Tensor Addresses
    context_->setTensorAddress("voxels", buffer_voxels_);
    context_->setTensorAddress("voxel_num_points", buffer_num_points_);
    context_->setTensorAddress("voxel_coords", buffer_coords_);
    context_->setTensorAddress("cls_preds", buffer_cls_);
    context_->setTensorAddress("box_preds", buffer_box_);
    context_->setTensorAddress("dir_cls_preds", buffer_dir_);

    // Run inference
    bool status = context_->enqueueV3(0); // 0 means default stream
    cudaStreamSynchronize(0);
    if (!status) return false;

    // Calculate exact output sizes dynamically (TRT 10 returns dimensions computed during execution)
    auto cls_dims = context_->getTensorShape("cls_preds");
    auto box_dims = context_->getTensorShape("box_preds");
    auto dir_dims = context_->getTensorShape("dir_cls_preds");

    size_t cls_size = 1; for(int i=0; i<cls_dims.nbDims; i++) cls_size *= cls_dims.d[i];
    size_t box_size = 1; for(int i=0; i<box_dims.nbDims; i++) box_size *= box_dims.d[i];
    size_t dir_size = 1; for(int i=0; i<dir_dims.nbDims; i++) dir_size *= dir_dims.d[i];

    // Copy back
    CHECK_CUDA(cudaMemcpy(cls_preds, buffer_cls_, cls_size * sizeof(float), cudaMemcpyDeviceToHost));
    CHECK_CUDA(cudaMemcpy(box_preds, buffer_box_, box_size * sizeof(float), cudaMemcpyDeviceToHost));
    CHECK_CUDA(cudaMemcpy(dir_cls_preds, buffer_dir_, dir_size * sizeof(float), cudaMemcpyDeviceToHost));

    return true;
}
