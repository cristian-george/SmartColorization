import torch
import colorize_image as clr
import matplotlib.pyplot as plt
import numpy as np

from model import SIGGRAPHGenerator
from utils import put_point

# Choose gpu to run the model on
gpu_id = 0
cuda0 = torch.device('cuda:0')

# Initialize colorization class
colorModel = clr.ColorizeImageTorch(Xd=256)

colorModel.prep_net(0, './models/model.pth', SIGGRAPHGenerator=SIGGRAPHGenerator)
# Load the image
colorModel.load_image('./images/image.jpg')  # load an image

# mask = np.zeros((1, 256, 256))  # giving no user points, so mask is all 0's
# input_ab = np.zeros((2, 256, 256))  # ab values of user points, default to 0 for no input
#
# img_out = colorModel.net_forward(torch.tensor(input_ab, dtype=torch.float32).to(cuda0),
#                                  torch.tensor(mask, dtype=torch.float32).to(cuda0))  # run model, returns 256x256 image
#
# img_gray_fullres = colorModel.get_img_gray_fullres()  # get grayscale image at full resolution
# img_out_fullres = colorModel.get_img_fullres()  # get image at full resolution
#
# # show result
# plt.figure(figsize=(7, 3))
# plt.imshow(np.concatenate((img_gray_fullres, img_out_fullres), axis=1))
# plt.axis('off')

# initialize with no user inputs
input_ab = np.zeros((2, 256, 256))
mask = np.zeros((1, 256, 256))

# add a blue point in the middle of the image
(input_ab, mask) = put_point(input_ab, mask, [135, 160], 3, [23, 99])

# # call forward
# # img_out = colorModel.net_forward(input_ab,mask)
# colorModel.net_forward(torch.tensor(input_ab, dtype=torch.float32).to(cuda0),
#                        torch.tensor(mask, dtype=torch.float32).to(cuda0))  # run model, returns 256x256 image
#
# # get mask, input image, and result in full resolution
# mask_fullres = colorModel.get_img_mask_fullres()  # get input mask in full res
# img_in_fullres = colorModel.get_input_img_fullres()  # get input image in full res
# img_out_fullres = colorModel.get_img_fullres()  # get image at full resolution
#
# # show user input, along with output
# plt.figure(figsize=(10, 6))
# plt.imshow(np.concatenate((mask_fullres, img_in_fullres, img_out_fullres), axis=1))
# plt.title('Mask of user points / Input grayscale with user points / Output colorization')
# plt.axis('off')
# plt.show()

# add a gray point in the inside of the cup
(input_ab, mask) = put_point(input_ab, mask, [100, 160], 3, [0, 0])

# call forward
colorModel.net_forward(torch.tensor(input_ab, dtype=torch.float32).to(cuda0),
                       torch.tensor(mask, dtype=torch.float32).to(cuda0))  # run model, returns 256x256 image

# get mask, input image, and result in full resolution
mask_fullres = colorModel.get_img_mask_fullres()  # get input mask in full res
img_in_fullres = colorModel.get_input_img_fullres()  # get input image in full res
img_out_fullres = colorModel.get_img_fullres()  # get image at full resolution

plt.imsave('result.jpg', img_out_fullres)

# # show user input, along with output
# plt.figure(figsize=(10, 6))
# plt.imshow(np.concatenate((mask_fullres, img_in_fullres, img_out_fullres), axis=1))
# plt.title('Mask of user points / Input grayscale with user points / Output colorization')
# plt.axis('off')
# plt.show()
