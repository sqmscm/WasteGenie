import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:confetti/confetti.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:waste_genie/helpers/classification_dict.dart';
import 'package:waste_genie/helpers/color_utils.dart';
import 'package:waste_genie/helpers/database_utils.dart';
import 'package:waste_genie/modules/comments.dart';
import 'package:waste_genie/modules/leaderboard.dart';
import 'package:waste_genie/modules/post_maker.dart';
import 'package:waste_genie/helpers/globals.dart' as globals;
import 'package:waste_genie/modules/feed_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeedPage extends StatefulWidget {
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  // pagination properties
  static const _pageSize = 8;
  final PagingController<int, FeedItem> _pagingController =
      PagingController(firstPageKey: DateTime.now().microsecondsSinceEpoch);

  var onlyShowLikes = false;
  var manifestLoaded = false; // liked list and completed quiz list

  Future<void> addPost(
      List<FeedItem> targetList,
      String feedId,
      Map<String, dynamic> curr,
      bool liked,
      int completeAttempts,
      bool addToHead) async {
    if (curr.isEmpty) {
      // post not exist
      return;
    }

    FeedItem feedItem = FeedItem(
        id: feedId,
        source: curr['textContent'] ?? '',
        authorId: curr['authorId'],
        authorName: await DatabaseUtils.getString(
            'user-public-profile/${curr['authorId']}/displayName'),
        imageId: curr['imageSrc'] ?? '',
        imageSrc:
            await DatabaseUtils.getString('img-storage/${curr['imageSrc']}'),
        imageScale: curr['imageScale'] ?? 1.0,
        imageWidth: curr['imageWidth'] ?? -1.0,
        timestamp: curr['timestamp'],
        liked: liked,
        completeAttempts: completeAttempts,
        numLikes: curr['likes'] ?? 0,
        isQuiz: curr['isQuiz'] ?? false,
        objectStats: curr['objectStats'] ?? [],
        objectPositions: curr['objectPositions'] ?? []);

    // add to list
    if (addToHead) {
      targetList.insert(0, feedItem);
    } else {
      targetList.add(feedItem);
    }
  }

  late Map<String, dynamic> likedList;
  late Map<String, dynamic> completedList;

  Future<void> retrieveFeeds(int pageKey) async {
    try {
      List<FeedItem> newPostList = [];

      if (!manifestLoaded) {
        // get my likes and completed quiz list
        String currUid = FirebaseAuth.instance.currentUser!.uid;
        likedList = Map<String, dynamic>.from(
            await DatabaseUtils.getData('feed-liked-by/$currUid', ''));
        completedList = Map<String, dynamic>.from(
            await DatabaseUtils.getData('quiz-completed-by/$currUid', ''));
        manifestLoaded = true;
      }

      if (onlyShowLikes) {
        for (var feedId in likedList.keys) {
          final curr = Map<String, dynamic>.from(
              await DatabaseUtils.getData('feed/$feedId', ''));

          // process the post
          await addPost(
              newPostList,
              feedId,
              curr,
              true,
              completedList.containsKey(feedId) ? completedList[feedId] : 0,
              false);
        }
      } else {
        // get the feed content
        final data = Map<String, dynamic>.from(await DatabaseUtils.getPagedData(
            'feed', 'timestamp', pageKey, _pageSize));

        for (var feedId in data.keys) {
          var curr = data[feedId];

          // process the post
          await addPost(
              newPostList,
              feedId,
              curr,
              likedList.containsKey(feedId),
              completedList.containsKey(feedId) ? completedList[feedId] : 0,
              true);
        }
      }

      final isLastPage = newPostList.length < _pageSize;
      if (isLastPage || onlyShowLikes) {
        _pagingController.appendLastPage(newPostList);
      } else {
        final nextPageKey = newPostList.last.timestamp;
        _pagingController.appendPage(newPostList, nextPageKey);
      }
    } catch (e) {
      _pagingController.error = e;
      print(e);
    }
  }

  void toggleViewMode() {
    if (mounted) {
      setState(() {
        onlyShowLikes = !onlyShowLikes;
        _pagingController.refresh();
      });
    }
  }

  void newPost() async {
    var ret = Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PostMaker()),
    );
    if (await ret != null) {
      _pagingController.refresh();
    }
    globals.currPageName = 'Feed';
  }

  @override
  void initState() {
    DatabaseUtils.writeLog('RefreshFeed', '');
    // init paging controller
    _pagingController.addPageRequestListener((pageKey) {
      retrieveFeeds(pageKey);
    });
    globals.currPageName = 'Feed';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Row topBottons = Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () => {toggleViewMode()},
              icon: onlyShowLikes
                  ? Icon(
                      Icons.favorite,
                      color: Colors.redAccent,
                    )
                  : Icon(Icons.favorite_border),
              label: Text('My Likes'),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () => newPost(),
              icon: Icon(Icons.edit_outlined),
              label: Text('New Post'),
            ),
          ),
        ),
      ],
    );

    return Column(
      children: [
        topBottons,
        Flexible(
          child: PagedListView(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<FeedItem>(
              itemBuilder: ((context, item, index) {
                return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: FeedCard(feedItem: item));
              }),
              noItemsFoundIndicatorBuilder: (context) => Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        'No items',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Text(
                        onlyShowLikes
                            ? 'You haven\'t liked any post yet.'
                            : 'No post available yet.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}

class FeedCard extends StatefulWidget {
  final FeedItem feedItem;
  FeedCard({required this.feedItem});

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  String parseTimeStr(int timestamp) {
    return DateFormat('HH:mm • MMM d')
        .format(DateTime.fromMicrosecondsSinceEpoch(timestamp * 1000))
        .toString();
  }

  Image decodeBase64(String base64str) {
    return Image.memory(base64Decode(base64str.replaceAll(RegExp(r'\s+'), '')));
  }

  void deletionCallback() {
    if (mounted) {
      setState(() {
        widget.feedItem.deleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.feedItem.deleted) {
      return Card(
        elevation: 3,
        child: Container(
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(15))),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(Icons.delete),
                  SizedBox(width: 8),
                  Text('Post deleted'),
                ],
              ),
            )),
      );
    }

    return Card(
      elevation: 3,
      child: Container(
        decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15))),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // user profile
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_circle_outlined),
                      const SizedBox(
                        width: 4,
                      ),
                      Text(
                        // author's display name
                        widget.feedItem.authorName,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(
                    // convert timestamp to date
                    parseTimeStr(widget.feedItem.timestamp),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              // post content
              widget.feedItem.isQuiz
                  ? InteractiveImage(feedItem: widget.feedItem)
                  : Image(
                      // post image
                      image: decodeBase64(widget.feedItem.imageSrc).image),
              const SizedBox(
                height: 4,
              ),
              // bottom functions
              CardStateBar(
                feedItem: widget.feedItem,
                deletionCallback: deletionCallback,
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// A custom Path to paint stars.
Path drawStar(Size size) {
  // Method to convert degree to radians
  double degToRad(double deg) => deg * (pi / 180.0);

  const numberOfPoints = 5;
  final halfWidth = size.width / 2;
  final externalRadius = halfWidth;
  final internalRadius = halfWidth / 2.5;
  final degreesPerStep = degToRad(360 / numberOfPoints);
  final halfDegreesPerStep = degreesPerStep / 2;
  final path = Path();
  final fullAngle = degToRad(360);
  path.moveTo(size.width, halfWidth);

  for (double step = 0; step < fullAngle; step += degreesPerStep) {
    path.lineTo(halfWidth + externalRadius * cos(step),
        halfWidth + externalRadius * sin(step));
    path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
        halfWidth + internalRadius * sin(step + halfDegreesPerStep));
  }
  path.close();
  return path;
}

// ignore: must_be_immutable
class InteractiveImage extends StatefulWidget {
  final FeedItem feedItem;

  InteractiveImage({required this.feedItem});

  @override
  State<InteractiveImage> createState() => _InteractiveImageState();
}

class _InteractiveImageState extends State<InteractiveImage> {
  bool isConfettiShown = false;
  late ConfettiController _confettiController;

  Image decodeBase64(String base64str, double scale) {
    return Image.memory(
      scale: scale,
      base64Decode(
        base64str.replaceAll(RegExp(r'\s+'), ''),
      ),
    );
  }

  double offsetX = 50;

  double offsetY = 50;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    super.dispose();
    _confettiController.dispose();
  }

  bool isInside(Offset cursor, Map rect, double scale) {
    return cursor.dx + offsetX > rect['xmin'] * scale &&
        cursor.dx + offsetX < rect['xmax'] * scale &&
        cursor.dy + offsetY > rect['ymin'] * scale &&
        cursor.dy + offsetY < rect['ymax'] * scale;
  }

  @override
  Widget build(BuildContext context) {
    double imagePreviewWidth = 400;

    // dynamic resize
    if (widget.feedItem.imageWidth > 0) {
      final screenWidth = MediaQuery.of(context).size.width;
      imagePreviewWidth = min(screenWidth * 0.9, 400);
      widget.feedItem.imageScale =
          widget.feedItem.imageWidth / imagePreviewWidth;
    }

    var imgCoreKey = GlobalKey();
    Image image =
        decodeBase64(widget.feedItem.imageSrc, widget.feedItem.imageScale);

    if (widget.feedItem.objectPositions.isEmpty) {
      return image;
    }

    var imgScale = widget.feedItem.imageScale;
    var rectList = [];
    int attempts = 0;

    for (int i = 0; i < widget.feedItem.objectPositions.length; ++i) {
      var position = widget.feedItem.objectPositions[i];
      String? category;
      if (widget.feedItem.objectStats.length > i) {
        category = widget.feedItem.objectStats[i]['category'];
      }
      var obj = ObjectRect(
        position: position,
        imgScale: 1 / imgScale,
        category: category,
      );
      rectList.add(obj);

      if (widget.feedItem.completeAttempts > 0) {
        obj.locked = true;
        obj.text = category ?? '';
        obj.setColor = ColorUtils.getColorTransparent(category);
        obj.backgroundColor.value = obj.setColor;
        obj.completed = true;
      }
    }

    return Column(
      children: [
        DragTarget<String>(
          builder: (context, candidateItems, rejectedItems) {
            return Stack(
              children: [
                SizedBox(
                  key: imgCoreKey,
                  width: imagePreviewWidth,
                  height: imagePreviewWidth,
                  child: image,
                ),
                for (var obj in rectList) obj,
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: pi / 2,
                    shouldLoop: false,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                      Colors.purple
                    ],
                    createParticlePath: drawStar,
                  ),
                ),
              ],
            );
          },
          onAcceptWithDetails: (details) {
            if (isConfettiShown || widget.feedItem.completeAttempts > 0) {
              return;
            }

            attempts += 1;

            RenderBox? box =
                imgCoreKey.currentContext?.findRenderObject() as RenderBox;
            Offset local = box.globalToLocal(details.offset);
            int correctCount = 0;
            for (ObjectRect obj in rectList) {
              // test the cursor position
              if (isInside(local, obj.position, obj.imgScale)) {
                obj.setColor = obj.backgroundColor.value;
                obj.text = details.data;
                obj.setText = details.data;
                if (obj.controller != null) {
                  obj.controller!.showResult();
                }
                obj.backgroundColor.value =
                    ColorUtils.getColorTransparent(details.data);
              }

              if (obj.category != null &&
                  obj.category?.toLowerCase() == obj.setText.toLowerCase()) {
                correctCount++;
              }
            }

            // show the confetti
            if (correctCount == rectList.length && !isConfettiShown) {
              String? uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) {
                return;
              }
              // lable as completed
              DatabaseUtils.write(
                  'quiz-completed-by/$uid/${widget.feedItem.id}', attempts);
              DatabaseUtils.increment(
                  'user-public-profile/$uid/carbon-credits',
                  ClassificationDict.computeCarbonCredits(
                      correctCount, attempts));
              if (mounted) {
                setState(() {
                  widget.feedItem.completeAttempts = attempts;
                });
              }
              isConfettiShown = true;
              _confettiController.play();
              for (ObjectRect obj in rectList) {
                obj.locked = true;
              }
            }
          },
          onMove: (details) {
            if (isConfettiShown || widget.feedItem.completeAttempts > 0) {
              return;
            }

            RenderBox? box =
                imgCoreKey.currentContext?.findRenderObject() as RenderBox;
            Offset local = box.globalToLocal(details.offset);
            for (ObjectRect obj in rectList) {
              // test the cursor position
              if (isInside(local, obj.position, obj.imgScale)) {
                obj.backgroundColor.value =
                    ColorUtils.getColorTransparent(details.data);
                obj.text = details.data;
                if (obj.controller != null) obj.controller!.hideResult();
              } else {
                obj.backgroundColor.value = obj.setColor;
                obj.text = obj.setText;
                if (obj.controller != null) obj.controller!.showResult();
              }
            }
          },
        ),
        const SizedBox(
          height: 4,
        ),
        if (widget.feedItem.completeAttempts == 0)
          SizedBox(
            width: 400,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DraggableButton(
                  color: ColorUtils.getColor('Recycle'),
                  iconSrc: 'images/recycle_drag.png',
                  text: 'Recycle',
                ),
                DraggableButton(
                  color: ColorUtils.getColor('Landfill'),
                  iconSrc: 'images/landfill_drag.png',
                  text: 'Landfill',
                ),
                DraggableButton(
                  color: ColorUtils.getColor('Compost'),
                  iconSrc: 'images/compost_drag.png',
                  text: 'Compost',
                ),
              ],
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.done,
                    color: Colors.green,
                  ),
                  SizedBox(width: 8),
                  Text(
                      'Earned ${ClassificationDict.computeCarbonCredits(rectList.length, widget.feedItem.completeAttempts).toStringAsFixed(2)} carbon credits'),
                ],
              ),
              InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Scaffold(
                                appBar: AppBar(
                                  title: Text('Leaderboard'),
                                ),
                                body: const LeaderBoard(),
                              )),
                    );
                    globals.currPageName = 'Feed';
                  },
                  child: Text(
                    "Leaderboard",
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  )),
            ],
          )
      ],
    );
  }
}

// ignore: must_be_immutable
class ObjectRect extends StatefulWidget {
  ObjectRect({
    Key? key,
    required this.position,
    required this.imgScale,
    this.category,
  }) : super(key: key);

  final Map position;
  final double imgScale;
  final String? category;

  bool locked = false;
  bool completed = false;

  Color setColor = ColorUtils.transparentOverlay;

  String setText = '';

  ValueNotifier<Color> backgroundColor =
      ValueNotifier<Color>(ColorUtils.transparentOverlay);

  String text = '';

  // ignore: library_private_types_in_public_api
  _ObjectRectState? controller;

  @override
  State<ObjectRect> createState() => _ObjectRectState();
}

class _ObjectRectState extends State<ObjectRect> {
  bool showResultFlag = false;

  void showResult() {
    if (widget.category != null && widget.setText.isNotEmpty && mounted) {
      setState(() {
        showResultFlag = true;
      });
    }
  }

  void hideResult() {
    if (mounted) {
      setState(() {
        showResultFlag = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.controller = this;
  }

  @override
  Widget build(BuildContext context) {
    double width =
        (widget.position['xmax'] - widget.position['xmin']) * widget.imgScale;
    double height =
        (widget.position['ymax'] - widget.position['ymin']) * widget.imgScale;

    return ValueListenableBuilder(
        valueListenable: widget.backgroundColor,
        builder: (context, value, child) {
          return Positioned(
            left: widget.position['xmin'] * widget.imgScale,
            top: widget.position['ymin'] * widget.imgScale,
            child: InkWell(
              onTap: () {
                if (widget.setText != '' && !widget.locked) {
                  // reset
                  widget.backgroundColor.value = ColorUtils.transparentOverlay;
                  widget.text = '';
                  widget.setColor = ColorUtils.transparentOverlay;
                  widget.setText = '';
                  if (mounted) {
                    setState(() {
                      showResultFlag = false;
                    });
                  }
                }
              },
              child: DottedBorder(
                color: widget.text.isEmpty ? Colors.grey : Colors.transparent,
                strokeWidth: 2,
                radius: const Radius.circular(12.0),
                borderType: BorderType.RRect,
                dashPattern: const [8, 4],
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                      color: value, // filled in color
                      border: Border.all(
                        width: 2,
                        color: widget.text.isEmpty
                            ? Colors.transparent
                            : Colors.grey,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(12))),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          color: Colors.transparent,
                          child: Text(
                            ' ${widget.text}', // category text
                            style: TextStyle(
                                color: Colors.white,
                                fontSize:
                                    min(14, width / (widget.text.length - 2))),
                          ),
                        ),
                      ),
                      if (showResultFlag || widget.completed)
                        if (widget.text.toLowerCase() ==
                            widget.category!.toLowerCase())
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Container(
                                width: 20.0,
                                height: 20.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        else
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Container(
                                width: 20.0,
                                height: 20.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.redAccent,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }
}

class DraggingItem extends StatelessWidget {
  const DraggingItem({
    super.key,
    required this.dragKey,
    required this.image,
  });

  final GlobalKey dragKey;
  final Image image;

  @override
  Widget build(BuildContext context) {
    return FractionalTranslation(
      translation: const Offset(-0.25, -0.25),
      child: ClipRRect(
        key: dragKey,
        borderRadius: BorderRadius.circular(12.0),
        child: SizedBox(
          height: 150,
          width: 150,
          child: Opacity(
            opacity: 0.85,
            child: image,
          ),
        ),
      ),
    );
  }
}

class DraggableButton extends StatelessWidget {
  const DraggableButton({
    Key? key,
    this.color = Colors.green,
    required this.iconSrc,
    required this.text,
  }) : super(key: key);

  final String iconSrc;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    Image icon = Image.asset(iconSrc);
    final GlobalKey draggableKey = GlobalKey();

    return Draggable<String>(
      data: text,
      feedback: DraggingItem(
        dragKey: draggableKey,
        image: icon,
      ),
      child: SizedBox(
        width: 80,
        height: 100,
        child: Material(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          shadowColor: Colors.grey,
          elevation: 2,
          color: color,
          child: InkWell(
            onTap: () {},
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon, // <-- Icon
                Text(text), // <-- Text
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class CardStateBar extends StatefulWidget {
  final FeedItem feedItem;
  final dynamic deletionCallback;
  CardStateBar({required this.feedItem, this.deletionCallback});

  @override
  State<CardStateBar> createState() => _CardStateBarState();
}

class _CardStateBarState extends State<CardStateBar> {
  Widget getSourceWidget(String text) {
    text = text.trim();
    if (Uri.parse(text).isAbsolute) {
      return InkWell(
          onTap: () => launchUrlString(text),
          child: Text(
            text.length > 30 ? '${text.substring(0, 30)}...' : text,
            style: TextStyle(
              decoration: TextDecoration.underline,
            ),
          ));
    } else {
      return Text(text.length > 40 ? '${text.substring(0, 40)}...' : text);
    }
  }

  // GlobalKey<CommentsPreviewState> _commentsPreview = GlobalKey();

  // void loadCommentScreen() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //         builder: (context) => CommentsScreen(postId: widget.feedItem.id)),
  //   ).then((value) {
  //     // _commentsPreview.currentState?.loadComments();
  //     setState(() {});
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    Icon favIcon;
    User? user = FirebaseAuth.instance.currentUser;

    if (widget.feedItem.liked) {
      favIcon = Icon(
        Icons.favorite,
        color: Colors.redAccent,
      );
    } else {
      favIcon = Icon(Icons.favorite_border);
    }

    // CommentsPreview preview = CommentsPreview(
    //   key: _commentsPreview,
    //   postId: widget.feedItem.id,
    // );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              // like button
              onPressed: () {
                String? uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) {
                  return;
                }
                if (widget.feedItem.liked) {
                  // remove like
                  DatabaseUtils.delete(
                      'feed-liked-by/$uid/${widget.feedItem.id}');
                  if (widget.feedItem.numLikes > 0) {
                    DatabaseUtils.increment(
                        'feed/${widget.feedItem.id}/likes', -1);
                    widget.feedItem.numLikes -= 1;
                  }
                  DatabaseUtils.writeLog('Unlike', 'Unlike');
                } else {
                  // add like
                  DatabaseUtils.write(
                      'feed-liked-by/$uid/${widget.feedItem.id}', true);
                  DatabaseUtils.increment(
                      'feed/${widget.feedItem.id}/likes', 1);
                  DatabaseUtils.writeLog('Like', 'Like');
                  widget.feedItem.numLikes += 1;
                }
                if (mounted) {
                  setState(() {
                    widget.feedItem.liked = !widget.feedItem.liked;
                  });
                }
              },
              icon: favIcon,
              padding: EdgeInsets.zero,
            ),
            Text(
              widget.feedItem.numLikes > 0
                  ? widget.feedItem.numLikes.toString()
                  : '',
            ),
            const SizedBox(
              width: 8,
            ),
            CommentButton(
              postId: widget.feedItem.id,
            ),
            const SizedBox(
              width: 8,
            ),
            // delete button
            if (user != null && user.uid == widget.feedItem.authorId)
              IconButton(
                icon: Icon(Icons.delete_outline),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        // delete post button
                        return AlertDialog(
                          content: Text('Delete this post?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                if (widget.feedItem.id.isNotEmpty) {
                                  if (widget.feedItem.isQuiz) {
                                    DatabaseUtils.increment(
                                        '/server-stat/totalQuizes', -1);
                                  }
                                  DatabaseUtils.delete(
                                      '/feed/${widget.feedItem.id}');
                                }
                                widget.deletionCallback();
                                Navigator.pop(context);
                              },
                              child: Text('Delete'),
                            ),
                          ],
                        );
                      });
                },
              ),
          ],
        ),
        // source string
        if (!widget.feedItem.isQuiz)
          Row(
            children: [
              Text(
                // source
                'Source: ',
              ),
              getSourceWidget(widget.feedItem.source),
            ],
          ),
        // comments
        // preview,
      ],
    );
  }
}
