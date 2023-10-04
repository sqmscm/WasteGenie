import 'package:waste_genie/helpers/editor_board.dart';
import 'package:waste_genie/modules/quiz_maker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:stack_board/stack_board.dart';

class PostMaker extends StatefulWidget {
  const PostMaker({Key? key}) : super(key: key);

  @override
  State<PostMaker> createState() => _PostMakerState();
}

class _PostMakerState extends State<PostMaker> {
  late EditorBoardController _boardController;

  String selectedFunction = 'post';

  @override
  void initState() {
    super.initState();
    _boardController = EditorBoardController();
  }

  @override
  void dispose() {
    _boardController.dispose();
    super.dispose();
  }

  // void changeColor(Color color) {
  //   setState(() => pickerColor = color);
  // }

  late EditorBoard editorBoard = EditorBoard(
    controller: _boardController,
    caseStyle: const CaseStyle(
      borderColor: Colors.grey,
      iconColor: Colors.white,
    ),
    tapToCancelAllItem: true,
    tapItemToMoveTop: true,
  );

  @override
  Widget build(BuildContext context) {
    var tipsFunction = editorBoard;
    var quizFunction = QuizMaker();

    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () {
                var dialogTitle = const Text('Make a New Post');
                var helpImg = 'images/help-newpost.png';

                if (selectedFunction == 'quiz') {
                  dialogTitle = const Text('Make a New Quiz');
                  helpImg = 'images/help-newquiz.png';
                }
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: dialogTitle,
                        content: SingleChildScrollView(
                            child: Image(image: AssetImage(helpImg))),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12.0, horizontal: 16.0),
                            ),
                            child: Text('OK'),
                          ),
                        ],
                      );
                    });
              },
              icon: Icon(Icons.help_outline_outlined),
            )
          ],
          flexibleSpace: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SegmentedButton(
                segments: [
                  ButtonSegment(
                    value: 'post',
                    label: Text('New Post'),
                    icon: Icon(Icons.tips_and_updates_outlined),
                  ),
                  ButtonSegment(
                    value: 'quiz',
                    label: Text('New Quiz'),
                    icon: Icon(Icons.category_outlined),
                  )
                ],
                selected: {selectedFunction},
                onSelectionChanged: (p0) {
                  setState(() {
                    selectedFunction = p0.first;
                  });
                },
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedFunction == 'post')
                tipsFunction
              else if (selectedFunction == 'quiz')
                quizFunction,
            ],
          ),
        ));
  }

  Future<Image> getImage(XFile file) async {
    return Image.memory(await file.readAsBytes());
  }
}
