#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/point_cloud2.hpp>
#include <visualization_msgs/msg/marker_array.hpp>
#include <pcl_conversions/pcl_conversions.h>
#include <pcl/point_cloud.h>
#include <pcl/point_types.h>

#include "tensorrt_infer.h"
#include "pointcloud_preprocess.h"
#include "postprocess.h"

class LidarDetectionNode : public rclcpp::Node {
public:
    LidarDetectionNode() : Node("lidar_detection_node") {
        this->declare_parameter<std::string>("engine_path", "models/engine/pointpillar.engine");
        std::string engine_path = this->get_parameter("engine_path").as_string();

        trt_infer_ = std::make_shared<TensorRTInfer>();
        if (!trt_infer_->loadEngine(engine_path)) {
            RCLCPP_ERROR(this->get_logger(), "Failed to load TensorRT Engine: %s", engine_path.c_str());
        } else {
            RCLCPP_INFO(this->get_logger(), "TensorRT Engine Loaded Successfully!");
        }

        VoxelConfig config;
        preprocessor_ = std::make_shared<PointCloudPreprocess>(config);
        postprocessor_ = std::make_shared<Postprocess>(3, 0.3f, 0.01f);

        // Grid sizes for PointPillars head (Feature Map Stride = 2)
        // BEV Grid is 496x432, Head Grid is 248x216
        grid_y_ = 248;
        grid_x_ = 216;

        // 6 anchors per cell. Classes=3.
        // cls_preds is [1, 248, 216, 18], box_preds is [1, 248, 216, 42], dir_preds is [1, 248, 216, 12]
        cls_preds_ = new float[grid_y_ * grid_x_ * 18];
        box_preds_ = new float[grid_y_ * grid_x_ * 42];
        dir_cls_preds_ = new float[grid_y_ * grid_x_ * 12];

        pointcloud_sub_ = this->create_subscription<sensor_msgs::msg::PointCloud2>(
            "/points_raw", 10, std::bind(&LidarDetectionNode::pointCloudCallback, this, std::placeholders::_1));
        
        marker_pub_ = this->create_publisher<visualization_msgs::msg::MarkerArray>("/detection/markers", 10);
        
        RCLCPP_INFO(this->get_logger(), "Lidar Detection Node Started.");
    }

    ~LidarDetectionNode() {
        delete[] cls_preds_;
        delete[] box_preds_;
        delete[] dir_cls_preds_;
    }

private:
    void pointCloudCallback(const sensor_msgs::msg::PointCloud2::SharedPtr msg) {
        pcl::PointCloud<pcl::PointXYZI>::Ptr pcl_pc(new pcl::PointCloud<pcl::PointXYZI>());
        pcl::fromROSMsg(*msg, *pcl_pc);

        int num_points = pcl_pc->points.size();
        std::vector<float> points(num_points * 4);
        for (int i = 0; i < num_points; ++i) {
            points[i * 4 + 0] = pcl_pc->points[i].x;
            points[i * 4 + 1] = pcl_pc->points[i].y;
            points[i * 4 + 2] = pcl_pc->points[i].z;
            points[i * 4 + 3] = pcl_pc->points[i].intensity;
        }

        const int MAX_VOXELS = 16000;
        std::vector<float> voxels(MAX_VOXELS * 32 * 4, 0.0f);
        std::vector<int> voxel_num_points(MAX_VOXELS, 0);
        std::vector<int> voxel_coords(MAX_VOXELS * 4, 0);
        int valid_voxels = 0;

        auto t1 = this->now();
        preprocessor_->process(points.data(), num_points, voxels.data(), voxel_num_points.data(), voxel_coords.data(), valid_voxels);
        auto t2 = this->now();

        if (valid_voxels == 0) return;

        bool infer_status = trt_infer_->doInference(voxels.data(), voxel_num_points.data(), voxel_coords.data(), valid_voxels,
                                                    cls_preds_, box_preds_, dir_cls_preds_);
        auto t3 = this->now();

        if (!infer_status) {
            RCLCPP_WARN(this->get_logger(), "Inference Failed");
            return;
        }

        auto boxes = postprocessor_->process(cls_preds_, box_preds_, dir_cls_preds_, grid_y_, grid_x_);
        auto t4 = this->now();

        RCLCPP_INFO(this->get_logger(), "Pre: %.2f ms | Infer: %.2f ms | Post: %.2f ms | Detections: %zu",
                    (t2 - t1).seconds() * 1000.0, (t3 - t2).seconds() * 1000.0, (t4 - t3).seconds() * 1000.0, boxes.size());

        publishMarkers(boxes, msg->header);
    }

    void publishMarkers(const std::vector<BoundingBox>& boxes, const std_msgs::msg::Header& header) {
        visualization_msgs::msg::MarkerArray marker_array;

        int id = 0;
        for (const auto& box : boxes) {
            visualization_msgs::msg::Marker marker;
            marker.header = header;
            marker.ns = "detections";
            marker.id = id++;
            marker.type = visualization_msgs::msg::Marker::CUBE;
            marker.action = visualization_msgs::msg::Marker::ADD;
            
            marker.pose.position.x = box.x;
            marker.pose.position.y = box.y;
            marker.pose.position.z = box.z;

            // Simplified quaternion from yaw
            marker.pose.orientation.x = 0.0;
            marker.pose.orientation.y = 0.0;
            marker.pose.orientation.z = sin(box.heading / 2.0);
            marker.pose.orientation.w = cos(box.heading / 2.0);

            marker.scale.x = box.dx;
            marker.scale.y = box.dy;
            marker.scale.z = box.dz;

            marker.color.a = 0.5;
            if (box.label == 0) { // Car
                marker.color.r = 0.0; marker.color.g = 1.0; marker.color.b = 0.0;
            } else if (box.label == 1) { // Pedestrian
                marker.color.r = 1.0; marker.color.g = 0.0; marker.color.b = 0.0;
            } else { // Cyclist
                marker.color.r = 0.0; marker.color.g = 0.0; marker.color.b = 1.0;
            }

            marker.lifetime = rclcpp::Duration::from_seconds(0.2);
            marker_array.markers.push_back(marker);
        }

        if (!marker_array.markers.empty()) {
            marker_pub_->publish(marker_array);
        }
    }

    std::shared_ptr<TensorRTInfer> trt_infer_;
    std::shared_ptr<PointCloudPreprocess> preprocessor_;
    std::shared_ptr<Postprocess> postprocessor_;
    
    int grid_y_, grid_x_;
    float *cls_preds_, *box_preds_, *dir_cls_preds_;

    rclcpp::Subscription<sensor_msgs::msg::PointCloud2>::SharedPtr pointcloud_sub_;
    rclcpp::Publisher<visualization_msgs::msg::MarkerArray>::SharedPtr marker_pub_;
};

int main(int argc, char** argv) {
    rclcpp::init(argc, argv);
    auto node = std::make_shared<LidarDetectionNode>();
    rclcpp::spin(node);
    rclcpp::shutdown();
    return 0;
}
