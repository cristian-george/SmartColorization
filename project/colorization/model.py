import numpy as np
import tensorflow as tf
from keras import Model
from keras.preprocessing.image import ImageDataGenerator
from keras.layers import Input, Conv2D, UpSampling2D
from skimage.color import rgb2lab

gpus = tf.config.list_physical_devices('GPU')
if gpus:
    try:
        for gpu in gpus:
            tf.config.experimental.set_memory_growth(gpu, True)

    except RuntimeError as e:
        print(e)

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

batch_size = 16

train_dir = '../../datasets/places365/train/'
train_datagen = ImageDataGenerator(rescale=1. / 255)
train_generator = train_datagen.flow_from_directory(
    train_dir,
    target_size=(224, 224),
    batch_size=batch_size,
    color_mode='rgb',
    classes=['house', 'cottage', 'beach_house', 'mosque-outdoor'],
    class_mode=None)

num_images = train_generator.n


# Define a function to get the L and AB channels from an RGB image
def get_lab(image):
    # Convert the image to LAB color space
    lab = rgb2lab(image)
    # Get the L channel
    lum = lab[..., 0]
    # Get the AB channels and normalize them to the range [-1, 1]
    ab = lab[..., 1:] / 128.
    # Return the L and AB channels as a tuple
    return lum, ab


def generator(gen):
    for batch in gen:
        x = []
        y = []

        for i in range(len(batch)):
            # Get the L and AB channels for the image
            l, ab = get_lab(batch[i])
            # Append the L and AB channels to the x and Y lists
            x.append(l)
            y.append(ab)

        # Convert the x and Y lists to numpy arrays
        x = np.array(x)
        y = np.array(y)
        # Yield the x and Y arrays
        yield x, y


# Train the model
model.compile(optimizer='adam', loss='mse', metrics=['accuracy'])
history = model.fit(generator(train_generator), batch_size=batch_size, epochs=10,
                    steps_per_epoch=num_images / batch_size)

# Save the model
model.save('models/colorization_model_places365.h5')
