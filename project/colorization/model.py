import math
import tensorflow as tf
from keras import Model
from keras.layers import Input, Conv2D, UpSampling2D, BatchNormalization
from matplotlib import pyplot as plt

from image_generator import ImageGenerator
from utils import check_gpu_available

check_gpu_available()

# Encoder
vgg19_model = tf.keras.applications.vgg19.VGG19(include_top=False,
                                                weights='imagenet',
                                                input_shape=(224, 224, 3))
vgg19_model.summary()
for layer in vgg19_model.layers:
    layer.trainable = False

decoder_input = Input(shape=(7, 7, 512))

# Add decoder layers to generate the colorized image
decoder = Conv2D(256, (3, 3), activation='relu', padding='same')(decoder_input)
decoder = BatchNormalization()(decoder)
decoder = UpSampling2D((2, 2))(decoder)
decoder = Conv2D(128, (3, 3), activation='relu', padding='same')(decoder)
decoder = BatchNormalization()(decoder)
decoder = UpSampling2D((2, 2))(decoder)
decoder = Conv2D(64, (3, 3), activation='relu', padding='same')(decoder)
decoder = BatchNormalization()(decoder)
decoder = UpSampling2D((2, 2))(decoder)
decoder = Conv2D(32, (3, 3), activation='relu', padding='same')(decoder)
decoder = BatchNormalization()(decoder)
decoder = UpSampling2D((2, 2))(decoder)
decoder = Conv2D(16, (3, 3), activation='relu', padding='same')(decoder)
decoder = Conv2D(2, (3, 3), activation='tanh', padding='same')(decoder)
decoder_output = UpSampling2D((2, 2))(decoder)

model = Model(inputs=decoder_input, outputs=decoder_output)
model.summary()

DATASET_NAME = 'flowers'
BATCH_SIZE = 16

train_dir = '../../datasets/' + DATASET_NAME
val_dir = '../../datasets/' + DATASET_NAME

train_ = ImageGenerator(train_dir, vgg19_model, batch_size=BATCH_SIZE, classes=['train'])
val_ = ImageGenerator(val_dir, vgg19_model, batch_size=BATCH_SIZE, classes=['val'])

# Callback to save the model after every epoch
from keras.callbacks import ModelCheckpoint

checkpoint = ModelCheckpoint('models/colorization_model_' + DATASET_NAME + '_checkpoint1.h5',
                             monitor='loss',
                             verbose=0,
                             save_best_only=True,
                             mode='auto',
                             save_freq='epoch')

# Train the model
model.compile(optimizer='adam', loss='mse', metrics=['accuracy'])
stats = model.fit(train_.generator(),
                  batch_size=BATCH_SIZE,
                  steps_per_epoch=math.ceil(train_.n / train_.batch_size),
                  validation_data=val_.generator(),
                  validation_batch_size=val_.batch_size,
                  validation_steps=math.ceil(val_.n / val_.batch_size),
                  epochs=100,
                  callbacks=[checkpoint])

# Save the model
model.save('models/colorization_model_' + DATASET_NAME + '.h5')

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
