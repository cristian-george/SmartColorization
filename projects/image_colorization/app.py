import cv2
import numpy as np
import base64
import torch
from flask import Flask, request

from interactive_colorization.colorization_model import ColorizeImageTorch
from interactive_colorization.colorize_image import colorize_image
from interactive_colorization.model import SIGGRAPHGenerator

app = Flask(__name__)

gpu_id = 0
cuda0 = torch.device('cuda:{}'.format(gpu_id))

model = ColorizeImageTorch(Xd=256)
model.prep_net(gpu_id,
               path='interactive_colorization/models/model.pth',
               SIGGRAPHGenerator=SIGGRAPHGenerator)


@app.route('/guided_colorization', methods=["POST"])
def guided_colorization():
    data = request.json

    image = data['image']
    coordinates = data['coordinates']
    colors = data['colors']

    image = base64.b64decode(image)
    image = np.frombuffer(image, np.uint8)
    image = cv2.imdecode(image, cv2.IMREAD_COLOR)

    _, color = colorize_image(cuda0, model, image, coordinates, colors)
    color = cv2.cvtColor(color, cv2.COLOR_BGR2RGB)
    _, buffer = cv2.imencode('.jpg', color)

    result = buffer.tobytes()
    return result


if __name__ == '__main__':
    app.run(host='192.168.0.141', port=5000)
