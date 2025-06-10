// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:house_services_flutter/pages/request_details_page.dart';
import 'package:house_services_flutter/pages/statistics_page.dart';
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
  String? _selectedStatus; // Выбранный статус для фильтрации
  final TextEditingController _searchController =
      TextEditingController(); // Контроллер для поля поиска
  String _searchText = ''; // Текст для поиска по описанию

  final List<String> _requestStatuses = [
    'ALL', // Добавляем опцию "Все"
    'CREATED',
    'ASSIGNED',
    'IN_PROGRESS',
    'COMPLETED',
    'CLOSED',
    'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = _requestStatuses.first;
    _loadRequests();

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_searchText != _searchController.text) {
      setState(() {
        _searchText = _searchController.text;
      });
      _loadRequests();
    }
  }

  void _add_request() async {
    await Navigator.of(context).pushNamed('/add-request');
    _loadRequests();
  }

  void _loadRequests() {
    setState(() {
      _requestsFuture =
          Provider.of<ApiService>(context, listen: false).getRequests(
        status: _selectedStatus,
        description: _searchText.isNotEmpty ? _searchText : null,
      );
    });
  }

  void _logout() async {
    await ApiService.clearAuthData();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  String _getPageTitle() {
    final role = ApiService.userRole;
    if (role == 'ROLE_TENANT') {
      return 'Мои заявки';
    } else if (role == 'ROLE_OPERATOR') {
      return 'Новые заявки';
    } else if (role == 'ROLE_REPAIR_TEAM') {
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
          if (userRole == 'ROLE_TENANT')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.of(context).pushNamed('/add-request');
                _loadRequests(); // Обновить список после добавления
              },
            ),
          // IconButton(
          //   icon: const Icon(Icons.add),
          //   onPressed: _add_request,
          // ),
          if (userRole == 'ROLE_OPERATOR')
            IconButton(
              onPressed: () async {
                await Navigator.of(context).pushNamed('/tenants');
                _loadRequests();
              },
              icon: const Icon(Icons.people),
            ),
          IconButton(
            onPressed: () async {
              await Navigator.of(context).pushNamed('/statistics');
              _loadRequests();
            },
            icon: const Icon(Icons.stacked_bar_chart),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Поиск по описанию',
                    hintText: 'Введите часть описания',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged(); // Очищаем поиск
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (_) =>
                      _loadRequests(), // Обновить по нажатию Enter
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Фильтр по статусу',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  items: _requestStatuses.map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedStatus = newValue;
                    });
                    _loadRequests(); // Перезагружаем заявки с новым статусом
                  },
                ),
              ],
            ),
          ),
          // --- КОНЕЦ ПАНЕЛИ ФИЛЬТРАЦИИ И ПОИСКА ---

          // --- СПИСОК ЗАЯВОК (FutureBuilder) ---
          Expanded(
            // Expanded нужен, чтобы ListView занимал оставшееся пространство
            child: FutureBuilder<List<RequestDto>>(
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
                          title: Text(
                              'Заявка #${request.id}: ${request.description}'),
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
          ),
        ],
      ),
    );
  }
}
