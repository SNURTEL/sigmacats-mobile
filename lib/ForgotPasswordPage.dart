import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {

  final TextEditingController _emailController = TextEditingController();

  Future<void> _sendEmail(BuildContext context) async {
    String email = _emailController.text;
    final apiUrl = Uri.parse('http://10.0.2.2:8000/api/auth/forgot-password');

    try {
      final response = await http.post(apiUrl, body: {'email': email});

      if (response.statusCode == 202) {
        showNotification(context, "Wysłano wiadomość! Sprawdź skrzynkę.");
      } else {
        showNotification(context, 'Niepoprawny adres email.');
      }
    } catch (e) {
      // Handle any exceptions or network errors
      showNotification(context, 'Wystąpił błąd.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resetowanie hasła'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Wprowadź adres email powiązany z kontem - wyślemy do Ciebie wiadomość z linkiem\ndo zresetowania hasła.",
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            SizedBox(
              height: 70.0,
              child: TextFormField(
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return "Adres email nie może być pusty.";
                  }
                  if (!RegExp(r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
                      .hasMatch(v)) {
                    return "Niepoprawny adres email.";
                  }
                  return null;
                },
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Adres e-mail',
                  enabledBorder: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            FilledButton(
              onPressed: () {
                _sendEmail(context);
              },
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(double.infinity, 50.0),
              ),
              child: const Text(
                'Wyślij wiadomość',
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
