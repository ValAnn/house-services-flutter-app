// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:house_services_flutter/pages/statistics_page.dart';
import 'package:provider/provider.dart';
import '../models/tenant_model.dart';
import '../services/api_service.dart';

class TenantsPage extends StatefulWidget {
  const TenantsPage({super.key});

  @override
  State<TenantsPage> createState() => _TenantsPageState();
}

class _TenantsPageState extends State<TenantsPage> {
  late Future<List<TenantDto>> _tenantsFuture;
  String? _selectedStatus; // Выбранный статус для фильтрации
  final TextEditingController _searchController =
      TextEditingController(); // Контроллер для поля поиска
  String _searchText = ''; // Текст для поиска по описанию

  @override
  void initState() {
    super.initState();

    _loadTenants();

    _searchController.addListener(_onSearchChanged);
  }

  final List<String> _requestStatuses = [
    'ALL', // Добавляем опцию "Все"
    'CREATED',
    'ASSIGNED',
    'IN_PROGRESS',
    'COMPLETED',
    'CLOSED',
    'CANCELLED',
  ];

  void _onSearchChanged() {
    if (_searchText != _searchController.text) {
      setState(() {
        _searchText = _searchController.text;
      });
      _loadTenants();
    }
  }

  void _add_tenant() async {
    await Navigator.of(context).pushNamed('/add-tenant');
    _loadTenants();
  }

  void _loadTenants() {
    setState(() {
      _tenantsFuture =
          Provider.of<ApiService>(context, listen: false).getTenants(
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
      return 'Жители';
    } else if (role == 'ROLE_REPAIR_TEAM') {
      return 'Заявки для бригады';
    }
    return 'Жители';
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
                await Navigator.of(context).pushNamed('/add-tenant');
                _loadTenants(); // Обновить список после добавления
              },
            ),
          // IconButton(
          //   icon: const Icon(Icons.add),
          //   onPressed: _add_tenant,
          // ),
          if (userRole == 'ROLE_OPERATOR')
            IconButton(
              onPressed: () async {
                await Navigator.of(context).pushNamed('/statistics');
                _loadTenants();
              },
              icon: const Icon(Icons.stacked_bar_chart),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTenants,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        // Используем Column для размещения фильтров и списка
        children: [
          // --- ПАНЕЛЬ ФИЛЬТРАЦИИ И ПОИСКА ---
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
                      _loadTenants(), // Обновить по нажатию Enter
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          Expanded(
            // Expanded нужен, чтобы ListView занимал оставшееся пространство
            child: FutureBuilder<List<TenantDto>>(
              future: _tenantsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Ошибка: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Нет доступных жителей.'));
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final tenant = snapshot.data![index];
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title:
                              Text('Житель #${tenant.id}: ${tenant.fullName}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Адрес: ${tenant.registrationAddress}'),
                              Text('Почта: ${tenant.email}'),
                              Text('Количество заявок: ${tenant.numRequests}'),
                            ],
                          ),
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
