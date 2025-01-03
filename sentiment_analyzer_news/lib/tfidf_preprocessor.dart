import 'dart:convert';
import 'package:flutter/services.dart';

class TFIDFPreprocessor {
  late Map<String, int> vocabulary;
  late List<double> idfWeights;

  TFIDFPreprocessor();

  Future<void> loadTFIDFData() async {
    final String data = await rootBundle.loadString('assets/tfidf_data.json');
    final Map<String, dynamic> tfidfData = json.decode(data);

    vocabulary = Map<String, int>.from(tfidfData['vocabulary']);
    idfWeights = List<double>.from(tfidfData['idf_weights']);
  }

  String cleanText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> tokenize(String text) {
    return text.split(' ');
  }

  Map<String, int> computeTermFrequencies(List<String> tokens) {
    final Map<String, int> termFrequencies = {};
    for (final token in tokens) {
      termFrequencies[token] = (termFrequencies[token] ?? 0) + 1;
    }
    return termFrequencies;
  }

  List<double> computeTFIDFVector(String text) {
    final cleanedText = cleanText(text);
    final tokens = tokenize(cleanedText);
    print('tokens $tokens');
    final termFrequencies = computeTermFrequencies(tokens);
    print('terms freq $termFrequencies');

    final List<double> tfidfVector = List.filled(vocabulary.length, 0.0);
    termFrequencies.forEach((token, frequency) {
      if (vocabulary.containsKey(token)) {
        final int index = vocabulary[token]!;
        tfidfVector[index] = frequency * idfWeights[index];
      }
    });

    return tfidfVector;
  }
}