import 'package:waste_genie/modules/about.dart';
import 'package:waste_genie/modules/help.dart';
import 'package:waste_genie/modules/leaderboard.dart';
import 'package:waste_genie/modules/scanner.dart';
import 'package:waste_genie/modules/search.dart';
import 'package:waste_genie/modules/settings.dart';
import 'package:flutter/material.dart';
import 'modules/feed.dart';

const String eraTitle = 'Waste Genie';
const int feedPage = 0;
const int searchPage = 1;
const int settingsPage = 2;
const int helpPage = 3;
const int aboutPage = 4;
const int scannerPage = 5;
const int leaderBoard = 6;

class EraHomePage extends StatefulWidget {
  @override
  State<EraHomePage> createState() => _EraHomePageState();
}

class _EraHomePageState extends State<EraHomePage> {
  var selectedIndex = 0;
  var pageTitle = 'Waste Genie';

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case feedPage:
        page = FeedPage();
        break;
      case scannerPage:
        page = ScannerPage();
        break;
      case searchPage:
        page = SearchWastes();
        break;
      case settingsPage:
        page = SettingsPage();
        break;
      case helpPage:
        page = HelpPage();
        break;
      case aboutPage:
        page = AboutPage();
        break;
      case leaderBoard:
        page = LeaderBoard();
        break;
      default:
        throw UnimplementedError('no widget for menu index $selectedIndex');
    }

    return Scaffold(
      appBar: AppBar(title: Text(pageTitle)),
      body: page,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(eraTitle),
              accountEmail: Text(''),
              currentAccountPicture:
                  const Image(image: AssetImage('images/recycle_icon.png')),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                setState(() {
                  selectedIndex = feedPage;
                });
                pageTitle = 'Waste Genie';
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.view_in_ar_outlined),
              title: const Text('Scanner'),
              onTap: () {
                setState(() {
                  selectedIndex = scannerPage;
                });
                pageTitle = 'Waste Scanner';
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.search_outlined),
              title: const Text('Search'),
              onTap: () {
                setState(() {
                  selectedIndex = searchPage;
                });
                pageTitle = 'Search Wastes';
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.leaderboard_outlined),
              title: const Text('Leaderboard'),
              onTap: () {
                setState(() {
                  selectedIndex = leaderBoard;
                });
                pageTitle = 'Leaderboard';
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                setState(() {
                  selectedIndex = settingsPage;
                });
                pageTitle = 'Settings';
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.help_center_outlined),
              title: const Text('Help'),
              onTap: () {
                setState(() {
                  selectedIndex = helpPage;
                });
                pageTitle = 'Help';
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                setState(() {
                  selectedIndex = aboutPage;
                });
                pageTitle = 'About';
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
