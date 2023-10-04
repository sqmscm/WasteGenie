import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:waste_genie/helpers/rich_text.dart';
import 'package:waste_genie/helpers/rich_text_case.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:stack_board/stack_board.dart';
import 'package:waste_genie/helpers/globals.dart' as globals;

import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'database_utils.dart';
import 'screenshot.dart';

/// 层叠板
class EditorBoard extends StatefulWidget {
  EditorBoard({
    Key? key,
    this.controller,
    this.background,
    this.caseStyle = const CaseStyle(),
    this.customBuilder,
    this.tapToCancelAllItem = false,
    this.tapItemToMoveTop = true,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _EditorBoardState createState() => _EditorBoardState();

  /// 层叠版控制器
  final EditorBoardController? controller;

  /// 背景
  final Widget? background;

  /// 操作框样式
  final CaseStyle? caseStyle;

  /// 自定义类型控件构建器
  final Widget? Function(StackBoardItem item)? customBuilder;

  /// 点击空白处取消全部选择（比较消耗性能，默认关闭）
  final bool tapToCancelAllItem;

  /// 点击item移至顶层
  final bool tapItemToMoveTop;
}

class _EditorBoardState extends State<EditorBoard> with SafeState<EditorBoard> {
  /// 子控件列表
  late List<StackBoardItem> _children;

  /// 当前item所用id
  int _lastId = 0;

  /// 所有item的操作状态
  OperatState? _operatState;

  /// 生成唯一Key
  Key _getKey(int? id) => Key('StackBoardItem$id');

  @override
  void initState() {
    super.initState();
    globals.currPageName = 'Post Maker';
    _children = <StackBoardItem>[];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.controller?._stackBoardState = this;
  }

  /// 添加一个
  void _add<T extends StackBoardItem>(StackBoardItem item) {
    if (_children.contains(item)) throw 'duplicate id';

    _children.add(item.copyWith(
      id: item.id ?? _lastId,
      caseStyle: item.caseStyle ?? widget.caseStyle,
    ));

    _lastId++;
    safeSetState(() {});
  }

  /// 移除指定id item
  void _remove(int? id) {
    _children.removeWhere((StackBoardItem b) => b.id == id);
    safeSetState(() {});
  }

  /// 将item移至顶层
  void _moveItemToTop(int? id) {
    if (id == null) return;

    final StackBoardItem item =
        _children.firstWhere((StackBoardItem i) => i.id == id);
    _children.removeWhere((StackBoardItem i) => i.id == id);
    _children.add(item);

    safeSetState(() {});
  }

  /// 清理
  void _clear() {
    _children.clear();
    _lastId = 0;
    safeSetState(() {});
  }

  /// 取消全部选中
  void _unFocus() {
    _operatState = OperatState.complate;
    safeSetState(() {});
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      _operatState = null;
      safeSetState(() {});
    });
  }

  /// 删除动作
  Future<void> _onDel(StackBoardItem box) async {
    final bool del = (await box.onDel?.call()) ?? true;
    if (del) _remove(box.id);
  }

  void changeColor(Color color) {
    setState(() => pickerColor = color);
  }

  final fonts = [
    'Arial',
    'GREENPIL',
    'Grinched',
    'Helvetica',
    'The Bold Font',
    'Thorne Shaded',
    'Toony Noodle NF'
  ];

  Color backgroundColor = Colors.white;
  Color pickerColor = Colors.white;
  String setStyle = 'Arial';
  Color setTextColor = Colors.black;
  GlobalKey editorBoardKey = GlobalKey();
  Map<Key, dynamic> textItems = {};
  final sourceController = TextEditingController();
  double imagePreviewWidth = 400;
  ScreenshotController boardshot = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    Widget child;

    child = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ColoredBox(color: backgroundColor),
        ..._children.map((StackBoardItem box) => _buildItem(box)).toList(),
      ],
    );

    if (widget.tapToCancelAllItem) {
      child = GestureDetector(
        onTap: _unFocus,
        child: child,
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    imagePreviewWidth = min(screenWidth * 0.95, 400);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
          width: imagePreviewWidth,
          height: imagePreviewWidth,
          child: Screenshot(
            controller: boardshot,
            child: child,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _spacer,
            FloatingActionButton.small(
              heroTag: null,
              onPressed: () {
                RichTextItem textItem = RichTextItem(
                  'Tap to edit',
                  tapToEdit: true,
                  style: TextStyle(
                    color: setTextColor,
                    fontFamily: setStyle,
                  ),
                );
                widget.controller?.add<RichTextItem>(textItem);
              },
              child: const Icon(Icons.format_shapes_outlined),
            ),
            if (textItems.isNotEmpty) _spacer,
            if (textItems.isNotEmpty)
              FloatingActionButton.small(
                backgroundColor: Colors.lightBlueAccent,
                heroTag: null,
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Choose a Font'),
                          content: SizedBox(
                            height: 350,
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  for (String font in fonts)
                                    ListTile(
                                      selectedTileColor:
                                          Theme.of(context).focusColor,
                                      selected: setStyle == font,
                                      onTap: () {
                                        setStyle = font;
                                        for (var modifier in textItems.values) {
                                          dynamic callback = modifier[1];
                                          callback(TextStyle(
                                            color: setTextColor,
                                            fontFamily: setStyle,
                                          ));
                                        }
                                        Navigator.of(context).pop();
                                      },
                                      title: Text(
                                        font,
                                        style: TextStyle(fontFamily: font),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                              ),
                              child: Text('Cancel'),
                            ),
                          ],
                        );
                      });
                },
                child: const Icon(Icons.title_outlined),
              ),
            if (textItems.isNotEmpty) _spacer,
            if (textItems.isNotEmpty)
              FloatingActionButton.small(
                backgroundColor: Colors.lightBlueAccent,
                heroTag: null,
                onPressed: () {
                  pickerColor = setTextColor;
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Text Color'),
                          content: SingleChildScrollView(
                            child: SlidePicker(
                              pickerColor: pickerColor,
                              onColorChanged: changeColor,
                              colorModel: ColorModel.rgb,
                              enableAlpha: false,
                              displayThumbColor: true,
                              showParams: false,
                              showIndicator: true,
                              indicatorBorderRadius:
                                  const BorderRadius.vertical(
                                      top: Radius.circular(25)),
                            ),
                          ),
                          actions: <Widget>[
                            ElevatedButton(
                              child: const Text('OK'),
                              onPressed: () {
                                setTextColor = pickerColor;
                                for (var modifier in textItems.values) {
                                  dynamic callback = modifier[1];
                                  callback(TextStyle(
                                    color: setTextColor,
                                    fontFamily: setStyle,
                                  ));
                                }
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      });
                },
                child: const Icon(Icons.invert_colors_outlined),
              ),
            _spacer,
            FloatingActionButton.small(
              heroTag: null,
              onPressed: () {
                _getImageFromGallery();
              },
              child: const Icon(Icons.image_outlined),
            ),
            _spacer,
            FloatingActionButton.small(
              heroTag: null,
              onPressed: () {
                _getImageFromCamera();
              },
              child: const Icon(Icons.camera_alt_outlined),
            ),
            _spacer,
            FloatingActionButton.small(
              heroTag: null,
              onPressed: () {
                pickerColor = backgroundColor;
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Background Color'),
                        content: SingleChildScrollView(
                          child: SlidePicker(
                            pickerColor: pickerColor,
                            onColorChanged: changeColor,
                            colorModel: ColorModel.rgb,
                            enableAlpha: false,
                            displayThumbColor: true,
                            showParams: false,
                            showIndicator: true,
                            indicatorBorderRadius: const BorderRadius.vertical(
                                top: Radius.circular(25)),
                          ),
                        ),
                        actions: <Widget>[
                          ElevatedButton(
                            child: const Text('OK'),
                            onPressed: () {
                              setState(() => backgroundColor = pickerColor);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    });
              },
              child: const Icon(Icons.palette_outlined),
            ),
            _spacer,
            FloatingActionButton.small(
              heroTag: null,
              onPressed: () {
                widget.controller?.clear();
                setState(() {
                  textItems.clear();
                });
              },
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.delete_forever_outlined),
            ),
          ],
        ),
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            style: TextStyle(fontSize: 15),
            controller: sourceController,
            decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Source',
                contentPadding: EdgeInsets.all(8)),
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _spacer,
            FilledButton.icon(
              onPressed: () => publish(),
              icon: Icon(Icons.done_outlined),
              label: Text('Publish'),
            ),
          ],
        )
      ],
    );
  }

  void showMsg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      duration: Duration(seconds: 2),
    ));
  }

  bool isPubishing = false;

  void publish() async {
    if (_children.isEmpty) {
      showMsg('The post is empty.');
      return;
    }
    if (sourceController.text.trim().isEmpty) {
      showMsg('Please enter your source to continue.');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (isPubishing || uid == null) return;
    isPubishing = true;
    showMsg('Publishing...');
    try {
      widget.controller?.completeAll();
      await Future.delayed(Duration(milliseconds: 200));

      final bytes = await boardshot.capture();
      final base64str = base64Encode(bytes!);

      final imgKey = await DatabaseUtils.uploadImage(base64str);

      // upload the post
      final postKey = await DatabaseUtils.writeWithKey('feed', {
        'authorId': uid,
        'imageWidth': imagePreviewWidth,
        'imageSrc': imgKey,
        'isQuiz': false,
        'textContent': sourceController.text.trim(),
        'timestamp': ServerValue.timestamp,
      });

      isPubishing = false;
      DatabaseUtils.write('user-public-profile/$uid/posts/$postKey', true);
      DatabaseUtils.writeLog('CreatePost', 'A new post is created.');
      if (context.mounted) Navigator.of(context).pop(postKey);
    } catch (e) {
      showMsg('Error generating image: $e');
      isPubishing = false;
    }
  }

  _getImageFromGallery() async {
    // Pick an image
    final XFile? imageFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (imageFile != null) {
      widget.controller?.add(
        StackBoardItem(
          child: await getImage(imageFile),
        ),
      );
    }
  }

  Future<Image> getImage(XFile file) async {
    return Image.memory(await file.readAsBytes());
  }

  _getImageFromCamera() async {
    // Pick an image
    final XFile? imageFile =
        await ImagePicker().pickImage(source: ImageSource.camera);

    if (imageFile != null) {
      widget.controller?.add(
        StackBoardItem(
          child: await getImage(imageFile),
        ),
      );
    }
  }

  /// 构建项
  Widget _buildItem(StackBoardItem item) {
    Widget child = ItemCase(
      key: _getKey(item.id),
      onDel: () => _onDel(item),
      onTap: () => _moveItemToTop(item.id),
      caseStyle: item.caseStyle,
      operatState: _operatState,
      child: Container(
        width: 150,
        height: 150,
        alignment: Alignment.center,
        child: const Text(
            'unknow item type, please use customBuilder to build it'),
      ),
    );

    if (item is RichTextItem) {
      Key key = _getKey(item.id);
      child = RichTextCase(
        key: key,
        adaptiveText: item,
        onDel: () {
          _onDel(item);
          safeSetState(() {
            textItems.remove(key);
          });
        },
        onComplete: () {
          safeSetState(() {
            textItems.remove(key);
          });
        },
        onTap: () => _moveItemToTop(item.id),
        onFocusing: (style, callback1) {
          safeSetState(() {
            textItems[key] = [style, callback1];
          });
        },
        operatState: _operatState,
      );
    } else {
      child = ItemCase(
        key: _getKey(item.id),
        onDel: () => _onDel(item),
        onTap: () => _moveItemToTop(item.id),
        caseStyle: item.caseStyle,
        operatState: _operatState,
        child: item.child,
      );

      if (widget.customBuilder != null) {
        final Widget? customWidget = widget.customBuilder!.call(item);
        if (customWidget != null) return child = customWidget;
      }
    }

    return child;
  }

  Widget get _spacer => const SizedBox(width: 5);
}

/// 控制器
class EditorBoardController {
  _EditorBoardState? _stackBoardState;

  /// 检查是否加载
  void _check() {
    if (_stackBoardState == null) throw '_stackBoardState is empty';
  }

  /// 添加一个
  void add<T extends StackBoardItem>(T item) {
    _check();
    _stackBoardState?._add<T>(item);
  }

  /// 移除
  void remove(int? id) {
    _check();
    _stackBoardState?._remove(id);
  }

  void moveItemToTop(int? id) {
    _check();
    _stackBoardState?._moveItemToTop(id);
  }

  /// 清理全部
  void clear() {
    _check();
    _stackBoardState?._clear();
  }

  // complete
  void completeAll() {
    _check();
    _stackBoardState?._unFocus();
  }

  /// 刷新
  void refresh() {
    _check();
    _stackBoardState?.safeSetState(() {});
  }

  /// 销毁
  void dispose() {
    _stackBoardState = null;
  }
}
