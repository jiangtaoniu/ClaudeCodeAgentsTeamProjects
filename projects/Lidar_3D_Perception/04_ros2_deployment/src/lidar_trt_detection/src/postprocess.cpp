#include "postprocess.h"
#include <cmath>
#include <algorithm>
#include <iostream>

Postprocess::Postprocess(int num_classes, float score_thresh, float nms_thresh)
    : num_classes_(num_classes), score_thresh_(score_thresh), nms_thresh_(nms_thresh) {}

float Postprocess::iou_bev(const BoundingBox& a, const BoundingBox& b) {
    // Simplified IoU calculation for BEV (Axis aligned approximation for speed, can be improved to rotated IoU)
    float a_min_x = a.x - a.dx / 2; float a_max_x = a.x + a.dx / 2;
    float a_min_y = a.y - a.dy / 2; float a_max_y = a.y + a.dy / 2;

    float b_min_x = b.x - b.dx / 2; float b_max_x = b.x + b.dx / 2;
    float b_min_y = b.y - b.dy / 2; float b_max_y = b.y + b.dy / 2;

    float inter_min_x = std::max(a_min_x, b_min_x);
    float inter_min_y = std::max(a_min_y, b_min_y);
    float inter_max_x = std::min(a_max_x, b_max_x);
    float inter_max_y = std::min(a_max_y, b_max_y);

    float inter_area = std::max(0.0f, inter_max_x - inter_min_x) * std::max(0.0f, inter_max_y - inter_min_y);
    float union_area = a.dx * a.dy + b.dx * b.dy - inter_area;

    if (union_area <= 0.0f) return 0.0f;
    return inter_area / union_area;
}

void Postprocess::nms(std::vector<BoundingBox>& boxes) {
    std::sort(boxes.begin(), boxes.end(), [](const BoundingBox& a, const BoundingBox& b) {
        return a.score > b.score;
    });

    std::vector<BoundingBox> keep;
    std::vector<bool> suppressed(boxes.size(), false);

    for (size_t i = 0; i < boxes.size(); ++i) {
        if (suppressed[i]) continue;
        keep.push_back(boxes[i]);
        for (size_t j = i + 1; j < boxes.size(); ++j) {
            if (suppressed[j]) continue;
            if (iou_bev(boxes[i], boxes[j]) > nms_thresh_) {
                suppressed[j] = true;
            }
        }
    }
    boxes = keep;
}

std::vector<BoundingBox> Postprocess::process(const float* cls_preds, const float* box_preds, const float* dir_cls_preds,
                                              int grid_y, int grid_x) {
    std::vector<BoundingBox> boxes;
    int num_anchors_per_cell = 2; // Typically 2 anchors (0 and 90 degrees) for 3 classes
    int num_box_attrs = 7; // x, y, z, w, l, h, theta

    // Simplified anchor generation and decoding matching PointPillars configuration
    float voxel_x = 0.16f, voxel_y = 0.16f;
    float point_cloud_range[6] = {0, -39.68f, -3, 69.12f, 39.68f, 1};

    int num_anchors = 6; // 2 for Car, 2 for Ped, 2 for Cyc
    int num_classes = 3;

    for (int y = 0; y < grid_y; ++y) {
        for (int x = 0; x < grid_x; ++x) {
            for (int a = 0; a < num_anchors; ++a) {
                int class_id = a / 2; // 0=Car, 1=Ped, 2=Cyc
                
                // cls_preds is [1, 496, 432, 18] -> 6 anchors * 3 classes
                int cls_idx = (y * grid_x + x) * (num_anchors * num_classes) + a * num_classes + class_id;
                
                float score = 1.0f / (1.0f + std::exp(-cls_preds[cls_idx]));
                if (score > score_thresh_) {
                    // box_preds is [1, 496, 432, 42] -> 6 anchors * 7 attrs
                    int box_idx = (y * grid_x + x) * (num_anchors * num_box_attrs) + a * num_box_attrs;
                    
                    // Simple Box Decoding (anchor sizes per class)
                    // Feature map stride is 2, so each grid cell corresponds to 2x2 voxels
                    float xa = point_cloud_range[0] + x * voxel_x * 2.0f + voxel_x;
                    float ya = point_cloud_range[1] + y * voxel_y * 2.0f + voxel_y;
                    float za = -1.0f, wa = 1.6f, la = 3.9f, ha = 1.56f;
                    
                    if (class_id == 0) { za = -1.78f; wa = 1.6f; la = 3.9f; ha = 1.56f; }
                    else if (class_id == 1) { za = -0.6f; wa = 0.6f; la = 0.8f; ha = 1.73f; }
                    else if (class_id == 2) { za = -0.6f; wa = 0.6f; la = 1.76f; ha = 1.73f; }
                    
                    float anchor_rot = (a % 2 == 0) ? 0.0f : 1.57f;

                    BoundingBox box;
                    box.x = xa + box_preds[box_idx + 0] * std::sqrt(wa * wa + la * la);
                    box.y = ya + box_preds[box_idx + 1] * std::sqrt(wa * wa + la * la);
                    box.z = za + box_preds[box_idx + 2] * ha;
                    box.dx = std::exp(box_preds[box_idx + 3]) * wa;
                    box.dy = std::exp(box_preds[box_idx + 4]) * la;
                    box.dz = std::exp(box_preds[box_idx + 5]) * ha;
                    box.heading = box_preds[box_idx + 6] + anchor_rot;
                    
                    if (dir_cls_preds) {
                        // dir_cls_preds is [1, 496, 432, 12] -> 6 anchors * 2 dirs
                        int dir_idx = (y * grid_x + x) * (num_anchors * 2) + a * 2;
                        if (dir_cls_preds[dir_idx] < dir_cls_preds[dir_idx + 1]) {
                            box.heading += M_PI;
                        }
                    }

                    box.score = score;
                    box.label = class_id;
                    boxes.push_back(box);
                }
            }
        }
    }

    nms(boxes);
    return boxes;
}
