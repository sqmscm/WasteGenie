import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dotted_border/dotted_border.dart';
import 'package:waste_genie/helpers/color_utils.dart';
import 'package:waste_genie/helpers/database_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:waste_genie/helpers/globals.dart' as globals;

class QuizMaker extends StatefulWidget {
  const QuizMaker({Key? key}) : super(key: key);

  @override
  State<QuizMaker> createState() => _QuizMakerState();
}

class _QuizMakerState extends State<QuizMaker> {
  XFile? _pickedFile;
  CroppedFile? _croppedFile;
  String selectedCategory = 'landfill';

  double imagePreviewWidth = 0;
  double imageCropperPreviewWidth = 0;
  double imageCropperViewportWidth = 0;

  @override
  void initState() {
    super.initState();
    globals.currPageName = 'Quiz Maker';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    imagePreviewWidth = min(screenWidth * 0.9, 400);
    imageCropperPreviewWidth = min(screenWidth * 0.75, 450);
    imageCropperViewportWidth = min(screenWidth * 0.65, 400);

    if (_croppedFile != null) {
      return _imageCard();
    } else {
      return _uploaderCard();
    }
  }

  Widget _imageCard() {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _menu(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _image(),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Ink(
                // clear button
                decoration: const ShapeDecoration(
                  color: Colors.redAccent,
                  shape: CircleBorder(),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline_outlined),
                  color: Colors.white,
                  onPressed: () {
                    _clear();
                  },
                ),
              ),
              SizedBox(width: 8),
              Ink(
                // undo button
                decoration: const ShapeDecoration(
                  color: Colors.blueAccent,
                  shape: CircleBorder(),
                ),
                child: IconButton(
                  icon: const Icon(Icons.undo_outlined),
                  color: Colors.white,
                  onPressed: () {
                    // undo drawing
                    if (setRect.isNotEmpty) {
                      AnnotationRect last = setRect.removeLast();
                      setState(() {
                        last.deleted = true;
                      });
                      currRect = setRect;
                    }
                  },
                ),
              ),
              SizedBox(width: 8),
              Ink(
                // publish button
                decoration: const ShapeDecoration(
                  color: Colors.green,
                  shape: CircleBorder(),
                ),
                child: IconButton(
                  icon: const Icon(Icons.done_outlined),
                  color: Colors.white,
                  onPressed: () => publish(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool uploading = false;

  void showMsg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      duration: Duration(seconds: 2),
    ));
  }

  void publish() async {
    // publish the post
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _croppedFile == null || uploading) {
      print('Error when uploading the content.');
      return;
    }

    uploading = true;

    // generate position and stat array
    var positions = [];
    var stats = [];
    final scale = imageCropperViewportWidth / imagePreviewWidth;

    for (AnnotationRect obj in setRect) {
      if (obj.deleted) {
        continue;
      }

      positions.add({
        'xmin': obj.xmin * scale,
        'xmax': (obj.xmin + obj.width) * scale,
        'ymin': obj.ymin * scale,
        'ymax': (obj.ymin + obj.height) * scale,
      });

      stats.add({'category': obj.category});
    }
    if (positions.isEmpty) {
      showMsg('Please label some items!');
      uploading = false;
      return;
    } else {
      showMsg('Publishing...');
    }
    final base64str = base64Encode(await _croppedFile!.readAsBytes());

    // upload the image
    final imgKey = await DatabaseUtils.uploadImage(base64str);

    // upload the post
    final postKey = await DatabaseUtils.writeWithKey('feed', {
      'authorId': uid,
      'imageWidth': imageCropperViewportWidth,
      'imageScale': scale,
      'imageSrc': imgKey,
      'isQuiz': true,
      'objectPositions': positions,
      'objectStats': stats,
      'textContent': null,
      'timestamp': ServerValue.timestamp,
    });

    DatabaseUtils.write('user-public-profile/$uid/posts/$postKey', true);
    DatabaseUtils.increment('/server-stat/totalQuizes', 1);
    DatabaseUtils.writeLog('CreateQuiz', 'A new quiz is created.');

    if (context.mounted) Navigator.of(context).pop(postKey);
  }

  double _x = 0, _y = 0, _width = 0, _height = 0;
  List setRect = [];
  List currRect = [];

  Widget _image() {
    if (_croppedFile != null) {
      final path = _croppedFile!.path;
      return MouseRegion(
        cursor: SystemMouseCursors.precise,
        child: GestureDetector(
          onPanStart: (details) {
            _x = details.localPosition.dx;
            _y = details.localPosition.dy;
          },
          onPanUpdate: (details) {
            double currX =
                min(imagePreviewWidth, max(0, details.localPosition.dx));
            double currY =
                min(imagePreviewWidth, max(0, details.localPosition.dy));

            _width = (currX - _x).abs();
            _height = (currY - _y).abs();
            double startX = min(_x, currX);
            double startY = min(_y, currY);
            setState(() {
              currRect = setRect +
                  [
                    AnnotationRect(
                      xmin: startX,
                      ymin: startY,
                      width: _width,
                      height: _height,
                      category: selectedCategory,
                    )
                  ];
            });
          },
          onPanEnd: (details) {
            if (_width < 50 && _height < 50) {
              if (_width > 5) {
                showMsg('Please draw a larger rectangle.');
              } else {
                showMsg('Please draw rectangles here for labelling.');
              }
              setState(() {
                currRect = setRect;
              });
              return;
            }
            setRect = currRect;
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: imagePreviewWidth,
              maxHeight: imagePreviewWidth,
            ),
            child: Stack(children: [
              kIsWeb
                  ? Image.network(
                      path,
                      scale: imageCropperViewportWidth / imagePreviewWidth,
                    )
                  : Image.file(
                      File(path),
                      scale: imageCropperViewportWidth / imagePreviewWidth,
                    ),
              for (AnnotationRect rect in currRect)
                if (!rect.deleted) rect,
            ]),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _menu() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
        child: Column(
          children: [
            Text('Draw boxes for: '),
            SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: 'recycle',
                      label: Text('Recycle'),
                      icon: Image.asset(
                        'images/recycle_drag.png',
                        width: 18,
                      ),
                    ),
                    ButtonSegment(
                      value: 'landfill',
                      label: Text('Landfill'),
                      icon: Image.asset(
                        'images/landfill_drag.png',
                        width: 18,
                      ),
                    ),
                    ButtonSegment(
                      value: 'compost',
                      label: Text('Compost'),
                      icon: Image.asset(
                        'images/compost_drag.png',
                        width: 18,
                      ),
                    )
                  ],
                  selected: {selectedCategory},
                  onSelectionChanged: (p0) {
                    setState(() {
                      selectedCategory = p0.first;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploaderCard() {
    return Center(
      child: InkWell(
        onTap: () => _uploadImage(),
        child: Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: SizedBox(
            width: imagePreviewWidth,
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: DottedBorder(
                        radius: const Radius.circular(12.0),
                        borderType: BorderType.RRect,
                        dashPattern: const [8, 4],
                        color:
                            Theme.of(context).highlightColor.withOpacity(0.4),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                color: Theme.of(context).highlightColor,
                                size: 80.0,
                              ),
                              const SizedBox(height: 24.0),
                              Text(
                                'Select an image to continue',
                                style: kIsWeb
                                    ? Theme.of(context)
                                        .textTheme
                                        .headlineSmall!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .highlightColor)
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .highlightColor),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cropImage() async {
    if (_pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _pickedFile!.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Cropper',
          ),
          WebUiSettings(
            context: context,
            customDialogBuilder: (cropper, crop, rotate) {
              return Dialog(
                insetPadding: EdgeInsets.zero,
                child: CropperDialog(
                  cropper: cropper,
                  crop: crop,
                  rotate: rotate,
                  imageCropperPreviewWidth: imageCropperPreviewWidth,
                ),
              );
            },
            presentStyle: CropperPresentStyle.dialog,
            boundary: CroppieBoundary(
              width: imageCropperPreviewWidth.toInt(),
              height: imageCropperPreviewWidth.toInt(),
            ),
            viewPort: CroppieViewPort(
              width: imageCropperViewportWidth.toInt(),
              height: imageCropperViewportWidth.toInt(),
              type: 'square',
            ),
            enableExif: true,
            enableZoom: true,
            showZoomer: true,
          ),
        ],
      );
      if (croppedFile != null) {
        setState(() {
          _croppedFile = croppedFile;
        });
      }
    }
  }

  Future<Image> getImage(XFile file) async {
    return Image.memory(await file.readAsBytes());
  }

  Future<void> _uploadImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedFile = pickedFile;
        _cropImage();
      });
    }
  }

  void _clear() {
    setState(() {
      setRect = [];
      currRect = [];
      _pickedFile = null;
      _croppedFile = null;
    });
  }
}

// ignore: must_be_immutable
class AnnotationRect extends StatefulWidget {
  AnnotationRect({
    Key? key,
    required this.xmin,
    required this.ymin,
    required this.width,
    required this.height,
    required this.category,
    this.deleted = false,
  }) : super(key: key);

  final double xmin, ymin, width, height;
  final String category;
  bool deleted;

  @override
  State<AnnotationRect> createState() => _AnnotationRectState();
}

class _AnnotationRectState extends State<AnnotationRect> {
  @override
  Widget build(BuildContext context) {
    return widget.deleted
        ? Container()
        : Positioned(
            left: widget.xmin,
            top: widget.ymin,
            child: InkWell(
              onTap: () => setState(() => widget.deleted = true),
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: ColorUtils.getColorTransparent(widget.category),
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
                      ' ${widget.category}',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: min(
                              14, widget.width / (widget.category.length - 2))),
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}

class CropperDialog extends StatelessWidget {
  final Widget cropper;
  final Future<String?> Function() crop;
  final void Function(RotationAngle) rotate;
  final double imageCropperPreviewWidth;

  const CropperDialog({
    Key? key,
    required this.cropper,
    required this.crop,
    required this.rotate,
    required this.imageCropperPreviewWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            offset: Offset(0, 0),
            blurRadius: 2,
            spreadRadius: 2,
          ),
        ],
      ),
      width: imageCropperPreviewWidth + 16,
      child: IntrinsicHeight(
        child: Column(
          children: [
            _header(context),
            const Divider(height: 1.0, thickness: 1.0),
            Padding(
              padding:
                  const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 50),
              child: _body(context),
            ),
            const Divider(height: 1.0, thickness: 1.0),
            _footer(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Edit Image',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.rotate_90_degrees_ccw_rounded),
              color: Colors.blue,
              onPressed: () => rotate(RotationAngle.counterClockwise90),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
              color: Colors.blue,
              onPressed: () => rotate(RotationAngle.clockwise90),
            ),
          ],
        ),
        SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: imageCropperPreviewWidth,
            height: imageCropperPreviewWidth,
            child: cropper,
          ),
        ),
      ],
    );
  }

  Widget _footer(BuildContext context) {
    return ButtonBar(
      buttonPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          ),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final result = await crop();
            if (context.mounted) Navigator.of(context).pop(result);
          },
          style: ElevatedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
          ),
          child: Text('OK'),
        ),
      ],
    );
  }
}
