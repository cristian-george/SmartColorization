import numpy as np


def put_point(input_ab, mask, loc, p, val):
    # input_ab    2x256x256    current user ab input (will be updated)
    # mask        1x256x256    binary mask of current user input (will be updated)
    # loc         2 tuple      (h,w) of where to put the user input
    # p           scalar       half-patch size
    # val         2 tuple      (a,b) value of user input
    input_ab[:, loc[0] - p:loc[0] + p + 1, loc[1] - p:loc[1] + p + 1] = np.array(val)[:, np.newaxis, np.newaxis]
    mask[:, loc[0] - p:loc[0] + p + 1, loc[1] - p:loc[1] + p + 1] = 1
    return input_ab, mask
