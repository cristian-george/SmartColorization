import numpy as np


def put_point(input_ab, mask, p, loc, val):
    input_ab[:, loc[0] - p:loc[0] + p + 1, loc[1] - p:loc[1] + p + 1] = np.array(val)[:, np.newaxis, np.newaxis]
    mask[:, loc[0] - p:loc[0] + p + 1, loc[1] - p:loc[1] + p + 1] = 1
    return input_ab, mask


def put_points(input_ab, mask, p, locs, vals):
    for i in range(len(locs)):
        loc = locs[i]
        val = vals[i]
        input_ab, mask = put_point(input_ab, mask, p, loc, val)

    return input_ab, mask
