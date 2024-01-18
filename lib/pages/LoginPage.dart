import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:sigmactas_alleycat/util/settings.dart' as settings;
import 'package:sigmactas_alleycat/util/notification.dart';

class LoginPage extends StatefulWidget {
  ///  Login page widget
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  ///  Login page widget state
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;

  Future<void> _handleLogin(BuildContext context) async {
    ///    Handles logging in, returns response in form of a message
    if (_formKey.currentState?.validate() ?? false) {
      String username = _usernameController.text;
      String password = _passwordController.text;
      final apiUrl = Uri.parse('${settings.apiBaseUrl}/api/auth/jwt/login');

      try {
        final response = await http.post(apiUrl, body: {'username': username, 'password': password});

        if (response.statusCode == 200) {
          Map<String, dynamic> responseData = json.decode(response.body);
          String accessToken = responseData['access_token'];
          Navigator.pushReplacementNamed(context, '/race_list', arguments: accessToken);
        } else if (response.statusCode == 400) {
          showSnackbarMessage(context, 'Niepoprawny adres email bądź hasło.');
        } else {
          showSnackbarMessage(context, 'Błąd logowania.');
        }
      } catch (e) {
        print(e);
        showSnackbarMessage(context, 'Wystąpił błąd.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ///    Builds the login page
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logowanie'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Adres email nie może być pusty.";
                    }
                    if (!RegExp(
                            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
                        .hasMatch(value)) {
                      return "Niepoprawny adres email.";
                    }
                    return null;
                  },
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Adres e-mail',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              Flexible(
                child: TextFormField(
                  obscureText: !_showPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Hasło nie może być puste.";
                    }
                    return null;
                  },
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Hasło',
                    border: const OutlineInputBorder(),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: IconButton(
                        icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              FilledButton(
                onPressed: () {
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
              const SizedBox(height: 10.0),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/reset_password');
                },
                child: const Text("Nie pamiętam hasła"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
