import os
from skimage.io import imsave

from model import ColorizationModel
from utils import load_image

images_inputs_path = "images/inputs/"
images_results_path = "images/results/"
models_path = "models/"


def predict_image(model, input_path, result_path):
    image = load_image(input_path)
    result = model.predict(image)
    imsave(result_path, result.astype('uint8'))


def predict_dir_images(model):
    for filename in os.listdir(images_inputs_path):
        input_path = images_inputs_path + filename
        result_path = images_results_path + 'result_' + filename
        predict_image(model, input_path, result_path)


model_weights_path = models_path + 'flowers_checkpoints/colorization_model_epoch_10.h5'
colorization_model = ColorizationModel()
colorization_model.build()
colorization_model.load_weights(model_weights_path)

# Colorize every image from a directory
predict_dir_images(colorization_model)

# Colorize an image
# filename = 'image.jpg'
# input_path = images_inputs_path + filename
# result_path = images_results_path + 'result_' + filename
# predict_image(colorization_model, input_path, result_path)
