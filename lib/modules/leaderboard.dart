import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:waste_genie/helpers/database_utils.dart';
import 'package:waste_genie/helpers/globals.dart' as globals;

class LeaderBoard extends StatefulWidget {
  const LeaderBoard({Key? key}) : super(key: key);

  @override
  State<LeaderBoard> createState() => _LeaderBoardState();
}

class _LeaderBoardState extends State<LeaderBoard> {
  bool loading = true;
  double myCredits = 0.0;
  String myRank = 'nth';
  final _rankMap = {1: 'st', 2: 'nd', 3: 'rd'};
  late Map<String, dynamic> profiles;
  late List<Map<String, dynamic>> ranks;
  User? user = FirebaseAuth.instance.currentUser;

  void loadLeaderboard() async {
    loading = true;

    profiles = Map<String, dynamic>.from(
        await DatabaseUtils.getData('user-public-profile', 'carbon-credits'));
    ranks = [];

    for (String uid in profiles.keys) {
      Map<String, dynamic> currUser = profiles[uid];
      currUser['uid'] = uid;
      if (currUser.containsKey('carbon-credits')) {
        ranks.add(currUser);
        if (user != null && user!.uid == uid) {
          myCredits = currUser['carbon-credits'];
        }
      }
    }
    ranks
        .sort((a, b) => ((b['carbon-credits']).compareTo(a['carbon-credits'])));

    int currRank = 0;
    for (var i = 0; i < ranks.length; i++) {
      if (i == 0 ||
          ranks[i]['carbon-credits'] != ranks[i - 1]['carbon-credits']) {
        currRank = i + 1;
      }

      if (user != null && ranks[i]['uid'] == user!.uid) {
        myRank = "$currRank${_rankMap[currRank] ?? 'th'}";
        break;
      }
    }

    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    loadLeaderboard();
    globals.currPageName = 'Leaderboard';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(8),
        child: CircularProgressIndicator(),
      ));
    }

    return Column(
      children: [
        if (ranks.isNotEmpty)
          ListTile(
            title: Text(
              'Rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            trailing: Text(
              'Carbon Credits',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
          ),
        if (ranks.isNotEmpty)
          Expanded(
            child: ListView.builder(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemCount: ranks.length,
                itemBuilder: (context, index) {
                  Map curr = ranks[index];
                  String rank = (index > 0 &&
                          curr['carbon-credits'] ==
                              ranks[index - 1]['carbon-credits'])
                      ? '-'
                      : '#${index + 1}';

                  if (user != null && user!.uid == curr['uid']) {
                    return ListTile(
                      leading: Text(
                        rank,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      tileColor: Color.fromARGB(255, 186, 227, 247),
                      title: Text(
                        '${curr['displayName']}',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Text(
                        (curr['carbon-credits'] ?? 0.0).toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  return ListTile(
                    leading: Text(
                      rank,
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    title: Text(
                      '${curr['displayName']}',
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    trailing: Text(
                      (curr['carbon-credits'] ?? 0.0).toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                  );
                }),
          ),
        Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: CarbonVisualizer(
            myCredits: myCredits,
            myRank: myRank,
          ),
        )
      ],
    );
  }
}

class CarbonVisualizer extends StatelessWidget {
  const CarbonVisualizer({
    super.key,
    required this.myCredits,
    required this.myRank,
  });

  final double myCredits;
  final String myRank;

  @override
  Widget build(BuildContext context) {
    if (myCredits == 0) {
      return Text(
        'Complete a quiz to join the leaderboard!',
        style: TextStyle(
          fontSize: 16.0,
        ),
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                  children: [
                    TextSpan(
                      text: 'You have earned ',
                    ),
                    TextSpan(
                      text: myCredits.toStringAsFixed(2),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    TextSpan(
                      text: ' carbon credits',
                      style: TextStyle(
                        color: Colors.green,
                      ),
                    ),
                    TextSpan(
                      text: ' (ranked $myRank)',
                    ),
                    TextSpan(
                      text: ', which is equal to',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 16,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Icon(
                  Icons.forest_outlined,
                  color: Colors.greenAccent,
                ),
                Text(
                  '${(myCredits / 30.7).toStringAsFixed(2)} tree-days',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                Text(
                  'carbon sequestration',
                  style: TextStyle(
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  color: Colors.orangeAccent,
                ),
                Text(
                  '${(myCredits / 108.5).toStringAsFixed(2)} miles',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                Text(
                  'in a passenger car',
                  style: TextStyle(
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(
          height: 16,
        ),
        InkWell(
            onTap: () => showDialog(
                context: context,
                builder: (context) {
                  globals.currPageName = 'AboutCarbonCredits';
                  DatabaseUtils.writeLog(
                      'AboutCarbonCredits', 'Click on how is it calculated');

                  return AlertDialog(
                    title: Text('About carbon credits'),
                    content: SingleChildScrollView(
                      child: CarbonCreditsDesc(),
                    ),
                    actions: [
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
                }).then((value) => globals.currPageName = 'Leaderboard'),
            child: Text(
              "How is it calculated?",
              style: TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
                fontSize: 15,
              ),
            )),
      ],
    );
  }
}

class CarbonCreditsDesc extends StatelessWidget {
  const CarbonCreditsDesc({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14.0,
            ),
            children: [
              TextSpan(
                text: "Carbon credits",
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: ":\n• Based on EPA's data on the amount of "
                    "Green Gas Benefits generated from recycling, "
                    "composting, and landfilling;\n• Estimates "
                    "how much greenhouse gas can be reduced if we process "
                    "the garbage appropriately;\n• The unit of the credits used "
                    "in Waste Genie is gCO2E (grams of carbon dioxide equivalent).",
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14.0,
            ),
            children: [
              WidgetSpan(
                child: Icon(
                  Icons.forest_outlined,
                  color: Colors.greenAccent,
                  size: 18.0,
                ),
              ),
              TextSpan(
                text: " Tree-days",
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text:
                    " estimates the number of days on average a mature tree needs"
                    " to absorb a given quantity of carbon dioxide.",
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14.0,
            ),
            children: [
              WidgetSpan(
                child: Icon(
                  Icons.directions_car_outlined,
                  color: Colors.orangeAccent,
                  size: 18.0,
                ),
              ),
              TextSpan(
                text: " Driving distance",
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: " is an estimation of the distance travelled by car"
                    " to emit the given amount of carbon dioxide.",
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        Divider(),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 10.0,
            ),
            children: [
              TextSpan(
                text: "More details can be found in EPA's ",
              ),
              TextSpan(
                text: "Facts and Figures about Materials, Waste and Recycling",
                style: TextStyle(
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => launchUrlString(
                      "https://www.epa.gov/facts-and-figures-about-materials-waste-and-recycling/national-overview-facts-and-figures-materials"),
              ),
              TextSpan(
                text:
                    ". The algorithm used to calculate the estimations can be "
                    "found in the paper: ",
              ),
              TextSpan(
                text:
                    "Green Algorithms: Quantifying the Carbon Footprint of Computation.",
                style: TextStyle(
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => launchUrlString(
                      "https://onlinelibrary.wiley.com/doi/10.1002/advs.202100707"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
