import os
import numpy as np
import tensorflow as tf
from skimage.io import imsave
from skimage.color import lab2rgb, rgb2lab, gray2rgb
from utils import check_gpu_available, load_image, resize_image, normalize_image, denormalize_image

check_gpu_available()

vgg19_model = tf.keras.models.load_model('models/vgg19.h5')


def predict_image(model, input_path, result_path):
    original_image, resized_image, input_shape = load_image(input_path, (224, 224), anti_aliasing=True)
    normalize_image(original_image, 255)
    normalize_image(resized_image, 255)

    lab = rgb2lab(resized_image)
    lum = lab[:, :, 0]
    gray_img = gray2rgb(lum)
    gray_img = gray_img.reshape((1, 224, 224, 3))

    prediction = vgg19_model.predict(gray_img, verbose=0)
    prediction = prediction.reshape((1, 7, 7, 512))

    ab = model.predict(prediction, verbose=0)

    denormalize_image(ab, 128)
    result = np.zeros((224, 224, 3))
    result[:, :, 1:] = ab

    result = resize_image(result, (input_shape[0], input_shape[1]), anti_aliasing=True)
    result[:, :, 0] = rgb2lab(original_image)[:, :, 0]
    result = lab2rgb(result)
    denormalize_image(result, 255)

    imsave(result_path, result.astype('uint8'))


INPUTS_PATH = "images/inputs/"
RESULTS_PATH = "images/results/"
MODEL_PATH = "models/"


def predict_dir_images(model_name):
    model = tf.keras.models.load_model(MODEL_PATH + model_name)
    for filename in os.listdir(INPUTS_PATH):
        input_path = INPUTS_PATH + filename
        result_path = RESULTS_PATH + 'result_' + filename
        predict_image(model, input_path, result_path)


def main():
    # predict_dir_images(model_name='colorization_model_flowers.h5')
    model = tf.keras.models.load_model(MODEL_PATH + 'colorization_model_dandelion.h5')
    model.compile(optimizer='adam', loss='mse', metrics=['accuracy'])

    filename = 'flower04.jpg'
    input_path = INPUTS_PATH + filename
    result_path = RESULTS_PATH + 'result_' + filename
    predict_image(model, input_path, result_path)


if __name__ == "__main__":
    main()
