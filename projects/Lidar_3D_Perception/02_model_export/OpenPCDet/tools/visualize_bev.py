import json
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from pathlib import Path

def get_corners(box):
    # box: x, y, z, l, w, h, yaw
    x, y, z, l, w, h, yaw = box['x'], box['y'], box['z'], box['l'], box['w'], box['h'], box['yaw']
    
    # 2D bounding box corners
    cos_yaw = np.cos(yaw)
    sin_yaw = np.sin(yaw)
    
    # Base coordinates for corners
    x_corners = np.array([l/2, l/2, -l/2, -l/2])
    y_corners = np.array([w/2, -w/2, -w/2, w/2])
    
    # Rotate and translate
    corners_x = x_corners * cos_yaw - y_corners * sin_yaw + x
    corners_y = x_corners * sin_yaw + y_corners * cos_yaw + y
    
    return np.vstack((corners_x, corners_y)).T

def visualize_bev():
    bin_path = Path('../demo_data/000008.bin')
    json_path = Path('../demo_data/demo_results.json')
    output_path = Path('../demo_data/result_bev.png')
    
    # Load point cloud
    points = np.fromfile(bin_path, dtype=np.float32).reshape(-1, 4)
    points_x = points[:, 0]
    points_y = points[:, 1]
    
    # Load results
    with open(json_path, 'r') as f:
        results = json.load(f)[0]['detections']
        
    plt.figure(figsize=(12, 12))
    
    # Set background color to dark
    plt.style.use('dark_background')
    
    # Plot point cloud (birds eye view)
    plt.scatter(points_x, points_y, s=0.1, c=points[:, 2], cmap='viridis', alpha=0.5)
    
    colors = {
        'Car': 'cyan',
        'Pedestrian': 'red',
        'Cyclist': 'yellow'
    }
    
    # Plot bounding boxes
    for det in results:
        label = det['label']
        score = det['score']
        
        # Only plot high confidence ones to keep it clean
        if score < 0.3:
            continue
            
        color = colors.get(label, 'white')
        corners = get_corners(det['box'])
        
        # Draw box
        polygon = patches.Polygon(corners, closed=True, fill=False, edgecolor=color, linewidth=2)
        plt.gca().add_patch(polygon)
        
        # Add label text (with direction indicator)
        front_x, front_y = (corners[0] + corners[1]) / 2
        plt.plot([det['box']['x'], front_x], [det['box']['y'], front_y], color=color, linewidth=1)
        plt.text(det['box']['x'], det['box']['y'], f"{label} {score:.2f}", 
                 color=color, fontsize=8, ha='center', va='center')

    plt.xlim(0, 60)
    plt.ylim(-30, 30)
    plt.title('Point Cloud Detection - Bird\'s Eye View (BEV)')
    plt.xlabel('X (front)')
    plt.ylabel('Y (left)')
    plt.grid(False)
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"Saved visualization to: {output_path.absolute()}")

if __name__ == '__main__':
    visualize_bev()
