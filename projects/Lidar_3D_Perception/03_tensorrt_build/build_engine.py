import tensorrt as trt
import os

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ONNX_MODEL = os.path.join(ROOT_DIR, "models/onnx/pointpillar.onnx")
TRT_ENGINE = os.path.join(ROOT_DIR, "models/engine/pointpillar.engine")

TRT_LOGGER = trt.Logger(trt.Logger.WARNING)

def build_engine():
    builder = trt.Builder(TRT_LOGGER)
    network = builder.create_network(1 << int(trt.NetworkDefinitionCreationFlag.EXPLICIT_BATCH))
    config = builder.create_builder_config()
    
    # We want FP16 if available
    if builder.platform_has_fast_fp16:
        config.set_flag(trt.BuilderFlag.FP16)
        
    parser = trt.OnnxParser(network, TRT_LOGGER)
    
    with open(ONNX_MODEL, 'rb') as model:
        if not parser.parse(model.read()):
            print("Failed to parse the ONNX file.")
            for error in range(parser.num_errors):
                print(parser.get_error(error))
            return None

    # Setup optimization profile for dynamic shapes
    profile = builder.create_optimization_profile()
    
    # Check what dynamic dimensions exist in the network
    for i in range(network.num_inputs):
        tensor = network.get_input(i)
        name = tensor.name
        shape = tensor.shape
        print(f"Input '{name}' with shape {shape}")
        
        if name == 'voxels':
            profile.set_shape(name, (1, 32, 4), (16000, 32, 4), (40000, 32, 4))
        elif name == 'voxel_num_points':
            profile.set_shape(name, (1,), (16000,), (40000,))
        elif name == 'voxel_coords':
            profile.set_shape(name, (1, 4), (16000, 4), (40000, 4))
            
    config.add_optimization_profile(profile)

    print("Building TensorRT engine. This may take a few minutes...")
    engine_bytes = builder.build_serialized_network(network, config)
    if engine_bytes is None:
        print("Failed to build engine.")
        return None
        
    os.makedirs(os.path.dirname(TRT_ENGINE), exist_ok=True)
    with open(TRT_ENGINE, 'wb') as f:
        f.write(engine_bytes)
    print(f"Successfully exported TensorRT engine to {TRT_ENGINE}")

if __name__ == '__main__':
    build_engine()
