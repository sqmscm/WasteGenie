import 'package:flutter/material.dart';

class FeedItem {
  final String id;
  final String source;
  final String imageId;
  final String imageSrc;
  final String authorId;
  final String authorName;
  final int timestamp;
  final bool isQuiz;
  final List objectPositions;
  final List objectStats;
  final double imageWidth;
  double imageScale;
  int completeAttempts;
  int numLikes;
  bool liked;
  bool deleted;
  Card? layout;

  FeedItem({
    this.id = '',
    this.source = '',
    this.imageSrc = '',
    this.imageId = '',
    this.authorName = '',
    this.authorId = '',
    this.timestamp = 0,
    this.liked = false,
    this.numLikes = 0,
    this.isQuiz = false,
    this.imageScale = 1.0,
    this.imageWidth = -1.0,
    this.deleted = false,
    this.completeAttempts = 0,
    this.layout,
    this.objectPositions = const [],
    this.objectStats = const [],
  });
}
