from image_generator import ImageGenerator
from model import ColorizationModel

colorization_model = ColorizationModel(gpu_memory_limit=1536)
colorization_model.build()
colorization_model.summary()
colorization_model.compile(learning_rate=1e-5)

# Prepare train_generator and validation_generator
dataset_name = 'flowers'
batch_size = 8

train_dir = '../../datasets/' + dataset_name
val_dir = '../../datasets/' + dataset_name

train_data = ImageGenerator(train_dir, batch_size=batch_size, classes=['train'], augment=True)
valid_data = ImageGenerator(val_dir, batch_size=batch_size, classes=['val'])

train_generator = train_data.generator()
valid_generator = valid_data.generator()

# Train the model
epochs = 100
steps_per_epoch = train_data.samples // batch_size
validation_steps = valid_data.samples // batch_size

colorization_model.train(train_generator, valid_generator, epochs, steps_per_epoch, validation_steps,
                         checkpoints_directory='models/flowers_checkpoints')
colorization_model.save_model('models/flowers_checkpoints/colorization_model_flowers.h5')
colorization_model.plot_history()
