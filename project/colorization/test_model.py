from skimage.io import imsave

from model import ColorizationModel
from utils import load_image

model = ColorizationModel()
model.load_model('models/flowers_checkpoints/colorization_model_flowers.h5')
model.compile()

image = load_image('images/inputs/flower01.jpg')
result = model.predict(image)
imsave('rgb.jpg', result.astype('uint8'))
