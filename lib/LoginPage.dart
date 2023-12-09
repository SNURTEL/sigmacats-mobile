import 'package:flutter/material.dart';
import 'RaceList.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logowanie'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: 70.0,
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Adres email',
                  enabledBorder: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder()
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            const SizedBox(
              height: 70.0,
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Hasło',
                  enabledBorder: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder()
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RaceList(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(// Use the primary color from the color scheme
                fixedSize: const Size(double.infinity, 50.0),
              ),
              child: const Text(
                'Zaloguj się',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
