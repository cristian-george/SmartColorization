import numpy as np
from keras.preprocessing.image import ImageDataGenerator
from skimage.color import gray2rgb

from utils import get_lab


class ImageGenerator:
    __dir_iterator = None
    __encoder = None
    n = 0
    batch_size = 0

    def __init__(self, directory, encoder, target_size=(224, 224), batch_size=16, classes=None):
        data_generator = ImageDataGenerator(rescale=1. / 255)
        self.__dir_iterator = data_generator.flow_from_directory(
            directory=directory,
            target_size=target_size,
            batch_size=batch_size,
            color_mode='rgb',
            classes=classes,
            class_mode=None)

        self.__encoder = encoder
        self.n = self.__dir_iterator.n
        self.batch_size = batch_size

    def __preprocess_image(self, image):
        # Get the L and AB channels of the image
        L, ab = get_lab(image)

        # Predict the (7,7,512) tensor based on lightness
        L = gray2rgb(L)
        L = L.reshape((1, 224, 224, 3))

        encoder_prediction = self.__encoder.predict(L, verbose=0)
        encoder_prediction = encoder_prediction.reshape((7, 7, 512))
        return encoder_prediction, ab

    def __preprocess_batch(self, batch):
        x = []
        y = []

        for image in batch:
            prediction, ab = self.__preprocess_image(image)

            # Append the prediction and AB channels to the x and Y lists
            x.append(prediction)
            y.append(ab)

        # Convert the x and Y lists to numpy arrays
        x = np.array(x)
        y = np.array(y)

        return x, y

    def generator(self):
        for batch in self.__dir_iterator:
            # Yield the x and Y arrays
            yield self.__preprocess_batch(batch)
