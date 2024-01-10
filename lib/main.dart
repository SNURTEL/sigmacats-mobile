import 'package:flutter/material.dart';

import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:provider/provider.dart';

import 'CustomColorScheme.dart';
import 'HomePage.dart';
import 'LocationPage.dart';
import 'LoginPage.dart';
import 'RegistrationPage.dart';
import 'RaceList.dart';
import 'Ranking.dart';
import 'RaceParticipation.dart';
import 'UserProfile.dart';
import 'ForgotPasswordPage.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const App(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeData themeLight = ThemeData(useMaterial3: true, colorScheme: lightColorScheme);
  ThemeData themeDark = ThemeData(useMaterial3: true, colorScheme: darkColorScheme);
  ThemeData _themeData = ThemeData(useMaterial3: true, colorScheme: lightColorScheme);

  ThemeData get themeData => _themeData;

  void toggleTheme() {
    _themeData = _themeData == themeLight ? themeDark : themeLight;
    notifyListeners();
  }
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      theme: themeProvider.themeData,
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        WidgetBuilder builder;
        switch (settings.name) {
          case '/':
            builder = (context) => const HomePage();
            break;
          case '/login':
            builder = (context) => const LoginPage();
            break;
          case '/reset_password':
            builder = (context) => const ForgotPasswordPage();
            break;
          case '/register':
            builder = (context) => const RegistrationPage();
            break;
          case '/race_list':
            final String accessToken = settings.arguments as String;
            builder = (context) => RaceList(accessToken: accessToken);
            break;
          case '/ranking':
            final String accessToken = settings.arguments as String;
            builder = (context) => Ranking(accessToken: accessToken);
            break;
          case '/race_participation':
            final String accessToken = settings.arguments as String;
            builder = (context) => RaceParticipation(accessToken: accessToken);
            break;
          case '/user_profile':
            final String accessToken = settings.arguments as String;
            builder = (context) => UserProfile(accessToken: accessToken);
            break;
          case '/location':
          // final String accessToken = settings.arguments as String;
          // builder = (context) => LocationPage(accessToken: accessToken);;
            builder = (context) => LocationPage();
            break;
          default:
            throw Exception('Invalid route: ${settings.name}');
        }

        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeInOut;
            var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
            var fadeAnimation = animation.drive(fadeTween);
            return FadeTransition(opacity: fadeAnimation, child: child);
          },
        );
      },
    );
  }
}
