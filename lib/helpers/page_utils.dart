import 'package:flutter/cupertino.dart';
import 'database_utils.dart';

class PageUtils {
  static double aspectRatioThreshold = 0.6;
  static int loggerIntervalSeconds = 5;

  static Widget build(BuildContext context, Widget target) {
    return MediaQuery.of(context).size.width /
                MediaQuery.of(context).size.height <
            aspectRatioThreshold
        ? target
        : Center(
            child: AspectRatio(
            aspectRatio: aspectRatioThreshold,
            child: target,
          ));
  }

  static void logPageViewTime(String pageName) {
    DatabaseUtils.writeLog('OnViewing', pageName);
  }
}
