import tensorflow as tf
from keras.preprocessing.image import ImageDataGenerator
from utils import check_gpu_available, generator

check_gpu_available()

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
model = tf.keras.models.load_model('models/colorization_model_' + DATASET_NAME + '_checkpoint.h5', compile=False)
model.compile(optimizer='adam', loss='mse', metrics=['accuracy'])
model.summary()

stats = model.fit(generator(train_generator),
                  batch_size=BATCH_SIZE, epochs=50,
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
