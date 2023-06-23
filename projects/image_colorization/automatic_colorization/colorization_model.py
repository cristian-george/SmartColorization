import json
import os

import numpy as np
import tensorflow as tf
from keras import Model, Input
from keras.applications import VGG19
from keras.callbacks import ModelCheckpoint
from keras.layers import Concatenate, Conv2D, BatchNormalization, UpSampling2D
from keras.losses import MeanSquaredError
from keras.optimizers import Adam
from keras.optimizers.schedules.learning_rate_schedule import ExponentialDecay
from matplotlib import pyplot as plt
from skimage.color import lab2rgb
from skimage.transform import resize

from automatic_colorization.colorization_utils import check_gpu_support, limit_gpu_memory, increase_cpu_num_threads, \
    rgb2lab_split_image


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

    def __build_encoder(self, freeze_encoder):
        input_tensor = Input(shape=self.shape)
        input_tensor = Concatenate(axis=-1)([input_tensor] * 3)
        vgg19 = VGG19(input_tensor=input_tensor, include_top=False, weights='imagenet')

        # Set the encoder layers to non-trainable if freeze_encoder = True
        if freeze_encoder:
            for layer in vgg19.layers:
                layer.trainable = False

        self.encoder = Model(name='encoder',
                             inputs=vgg19.input,
                             outputs=vgg19.output)

    def __build_decoder(self):
        decoder_input = self.encoder.output  # Input(shape=(7, 7, 512))
        decoder = Conv2D(256, (3, 3), activation='relu', padding='same')(decoder_input)
        decoder = BatchNormalization()(decoder)
        decoder = UpSampling2D((2, 2), interpolation='bilinear')(decoder)
        decoder = Conv2D(128, (3, 3), activation='relu', padding='same')(decoder)
        decoder = BatchNormalization()(decoder)
        decoder = UpSampling2D((2, 2), interpolation='bilinear')(decoder)
        decoder = Conv2D(64, (3, 3), activation='relu', padding='same')(decoder)
        decoder = BatchNormalization()(decoder)
        decoder = UpSampling2D((2, 2), interpolation='bilinear')(decoder)
        decoder = Conv2D(32, (3, 3), activation='relu', padding='same')(decoder)
        decoder = BatchNormalization()(decoder)
        decoder = UpSampling2D((2, 2), interpolation='bilinear')(decoder)
        decoder = Conv2D(16, (3, 3), activation='relu', padding='same')(decoder)
        decoder = Conv2D(2, (3, 3), activation='tanh', padding='same')(decoder)
        decoder_output = UpSampling2D((2, 2))(decoder)

        self.decoder = Model(name='decoder',
                             inputs=decoder_input,
                             outputs=decoder_output)

    def build(self, freeze_encoder=False):
        self.__build_encoder(freeze_encoder)
        self.__build_decoder()

        autoencoder_input = self.encoder.input  # Input(shape=(224, 224, 3))
        autoencoder_output = self.decoder(self.encoder(autoencoder_input))

        self.autoencoder = Model(name='autoencoder',
                                 inputs=autoencoder_input,
                                 outputs=autoencoder_output)

    def compile(self, learning_rate=1e-3, decay_steps=10000, decay_rate=0.9):
        lr_schedule = ExponentialDecay(initial_learning_rate=learning_rate,
                                       decay_steps=decay_steps,
                                       decay_rate=decay_rate)

        self.autoencoder.compile(optimizer=Adam(learning_rate=lr_schedule),
                                 loss=MeanSquaredError(),
                                 metrics=['accuracy'])

    def train(self, train_generator, val_generator, epochs, steps_per_epoch, val_steps, ckpt_dir, initial_epoch=0):
        if not os.path.exists(ckpt_dir):
            os.makedirs(ckpt_dir)

        model_checkpoint = ModelCheckpoint(
            filepath=os.path.join(ckpt_dir, 'colorization_model_epoch_{epoch:02d}_v2.h5'),
            save_freq=steps_per_epoch // 25,
            save_best_only=False,
            save_weights_only=True)

        self.history = self.autoencoder.fit(train_generator,
                                            validation_data=val_generator,
                                            epochs=epochs,
                                            steps_per_epoch=steps_per_epoch,
                                            validation_steps=val_steps,
                                            callbacks=[model_checkpoint],
                                            initial_epoch=initial_epoch)

    def predict(self, image):
        luminance, _ = rgb2lab_split_image(image)

        lum = resize(luminance, self.shape, anti_aliasing=True)
        lum = np.reshape(lum, (1, self.shape[0], self.shape[1], 1))

        chrom = self.autoencoder.predict(lum, verbose=False)
        chrom = np.reshape(chrom, (self.shape[0], self.shape[1], 2))

        chrominance = resize(chrom, (image.shape[0], image.shape[1]), anti_aliasing=True) * 128.0

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

    def save_as_tflite(self, tflite_model_path):
        # Convert the model to a concrete function
        concrete_function = tf.function(lambda inputs: self.autoencoder(inputs))
        concrete_function = concrete_function.get_concrete_function(
            [tf.TensorSpec(shape=self.autoencoder.inputs[i].shape,
                           dtype=self.autoencoder.inputs[i].dtype) for i in
             range(len(self.autoencoder.inputs))]
        )

        # Convert the model to TensorFlow Lite format
        converter = tf.lite.TFLiteConverter.from_concrete_functions([concrete_function], self.autoencoder)
        tflite_model = converter.convert()

        # Save the .tflite model to a file
        with open(tflite_model_path, 'wb') as f:
            f.write(tflite_model)


def psnr(y_true, y_prediction):
    return tf.image.psnr(y_true, y_prediction, max_val=1.0)


def ssim(y_true, y_prediction):
    return tf.reduce_mean(tf.image.ssim(y_true, y_prediction, max_val=1.0))
