// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:house_services_flutter/pages/request_details_page.dart';
import 'package:provider/provider.dart';
import '../models/request_model.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<RequestDto>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    setState(() {
      _requestsFuture =
          Provider.of<ApiService>(context, listen: false).getRequests();
    });
  }

  void _logout() async {
    await ApiService.clearAuthData();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  String _getPageTitle() {
    final role = ApiService.userRole;
    if (role == 'TENANT') {
      return 'Мои заявки';
    } else if (role == 'OPERATOR') {
      return 'Новые заявки';
    } else if (role == 'REPAIR_TEAM') {
      return 'Заявки для бригады';
    }
    return 'Заявки';
  }

  @override
  Widget build(BuildContext context) {
    final userRole = ApiService.userRole;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle()),
        actions: [
          if (userRole == 'TENANT')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.of(context).pushNamed('/add-request');
                _loadRequests(); // Обновить список после добавления
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<List<RequestDto>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Нет доступных заявок.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final request = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title:
                        Text('Заявка #${request.id}: ${request.description}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Статус: ${request.status}'),
                        if (request.creatingDate != null)
                          Text(
                              'Создана: ${request.formatDateTime(request.creatingDate)}'),
                        if (request.progressDate != null)
                          Text(
                              'В работе: ${request.formatDateTime(request.progressDate)}'),
                        if (request.closeDate != null)
                          Text(
                              'Закрыта: ${request.formatDateTime(request.closeDate)}'),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  RequestDetailsPage(request: request),
                            ),
                          )
                          .then((_) =>
                              _loadRequests()); // Обновить после возвращения со страницы деталей
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
