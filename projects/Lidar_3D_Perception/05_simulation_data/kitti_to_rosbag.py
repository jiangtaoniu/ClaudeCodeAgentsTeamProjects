import rclpy
from rclpy.node import Node
from sensor_msgs.msg import PointCloud2, PointField
import numpy as np
import os
import glob
import time
from std_msgs.msg import Header

class KittiPublisher(Node):
    def __init__(self):
        super().__init__('kitti_publisher')
        self.publisher_ = self.create_publisher(PointCloud2, '/points_raw', 10)
        self.timer = self.create_timer(0.1, self.timer_callback) # 10 Hz
        
        # Look for kitti bin files
        self.data_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'data', 'kitti', 'training', 'velodyne')
        if not os.path.exists(self.data_path):
            self.data_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), '02_model_export', 'OpenPCDet', 'demo_data')
            
        if not os.path.exists(self.data_path):
            self.get_logger().warn("No data path found!")
            self.files = []
        else:
            self.files = sorted(glob.glob(os.path.join(self.data_path, '*.bin')))
            
        self.idx = 0

    def timer_callback(self):
        if not self.files:
            return
            
        if self.idx >= len(self.files):
            self.idx = 0
            
        bin_file = self.files[self.idx]
        points = np.fromfile(bin_file, dtype=np.float32).reshape(-1, 4)
        
        msg = PointCloud2()
        msg.header = Header()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.header.frame_id = "velodyne"
        
        msg.height = 1
        msg.width = points.shape[0]
        msg.fields = [
            PointField(name='x', offset=0, datatype=PointField.FLOAT32, count=1),
            PointField(name='y', offset=4, datatype=PointField.FLOAT32, count=1),
            PointField(name='z', offset=8, datatype=PointField.FLOAT32, count=1),
            PointField(name='intensity', offset=12, datatype=PointField.FLOAT32, count=1),
        ]
        msg.is_bigendian = False
        msg.point_step = 16
        msg.row_step = msg.point_step * msg.width
        msg.is_dense = True
        msg.data = points.tobytes()
        
        self.publisher_.publish(msg)
        self.get_logger().info(f"Published {os.path.basename(bin_file)} with {points.shape[0]} points.")
        self.idx += 1

def main(args=None):
    rclpy.init(args=args)
    node = KittiPublisher()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()
