import numpy as np
from keras.preprocessing.image import ImageDataGenerator

from utils import rgb2lab_split_image


class ImageGenerator:
    def __init__(self, directory, batch_size, image_size=(224, 224), shuffle=True, augment=False, classes=None):
        if augment:
            self.datagen = ImageDataGenerator(
                rescale=1. / 255,
                rotation_range=20,
                width_shift_range=0.2,
                height_shift_range=0.2,
                horizontal_flip=True,
                vertical_flip=False,
            )
        else:
            self.datagen = ImageDataGenerator(rescale=1. / 255)

        self.dirIterator = self.datagen.flow_from_directory(
            directory,
            target_size=image_size,
            batch_size=batch_size,
            classes=classes,
            color_mode='rgb',
            class_mode=None,
            shuffle=shuffle)

        self.samples = self.dirIterator.n

    def generator(self):
        for batch in self.dirIterator:
            x = []
            y = []

            for image in batch:
                l, ab = rgb2lab_split_image(image)

                # Append the L channel to the x list and AB channels to the y lists
                x.append(l)
                y.append(ab)

            # Convert the x and y lists to numpy arrays
            x = np.array(x)
            y = np.array(y)

            # Yield the x and y arrays
            yield x, y
