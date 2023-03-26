from keras_preprocessing.image import img_to_array, load_img
from skimage.color import rgb2lab, lab2rgb
import matplotlib.pyplot as plt
import numpy as np


def extract_single_dim_from_lab_convert_to_rgb(image, channel):
    result = np.zeros(image.shape)
    if channel != 0:
        result[:, :, 0] = 80  # needs brightness to plot the image along 1st or 2nd axis
    result[:, :, channel] = image[:, :, channel]
    result = lab2rgb(result)
    return result


def extract_ab_from_lab_convert_to_rgb(image):
    result = np.zeros(image.shape)
    result[:, :, 0] = 80  # needs brightness to plot the image along 1st or 2nd axis
    result[:, :, 1:] = image[:, :, 1:]
    result = lab2rgb(result)
    return result


def plot_lab_spectrum():
    # Get image path from console input
    img_path = input("Enter the image path: ")

    # Load image
    rgb = img_to_array(load_img(img_path), dtype='uint8')
    lab = rgb2lab(rgb / 255.0)

    lab_l = extract_single_dim_from_lab_convert_to_rgb(lab, 0)
    lab_ab = extract_ab_from_lab_convert_to_rgb(lab)
    lab = (lab + [0, 128, 128]) / [100, 255, 255]

    # Plot the results
    N_ROWS = 2
    N_COLS = 2

    fig, axes = plt.subplots(nrows=N_ROWS, ncols=N_COLS)
    data = [('rgb image', rgb), ('lab image', lab),
            ('L: lightness', lab_l), ('ab: chromatic', lab_ab)]

    for i in range(0, N_ROWS):
        for j in range(0, N_COLS):
            title = data[N_ROWS * i + j][0]
            img = data[N_ROWS * i + j][1]
            axes[i][j].set_title(title)
            axes[i][j].imshow(img)
            axes[i][j].axis('off')

    plt.savefig('images/figures/fig.jpg')
    plt.show()


plot_lab_spectrum()
