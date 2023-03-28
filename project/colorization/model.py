import numpy as np
import tensorflow as tf
from keras import Model
from keras.preprocessing.image import ImageDataGenerator
from keras.layers import Input, Conv2D, UpSampling2D
from skimage.color import gray2rgb
from matplotlib import pyplot as plt

from utils import check_gpu_available, get_lab

check_gpu_available()

# Encoder
vgg19_model = tf.keras.applications.vgg19.VGG19(include_top=False,
                                                weights='imagenet',
                                                input_shape=(224, 224, 3))
vgg19_model.summary()
for layer in vgg19_model.layers:
    layer.trainable = False

encoder_input = Input(shape=(7, 7, 512))

# Add decoder layers to generate the colorized image
decoder = Conv2D(256, (3, 3), activation='relu', padding='same')(encoder_input)
decoder = UpSampling2D((2, 2))(decoder)
decoder = Conv2D(128, (3, 3), activation='relu', padding='same')(decoder)
decoder = UpSampling2D((2, 2))(decoder)
decoder = Conv2D(64, (3, 3), activation='relu', padding='same')(decoder)
decoder = UpSampling2D((2, 2))(decoder)
decoder = Conv2D(32, (3, 3), activation='relu', padding='same')(decoder)
decoder = UpSampling2D((2, 2))(decoder)
decoder = Conv2D(16, (3, 3), activation='relu', padding='same')(decoder)
decoder = UpSampling2D((2, 2))(decoder)
decoder_output = Conv2D(2, (3, 3), activation='tanh', padding='same')(decoder)

model = Model(inputs=encoder_input, outputs=decoder_output)
model.summary()

DATASET_NAME = 'flowers'
BATCH_SIZE = 16

train_dir = '../../datasets/' + DATASET_NAME + '/train'
train_datagen = ImageDataGenerator(rescale=1. / 255)
train_generator = train_datagen.flow_from_directory(
    train_dir,
    target_size=(224, 224),
    batch_size=BATCH_SIZE,
    color_mode='rgb',
    classes=['dandelion'],
    class_mode=None)

val_dir = '../../datasets/' + DATASET_NAME + '/val'
val_datagen = ImageDataGenerator(rescale=1. / 255)
val_generator = val_datagen.flow_from_directory(
    val_dir,
    target_size=(224, 224),
    batch_size=BATCH_SIZE,
    color_mode='rgb',
    classes=['dandelion'],
    class_mode=None)

N_TRAIN_IMAGES = train_generator.n
N_VAL_IMAGES = val_generator.n


def generator(gen):
    for batch in gen:
        x = []
        y = []

        for i in range(len(batch)):
            # Get the L and AB channels for the image
            l, ab = get_lab(batch[i])

            # Predict the (7,7,512) tensor based on lightness
            l = gray2rgb(l)
            l = l.reshape((1, 224, 224, 3))

            prediction = vgg19_model.predict(l, verbose=0)
            prediction = prediction.reshape((7, 7, 512))

            # Append the prediction and AB channels to the x and Y lists
            x.append(prediction)
            y.append(ab)

        # Convert the x and Y lists to numpy arrays
        x = np.array(x)
        y = np.array(y)

        # Yield the x and Y arrays
        yield x, y


# Callback to save the model after every epoch
from keras.callbacks import ModelCheckpoint

checkpoint = ModelCheckpoint('models/colorization_model_dandelion_checkpoint.h5',
                             monitor='loss',
                             verbose=0,
                             save_best_only=True,
                             mode='auto')

# Train the model
model.compile(optimizer='adam', loss='mse', metrics=['accuracy'])
stats = model.fit(generator(train_generator),
                  batch_size=BATCH_SIZE,
                  steps_per_epoch=N_TRAIN_IMAGES / BATCH_SIZE,
                  validation_data=generator(val_generator),
                  validation_batch_size=BATCH_SIZE,
                  validation_steps=N_VAL_IMAGES / BATCH_SIZE,
                  epochs=50,
                  callbacks=[checkpoint])

# Save the model
model.save('models/colorization_model_dandelion.h5')

# Plot the model statistics
acc = stats.history['accuracy']
val_acc = stats.history['val_accuracy']
loss = stats.history['loss']
val_loss = stats.history['val_loss']

epochs = range(1, len(acc) + 1)

plt.plot(epochs, acc, 'r', label='Training acc')
plt.plot(epochs, val_acc, 'b', label='Validation acc')
plt.title('Training and validation accuracy')
plt.legend()

plt.figure()

plt.plot(epochs, loss, 'r', label='Training loss')
plt.plot(epochs, val_loss, 'b', label='Validation loss')
plt.title('Training and validation loss')
plt.legend()

plt.show()
