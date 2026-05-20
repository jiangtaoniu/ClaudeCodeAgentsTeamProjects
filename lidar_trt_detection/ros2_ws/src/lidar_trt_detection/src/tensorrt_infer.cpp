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
    for (int i = 0; i < 6; ++i) {
        if (buffers_[i] != nullptr) {
            cudaFree(buffers_[i]);
        }
    }
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

    // Get bindings
    input_index_voxels_ = engine_->getBindingIndex("voxels");
    input_index_num_points_ = engine_->getBindingIndex("voxel_num_points");
    input_index_coords_ = engine_->getBindingIndex("voxel_coords");
    output_index_cls_ = engine_->getBindingIndex("cls_preds");
    output_index_box_ = engine_->getBindingIndex("box_preds");
    output_index_dir_ = engine_->getBindingIndex("dir_cls_preds");

    // Allocate Max Size CUDA Buffers (Assuming max 40000 voxels)
    const int MAX_VOXELS = 40000;
    
    CHECK_CUDA(cudaMalloc(&buffers_[input_index_voxels_], MAX_VOXELS * 32 * 4 * sizeof(float)));
    CHECK_CUDA(cudaMalloc(&buffers_[input_index_num_points_], MAX_VOXELS * sizeof(int)));
    CHECK_CUDA(cudaMalloc(&buffers_[input_index_coords_], MAX_VOXELS * 4 * sizeof(int)));
    
    // Outputs are fixed size based on BEV grid (e.g. 248x216 or 496x432 depending on config)
    // We get max size from the engine's output dims for max batch size (1)
    auto cls_dims = engine_->getBindingDimensions(output_index_cls_);
    auto box_dims = engine_->getBindingDimensions(output_index_box_);
    auto dir_dims = engine_->getBindingDimensions(output_index_dir_);

    size_t cls_size = 1; for(int i=0; i<cls_dims.nbDims; i++) cls_size *= std::max(1, cls_dims.d[i]);
    size_t box_size = 1; for(int i=0; i<box_dims.nbDims; i++) box_size *= std::max(1, box_dims.d[i]);
    size_t dir_size = 1; for(int i=0; i<dir_dims.nbDims; i++) dir_size *= std::max(1, dir_dims.d[i]);

    CHECK_CUDA(cudaMalloc(&buffers_[output_index_cls_], cls_size * sizeof(float)));
    CHECK_CUDA(cudaMalloc(&buffers_[output_index_box_], box_size * sizeof(float)));
    CHECK_CUDA(cudaMalloc(&buffers_[output_index_dir_], dir_size * sizeof(float)));

    return true;
}

bool TensorRTInfer::doInference(const float* voxels, const int* voxel_num_points, const int* voxel_coords, int num_voxels,
                                float* cls_preds, float* box_preds, float* dir_cls_preds) {
    if (!context_) return false;

    // Set dynamic shapes
    context_->setBindingDimensions(input_index_voxels_, nvinfer1::Dims3{num_voxels, 32, 4});
    context_->setBindingDimensions(input_index_num_points_, nvinfer1::Dims{1, {num_voxels}});
    context_->setBindingDimensions(input_index_coords_, nvinfer1::Dims2{num_voxels, 4});

    // Copy to Device
    CHECK_CUDA(cudaMemcpy(buffers_[input_index_voxels_], voxels, num_voxels * 32 * 4 * sizeof(float), cudaMemcpyHostToDevice));
    CHECK_CUDA(cudaMemcpy(buffers_[input_index_num_points_], voxel_num_points, num_voxels * sizeof(int), cudaMemcpyHostToDevice));
    CHECK_CUDA(cudaMemcpy(buffers_[input_index_coords_], voxel_coords, num_voxels * 4 * sizeof(int), cudaMemcpyHostToDevice));

    // Run inference
    bool status = context_->executeV2(buffers_);
    if (!status) return false;

    // Calculate output sizes dynamically
    auto cls_dims = context_->getBindingDimensions(output_index_cls_);
    auto box_dims = context_->getBindingDimensions(output_index_box_);
    auto dir_dims = context_->getBindingDimensions(output_index_dir_);

    size_t cls_size = 1; for(int i=0; i<cls_dims.nbDims; i++) cls_size *= cls_dims.d[i];
    size_t box_size = 1; for(int i=0; i<box_dims.nbDims; i++) box_size *= box_dims.d[i];
    size_t dir_size = 1; for(int i=0; i<dir_dims.nbDims; i++) dir_size *= dir_dims.d[i];

    // Copy back
    CHECK_CUDA(cudaMemcpy(cls_preds, buffers_[output_index_cls_], cls_size * sizeof(float), cudaMemcpyDeviceToHost));
    CHECK_CUDA(cudaMemcpy(box_preds, buffers_[output_index_box_], box_size * sizeof(float), cudaMemcpyDeviceToHost));
    CHECK_CUDA(cudaMemcpy(dir_cls_preds, buffers_[output_index_dir_], dir_size * sizeof(float), cudaMemcpyDeviceToHost));

    return true;
}
