// lib/pages/auth/registration_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/auth_models.dart';
import '../../services/api_service.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController(); // Для Tenant
  final _passportNumberController = TextEditingController();
  String? _errorMessage;

  Future<void> _register() async {
    setState(() {
      _errorMessage = null;
    });
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final registerRequest = RegisterRequest(
          fullName: _fullNameController.text,
          email: _emailController.text,
          phoneNumber: _phoneNumberController.text,
          password: _passwordController.text,
          registrationAddress: _addressController.text,
          passportNumber: _passportNumberController.text);
      await apiService.registerTenant(registerRequest);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Регистрация успешна! Войдите в систему.')),
      );
      Navigator.of(context).pop(); // Вернуться на страницу входа
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Полное имя')),
              const SizedBox(height: 10),
              TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              TextField(
                  controller: _phoneNumberController,
                  decoration:
                      const InputDecoration(labelText: 'Номер телефона'),
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Пароль'),
                  obscureText: true),
              const SizedBox(height: 10),
              TextField(
                  controller: _addressController,
                  decoration:
                      const InputDecoration(labelText: 'Адрес регистрации')),
              TextField(
                  controller: _passportNumberController,
                  decoration: const InputDecoration(
                      labelText: 'Номер и серия паспорта')),
              const SizedBox(height: 10),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                child: const Text('Зарегистрироваться'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
