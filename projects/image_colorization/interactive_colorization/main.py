import cv2
import torch
import matplotlib.pyplot as plt

from colorization_model import ColorizeImageTorch
from colorize_image import colorize_image
from model import SIGGRAPHGenerator

cuda_device = None

if torch.cuda.is_available():
    gpu_id = torch.cuda.current_device()
    cuda_device = torch.device('cuda:{}'.format(gpu_id))

model = ColorizeImageTorch(Xd=256)
model.prep_net(cuda_device,
               'models/model.pth',
               SIGGRAPHGenerator=SIGGRAPHGenerator)
print(model.net)

im = cv2.cvtColor(cv2.imread('images/mortar_pestle.jpg', 1), cv2.COLOR_BGR2RGB)
locs = [[370, 340], [370, 180]]
vals = [[23, -69], [0, 0]]
original, processed = colorize_image(cuda_device, model, im, locs, vals)

plt.imsave('images/original.jpg', original)
plt.imsave('images/processed.jpg', processed)
