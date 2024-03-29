import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  ///  Home page widget
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    ///    Build the homepage
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Alleycat: Liga',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 50.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 100.0),
            FilledButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(double.infinity, 50.0),
              ),
              child: const Text('Zaloguj się', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20.0),
            const Text(
              'LUB',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20.0),
            FilledButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(double.infinity, 50.0),
              ),
              child: const Text('Zarejestruj się', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
