import 'dart:async';

import 'dart:convert';
import 'dart:js_util';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:waste_genie/helpers/ai_utils.dart';
import 'package:waste_genie/helpers/classification_dict.dart';
import 'package:waste_genie/helpers/database_utils.dart';
import 'package:waste_genie/helpers/globals.dart' as globals;

import '../helpers/color_utils.dart';

class ScannerPage extends StatefulWidget {
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  static const int IDLE = 0;
  static const int RUNNING = 1;
  static const int DONE = 2;
  static int SCANNER_STATUS = IDLE;

  Timer? timer;
  Map<String, dynamic>? frame;
  List<Map<String, dynamic>> garbage = [];
  Map<String, dynamic>? objects;

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    initCamera();
    globals.currPageName = 'Scanner';
    timer =
        Timer.periodic(Duration(milliseconds: 100), (timer) => _updateFrame());
  }

  @override
  void dispose() {
    timer?.cancel();
    disposeScanner();
    super.dispose();
  }

  Widget getDetectionButton() {
    switch (SCANNER_STATUS) {
      case RUNNING:
        return CircularProgressIndicator();
      case DONE:
        return FloatingActionButton.small(
          onPressed: () {
            resetPrediction();
            garbage.clear();
            SCANNER_STATUS = IDLE;
          },
          backgroundColor: Colors.redAccent,
          child: const Icon(Icons.delete_outlined),
        );
      default: //status = IDLE
        return FloatingActionButton.small(
          onPressed: () => _runClassification(),
          child: const Icon(Icons.camera_alt_outlined),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    Set<int> classes = {};

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (frame != null && frame!['width'] > 0)
              Stack(children: [
                DetectionResult(
                  image: frame!,
                  objects: garbage,
                ),
                Positioned(
                  bottom: 8,
                  right: 0,
                  left: 0,
                  child: Center(
                    child: getDetectionButton(),
                  ),
                ),
              ])
            else
              Text("Initializing model..."),
            const SizedBox(height: 8),
            Text("Take a photo to get recycle guidances. "),
            Text("Results are only for references."),
            const SizedBox(height: 8),
            ListView.builder(
              itemCount: garbage.length,
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                int wasteId = garbage[index]['className'];
                if (classes.contains(wasteId)) {
                  return null;
                }
                classes.add(wasteId);
                String wasteName = ClassificationDict.getClassName(wasteId);
                String guidelines =
                    ClassificationDict.getRecycleGuidelines(wasteId);

                return Card(
                  child: ListTile(
                    title: Text(wasteName),
                    subtitle: Text(guidelines),
                    trailing: ClassificationDict.getWasteLabelIcon(guidelines),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  _runClassification() async {
    if (!isModelReady() || SCANNER_STATUS != IDLE) return;

    if (mounted) {
      setState(() {
        SCANNER_STATUS = RUNNING;
      });
    }

    garbage.clear();
    List<int> classes = [];
    List<dynamic>? predictions =
        json.decode(await promiseToFuture(getPredictions()))['result'];
    if (predictions != null) {
      if (predictions.isNotEmpty) {
        for (Map<String, dynamic> obj in predictions) {
          garbage.add(obj);
          classes.add(obj['className']);
        }
        garbage.sort((a, b) => ((b['score']).compareTo(a['score'])));
      } else {
        garbage.add({
          'className': -1,
        });
      }
    }

    SCANNER_STATUS = DONE;
    if (mounted) setState(() {});

    DatabaseUtils.writeLog('ScannerResult', classes.toString());
  }

  bool isUpdating = false;

  _updateFrame() {
    if (isUpdating || !isModelReady()) return;
    isUpdating = true;
    frame = json.decode(getFrameData());
    if (mounted) {
      setState(() {});
    }
    isUpdating = false;
  }
}

class DetectionResult extends StatelessWidget {
  const DetectionResult({
    super.key,
    required this.image,
    required this.objects,
  });

  final Map<String, dynamic> image;
  final List<Map<String, dynamic>> objects;

  Image decodeBase64(String base64str) {
    return Image.memory(
      base64Decode(base64str.replaceAll(RegExp(r'\s+'), '')),
      gaplessPlayback: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    double imagePreviewWidth = 0;
    double imagePreviewHeight = 0;
    double scale = 1.0;

    if (image['width'] > 0) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      imagePreviewWidth = min(screenWidth * 0.9, image['width']);
      imagePreviewHeight = min(screenHeight * 0.6, image['height']);

      scale = min(imagePreviewWidth / image['width'],
          imagePreviewHeight / image['height']);

      imagePreviewWidth = scale * image['width'];
    } else {
      return Text("Detection model not correctly loaded.");
    }

    var detectionBoxes = [];

    for (Map<String, dynamic> obj in objects) {
      int objId = obj['className'];

      if (objId < 0) {
        break;
      }

      detectionBoxes.add(DetectionRect(
        category: ClassificationDict.getClassName(objId),
        guidelines: ClassificationDict.getRecycleGuidelines(objId),
        xmin: obj['xmin'] * scale,
        ymin: obj['ymin'] * scale,
        width: obj['width'] * scale,
        height: obj['height'] * scale,
      ));
    }

    return Stack(
      children: [
        SizedBox(
          width: imagePreviewWidth,
          child: decodeBase64(image['image']),
        ),
        for (var box in detectionBoxes) box,
      ],
    );
  }
}

class DetectionRect extends StatelessWidget {
  DetectionRect({
    Key? key,
    required this.xmin,
    required this.ymin,
    required this.width,
    required this.height,
    required this.category,
    required this.guidelines,
  }) : super(key: key);

  final double xmin, ymin, width, height;
  final String category, guidelines;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: xmin,
      top: ymin,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: ColorUtils.getColorTransparent(guidelines),
          border: Border.all(
            width: 2,
            color: Colors.grey,
          ),
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            color: Colors.transparent,
            child: Text(
              ' $category',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: min(14, width / (category.length - 2))),
            ),
          ),
        ),
      ),
    );
  }
}
