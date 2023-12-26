import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatelessWidget {
  LoginPage({Key? key});

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleLogin(BuildContext context) async {
    String username = _usernameController.text;
    String password = _passwordController.text;
    // API endpoint for login
    final apiUrl = Uri.parse('http://10.0.2.2:8000/api/auth/jwt/login');

    // Request body with username and password
    final body = {
      'grant_type': '',
      'username': username,
      'password': password,
      'scope': '',
      'client_id': '',
      'client_secret': '',
    };

    try {
      final response = await http.post(apiUrl, body: {'username': username, 'password': password});

      if (response.statusCode == 200) {
        // Successful login, navigate to the home page
        Map<String, dynamic> responseData = json.decode(response.body);
        String accessToken = responseData['access_token'];
        Navigator.pushReplacementNamed(context, '/race_list', arguments: accessToken);
      } else {
        // Unsuccessful login, show notification
        showNotification(context, 'Logowanie się nie powiodło');
      }
    } catch (e) {
      // Handle any exceptions or network errors
      showNotification(context, 'Wystąpił błąd: $e');
    }
  }

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
            SizedBox(
              height: 70.0,
              child: TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Adres e-mail',
                  enabledBorder: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 20.0),
            SizedBox(
              height: 70.0,
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Hasło',
                  enabledBorder: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                // Call the method to handle login
                _handleLogin(context);
              },
              style: ElevatedButton.styleFrom(
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

  void showNotification(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
