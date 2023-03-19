import os
import numpy as np
import tensorflow as tf
from skimage.io import imsave
from skimage.color import lab2rgb, rgb2lab
from utils import load_image, resize_image, normalize_image, denormalize_image


def predict_image(model, input_path, result_path):
    original_image, resized_image, input_shape = load_image(input_path, (224, 224), anti_aliasing=True)
    normalize_image(original_image, 255)
    normalize_image(resized_image, 255)

    lab = rgb2lab(resized_image)
    lum = lab[:, :, 0]
    grayscale_image = np.reshape(lum, (1, 224, 224, 1))

    ab = model.predict(grayscale_image, verbose=0)
    denormalize_image(ab, 128)
    result = np.zeros((224, 224, 3))
    result[:, :, 1:] = ab

    result = resize_image(result, (input_shape[0], input_shape[1]), anti_aliasing=True)
    result[:, :, 0] = rgb2lab(original_image)[:, :, 0]
    result = lab2rgb(result)
    denormalize_image(result, 255)

    imsave(result_path, result.astype('uint8'))


def main():
    inputs_path = "images/inputs/"
    results_path = "images/results/"
    model_path = "models/colorization_model_places365.h5"

    model = tf.keras.models.load_model(model_path)
    for filename in os.listdir(inputs_path):
        input_path = inputs_path + '/' + filename
        result_path = results_path + '/result_' + filename
        predict_image(model, input_path, result_path)


if __name__ == "__main__":
    main()
