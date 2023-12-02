import 'package:flutter/material.dart';
import 'RaceList.dart';
import 'CustomColorScheme.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logowanie'),
        backgroundColor: CustomColorScheme.primaryColor, // Set app bar color to primary color
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 70.0,
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Adres email',
                  fillColor: Colors.white,
                  filled: true,
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: CustomColorScheme.primaryColor)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: CustomColorScheme.onPrimaryContainer)),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                ),
                cursorColor: CustomColorScheme.primaryColor,
              ),
            ),
            SizedBox(height: 20.0),
            Container(
              height: 70.0,
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Hasło',
                  fillColor: Colors.white,
                  filled: true,
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: CustomColorScheme.primaryColor)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: CustomColorScheme.onPrimaryContainer)),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                ),
                cursorColor: CustomColorScheme.primaryColor,
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RaceList(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomColorScheme.primaryColor, // Use the primary color from the color scheme
                fixedSize: Size(double.infinity, 50.0),
              ),
              child: Text(
                'Zaloguj się',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: CustomColorScheme.primaryContainer,
    );
  }
}
