import numpy as np
import tensorflow as tf
from skimage.color import rgb2lab, gray2rgb, lab2rgb
from skimage.io import imsave

from utils import load_image, normalize_image, resize_image

tf.config.threading.set_inter_op_parallelism_threads(num_threads=8)
print(tf.config.threading.get_intra_op_parallelism_threads())

vgg19_encoder = tf.keras.models.load_model("models/vgg19_encoder.h5")
decoder = tf.keras.models.load_model("models/decoder.h5")

image_path = "images/image.jpg"

loaded_image, input_shape = load_image(image_path, (224, 224), anti_aliasing=True)
normalize_image(loaded_image, 1. / 255)

lab = rgb2lab(loaded_image)
lum = lab[:, :, 0]
grayscale_image = gray2rgb(lum)
grayscale_image = grayscale_image.reshape((1, 224, 224, 3))

encoder_prediction = vgg19_encoder.predict(grayscale_image, verbose=0)
ab = decoder.predict(encoder_prediction, verbose=0)
ab *= 128
result = np.zeros((224, 224, 3))
result[:, :, 0] = lum
result[:, :, 1:] = ab

result = resize_image(result, (input_shape[0], input_shape[1]), anti_aliasing=True)

result = lab2rgb(result)
normalize_image(result, 255)

imsave("images/result.jpg", result.astype('uint8'))
