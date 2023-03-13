from keras_preprocessing.image import load_img, img_to_array
from skimage.transform import resize


def load_image(image_path, output_shape=(224, 224), anti_aliasing=False):
    image = img_to_array(load_img(image_path))
    input_shape = (image.shape[0], image.shape[1])

    image = resize_image(image, output_shape, anti_aliasing)
    return image, input_shape


def resize_image(image, size, anti_aliasing=False):
    image = resize(image, size, anti_aliasing)
    return image


def normalize_image(image, value):
    image *= value
