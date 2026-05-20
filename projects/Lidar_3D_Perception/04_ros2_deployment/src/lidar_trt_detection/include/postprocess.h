#ifndef POSTPROCESS_H
#define POSTPROCESS_H

#include <vector>
#include <string>

struct BoundingBox {
    float x;
    float y;
    float z;
    float dx;
    float dy;
    float dz;
    float heading;
    float score;
    int label;
};

class Postprocess {
public:
    Postprocess(int num_classes = 3, float score_thresh = 0.3f, float nms_thresh = 0.01f);
    ~Postprocess() = default;

    std::vector<BoundingBox> process(const float* cls_preds, const float* box_preds, const float* dir_cls_preds,
                                     int grid_y, int grid_x);

private:
    int num_classes_;
    float score_thresh_;
    float nms_thresh_;

    float iou_bev(const BoundingBox& a, const BoundingBox& b);
    void nms(std::vector<BoundingBox>& boxes);
};

#endif // POSTPROCESS_H
