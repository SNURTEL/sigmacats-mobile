import 'package:flutter/material.dart';
import 'CustomColorScheme.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Alleycat: Liga',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 50.0, fontWeight: FontWeight.bold, color: CustomColorScheme.onPrimaryContainer),
            ),
            SizedBox(height: 100.0),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomColorScheme.primaryColor, // Set the button color to red using hex value
                fixedSize: Size(double.infinity, 50.0), // Set the height to 50.0
              ),
              child: Text(
                  'Zaloguj się',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 20.0),
            Text(
              'LUB',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: CustomColorScheme.onPrimaryContainer),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomColorScheme.primaryColor, // Set the button color to red using hex value
                fixedSize: Size(double.infinity, 50.0), // Set the height to 50.0
              ),
              child: Text(
                  'Zarejestruj się',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      backgroundColor: CustomColorScheme.primaryContainer,
    );
  }
}