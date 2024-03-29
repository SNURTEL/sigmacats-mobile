import 'package:flutter/material.dart';

import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'theme/Color.dart';
import 'pages/HomePage.dart';
import 'pages/LoginPage.dart';
import 'pages/RaceTrackingPage.dart';
import 'pages/RegistrationPage.dart';
import 'pages/RaceListPage.dart';
import 'pages/RankingPage.dart';
import 'pages/RaceParticipationPage.dart';
import 'pages/UserProfilePage.dart';
import 'pages/ForgotPasswordPage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'util/settings.dart' as settings;

void main() async {
  ///  Runs the application
  await dotenv.load(fileName: ".env");
  settings.apiBaseUrl = dotenv.env["FLUTTER_FASTAPI_HOST"] ?? "http://10.0.2.2";
  settings.uploadBaseUrl =
      '${dotenv.env["FLUTTER_FASTAPI_HOST"] ?? "http://10.0.2.2"}:${dotenv.env["FLUTTER_FASTAPI_UPLOAD_PORT"] ?? 5050}${dotenv.env["FLUTTER_FASTAPI_UPLOAD_URL_PREFIX"] ?? "/api/race/"}';
  await initializeDateFormatting('pl_PL', null);
  runApp(const App());
}

class App extends StatefulWidget {
  ///  App class used to build the application, includes states
  const App({Key? key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  ///  Class used for setting the initial state of the application
  @override
  void initState() {
    super.initState();
    bg.BackgroundGeolocation.stop();
    bg.BackgroundGeolocation.removeListeners();
  }

  @override
  Widget build(BuildContext context) {
    ///    Builds the whole application
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('pl', 'PL'),
      ],
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
