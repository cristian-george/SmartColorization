import cv2
import numpy as np
from flask import Flask, request

app = Flask(__name__)


@app.route("/convert_to_gray", methods=["POST"])
def convert_to_gray():
    image = request.data
    # convert the binary image data to a numpy array
    image = np.frombuffer(image, np.uint8)
    # decode the image
    image = cv2.imdecode(image, cv2.IMREAD_COLOR)
    # convert the image to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    # encode the grayscale image to binary
    _, buffer = cv2.imencode('.jpg', gray)
    return buffer.tobytes()


if __name__ == "__main__":
    app.run(host='192.168.0.116', port=5000)
