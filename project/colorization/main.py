import os

from skimage.io import imsave

import tensorflow as tf
from model import ColorizationModel
from utils import load_image

images_inputs_path = "images/inputs/"
images_results_path = "images/results/"
models_path = "models/"


def predict_image(model, input_path, result_path):
    image = load_image(input_path)
    result = model.predict(image)
    imsave(result_path, result.astype('uint8'))


def colorize_image(model):
    filename = 'flower01.jpg'
    input_path = images_inputs_path + filename
    result_path = images_results_path + 'result_' + filename
    predict_image(model, input_path, result_path)


def predict_dir_images(model):
    for filename in os.listdir(images_inputs_path):
        input_path = images_inputs_path + filename
        result_path = images_results_path + 'result_' + filename
        predict_image(model, input_path, result_path)


# model_weights_path = models_path + 'colorization_model_flowers.h5'
# colorization_model = ColorizationModel()
# colorization_model.build()
# colorization_model.load_weights(model_weights_path)


# Colorize every image from a directory
# predict_dir_images(colorization_model)


# Convert .h5 model to .tflite model
def convert_model_to_tflite(h5_model_weights_path, tflite_model_path):
    # Load the weights
    colorization_model = ColorizationModel()
    colorization_model.build()
    colorization_model.load_weights(h5_model_weights_path)
    colorization_model.compile()

    # Convert the model to a concrete function
    concrete_function = tf.function(lambda inputs: colorization_model.autoencoder(inputs))
    concrete_function = concrete_function.get_concrete_function(
        [tf.TensorSpec(shape=colorization_model.autoencoder.inputs[i].shape,
                       dtype=colorization_model.autoencoder.inputs[i].dtype) for i in
         range(len(colorization_model.autoencoder.inputs))]
    )

    # Convert the model to TensorFlow Lite format
    converter = tf.lite.TFLiteConverter.from_concrete_functions([concrete_function],
                                                                trackable_obj=colorization_model.autoencoder)
    tflite_model = converter.convert()

    # Save the .tflite model to a file
    with open(tflite_model_path, 'wb') as f:
        f.write(tflite_model)


def h5_to_tflite(h5_model_path='models/places365_checkpoints/colorization_model_epoch_08_v2.h5',
                 tflite_model_path='models/tflite/colorization_model_places365.tflite'):
    convert_model_to_tflite(h5_model_path, tflite_model_path)


h5_to_tflite()
