import math
import tensorflow as tf

from image_generator import ImageGenerator
from utils import check_gpu_available

check_gpu_available()

DATASET_NAME = 'flowers'
BATCH_SIZE = 128

encoder = tf.keras.models.load_model('models/vgg19.h5')
decoder = tf.keras.models.load_model('models/colorization_model_' + DATASET_NAME + '_checkpoint1.h5')

train_dir = '../../datasets/' + DATASET_NAME
val_dir = '../../datasets/' + DATASET_NAME

train_ = ImageGenerator(train_dir, encoder, batch_size=BATCH_SIZE, classes=['train'])
val_ = ImageGenerator(val_dir, encoder, batch_size=BATCH_SIZE, classes=['val'])

# Callback to save the model after every epoch
from keras.callbacks import ModelCheckpoint

checkpoint = ModelCheckpoint('models/colorization_model_' + DATASET_NAME + '_checkpoint1.h5',
                             monitor='loss',
                             verbose=0,
                             save_best_only=True,
                             mode='auto',
                             save_freq='epoch')

# Train the model
decoder.compile(optimizer='adam', loss='mse', metrics=['accuracy'])
stats = decoder.fit(train_.generator(),
                    batch_size=BATCH_SIZE,
                    steps_per_epoch=math.ceil(train_.n / train_.batch_size),
                    validation_data=val_.generator(),
                    validation_batch_size=val_.batch_size,
                    validation_steps=math.ceil(val_.n / val_.batch_size),
                    epochs=100,
                    callbacks=[checkpoint])

# Save the model
decoder.save('models/colorization_model_' + DATASET_NAME + '.h5')
