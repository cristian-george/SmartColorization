import visualkeras
from PIL import ImageFont
from keras import Model

from automatic_colorization.colorization_model import ColorizationModel

colorization_model = ColorizationModel()
colorization_model.build()

encoder_output = colorization_model.encoder.output
decoder_input = colorization_model.decoder.layers[1](encoder_output)

x = decoder_input
for layer in colorization_model.decoder.layers[2:]:
    x = layer(x)

decoder_output = x

model = Model(inputs=colorization_model.encoder.input, outputs=decoder_output)

font = ImageFont.truetype("calibri.ttf", 24)
visualkeras.layered_view(model, to_file='../images/visualkeras/model.bmp', scale_xy=2, font=font, legend=True).show()
