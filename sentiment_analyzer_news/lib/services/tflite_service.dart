import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset("./assets/model.tflite");
      print("Model loaded successfully.");
    } catch (e) {
      print("Failed to load model: $e");
    }
  }

  Future<List<dynamic>?> analyzeSentiment(Uint8List inputVector) async {
    if (_interpreter == null) {
      print("Interpreter is not initialized. Call loadModel() first.");
      return null;
    }

    try {
      // Prepare input and output tensors
      var input = inputVector.buffer.asFloat32List();
      var output = List.filled(3, 0.0).reshape([1, 3]); 
      
      _interpreter!.run(input, output);
      print("Inference output: $output");
      return output[0];
    } catch (e) {
      print("Error during inference: $e");
      return null;
    }
  }

  Future<void> disposeModel() async {
    try {
      _interpreter?.close();
      print("Model disposed.");
    } catch (e) {
      print("Error disposing model: $e");
    }
  }
}
