import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:sigmactas_alleycat/util/notification.dart';
import 'package:sigmactas_alleycat/util/settings.dart' as settings;

class ForgotPasswordPage extends StatefulWidget {
  ///  Page for resetting account password
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  ///  Forgot password page state
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  Future<void> _sendEmail(BuildContext context) async {
    ///    Make a reset-password request to backend, which should result in sending an email
    if (_formKey.currentState?.validate() ?? false) {
      String email = _emailController.text;
      final apiUrl = Uri.parse('${settings.apiBaseUrl}/api/auth/forgot-password');

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
  }

  @override
  Widget build(BuildContext context) {
    ///    Builds the reset password page
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resetowanie hasła'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Wprowadź adres email powiązany z kontem - wyślemy do Ciebie wiadomość z linkiem\ndo zresetowania hasła.",
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30.0),
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
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Adres e-mail',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 30.0),
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
      ),
    );
  }
}
