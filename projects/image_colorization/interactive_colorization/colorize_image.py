import numpy as np
import torch

from interactive_colorization.utils import put_points


def colorize_image(device, model, image, locs, vals):
    """
    device: gpu device on which we are running the model (torch device)
    model: colorization model (ColorizeImageTorch)
    image: half-patch size (scalar)
    locs: (h,w) values of where to put the user input (list of tuple)
    vals: (a,b) values of user input (list of tuple)
    """

    # Load the image
    model.load_image(image)

    # Initialize with no user inputs
    input_ab = np.zeros((2, 256, 256))
    mask = np.zeros((1, 256, 256))

    # Normalize locs
    height = image.shape[0]
    width = image.shape[1]

    locs = [normalize_loc(loc, width, height) for loc in locs]

    # Fill tensors with user inputs
    input_ab, mask = put_points(input_ab, mask, 3, locs, vals)

    # Call forward (run model and return 256x256 image)
    model.net_forward(torch.tensor(input_ab, dtype=torch.float32).to(device),
                      torch.tensor(mask, dtype=torch.float32).to(device))

    # Get images at full resolution
    mask = model.get_input_img_fullres()
    result = model.get_img_fullres()

    return mask, result


def normalize_loc(loc, width, height):
    # Normalize the coordinates
    y_norm = loc[1] / float(height)
    x_norm = loc[0] / float(width)

    # Scale to the new image size
    y = int(y_norm * 256)
    x = int(x_norm * 256)

    return [y, x]
