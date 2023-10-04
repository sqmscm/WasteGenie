import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DatabaseUtils {
  static final ref = FirebaseDatabase.instance.ref();

  static Future<String> getString(String path) async {
    final snapshot = await ref.child(path).get();
    if (snapshot.exists) {
      return snapshot.value.toString();
    }
    return '';
  }

  static Future<dynamic> getData(String path, String orderBy) async {
    final snapshot = orderBy.isEmpty
        ? await ref.child(path).get()
        : await ref.child(path).orderByChild(orderBy).get();
    if (snapshot.exists) {
      return snapshot.value as dynamic;
    }
    return <String, dynamic>{};
  }

  static Future<dynamic> getPagedData(
      String path, String orderBy, int endTime, int limit) async {
    final snapshot = await ref
        .child(path)
        .orderByChild(orderBy)
        .endBefore(endTime)
        .limitToLast(limit)
        .get();
    if (snapshot.exists) {
      return snapshot.value as dynamic;
    }
    return <String, dynamic>{};
  }

  static write(String path, dynamic data) async {
    await ref.child(path).set(data);
  }

  static increment(String path, num delta) async {
    await ref.child(path).set(ServerValue.increment(delta));
  }

  static delete(String path) async {
    await ref.child(path).remove();
  }

  static Future<String?> writeWithKey(String path, dynamic data) async {
    final postKey = ref.child(path).push().key;
    await write('$path/$postKey', data);
    return postKey;
  }

  static Future<String?> uploadImage(String base64str) async {
    final postKey = ref.child('img-storage').push().key;
    await write('img-storage/$postKey', base64str);
    return postKey;
  }

  static void writeLog(String name, String desc) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    String uid = user.uid;
    final postKey = ref.child('activities').push().key;
    write('activities/$postKey', {
      'activityName': name,
      'activityDesc': desc,
      'timestamp': ServerValue.timestamp,
      'userId': uid,
    });
  }
}
