@JS()
library main;

import 'package:js/js.dart';

@JS('getPredictions')
external Future<String> getPredictions();

@JS('JSON.stringify')
external String stringify(Object obj);

@JS('isModelReady')
external bool isModelReady();

@JS('initCamera')
external void initCamera();

@JS('resetPrediction')
external void resetPrediction();

@JS('disposeScanner')
external void disposeScanner();

@JS('getFrameData')
external String getFrameData();
