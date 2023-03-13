import tensorflow as tf
from keras import Model
from keras.models import Sequential
from keras.preprocessing.image import ImageDataGenerator
from skimage.color import rgb2lab, gray2rgb
import numpy as np
from keras.layers import Input, Conv2D, UpSampling2D

vgg_model = tf.keras.applications.vgg19.VGG19()

vgg19_encoder = Sequential()

for i, layer in enumerate(vgg_model.layers):
    if i < 22:
        vgg19_encoder.add(layer)

for layer in vgg19_encoder.layers:
    layer.trainable = False

path = '../../datasets/places365/train/'
train_datagen = ImageDataGenerator(rescale=1. / 255)
train = train_datagen.flow_from_directory(path,
                                          target_size=(224, 224),
                                          batch_size=1,
                                          classes=['house'],
                                          class_mode=None)

X = []
Y = []
for i, img in enumerate(train):
    if i < 1024:
        lab = rgb2lab(img)
        lum = lab[..., 0]
        X.append(lum)
        ab = lab[..., 1:]
        Y.append(ab / 128)
    else:
        break

X = np.array(X)
Y = np.array(Y)
X = X.reshape(X.shape + (1,))
Y = Y.reshape((Y.shape[0], 224, 224, 2))

vgg_features = []
for i, sample in enumerate(X):
    sample = gray2rgb(sample)
    sample = sample.reshape((1, 224, 224, 3))
    prediction = vgg19_encoder.predict(sample, verbose=0)
    prediction = prediction.reshape((7, 7, 512))
    vgg_features.append(prediction)

vgg_features = np.array(vgg_features)

vgg19_encoder.compile()
vgg19_encoder.save('models/vgg19_encoder.h5')

# Train the network

# Encoder
encoder_input = Input(shape=(7, 7, 512,))

# Decoder
decoder_output = Conv2D(256, (3, 3), activation='relu', padding='same')(encoder_input)
decoder_output = UpSampling2D((2, 2))(decoder_output)
decoder_output = Conv2D(128, (3, 3), activation='relu', padding='same')(decoder_output)
decoder_output = UpSampling2D((2, 2))(decoder_output)
decoder_output = Conv2D(64, (3, 3), activation='relu', padding='same')(decoder_output)
decoder_output = UpSampling2D((2, 2))(decoder_output)
decoder_output = Conv2D(32, (3, 3), activation='relu', padding='same')(decoder_output)
decoder_output = UpSampling2D((2, 2))(decoder_output)
decoder_output = Conv2D(2, (3, 3), activation='tanh', padding='same')(decoder_output)
decoder_output = UpSampling2D((2, 2))(decoder_output)

decoder = Model(inputs=encoder_input, outputs=decoder_output)
decoder.summary()

decoder.compile(optimizer='adam', loss='mse', metrics=['accuracy'])
decoder.fit(vgg_features, Y, epochs=100, batch_size=32)

decoder.save('models/decoder.h5')
