import os
import numpy as np
from skimage.io import imsave
from skimage.color import lab2rgb, rgb2lab, gray2rgb

from model import ColorizationModel
from utils import load_image, resize_image, normalize_image, denormalize_image


def predict_image(model, input_path, result_path):
    original_image, resized_image, input_shape = load_image(input_path, (224, 224), anti_aliasing=True)
    normalize_image(original_image, 255)
    normalize_image(resized_image, 255)

    lab = rgb2lab(resized_image)
    lum = lab[:, :, 0]
    gray_img = gray2rgb(lum)
    gray_img = gray_img.reshape((1, 224, 224, 3))

    ab = model.predict(gray_img)

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
MODEL_PATH = "model_checkpoints/"


def predict_dir_images(model):
    for filename in os.listdir(INPUTS_PATH):
        input_path = INPUTS_PATH + filename
        result_path = RESULTS_PATH + 'result_' + filename
        predict_image(model, input_path, result_path)


def main():
    model_weights_path = MODEL_PATH + 'colorization_model_epoch_10.h5'
    colorization_model = ColorizationModel()
    colorization_model.build()
    colorization_model.load_weights(model_weights_path)

    predict_dir_images(colorization_model)
    # model = tf.keras.models.load_model(MODEL_PATH + 'colorization_model_flowers_checkpoint1.h5')
    # # model.compile(optimizer='adam', loss='mse', metrics=['accuracy'])
    #
    # filename = 'flower05.jpg'
    # input_path = INPUTS_PATH + filename
    # result_path = RESULTS_PATH + 'result_' + filename
    # predict_image(model, input_path, result_path)


if __name__ == "__main__":
    main()
