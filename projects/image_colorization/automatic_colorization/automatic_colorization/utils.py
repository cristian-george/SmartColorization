import numpy as np
import tensorflow as tf
from keras.utils import load_img, img_to_array
from skimage.color import rgb2lab, gray2rgb
from tensorflow.python.eager.context import LogicalDeviceConfiguration
from tensorflow.python.framework import config


def load_image(image_path):
    # Load a grayscale image and normalize it
    image = img_to_array(load_img(image_path, color_mode='grayscale')) / 255.0

    # Copy the information that is stored on the first channel to the other two channels for simulating an RGB image
    image = gray2rgb(image)
    image = np.reshape(image, (image.shape[0], image.shape[1], 3))
    return image


def rgb2lab_split_image(image):
    # Convert the image to LAB color space
    lab = rgb2lab(image)
    # Get the L channel
    luminance = lab[:, :, 0]
    # Get the AB channels and normalize them to the range [-1, 1]
    chrominance = lab[:, :, 1:] / 128.0
    # Return the L and AB channels as a tuple
    return luminance, chrominance


def limit_gpu_memory(memory_limit=1024):
    gpus = tf.config.list_physical_devices('GPU')
    if gpus:
        try:
            config.set_logical_device_configuration(gpus[0], [LogicalDeviceConfiguration(memory_limit=memory_limit)])
            print("Using GPU: {}".format(gpus[0]))
        except RuntimeError as e:
            print(e)


def increase_cpu_num_threads(num_threads=1):
    cpus = tf.config.list_physical_devices('CPU')
    if cpus:
        try:
            config.set_inter_op_parallelism_threads(num_threads=num_threads)
            config.set_intra_op_parallelism_threads(num_threads=num_threads)
            print("Using CPU: {} threads".format(num_threads))
        except RuntimeError as e:
            print(e)


def check_gpu_support():
    gpus = tf.config.list_physical_devices('GPU')
    if tf.test.is_built_with_cuda() and tf.test.is_built_with_gpu_support() and gpus:
        print("TensorFlow was built with CUDA support")
        print("TensorFlow was built with cuDNN support")
        return True

    return False


def convert_h5_to_tflite(h5_model_path, tflite_model_path):
    # Load the .h5 model
    keras_model = tf.keras.models.load_model(h5_model_path)
    keras_model.compile(optimizer='adam', loss='mse')

    # Convert the model to a concrete function
    concrete_function = tf.function(lambda inputs: keras_model(inputs))
    concrete_function = concrete_function.get_concrete_function(
        [tf.TensorSpec(shape=keras_model.inputs[i].shape, dtype=keras_model.inputs[i].dtype) for i in
         range(len(keras_model.inputs))]
    )

    # Convert the model to TensorFlow Lite format
    converter = tf.lite.TFLiteConverter.from_concrete_functions([concrete_function], trackable_obj=keras_model)
    tflite_model = converter.convert()

    # Save the .tflite model to a file
    with open(tflite_model_path, 'wb') as f:
        f.write(tflite_model)
