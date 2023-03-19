import tensorflow as tf

if tf.test.is_built_with_cuda():
    print("TensorFlow was built with CUDA support")
else:
    print("TensorFlow was not built with CUDA support")

if tf.test.is_built_with_gpu_support():
    print("TensorFlow was built with cuDNN support")
else:
    print("TensorFlow was not built with cuDNN support")
