from imageio.v2 import imsave
from keras.utils import load_img, img_to_array
from skimage.color import rgb2lab, lab2rgb
import matplotlib.pyplot as plt
import numpy as np


def luminance2rgb(lab_image):
    result = np.zeros(lab_image.shape)
    result[:, :, 0] = lab_image[:, :, 0]
    result = lab2rgb(result)
    return result


def chroma2rgb(lab_image, default_luminance=80):
    result = np.zeros(lab_image.shape)
    result[:, :, 0] = default_luminance
    result[:, :, 1:] = lab_image[:, :, 1:]
    result = lab2rgb(result)
    return result


def visualize_lab(image, img_name):
    lab = rgb2lab(image / 255.0)
    lab_l = luminance2rgb(lab)
    lab_ab = chroma2rgb(lab)
    lab = (lab + [0, 128, 128]) / [100, 255, 255]

    # Plot the results
    figures_path = '../images/figures/'
    n_rows = 2
    n_cols = 2

    fig, axes = plt.subplots(nrows=n_rows, ncols=n_cols)
    data = [('RGB image', image), ('CIELAB image', lab),
            ('luminance (L)', lab_l), ('chrominance (ab)', lab_ab)]

    for i in range(0, n_rows):
        for j in range(0, n_cols):
            title = data[n_rows * i + j][0]
            img = data[n_rows * i + j][1]
            imsave(figures_path + img_name + '_{}{}.bmp'.format(i, j), img)

            axes[i][j].set_title(title)
            axes[i][j].imshow(img)
            axes[i][j].axis('off')

        plt.savefig(figures_path + img_name + '.svg', format='svg', dpi=1000)
        plt.show()


filename = 'result_flower'
img_path = '../images/results/' + filename + '.jpg'
rgb_image = img_to_array(load_img(img_path), dtype='uint8')
visualize_lab(rgb_image, filename)
