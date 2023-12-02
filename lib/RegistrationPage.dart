import 'package:flutter/material.dart';
import 'RaceList.dart';
import 'CustomColorScheme.dart';

class RegistrationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rejestracja'),
        backgroundColor: CustomColorScheme.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Imię',
                  fillColor: Colors.white,
                  filled: true,
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: CustomColorScheme.primaryColor)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: CustomColorScheme.onPrimaryContainer)),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                ),
                cursorColor: CustomColorScheme.primaryColor,
              ),
              SizedBox(height: 20.0),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Nazwisko',
                  fillColor: Colors.white,
                  filled: true,
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: CustomColorScheme.primaryColor)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: CustomColorScheme.onPrimaryContainer)),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                ),
                cursorColor: CustomColorScheme.primaryColor,
              ),
              SizedBox(height: 20.0),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Płeć',
                  fillColor: Colors.white,
                  filled: true,
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: CustomColorScheme.primaryColor)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: CustomColorScheme.onPrimaryContainer)),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                ),
                items: ['Mężczyzna', 'Kobieta', 'Inna'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? value) {
                  // Handle the selected value
                },
              ),
              SizedBox(height: 20.0),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Data urodzenia',
                  fillColor: Colors.white,
                  filled: true,
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: CustomColorScheme.primaryColor)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: CustomColorScheme.onPrimaryContainer)),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                ),
                cursorColor: CustomColorScheme.primaryColor,
                onTap: () {
                  // Show date picker here
                },
              ),
              SizedBox(height: 20.0),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Typ roweru',
                  fillColor: Colors.white,
                  filled: true,
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: CustomColorScheme.primaryColor)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: CustomColorScheme.onPrimaryContainer)),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                ),
                items: ['Szosa', 'Ostre koło', 'Inny'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? value) {
                  // Handle the selected value
                },
              ),
              SizedBox(height: 20.0),
              TextField(
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
              SizedBox(height: 20.0),
              TextField(
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
              SizedBox(height: 20.0),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Powtórz hasło',
                  fillColor: Colors.white,
                  filled: true,
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: CustomColorScheme.primaryColor)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: CustomColorScheme.onPrimaryContainer)),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                ),
                cursorColor: CustomColorScheme.primaryColor,
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
                  backgroundColor: CustomColorScheme.primaryColor,
                  fixedSize: Size(double.infinity, 50.0),
                ),
                child: Text(
                  'Zarejestruj się',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: CustomColorScheme.primaryContainer,
    );
  }
}
