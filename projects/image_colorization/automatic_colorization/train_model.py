from image_generator import ImageGenerator
from colorization_model import ColorizationModel

dataset_name = 'flowers'
weights = 'models/' + dataset_name + '_checkpoints/colorization_model_epoch_100.h5'

# Prepare model
model = ColorizationModel(gpu_memory_limit=5000)
model.build(freeze_encoder=True)
model.load_weights(weights_path=weights)
model.compile()
model.summary()

# Prepare training and validation data
batch_size = 32

train_dir = 'images/datasets/' + dataset_name
val_dir = 'images/datasets/' + dataset_name

train_data = ImageGenerator(train_dir, batch_size=batch_size, classes=['train'], augment=True)
valid_data = ImageGenerator(val_dir, batch_size=batch_size, classes=['val'])

train_generator = train_data.generator()
valid_generator = valid_data.generator()

# Train the model
epochs = 50
steps_per_epoch = train_data.samples // batch_size
validation_steps = valid_data.samples // batch_size

model.train(train_generator,
            valid_generator,
            epochs,
            steps_per_epoch,
            validation_steps,
            ckpt_dir='models/' + dataset_name + '_checkpoints')
model.save_model('models/colorization_model_' + dataset_name + '.h5')
model.plot_history()
