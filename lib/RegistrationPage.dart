import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  List<Map<String, String?>> genderOptions = [
    {'display': 'mężczyzna', 'value': 'male'},
    {'display': 'kobieta', 'value': 'female'},
    {'display': 'inna', 'value': null},
  ];
  String? selectedGenderOption = null;
  bool _showPassword = false;
  bool _showRepeatPassword = false;

  Future<void> registerUser(BuildContext context) async {
    Map data = {
      "email": _emailController.text,
      "password": _passwordController.text,
      "username": _usernameController.text,
      "name": _nameController.text,
      "surname": _surnameController.text,
      "gender": selectedGenderOption,
      "birth_date": 'todo',
    };
    var body = json.encode(data);
    final response = await http.post(
      Uri.parse('http://10.0.2.2:80/api/auth/register'),
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      showNotification(context, 'Udało się zarejestrować!');
    } else {
      showNotification(
          context, 'Błąd podczas rejestracji ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejestracja'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Imię nie może być puste.";
                    }
                    if (value.contains(new RegExp(r'[0-9!-/:-@\[-`\{-~]')) ||
                        value.contains(" ")) {
                      return "Niepoprawne imię.";
                    }
                    return null;
                  },
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Imię',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Nazwisko nie może być puste.";
                    }
                    if (value.contains(new RegExp(r'[0-9!-/:-@\[-`\{-~]')) ||
                        value.contains(" ")) {
                      return "Niepoprawne nazwisko.";
                    }
                    return null;
                  },
                  controller: _surnameController,
                  decoration: const InputDecoration(
                    labelText: 'Nazwisko',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Nazwa użytkownika nie może być pusta.";
                    }
                    if (value.contains(new RegExp(r'[!-/:-@\[-\^`\{-~]')) ||
                        value.contains(" ")) {
                      return "Niepoprawna nazwa użytkownika.";
                    }
                    return null;
                  },
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nazwa użytkownika',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20.0),
                DropdownButtonFormField<String>(
                  value: selectedGenderOption,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Płeć',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      selectedGenderOption = value!;
                    });
                  },
                  items: genderOptions.map<DropdownMenuItem<String>>(
                        (Map<String, String?> genderOption) {
                      return DropdownMenuItem<String>(
                        value: genderOption['value'],
                        child: Text('${genderOption['display']}'),
                      );
                    },
                  ).toList(),
                ),
                const SizedBox(height: 20.0),
                TextFormField(
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
                const SizedBox(height: 20.0),
                TextFormField(
                  obscureText: !_showPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Hasło nie może być puste.";
                    }
                    if (value.length < 8) {
                      return "Hasło musi zawierać co najmniej 8 znaków.";
                    }
                    if (value != _repeatPasswordController.text) {
                      return "Hasła muszą być takie same.";
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
                        icon: Icon(_showPassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  obscureText: !_showRepeatPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Hasło nie może być puste.";
                    }
                    if (value.length < 8) {
                      return "Hasło musi zawierać co najmniej 8 znaków.";
                    }
                    if (value != _passwordController.text) {
                      return "Hasła muszą być takie same.";
                    }
                    return null;
                  },
                  controller: _repeatPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Powtórz hasło',
                    border: const OutlineInputBorder(),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: IconButton(
                        icon: Icon(_showRepeatPassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _showRepeatPassword = !_showRepeatPassword;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                FilledButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      registerUser(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(double.infinity, 50.0),
                  ),
                  child: const Text(
                    'Zarejestruj się',
                    style:
                        TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
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
