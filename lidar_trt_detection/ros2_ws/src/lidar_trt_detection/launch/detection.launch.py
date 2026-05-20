import os
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    pkg_dir = get_package_share_directory('lidar_trt_detection')
    rviz_config_file = os.path.join(pkg_dir, 'rviz', 'detection.rviz')
    
    # Needs absolute path to engine depending on where it's stored.
    # Assuming it's in the workspace root or passed as argument.
    engine_path = os.path.join(os.getcwd(), 'models', 'engine', 'pointpillar.engine')

    return LaunchDescription([
        Node(
            package='lidar_trt_detection',
            executable='lidar_detection_node',
            name='lidar_detection_node',
            output='screen',
            parameters=[
                {'engine_path': engine_path}
            ]
        ),
        Node(
            package='rviz2',
            executable='rviz2',
            name='rviz2',
            arguments=['-d', rviz_config_file],
            output='screen'
        )
    ])
