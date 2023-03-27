import tensorflow as tf
from keras import Model
from keras.preprocessing.image import ImageDataGenerator
from keras.layers import Input, Conv2D, UpSampling2D
from utils import check_gpu_available, generator

check_gpu_available()

vgg19_model = tf.keras.applications.vgg19.VGG19(include_top=False,
                                                weights='imagenet',
                                                input_shape=(224, 224, 3))

for layer in vgg19_model.layers:
    layer.trainable = False

# Define the input tensor for grayscale images
inputs = Input(shape=(224, 224, 1))

# Convert the grayscale image to a 3-channel image
encoder = Conv2D(3, (1, 1), activation='relu')(inputs)

# Pass the 3-channel image through the pre-trained VGG19 model
encoder = vgg19_model(encoder)

# Add decoder layers to generate the colorized image
decoder = Conv2D(256, (3, 3), activation='relu', strides=1, padding='same')(encoder)
decoder = UpSampling2D((2, 2))(decoder)
decoder = Conv2D(128, (3, 3), activation='relu', strides=1, padding='same')(decoder)
decoder = UpSampling2D((2, 2))(decoder)
decoder = Conv2D(64, (3, 3), activation='relu', strides=1, padding='same')(decoder)
decoder = UpSampling2D((2, 2))(decoder)
decoder = Conv2D(32, (3, 3), activation='relu', strides=1, padding='same')(decoder)
decoder = UpSampling2D((2, 2))(decoder)
decoder = Conv2D(2, (3, 3), activation='tanh', strides=1, padding='same')(decoder)
outputs = UpSampling2D((2, 2))(decoder)

model = Model(inputs=inputs, outputs=outputs)
model.summary()

DATASET_NAME = 'flowers'
BATCH_SIZE = 16

train_dir = '../../datasets/' + DATASET_NAME
train_datagen = ImageDataGenerator(rescale=1. / 255)
train_generator = train_datagen.flow_from_directory(
    train_dir,
    target_size=(224, 224),
    batch_size=BATCH_SIZE,
    color_mode='rgb',
    classes=['train'],
    class_mode=None)

val_dir = '../../datasets/' + DATASET_NAME
val_datagen = ImageDataGenerator(rescale=1. / 255)
val_generator = val_datagen.flow_from_directory(
    val_dir,
    target_size=(224, 224),
    batch_size=BATCH_SIZE,
    color_mode='rgb',
    classes=['val'],
    class_mode=None)

NUM_IMAGES = train_generator.n

# Callback to save the model after every epoch
from keras.callbacks import ModelCheckpoint

checkpoint = ModelCheckpoint('models/colorization_model_' + DATASET_NAME + '_checkpoint.h5',
                             monitor='loss',
                             verbose=0,
                             save_best_only=True,
                             mode='auto')

# Train the model
model.compile(optimizer='adam', loss='mse', metrics=['accuracy'])
stats = model.fit(generator(train_generator),
                  batch_size=BATCH_SIZE, epochs=10,
                  steps_per_epoch=NUM_IMAGES / BATCH_SIZE,
                  validation_data=generator(val_generator),
                  validation_batch_size=BATCH_SIZE,
                  validation_steps=NUM_IMAGES / BATCH_SIZE,
                  callbacks=[checkpoint])

# Save the model
model.save('models/colorization_model_' + DATASET_NAME + '.h5')

# Plot the model statistics
from matplotlib import pyplot as plt

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
