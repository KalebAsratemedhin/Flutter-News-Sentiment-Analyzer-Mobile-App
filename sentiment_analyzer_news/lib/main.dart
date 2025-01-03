import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

import 'services/tflite_service.dart';
import 'tfidf_preprocessor.dart';

void main() {
  runApp(SentimentAnalyzerApp());
}

class SentimentAnalyzerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SentimentAnalyzerScreen(),
    );
  }
}

class SentimentAnalyzerScreen extends StatefulWidget {
  @override
  _SentimentAnalyzerScreenState createState() =>
      _SentimentAnalyzerScreenState();
}

class _SentimentAnalyzerScreenState extends State<SentimentAnalyzerScreen> {
  final TFLiteService _tfliteService = TFLiteService();
  final TextEditingController _textController = TextEditingController();
  final TFIDFPreprocessor _tfidfPreprocessor = TFIDFPreprocessor();

  String _result = "";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _tfliteService.loadModel();
    await _tfidfPreprocessor.loadTFIDFData();
  }

  Uint8List convertToBinaryInput(List<double> input) {
    Float32List float32List = Float32List.fromList(input);
    return float32List.buffer.asUint8List();
  }

  Future<void> _analyzeSentiment(String inputText) async {
    if (inputText.isEmpty) return;

    final tfidfVector = _tfidfPreprocessor.computeTFIDFVector(inputText);
    var analysis = await _tfliteService.analyzeSentiment(
      convertToBinaryInput(tfidfVector),
    );

    setState(() {
      if (analysis != null && analysis is List && analysis.isNotEmpty) {
        try {
          List<double> probabilities = analysis.cast<double>();
          List<String> labels = ['Negative', 'Neutral', 'Positive'];
          List<String> formattedProbabilities = probabilities
              .map((prob) => prob.toStringAsFixed(5))
              .toList();
          int maxIndex = probabilities.indexWhere(
              (prob) => prob == probabilities.reduce((a, b) => a > b ? a : b));
          String dominantSentiment = labels[maxIndex];

          _result = "Sentiment Probabilities:\n" +
              List.generate(
                labels.length,
                (index) => "${labels[index]}: ${formattedProbabilities[index]}",
              ).join("\n") +
              "\n\nDominant Sentiment: $dominantSentiment";
        } catch (e) {
          _result = "Error processing sentiment analysis: $e";
        }
      } else {
        _result = "No sentiment detected.";
      }
    });
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String fileContent = await file.readAsString();
        setState(() {
          _textController.text = fileContent;
        });
      } else {
        _showSnackBar("No file selected.");
      }
    } catch (e) {
      _showSnackBar("Error picking file: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _tfliteService.disposeModel();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("News Sentiment Analyzer"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: "Enter news text",
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _analyzeSentiment(_textController.text),
              child: Text("Analyze Sentiment"),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickFile,
              child: Text("Upload Text File"),
            ),
            SizedBox(height: 16),
            Text(
              "Result:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _result,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
