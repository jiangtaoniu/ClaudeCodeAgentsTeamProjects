#ifndef TENSORRT_INFER_H
#define TENSORRT_INFER_H

#include <string>
#include <vector>
#include <memory>
#include <iostream>
#include <NvInfer.h>

class Logger : public nvinfer1::ILogger {
public:
    void log(Severity severity, const char* msg) noexcept override {
        if (severity <= Severity::kWARNING) {
            std::cout << "[TRT] " << msg << std::endl;
        }
    }
};

class TensorRTInfer {
public:
    TensorRTInfer();
    ~TensorRTInfer();

    bool loadEngine(const std::string& engine_path);
    
    // Inputs: voxels [N, 32, 4], voxel_num_points [N], voxel_coords [N, 4]
    // Outputs: cls_preds, box_preds, dir_cls_preds
    bool doInference(const float* voxels, const int* voxel_num_points, const int* voxel_coords, int num_voxels,
                     float* cls_preds, float* box_preds, float* dir_cls_preds);

private:
    Logger gLogger;
    std::unique_ptr<nvinfer1::IRuntime> runtime_;
    std::shared_ptr<nvinfer1::ICudaEngine> engine_;
    std::unique_ptr<nvinfer1::IExecutionContext> context_;

    void* buffer_voxels_ = nullptr;
    void* buffer_num_points_ = nullptr;
    void* buffer_coords_ = nullptr;
    void* buffer_cls_ = nullptr;
    void* buffer_box_ = nullptr;
    void* buffer_dir_ = nullptr;
};

#endif // TENSORRT_INFER_H
