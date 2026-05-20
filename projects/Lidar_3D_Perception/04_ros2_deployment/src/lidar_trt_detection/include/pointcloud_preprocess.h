#ifndef POINTCLOUD_PREPROCESS_H
#define POINTCLOUD_PREPROCESS_H

#include <vector>

struct VoxelConfig {
    float min_x = 0.0f;
    float max_x = 69.12f;
    float min_y = -39.68f;
    float max_y = 39.68f;
    float min_z = -3.0f;
    float max_z = 1.0f;
    float voxel_x = 0.16f;
    float voxel_y = 0.16f;
    float voxel_z = 4.0f;
    int max_points_per_voxel = 32;
    int max_voxels = 16000;
};

class PointCloudPreprocess {
public:
    PointCloudPreprocess(const VoxelConfig& config);
    ~PointCloudPreprocess();

    // points format: x, y, z, intensity
    // outputs: voxels [N, 32, 4], voxel_num_points [N], voxel_coords [N, 4]
    void process(const float* points, int num_points, 
                 float* voxels, int* voxel_num_points, int* voxel_coords, int& valid_voxels);

private:
    VoxelConfig config_;
    int grid_x_, grid_y_, grid_z_;
    int* voxel_mapping_; // to track if a voxel is already created
};

#endif // POINTCLOUD_PREPROCESS_H
