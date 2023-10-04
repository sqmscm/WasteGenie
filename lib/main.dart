import 'dart:async';
import 'dart:html';

import 'package:waste_genie/helpers/database_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterfire_ui/auth.dart';
import 'helpers/page_utils.dart';
import 'helpers/globals.dart' as globals;
import 'firebase_options.dart';
import 'homepage.dart';

const String eraTitle = 'Waste Genie';
const String googleWebClientId =
    '394453041195-ji0cdvo6ek6fvleiae311ip09h5iee7q.apps.googleusercontent.com';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterFireUIAuth.configureProviders([
    const EmailProviderConfiguration(),
    const GoogleProviderConfiguration(clientId: googleWebClientId),
  ]);

  // init logger
  bool onFrontEnd = true;
  document.addEventListener("visibilitychange", (event) {
    if (document.visibilityState == "visible") {
      onFrontEnd = true;
    } else {
      onFrontEnd = false;
    }
  });
  Timer.periodic(Duration(seconds: PageUtils.loggerIntervalSeconds), (timer) {
    if (onFrontEnd) {
      PageUtils.logPageViewTime(globals.currPageName);
    }
  });

  runApp(EraApp());
}

class EraApp extends StatelessWidget {
  const EraApp({super.key});

  final double aspectRatioThreshold = 0.7;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EraState(),
      child: MaterialApp(
        title: eraTitle,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: Color.fromARGB(255, 184, 248, 218)),
        ),
        home: AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  void inspectPublicProfile(User? user) async {
    if (user == null) {
      return;
    }
    final uid = user.uid;
    final profile = Map<String, dynamic>.from(
        await DatabaseUtils.getData('user-public-profile/$uid', ''));
    if (profile.isEmpty || !profile.containsKey('displayName')) {
      String emailName = user.email!.split('@')[0];
      await DatabaseUtils.write('user-public-profile/$uid', {
        "providedName": user.displayName ?? 'Anonymous',
        "displayName": emailName
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageUtils.build(
        context,
        StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // User is not signed in
            if (!snapshot.hasData) {
              return SignInScreen(
                headerBuilder: (context, constraints, shrinkOffset) => Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Center(
                      child: Column(
                    children: [
                      const Image(image: AssetImage('images/recycle_icon.png')),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        'Waste Genie',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  )),
                ),
              );
            }

            // Render your application if authenticated
            inspectPublicProfile(snapshot.data);
            return EraHomePage();
          },
        ));
  }
}

class EraState extends ChangeNotifier {}
