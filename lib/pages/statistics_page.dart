// lib/screens/statistics_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // <--- ДОБАВЬТЕ ЭТОТ ИМПОРТ
import '../services/api_service.dart';

class StatisticsPage extends StatefulWidget {
  // Удаляем final ApiService apiService из конструктора,
  // так как будем получать его из Provider.
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Map<String, int>? _statisticsData;
  bool _isLoading = false;
  String? _errorMessage;

  // Объявляем ApiService здесь, но инициализируем в didChangeDependencies
  late ApiService _apiService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Получаем ApiService из Provider
    _apiService = Provider.of<ApiService>(context, listen: false);
    // Загружаем статистику при первой инициализации или изменении зависимостей
    // (например, при первом открытии страницы)
    if (_statisticsData == null && !_isLoading) {
      // Чтобы не загружать повторно, если уже есть данные
      _fetchStatistics();
    }
  }

  // Удаляем initState(), так как инициализация _apiService и _fetchStatistics
  // перенесена в didChangeDependencies().
  // @override
  // void initState() {
  //   super.initState();
  //   _fetchStatistics();
  // }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _fetchStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statisticsData = null;
    });

    try {
      final DateTime actualStartDate =
          DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
      final DateTime actualEndDate =
          DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

      // Используем _apiService, полученный из Provider
      final data = await _apiService.getRequestStatistics(
          actualStartDate, actualEndDate);
      setState(() {
        _statisticsData = data;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        print('Error fetching statistics: $_errorMessage');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getRussianStatusName(String key) {
    switch (key) {
      case 'total':
        return 'Всего заявок';
      case 'created':
        return 'Создано';
      case 'assigned':
        return 'Назначено';
      case 'inProgress':
        return 'В работе';
      case 'completed':
        return 'Выполнено';
      case 'cancelled':
        return 'Отклонено';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика по заявкам'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Начальная дата:'),
                    subtitle: Text(DateFormat('dd.MM.yyyy').format(_startDate)),
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Конечная дата:'),
                    subtitle: Text(DateFormat('dd.MM.yyyy').format(_endDate)),
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchStatistics,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Показать статистику'),
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Text(
                'Ошибка: $_errorMessage',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              )
            else if (_statisticsData != null)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Статус')),
                      DataColumn(label: Text('Количество'), numeric: true),
                    ],
                    rows: _statisticsData!.entries.map((entry) {
                      return DataRow(cells: [
                        DataCell(Text(_getRussianStatusName(entry.key))),
                        DataCell(Text(entry.value.toString())),
                      ]);
                    }).toList(),
                  ),
                ),
              )
            else if (!_isLoading)
              const Center(
                  child: Text('Выберите даты и нажмите "Показать статистику"'))
          ],
        ),
      ),
    );
  }
}
