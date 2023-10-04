import 'package:flutter/material.dart';
import 'package:waste_genie/modules/leaderboard.dart';
import 'package:waste_genie/helpers/globals.dart' as globals;

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    globals.currPageName = 'Help';

    return Padding(
      padding: EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to complete a quiz',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Image(image: AssetImage('images/help-playquiz.png')),
            SizedBox(height: 4),
            Divider(),
            SizedBox(height: 4),
            Text(
              'How to create a new post',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Image(image: AssetImage('images/help-newpost.png')),
            SizedBox(height: 4),
            Divider(),
            SizedBox(height: 4),
            Text(
              'How to create a new quiz',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Image(image: AssetImage('images/help-newquiz.png')),
            SizedBox(height: 4),
            Divider(),
            SizedBox(height: 4),
            Text(
              'About carbon credits',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            CarbonCreditsDesc(),
          ],
        ),
      ),
    );
  }
}
