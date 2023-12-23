import 'package:flutter/material.dart';
import 'CustomColorScheme.dart';
import 'HomePage.dart';
import 'LoginPage.dart';
import 'RegistrationPage.dart';
import 'RaceList.dart';
import 'Ranking.dart';
import 'RaceParticipation.dart';
import 'UserProfile.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
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
          case '/register':
            builder = (context) => const RegistrationPage();
            break;
          case '/race_list':
            builder = (context) => RaceList();
            break;
          case '/ranking':
            builder = (context) => Ranking();
            break;
          case '/race_participation':
            builder = (context) => RaceParticipation();
            break;
          case '/user_profile':
            builder = (context) => UserProfile();
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
