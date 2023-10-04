import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waste_genie/helpers/database_utils.dart';

class Comment {
  final String id;
  final int timestamp;
  final String postId;
  final String authorId;
  final String authorName;
  final String content;

  Comment({
    this.id = '',
    this.postId = '',
    this.authorId = '',
    this.authorName = '',
    this.timestamp = 0,
    this.content = '',
  });
}

class CommentButton extends StatefulWidget {
  final String postId;

  CommentButton({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommentButton> createState() => CommentButtonState();
}

class CommentButtonState extends State<CommentButton> {
  int commentsCount = 0;
  bool loading = true;

  void loadCommentCount() async {
    // load comments
    final data = Map<String, dynamic>.from(
        await DatabaseUtils.getData('comments/${widget.postId}', 'timestamp'));

    commentsCount = data.length;

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void loadCommentScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CommentsScreen(postId: widget.postId)),
    ).then((value) {
      loadCommentCount();
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    loadCommentCount();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      IconButton(
        // comment button
        onPressed: () => loadCommentScreen(),
        icon: Icon(Icons.comment_outlined),
        padding: EdgeInsets.zero,
      ),
      if (!loading)
        InkWell(
          onTap: () => loadCommentScreen(),
          child: Text(
            commentsCount > 0 ? commentsCount.toString() : '',
          ),
        ),
    ]);
  }
}

class CommentsPreview extends StatefulWidget {
  final String postId;

  CommentsPreview({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommentsPreview> createState() => CommentsPreviewState();
}

class CommentsPreviewState extends State<CommentsPreview> {
  List<Comment> comments = [];
  int commentsCount = 0;
  bool loading = true;

  void loadComments() async {
    comments.clear();

    // load comments
    final data = Map<String, dynamic>.from(
        await DatabaseUtils.getData('comments/${widget.postId}', 'timestamp'));

    commentsCount = data.length;

    // only show first 3 comments
    for (var commentId in data.keys.take(3)) {
      var curr = data[commentId];
      comments.add(Comment(
          id: commentId,
          postId: curr['postId'],
          authorId: curr['authorId'],
          authorName: await DatabaseUtils.getString(
              'user-public-profile/${curr['authorId']}/displayName'),
          timestamp: curr['timestamp'],
          content: curr['content']));
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void loadCommentScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CommentsScreen(postId: widget.postId)),
    ).then((value) {
      loadComments();
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    loadComments();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!loading)
            for (Comment comment in comments)
              InkWell(
                onTap: () => loadCommentScreen(),
                child: Container(
                  padding: EdgeInsets.only(
                    top: 8,
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: comment.authorName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text:
                              '  ${comment.content.length > 50 ? '${comment.content.substring(0, 50)}...' : comment.content}',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          if (!loading && commentsCount > 3)
            InkWell(
              onTap: () => loadCommentScreen(),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: 6,
                ),
                child: Text(
                  'View all $commentsCount comments',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
        ]);
  }
}

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({
    Key? key,
    required this.postId,
  }) : super(key: key);

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  TextEditingController _commentController = TextEditingController();

  List<Comment> comments = [];
  String displayName = '';
  User? user = FirebaseAuth.instance.currentUser;

  void loadComments() async {
    comments.clear();

    // load current user's name
    displayName = await DatabaseUtils.getString(
        'user-public-profile/${user!.uid}/displayName');

    // load comments
    final data = Map<String, dynamic>.from(
        await DatabaseUtils.getData('comments/${widget.postId}', 'timestamp'));

    for (var commentId in data.keys) {
      var curr = data[commentId];
      comments.add(Comment(
          id: commentId,
          postId: curr['postId'],
          authorId: curr['authorId'],
          authorName: await DatabaseUtils.getString(
              'user-public-profile/${curr['authorId']}/displayName'),
          timestamp: curr['timestamp'],
          content: curr['content']));
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool loading = true;

  void showMsg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      duration: Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (loading) {
      body = const Center(
          child: Padding(
        padding: EdgeInsets.all(8),
        child: CircularProgressIndicator(),
      ));
    } else {
      body = ListView.builder(
          itemCount: comments.length,
          itemBuilder: (context, index) {
            Comment curr = comments[index];
            return CommentLine(comment: curr);
          });
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Comments",
        ),
        centerTitle: false,
      ),
      body: body,
      bottomNavigationBar: SafeArea(
        child: Container(
          height: kToolbarHeight,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 8,
          ),
          child: Row(
            children: [
              Icon(Icons.account_circle_outlined),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Comment as $displayName',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              if (!loading)
                InkWell(
                  onTap: () async {
                    if (_commentController.text.trim().isEmpty) {
                      showMsg('Comment is empty.');
                      return;
                    }
                    await DatabaseUtils.writeWithKey(
                        'comments/${widget.postId}', {
                      'authorId': user!.uid,
                      'postId': widget.postId,
                      'timestamp': ServerValue.timestamp,
                      'content': _commentController.text,
                    });
                    DatabaseUtils.writeLog('Comment', 'Comment');
                    loadComments();
                    _commentController.clear();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: Icon(Icons.send_outlined),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

class CommentLine extends StatefulWidget {
  const CommentLine({
    super.key,
    required this.comment,
  });

  final Comment comment;

  @override
  State<CommentLine> createState() => _CommentLineState();
}

class _CommentLineState extends State<CommentLine> {
  User? user = FirebaseAuth.instance.currentUser;
  bool deleted = false;

  @override
  Widget build(BuildContext context) {
    if (deleted) {
      return Container(
        padding: EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        child: Row(
          children: [
            Icon(Icons.delete),
            SizedBox(width: 8),
            Text('Comment deleted'),
          ],
        ),
      );
    }
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 16,
      ),
      child: Row(
        children: [
          Icon(Icons.account_circle_outlined),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: widget.comment.authorName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: '  ${widget.comment.content}',
                          style: TextStyle(),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: 4,
                    ),
                    child: Text(
                      DateFormat.yMMMd().format(
                        DateTime.fromMicrosecondsSinceEpoch(
                            widget.comment.timestamp * 1000),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (user != null && user!.uid == widget.comment.authorId)
            IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: () {
                DatabaseUtils.delete(
                    '/comments/${widget.comment.postId}/${widget.comment.id}');
                setState(() {
                  deleted = true;
                });
              },
            ),
        ],
      ),
    );
  }
}
