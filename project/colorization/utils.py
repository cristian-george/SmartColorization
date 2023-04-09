import os

from keras.utils import load_img, img_to_array
from skimage.color import rgb2lab
from skimage.transform import resize
import tensorflow as tf


def load_image(image_path, output_shape=(224, 224), anti_aliasing=False):
    original_image = img_to_array(load_img(image_path))
    input_shape = (original_image.shape[0], original_image.shape[1])

    resized_image = resize_image(original_image, output_shape, anti_aliasing)
    return original_image, resized_image, input_shape


def resize_image(image, size, anti_aliasing=False):
    image = resize(image, size, anti_aliasing)
    return image


def normalize_image(image, value):
    image /= value


def denormalize_image(image, value):
    image *= value


# Define a function to get the L and AB channels from an RGB image
def get_lab(image):
    # Convert the image to LAB color space
    lab = rgb2lab(image)
    # Get the L channel
    lum = lab[:, :, 0]
    # Get the AB channels and normalize them to the range [-1, 1]
    ab = lab[:, :, 1:] / 128.
    # Return the L and AB channels as a tuple
    return lum, ab


def check_gpu_available():
    gpus = tf.config.list_physical_devices('GPU')
    if gpus:
        for gpu in gpus:
            tf.config.experimental.set_memory_growth(gpu, True)
            print("Using gpu: {}".format(gpu))
    else:
        num_threads = os.cpu_count()
        tf.config.threading.set_inter_op_parallelism_threads(num_threads=num_threads)
        tf.config.threading.set_intra_op_parallelism_threads(num_threads=num_threads)
        print("Using cpu: {} threads".format(num_threads))
