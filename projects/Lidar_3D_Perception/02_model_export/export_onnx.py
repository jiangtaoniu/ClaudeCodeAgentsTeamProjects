import sys
import os
import torch
import torch.nn as nn
import numpy as np

# Add OpenPCDet to PYTHONPATH
ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OPENPCDET_DIR = os.path.join(ROOT_DIR, "02_model_export", "OpenPCDet")
sys.path.append(OPENPCDET_DIR)

from pcdet.config import cfg, cfg_from_yaml_file
from pcdet.models import build_network

class MockDataset:
    def __init__(self, dataset_cfg):
        self.dataset_cfg = dataset_cfg
        self.class_names = cfg.CLASS_NAMES
        self.point_cloud_range = np.array(dataset_cfg.POINT_CLOUD_RANGE, dtype=np.float32)
        
        # Get voxel size from processor config
        for processor in dataset_cfg.DATA_PROCESSOR:
            if processor.NAME == 'transform_points_to_voxels':
                self.voxel_size = np.array(processor.VOXEL_SIZE, dtype=np.float32)
                break
        
        # Grid size
        grid_size = (self.point_cloud_range[3:6] - self.point_cloud_range[0:3]) / self.voxel_size
        self.grid_size = np.round(grid_size).astype(np.int64)
        
        # Point feature encoder
        class MockPFE:
            def __init__(self, num_features):
                self.num_point_features = num_features
        
        num_features = 4
        for augmentor in dataset_cfg.get('DATA_AUGMENTOR', {}).get('AUG_CONFIG_LIST', []):
            if augmentor.get('NAME') == 'gt_sampling':
                num_features = augmentor.get('NUM_POINT_FEATURES', 4)
        
        self.point_feature_encoder = MockPFE(num_features)
        self.depth_downsample_factor = None

class PointPillarsONNX(nn.Module):
    def __init__(self, model):
        super().__init__()
        self.vfe = model.vfe
        self.map_to_bev = model.map_to_bev_module
        self.backbone_2d = model.backbone_2d
        self.dense_head = model.dense_head

        # Monkey patch PointPillarScatter to remove dynamic batch loop
        # and hardcode batch_size = 1
        def scatter_forward(batch_dict, **kwargs):
            pillar_features, coords = batch_dict['pillar_features'], batch_dict['voxel_coords']
            # We assume batch_size = 1 for ONNX export
            spatial_feature = torch.zeros(
                (self.map_to_bev.nz * self.map_to_bev.nx * self.map_to_bev.ny, self.map_to_bev.num_bev_features),
                dtype=pillar_features.dtype,
                device=pillar_features.device
            )
            # coords is [N, 4]. For batch_size=1, coords[:, 0] is always 0.
            # indices = z * ny * nx + y * nx + x
            # Since nz=1 for PointPillars, it's just y * nx + x
            indices = coords[:, 2] * self.map_to_bev.nx + coords[:, 3]
            indices = indices.type(torch.long)
            
            spatial_feature[indices, :] = pillar_features
            spatial_feature = spatial_feature.t()
            
            batch_spatial_features = spatial_feature.view(1, self.map_to_bev.num_bev_features * self.map_to_bev.nz, self.map_to_bev.ny, self.map_to_bev.nx)
            batch_dict['spatial_features'] = batch_spatial_features
            return batch_dict

        self.map_to_bev.forward = scatter_forward

    def forward(self, voxels, voxel_num_points, voxel_coords):
        batch_dict = {
            'voxels': voxels,
            'voxel_num_points': voxel_num_points,
            'voxel_coords': voxel_coords,
            'batch_size': 1
        }
        
        batch_dict = self.vfe(batch_dict)
        batch_dict = self.map_to_bev(batch_dict)
        batch_dict = self.backbone_2d(batch_dict)
        batch_dict = self.dense_head(batch_dict)
        
        return self.dense_head.forward_ret_dict['cls_preds'], self.dense_head.forward_ret_dict['box_preds'], self.dense_head.forward_ret_dict.get('dir_cls_preds')

def main():
    cfg_file = os.path.join(OPENPCDET_DIR, "tools/cfgs/kitti_models/pointpillar.yaml")
    ckpt_path = os.path.join(OPENPCDET_DIR, "checkpoints/pointpillar_7728.pth")
    onnx_path = os.path.join(ROOT_DIR, "models/onnx/pointpillar.onnx")

    os.makedirs(os.path.dirname(onnx_path), exist_ok=True)

    os.chdir(os.path.join(OPENPCDET_DIR, "tools"))
    cfg_from_yaml_file(cfg_file, cfg)
    
    mock_dataset = MockDataset(cfg.DATA_CONFIG)
    
    model = build_network(model_cfg=cfg.MODEL, num_class=len(cfg.CLASS_NAMES), dataset=mock_dataset)
    model.load_state_dict(torch.load(ckpt_path, map_location='cpu')['model_state'])
    model.cuda()
    model.eval()

    onnx_model = PointPillarsONNX(model)
    onnx_model.eval()

    # Dummy inputs
    max_voxels = 10000
    dummy_voxels = torch.zeros((max_voxels, 32, 4), dtype=torch.float32).cuda()
    dummy_voxel_num = torch.ones((max_voxels,), dtype=torch.int32).cuda()
    dummy_coords = torch.zeros((max_voxels, 4), dtype=torch.int32).cuda()
    
    # Needs to be realistic coords to avoid index out of bounds in Scatter
    # map_to_bev shape: ny=496, nx=432
    dummy_coords[:, 2] = torch.randint(0, 496, (max_voxels,)).int().cuda()
    dummy_coords[:, 3] = torch.randint(0, 432, (max_voxels,)).int().cuda()

    print("Exporting ONNX model...")
    with torch.no_grad():
        torch.onnx.export(
            onnx_model,
            (dummy_voxels, dummy_voxel_num, dummy_coords),
            onnx_path,
            input_names=['voxels', 'voxel_num_points', 'voxel_coords'],
            output_names=['cls_preds', 'box_preds', 'dir_cls_preds'],
            dynamic_axes={
                'voxels': {0: 'voxel_num'},
                'voxel_num_points': {0: 'voxel_num'},
                'voxel_coords': {0: 'voxel_num'},
            },
            opset_version=11
        )
    print(f"ONNX exported successfully to {onnx_path}")

    # Verify with onnxruntime
    import onnxruntime as ort

    print("Verifying ONNX model with ONNX Runtime...")
    sess_options = ort.SessionOptions()
    sess = ort.InferenceSession(onnx_path, sess_options, providers=['CUDAExecutionProvider', 'CPUExecutionProvider'])

    out_onnx = sess.run(
        None, 
        {
            'voxels': dummy_voxels.cpu().numpy(),
            'voxel_num_points': dummy_voxel_num.cpu().numpy(),
            'voxel_coords': dummy_coords.cpu().numpy(),
        }
    )

    with torch.no_grad():
        out_pytorch = onnx_model(dummy_voxels, dummy_voxel_num, dummy_coords)
    
    max_diff = 0
    for o_onnx, o_pt in zip(out_onnx, out_pytorch):
        diff = np.abs(o_onnx - o_pt.cpu().detach().numpy()).max()
        max_diff = max(max_diff, diff)

    print(f"Max difference between PyTorch and ONNX Runtime: {max_diff}")
    if max_diff < 1e-4:
        print("[SUCCESS] Output matches PyTorch!")
    else:
        print("[WARNING] Output difference is large.")

if __name__ == '__main__':
    main()
