import json
import os

import numpy as np
from keras import Model, Input
from keras.applications import VGG19
from keras.callbacks import ModelCheckpoint
from keras.layers import Concatenate, Conv2D, BatchNormalization, UpSampling2D
from keras.optimizers import Adam
from matplotlib import pyplot as plt
from skimage.color import lab2rgb
from skimage.transform import resize

from utils import check_gpu_support, limit_gpu_memory, increase_cpu_num_threads, rgb2lab_split_image


class ColorizationModel:
    def __init__(self, gpu_memory_limit=1024):
        self.autoencoder = None
        self.history = None
        self.shape = (224, 224, 1)

        use_gpu = check_gpu_support()
        if use_gpu:
            limit_gpu_memory(memory_limit=gpu_memory_limit)
        else:
            increase_cpu_num_threads(num_threads=os.cpu_count())

    def __build_encoder(self):
        input_tensor = Input(shape=self.shape)
        input_tensor = Concatenate(axis=-1)([input_tensor] * 3)
        vgg19 = VGG19(input_tensor=input_tensor, include_top=False, weights='imagenet')

        # Set the encoder layers to non-trainable
        # for layer in vgg19.layers:
        #     layer.trainable = False

        self.encoder = Model(name='encoder',
                             inputs=vgg19.input,
                             outputs=vgg19.output)

    def __build_decoder(self):
        decoder_input = self.encoder.output  # Input(shape=(7, 7, 512))
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

        self.decoder = Model(name='decoder',
                             inputs=decoder_input,
                             outputs=decoder_output)

    def build(self):
        self.__build_encoder()
        self.__build_decoder()

        autoencoder_input = self.encoder.input  # Input(shape=(224, 224, 3))
        autoencoder_output = self.decoder(self.encoder(autoencoder_input))

        self.autoencoder = Model(name='autoencoder',
                                 inputs=autoencoder_input,
                                 outputs=autoencoder_output)

    def compile(self, learning_rate=1e-4):
        self.autoencoder.compile(optimizer=Adam(learning_rate=learning_rate),
                                 loss='mse',
                                 metrics=['accuracy'])

    def train(self, train_generator, val_generator, epochs, steps_per_epoch, val_steps,
              checkpoints_directory='models'):
        if not os.path.exists(checkpoints_directory):
            os.makedirs(checkpoints_directory)

        model_checkpoint = ModelCheckpoint(
            filepath=os.path.join(checkpoints_directory, 'colorization_model_epoch_{epoch:02d}.h5'),
            save_freq=steps_per_epoch // 4,
            save_best_only=False,
            save_weights_only=True)

        self.history = self.autoencoder.fit(train_generator,
                                            validation_data=val_generator,
                                            epochs=epochs,
                                            steps_per_epoch=steps_per_epoch,
                                            validation_steps=val_steps,
                                            callbacks=[model_checkpoint])

    def predict(self, image):
        luminance, _ = rgb2lab_split_image(image)

        lum = resize(luminance, self.shape, anti_aliasing=True)
        lum = np.reshape(lum, (1, self.shape[0], self.shape[1], 1))

        chrom = self.autoencoder.predict(lum, verbose=False)
        chrom = np.reshape(chrom, (self.shape[0], self.shape[1], 2))

        chrominance = resize(chrom, (image.shape[0], image.shape[1])) * 128.0

        result = np.zeros((image.shape[0], image.shape[1], 3))
        result[:, :, 0] = luminance
        result[:, :, 1:] = chrominance
        result = lab2rgb(result) * 255.0

        return result

    def summary(self, expand_nested=True, show_trainable=True):
        self.autoencoder.summary(expand_nested=expand_nested,
                                 show_trainable=show_trainable)

    def load_weights(self, weights_path):
        self.autoencoder.load_weights(weights_path)

    def save_model(self, model_path):
        self.autoencoder.save(model_path)

    def save_history(self, output_directory):
        if not os.path.exists(output_directory):
            os.makedirs(output_directory)

        history = {}
        for key in self.history.history:
            history[key] = self.history.history[key]

        with open(os.path.join(output_directory, 'history.json'), 'w') as f:
            json.dump(history, f)

    def plot_history(self, output_directory=None):
        if not hasattr(self, 'history'):
            raise ValueError('No training history found. Train the model first.')

        plt.figure(figsize=(12, 4))
        plt.subplot(1, 2, 1)
        plt.plot(self.history.history['loss'], label='Train Loss')
        plt.plot(self.history.history['val_loss'], label='Validation Loss')
        plt.xlabel('Epochs')
        plt.ylabel('Loss')
        plt.legend()

        plt.subplot(1, 2, 2)
        plt.plot(self.history.history['accuracy'], label='Train Accuracy')
        plt.plot(self.history.history['val_accuracy'], label='Validation Accuracy')
        plt.xlabel('Epochs')
        plt.ylabel('Accuracy')
        plt.legend()

        if output_directory:
            if not os.path.exists(output_directory):
                os.makedirs(output_directory)
            plt.savefig(os.path.join(output_directory, 'training_history.png'))

        plt.show()
