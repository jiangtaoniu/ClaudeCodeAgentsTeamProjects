cmake_minimum_required(VERSION 3.8)
project(lidar_trt_detection)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic -O3)
endif()

# Find dependencies
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(pcl_conversions REQUIRED)

# CUDA
find_package(CUDA REQUIRED)

# TensorRT (Custom paths might be needed depending on installation)
# Assuming TensorRT is in the system path or LD_LIBRARY_PATH
find_library(TENSORRT_LIBRARY nvinfer)
find_library(TENSORRT_PARSER nvonnxparser)

# Include directories
include_directories(
  include
  ${CUDA_INCLUDE_DIRS}
)

# Source files
set(SRCS
  src/tensorrt_infer.cpp
  src/pointcloud_preprocess.cpp
  src/postprocess.cpp
  src/lidar_detection_node.cpp
)

# Executable
add_executable(lidar_detection_node ${SRCS})

# Include directories for executable
target_include_directories(lidar_detection_node PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

# Link libraries
ament_target_dependencies(lidar_detection_node
  rclcpp
  sensor_msgs
  visualization_msgs
  pcl_conversions
)

target_link_libraries(lidar_detection_node
  ${CUDA_LIBRARIES}
  ${TENSORRT_LIBRARY}
  ${TENSORRT_PARSER}
)

# Install
install(TARGETS lidar_detection_node
  DESTINATION lib/${PROJECT_NAME}
)

install(DIRECTORY launch config rviz
  DESTINATION share/${PROJECT_NAME}
)

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_dependencies()
endif()

ament_package()
