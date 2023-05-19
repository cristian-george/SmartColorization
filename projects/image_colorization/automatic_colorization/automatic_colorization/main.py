from colorization_model import ColorizationModel
from colorization_utils import colorize_image, colorize_images

input_path = 'images/inputs/'
output_path = 'images/results/'
weights_path = 'models/colorization_model_places365.h5'

model = ColorizationModel()
model.build()
model.load_weights(weights_path)

# Colorize an image from directory at input_path with filename specified
# and save results to directory at output_path
# colorize_image(model, 'flower.jpg', input_path, output_path)

# Colorize all images from directory at input_path
# and save results to directory at output_path
colorize_images(model, input_path, output_path)

# Compile and save model as tflite at specified path
# model.compile()
# model.save_as_tflite('models/colorization_model_places365.tflite')
