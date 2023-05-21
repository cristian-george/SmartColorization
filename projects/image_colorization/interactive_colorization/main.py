import cv2
import torch
import matplotlib.pyplot as plt

from colorize_image import ColorizeImageTorch
from model import SIGGRAPHGenerator
from utils import colorize_im

gpu_id = 0
cuda0 = torch.device('cuda:{}'.format(gpu_id))
model = ColorizeImageTorch(Xd=256)

model.prep_net(gpu_id, 'models/model.pth', SIGGRAPHGenerator=SIGGRAPHGenerator)

im = cv2.cvtColor(cv2.imread('images/mortar_pestle.jpg', 1), cv2.COLOR_BGR2RGB)
locs = [[135, 160], [100, 160]]
vals = [[23, -69], [0, 0]]
original, processed = colorize_im(cuda0, model, im, locs, vals)

plt.imsave('images/original.jpg', original)
plt.imsave('images/processed.jpg', processed)
