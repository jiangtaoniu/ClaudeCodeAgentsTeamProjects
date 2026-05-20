#include "pointcloud_preprocess.h"
#include <cstring>
#include <cmath>

PointCloudPreprocess::PointCloudPreprocess(const VoxelConfig& config) : config_(config) {
    grid_x_ = static_cast<int>(std::round((config_.max_x - config_.min_x) / config_.voxel_x));
    grid_y_ = static_cast<int>(std::round((config_.max_y - config_.min_y) / config_.voxel_y));
    grid_z_ = static_cast<int>(std::round((config_.max_z - config_.min_z) / config_.voxel_z));
    voxel_mapping_ = new int[grid_x_ * grid_y_ * grid_z_];
}

PointCloudPreprocess::~PointCloudPreprocess() {
    delete[] voxel_mapping_;
}

void PointCloudPreprocess::process(const float* points, int num_points, 
                                   float* voxels, int* voxel_num_points, int* voxel_coords, int& valid_voxels) {
    // Reset mapping
    std::memset(voxel_mapping_, -1, grid_x_ * grid_y_ * grid_z_ * sizeof(int));
    valid_voxels = 0;

    for (int i = 0; i < num_points; ++i) {
        float x = points[i * 4 + 0];
        float y = points[i * 4 + 1];
        float z = points[i * 4 + 2];
        float intensity = points[i * 4 + 3];

        if (x < config_.min_x || x >= config_.max_x ||
            y < config_.min_y || y >= config_.max_y ||
            z < config_.min_z || z >= config_.max_z) {
            continue;
        }

        int c_x = static_cast<int>((x - config_.min_x) / config_.voxel_x);
        int c_y = static_cast<int>((y - config_.min_y) / config_.voxel_y);
        int c_z = static_cast<int>((z - config_.min_z) / config_.voxel_z);

        if (c_x < 0 || c_x >= grid_x_ || c_y < 0 || c_y >= grid_y_ || c_z < 0 || c_z >= grid_z_) {
            continue;
        }

        int grid_idx = c_z * grid_y_ * grid_x_ + c_y * grid_x_ + c_x;
        int voxel_idx = voxel_mapping_[grid_idx];

        if (voxel_idx == -1) {
            if (valid_voxels >= config_.max_voxels) continue;
            voxel_idx = valid_voxels++;
            voxel_mapping_[grid_idx] = voxel_idx;
            voxel_num_points[voxel_idx] = 0;
            voxel_coords[voxel_idx * 4 + 0] = 0; // batch_idx (usually 0)
            voxel_coords[voxel_idx * 4 + 1] = c_z;
            voxel_coords[voxel_idx * 4 + 2] = c_y;
            voxel_coords[voxel_idx * 4 + 3] = c_x;
        }

        int p_idx = voxel_num_points[voxel_idx];
        if (p_idx < config_.max_points_per_voxel) {
            int offset = voxel_idx * config_.max_points_per_voxel * 4 + p_idx * 4;
            voxels[offset + 0] = x;
            voxels[offset + 1] = y;
            voxels[offset + 2] = z;
            voxels[offset + 3] = intensity;
            voxel_num_points[voxel_idx]++;
        }
    }
}
