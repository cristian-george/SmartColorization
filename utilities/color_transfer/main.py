import numpy as np
import cv2


def color_transfer(target, reference):
    # convert the images from the RGB to L*ab* color space, being
    # sure to utilizing the floating point data type (note: OpenCV
    # expects float to be 32-bit, so use that instead of 64-bit)
    target = cv2.cvtColor(target, cv2.COLOR_BGR2LAB).astype("float32")
    reference = cv2.cvtColor(reference, cv2.COLOR_BGR2LAB).astype("float32")

    # compute color statistics for the source and target images
    (lMeanSrc, lStdSrc, aMeanSrc, aStdSrc, bMeanSrc, bStdSrc) = image_stats(target)
    (lMeanTar, lStdTar, aMeanTar, aStdTar, bMeanTar, bStdTar) = image_stats(reference)

    # subtract the means from the target image
    (l, a, b) = cv2.split(target)
    l -= lMeanSrc
    a -= aMeanSrc
    b -= bMeanSrc

    # scale by the standard deviations
    l = (lStdTar / lStdSrc) * l
    a = (aStdTar / aStdSrc) * a
    b = (bStdTar / bStdSrc) * b

    # add in the source mean
    l += lMeanTar
    a += aMeanTar
    b += bMeanTar

    # clip the pixel intensities to [0, 255] if they fall outside
    # this range
    l = np.clip(l, 0, 255)
    a = np.clip(a, 0, 255)
    b = np.clip(b, 0, 255)

    # merge the channels together and convert back to the RGB color
    # space, being sure to utilize the 8-bit unsigned integer data type
    transfer = cv2.merge([l, a, b])
    transfer = cv2.cvtColor(transfer.astype("uint8"), cv2.COLOR_LAB2BGR)

    # return the color transferred image
    return transfer


def image_stats(image):
    # compute the mean and standard deviation of each channel
    epsilon = 1e-5
    (l, a, b) = cv2.split(image)
    (lMean, lStd) = (l.mean(), l.std())
    (aMean, aStd) = (a.mean(), a.std() + epsilon)
    (bMean, bStd) = (b.mean(), b.std() + epsilon)

    # return the color statistics
    return lMean, lStd, aMean, aStd, bMean, bStd


def color_transfer_and_save(target_path, reference_path, result_path, dim=None):
    target = cv2.imread(target_path)
    reference = cv2.imread(reference_path)

    # resize the images if needed
    if dim is not None:
        target = resize_image(target, dim)
        reference = resize_image(reference, dim)

    result = color_transfer(target, reference)
    cv2.imwrite(result_path, result)


def resize_image(image, dim):
    return cv2.resize(image, dim, interpolation=cv2.INTER_AREA)


if __name__ == "__main__":
    target_path = "images/target/example.jpeg"
    reference_path = "images/reference/example2.jpeg"
    result_path = "images/result.jpeg"

    color_transfer_and_save(target_path, reference_path, result_path)
