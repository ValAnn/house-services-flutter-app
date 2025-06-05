// lib/pages/add_request_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/request_model.dart';
import '../services/api_service.dart';

import 'package:file_picker/file_picker.dart';
import 'dart:convert';

class AddRequestPage extends StatefulWidget {
  const AddRequestPage({super.key});

  @override
  State<AddRequestPage> createState() => _AddRequestPageState();
}

class _AddRequestPageState extends State<AddRequestPage> {
  final _descriptionController = TextEditingController();
  String? _errorMessage;
  String? _base64Photo; // Для Base64

  Future<void> _addRequest() async {
    setState(() {
      _errorMessage = null;
    });

    if (ApiService.id == null) {
      setState(() {
        _errorMessage =
            'Ошибка: ID пользователя не найден. Пожалуйста, войдите снова.';
      });
      return;
    }

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final newRequest = RequestDto(
        description: _descriptionController.text,
        tenantId:
            ApiService.id!, // Используем ID текущего пользователя как tenantId
        photoData: _base64Photo, // Включите, если реализуете загрузку фото
      );
      await apiService.createRequest(newRequest);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заявка успешно добавлена!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pickAndEncodePhoto() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _base64Photo = base64Encode(result.files.single.bytes!);
        print('Photo selected and encoded!');
      });
    } else {
      // User canceled the picker or no file selected
      setState(() {
        _base64Photo = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить заявку')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание заявки',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickAndEncodePhoto,
                child: Text(_base64Photo != null
                    ? 'Фото выбрано'
                    : 'Выбрать фото (опционально)'),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                onPressed: _addRequest,
                child: const Text('Создать заявку'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
