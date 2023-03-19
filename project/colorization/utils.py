from keras_preprocessing.image import load_img, img_to_array
from skimage.transform import resize


def load_image(image_path, output_shape=(224, 224), anti_aliasing=False):
    original_image = img_to_array(load_img(image_path))
    input_shape = (original_image.shape[0], original_image.shape[1])

    resized_image = resize_image(original_image, output_shape, anti_aliasing)
    return original_image, resized_image, input_shape


def resize_image(image, size, anti_aliasing=False):
    image = resize(image, size, anti_aliasing)
    return image


def normalize_image(image, value):
    image /= value


def denormalize_image(image, value):
    image *= value
