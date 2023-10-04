import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:waste_genie/helpers/globals.dart' as globals;
import '../helpers/database_utils.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String displayName = 'loading...';
  String completedQuizes = 'loading...';
  String totalQuizes = 'loading...';
  String likesReceived = 'loading...';
  String postsCreated = 'loading...';
  String quizCreated = 'loading...';
  String carbonCredits = 'loading...';
  bool loaded = false;

  User? user = FirebaseAuth.instance.currentUser;
  final nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    globals.currPageName = 'Settings';
  }

  void loadProfile() async {
    if (loaded) return;
    loaded = true;

    // update display name

    final profile = Map<String, dynamic>.from(
        await DatabaseUtils.getData('user-public-profile/${user!.uid}', ''));

    if (mounted) {
      setState(() {
        displayName = profile['displayName'];
        carbonCredits = (profile['carbon-credits'] ?? 0.0).toStringAsFixed(2);
      });
    }

    // update total number of available quizes

    final totalQuizesNumber =
        await DatabaseUtils.getString('/server-stat/totalQuizes');

    if (mounted) {
      setState(() {
        totalQuizes = totalQuizesNumber;
      });
    }

    // update number of likes, posts, and quizes of the user

    int likes = 0;
    int posts = 0;
    int quizes = 0;

    if (profile.containsKey('posts')) {
      final postList = Map<String, dynamic>.from(profile['posts']);
      for (var postKey in postList.keys) {
        String t = await DatabaseUtils.getString('feed/$postKey/likes');
        String quizFlag = await DatabaseUtils.getString('feed/$postKey/isQuiz');
        if (t.isNotEmpty) {
          likes += int.tryParse(t) ?? 0;
        }
        if (quizFlag == 'true') {
          quizes += 1;
        } else if (quizFlag == 'false') {
          posts += 1;
        }
      }
    }

    if (mounted) {
      setState(() {
        likesReceived = likes.toString();
        postsCreated = posts.toString();
        quizCreated = quizes.toString();
      });
    }

    // update number of quizes completed by the user

    final completedQuizesList = Map<String, dynamic>.from(
        await DatabaseUtils.getData('quiz-completed-by/${user!.uid}', ''));

    int completed = 0;
    for (String quiz in completedQuizesList.keys) {
      if ((await DatabaseUtils.getString('feed/$quiz/isQuiz')).isNotEmpty) {
        completed += 1;
      }
    }

    if (mounted) {
      setState(() {
        completedQuizes = completed.toString();
      });
    }
  }

  void showMsg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      duration: Duration(seconds: 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Text('Please login.');
    }

    loadProfile();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Display name: $displayName',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: IconButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          // delete post button
                          return AlertDialog(
                            content: TextField(
                              style: TextStyle(fontSize: 15),
                              controller: nameController,
                              decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Change display name',
                                  contentPadding: EdgeInsets.all(8)),
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  var newName = nameController.text.trim();
                                  if (newName.isEmpty || newName.length > 25) {
                                    showMsg(
                                        'Display name should be in 1-25 characters.');
                                    return;
                                  }
                                  DatabaseUtils.write(
                                      'user-public-profile/${user!.uid}/displayName',
                                      newName);
                                  setState(() {
                                    displayName = newName;
                                  });
                                  Navigator.pop(context);
                                },
                                child: Text('OK'),
                              ),
                            ],
                          );
                        });
                  },
                  icon: Icon(Icons.edit_outlined),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Email: ${user!.email}',
              style: TextStyle(fontSize: 15),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Your Waste Genie analytics:',
              style: TextStyle(fontSize: 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Posts created: $postsCreated',
              style: TextStyle(fontSize: 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Quizes created: $quizCreated',
              style: TextStyle(fontSize: 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Completed quizes: $completedQuizes/$totalQuizes',
              style: TextStyle(fontSize: 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Carbon Credits: $carbonCredits',
              style: TextStyle(fontSize: 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Likes received: $likesReceived',
              style: TextStyle(fontSize: 15),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
              },
              child: const Text('Log out'),
            ),
          ),
        ],
      ),
    );
  }
}
