import numpy as np
import tensorflow as tf
from keras.layers import Concatenate
from keras.utils import load_img, img_to_array, save_img
from skimage.transform import resize

grayscale_image = img_to_array(load_img('gray.jpg', color_mode='grayscale'))

grayscale_image_resized = resize(grayscale_image, (224, 224), anti_aliasing=True)
grayscale_image_expanded = np.expand_dims(grayscale_image_resized, axis=(0, -1))

input_tensor = tf.keras.Input(shape=(224, 224, 1))
input_tensor_rgb = Concatenate(axis=-1)([input_tensor] * 3)

# Create a model to convert the grayscale image to a pseudo-RGB image
model = tf.keras.Model(inputs=input_tensor, outputs=input_tensor_rgb)

rgb_image = model.predict(grayscale_image_expanded)
save_img('rgb.jpg', rgb_image[0])
