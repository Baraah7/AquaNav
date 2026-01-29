# Fish Recognition Model - Training Fixes

## What Was Wrong

### 1. **TFLite Quantization Corruption**
The original notebook used:
```python
converter.optimizations = [tf.lite.Optimize.DEFAULT]
```

This applies dynamic range quantization which **corrupted the model**, causing:
- Gilt-Head Bream: always ~0% probability
- Sea Bass: always ~0% probability
- Only Hourse Mackerel and Shrimp were predicted

### 2. **Misleading Test**
Cell 14 in the original notebook tested the TFLite model using:
```python
test_batch = next(iter(validation_generator))
test_image = test_batch[0][0:1]  # Already preprocessed!
```

This test used **already preprocessed data** from ImageDataGenerator, not raw images like Flutter uses. That's why it showed 99% accuracy in the notebook but failed with real images.

### 3. **Weak Classifier Head**
The original model had only one dense layer (512 units), which wasn't strong enough to learn all 4 classes properly.

### 4. **Overfitting**
The model achieved 100% validation accuracy during training, which is a red flag for overfitting. It memorized the validation set but didn't generalize.

## Fixes in the New Notebook

### 1. **No Quantization**
```python
converter = tf.lite.TFLiteConverter.from_keras_model(model)
# NO optimizations - prevents corruption
tflite_model = converter.convert()
```

Result: Larger model (4-5 MB instead of 1.3 MB) but **actually works**.

### 2. **Proper TFLite Testing**
Added a comprehensive test that:
- Loads raw images from disk (like Flutter does)
- Applies Flutter-style preprocessing
- Tests 3 images from each class
- Shows probabilities for all classes
- Reports overall accuracy

### 3. **Stronger Model Architecture**
```python
# Two dense layers instead of one
x = layers.Dense(256, activation='relu', kernel_regularizer=keras.regularizers.l2(0.01))(x)
x = layers.BatchNormalization()(x)
x = layers.Dropout(0.5)(x)

x = layers.Dense(128, activation='relu', kernel_regularizer=keras.regularizers.l2(0.01))(x)
x = layers.BatchNormalization()(x)
x = layers.Dropout(0.3)(x)
```

### 4. **Better Regularization**
- **Label smoothing**: Prevents overconfident predictions
- **L2 regularization**: Prevents large weights
- **Higher dropout**: 50% and 30% instead of 40%
- **Better data augmentation**: More rotation, shearing, and zooming

### 5. **Model Checkpointing**
Saves the best model during training based on validation accuracy.

## How to Use the New Notebook

1. Open `fish-recognition-fixed.ipynb` in Jupyter Notebook or VS Code
2. Run all cells in order
3. Wait for training to complete (~30-40 minutes on CPU)
4. Check the TFLite test results at the end
5. If accuracy is > 70%, copy the model files to Flutter:
   ```
   From: C:\Users\s62ht\Downloads\fish_model_output_fixed\fish_classifier.tflite
   To:   c:\Users\s62ht\Desktop\Bahaar\assets\models\fish_classifier.tflite
   ```

## Expected Results

The new model should:
- Show **all 4 classes with non-zero probabilities** (not just 2)
- Achieve **>80% accuracy** on the raw image test
- Work correctly in the Flutter app

## If It Still Doesn't Work

If the model still shows bias toward certain classes:

1. **Check class balance**: Ensure each class has 800 training images
2. **Increase training time**: Try EPOCHS = 30 or 40
3. **Try different architecture**: Consider EfficientNetB0 instead of MobileNetV3
4. **Check dataset quality**: Some images might be mislabeled or corrupted

## Technical Details

### Why Quantization Failed

TensorFlow Lite's dynamic range quantization converts float32 weights to int8, which reduces model size but can cause:
- **Precision loss** in the final dense layers
- **Biased predictions** toward classes with stronger activations
- **Near-zero probabilities** for classes with weaker features

For a 4-class fish classifier, the precision loss was catastrophic for Gilt-Head Bream and Sea Bass.

### Why Label Smoothing Helps

Instead of hard targets like [1, 0, 0, 0], label smoothing uses softer targets like [0.925, 0.025, 0.025, 0.025]. This:
- Prevents the model from becoming overconfident
- Improves generalization
- Reduces overfitting

### Why Two Dense Layers Are Better

The two-layer classifier head creates:
- **First layer (256 units)**: Learns high-level features specific to fish classification
- **Second layer (128 units)**: Combines those features for final classification
- **Better separation** between similar-looking fish classes
