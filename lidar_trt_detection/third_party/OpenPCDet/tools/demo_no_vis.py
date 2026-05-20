"""
OpenPCDet Demo - 无可视化版本
跳过 open3d/mayavi 的导入，只输出检测结果到终端和 JSON 文件。
适用于 WSL 无图形界面环境。

用法:
  cd ~/projects/ClaudeCodeAgentsTeamProjects/lidar_trt_detection/third_party/OpenPCDet/tools
  python demo_no_vis.py \
    --cfg_file cfgs/kitti_models/pointpillar.yaml \
    --ckpt ../checkpoints/pointpillar_7728.pth \
    --data_path ../demo_data/000008.bin
"""

import argparse
import glob
import json
from pathlib import Path

import numpy as np
import torch

from pcdet.config import cfg, cfg_from_yaml_file
from pcdet.datasets import DatasetTemplate
from pcdet.models import build_network, load_data_to_gpu
from pcdet.utils import common_utils


class DemoDataset(DatasetTemplate):
    def __init__(self, dataset_cfg, class_names, training=True, root_path=None, logger=None, ext='.bin'):
        super().__init__(
            dataset_cfg=dataset_cfg, class_names=class_names, training=training, root_path=root_path, logger=logger
        )
        self.root_path = root_path
        self.ext = ext
        data_file_list = glob.glob(str(root_path / f'*{self.ext}')) if self.root_path.is_dir() else [self.root_path]

        data_file_list.sort()
        self.sample_file_list = data_file_list

    def __len__(self):
        return len(self.sample_file_list)

    def __getitem__(self, index):
        if self.ext == '.bin':
            points = np.fromfile(self.sample_file_list[index], dtype=np.float32).reshape(-1, 4)
        elif self.ext == '.npy':
            points = np.load(self.sample_file_list[index])
        else:
            raise NotImplementedError

        input_dict = {
            'points': points,
            'frame_id': index,
        }

        data_dict = self.prepare_data(data_dict=input_dict)
        return data_dict


def parse_config():
    parser = argparse.ArgumentParser(description='arg parser')
    parser.add_argument('--cfg_file', type=str, default='cfgs/kitti_models/second.yaml',
                        help='specify the config for demo')
    parser.add_argument('--data_path', type=str, default='demo_data',
                        help='specify the point cloud data file or directory')
    parser.add_argument('--ckpt', type=str, default=None, help='specify the pretrained model')
    parser.add_argument('--ext', type=str, default='.bin', help='specify the extension of your point cloud data file')

    args = parser.parse_args()

    cfg_from_yaml_file(args.cfg_file, cfg)

    return args, cfg


KITTI_CLASS_NAMES = ['Car', 'Pedestrian', 'Cyclist']


def main():
    args, cfg = parse_config()
    logger = common_utils.create_logger()
    logger.info('=' * 60)
    logger.info('  OpenPCDet Demo (No Visualization)')
    logger.info('=' * 60)

    demo_dataset = DemoDataset(
        dataset_cfg=cfg.DATA_CONFIG, class_names=cfg.CLASS_NAMES, training=False,
        root_path=Path(args.data_path), ext=args.ext, logger=logger
    )
    logger.info(f'Total number of samples: \t{len(demo_dataset)}')

    model = build_network(model_cfg=cfg.MODEL, num_class=len(cfg.CLASS_NAMES), dataset=demo_dataset)
    model.load_params_from_file(filename=args.ckpt, logger=logger, to_cpu=True)
    model.cuda()
    model.eval()

    all_results = []

    with torch.no_grad():
        for idx, data_dict in enumerate(demo_dataset):
            logger.info(f'Processing sample index: \t{idx + 1}')
            data_dict = demo_dataset.collate_batch([data_dict])
            load_data_to_gpu(data_dict)
            pred_dicts, _ = model.forward(data_dict)

            pred_boxes = pred_dicts[0]['pred_boxes'].cpu().numpy()
            pred_scores = pred_dicts[0]['pred_scores'].cpu().numpy()
            pred_labels = pred_dicts[0]['pred_labels'].cpu().numpy()

            # 打印检测结果
            logger.info(f'--- Sample {idx + 1} Results ---')
            logger.info(f'  Total detections: {len(pred_scores)}')

            sample_results = []
            for i in range(len(pred_scores)):
                label_name = cfg.CLASS_NAMES[pred_labels[i] - 1] if pred_labels[i] <= len(cfg.CLASS_NAMES) else f'Unknown({pred_labels[i]})'
                box = pred_boxes[i]
                score = pred_scores[i]

                logger.info(
                    f'  [{i+1}] {label_name:12s}  score={score:.4f}  '
                    f'xyz=({box[0]:.2f}, {box[1]:.2f}, {box[2]:.2f})  '
                    f'lwh=({box[3]:.2f}, {box[4]:.2f}, {box[5]:.2f})  '
                    f'yaw={box[6]:.4f}'
                )

                sample_results.append({
                    'label': label_name,
                    'score': float(score),
                    'box': {
                        'x': float(box[0]), 'y': float(box[1]), 'z': float(box[2]),
                        'l': float(box[3]), 'w': float(box[4]), 'h': float(box[5]),
                        'yaw': float(box[6])
                    }
                })

            all_results.append({
                'sample_index': idx,
                'num_detections': len(pred_scores),
                'detections': sample_results
            })

    # 保存结果到 JSON 文件
    output_path = Path(args.data_path).parent / 'demo_results.json'
    with open(output_path, 'w') as f:
        json.dump(all_results, f, indent=2)
    logger.info(f'Results saved to: {output_path}')

    logger.info('=' * 60)
    logger.info('  Demo done successfully!')
    logger.info('=' * 60)


if __name__ == '__main__':
    main()
