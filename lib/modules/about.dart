import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:waste_genie/helpers/globals.dart' as globals;

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final url =
      'https://webpages.scu.edu/ftp/ihsiao/Research/EdTechWasteMgt.html';

  String buildVer = '';
  String appName = '';
  String packageName = '';
  String buildNumber = '';

  @override
  void initState() {
    super.initState();
    globals.currPageName = 'About';
  }

  void initPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        packageName = packageInfo.packageName;
        appName = packageInfo.appName;
        buildVer = packageInfo.version;
        buildNumber = packageInfo.buildNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    initPackageInfo();

    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Waste Genie is a web-based application that ensembles a suite of AI, AR & Social technologies that we\'ve researched above. It provides users the most updated waste management content and support. Waste Genie is designed to be THE go-to place and tool to get well-informed for sustainability resources, eco-tips, waste sorting feedback, etc. to adapt to our forever-growing-complex and sacred environment.',
              style: TextStyle(fontSize: 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
                onTap: () => launchUrlString(url),
                child: Text(
                  "Learn More",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontSize: 15,
                  ),
                )),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Build v$buildVer+$buildNumber',
              style: TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
