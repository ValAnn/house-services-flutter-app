// lib/pages/request_details_page.dart

import 'package:flutter/material.dart';
import 'package:house_services_flutter/models/repair_team_model.dart';
import 'package:provider/provider.dart';
import '../models/request_model.dart';
import '../services/api_service.dart';
import 'dart:convert'; // Для base64Decode

class RequestDetailsPage extends StatefulWidget {
  final RequestDto request;

  const RequestDetailsPage({super.key, required this.request});

  @override
  State<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  late RequestDto _currentRequest;
  final ApiService _apiService = ApiService();

  List<RepairTeamDto> _repairTeams = []; // List of available repair teams
  bool _isLoadingTeams = false; // Flag for loading repair teams
  int? _selectedRepairTeamId; // Selected repair team ID for assignment

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.request;
    if (ApiService.userRole == 'ROLE_OPERATOR') {
      _fetchRepairTeams();
    }
  }

  Future<void> _fetchRepairTeams() async {
    setState(() {
      _isLoadingTeams = true;
    });
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      _repairTeams = await apiService.getRepairTeams();
    } catch (e) {
      print('Ошибка при загрузке ремонтных бригад: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки бригад: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoadingTeams = false;
      });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      // await _apiService.updateRequestStatus(_currentRequest.id!, newStatus);

      if (newStatus == 'ASSIGNED' && _selectedRepairTeamId != null) {
        await _apiService.assignRequestToTeam(
            _currentRequest.id!, _selectedRepairTeamId!);
      }
      if (newStatus == 'COMPLETED') {
        RequestDto curRequest = RequestDto(
          id: _currentRequest.id,
          creatingDate: _currentRequest.creatingDate,
          progressDate: _currentRequest.progressDate,
          closeDate: _currentRequest.closeDate,
          description: _currentRequest.description,
          status: newStatus,
          operatorId: _currentRequest.operatorId,
          tenantId: _currentRequest.tenantId,
          repairTeamId: _currentRequest.repairTeamId,
          result: _currentRequest.result,
          photoData: _currentRequest.photoData,
        );
        await _apiService.addRepairComment(_currentRequest.id!, curRequest);
      }
      setState(() {
        _currentRequest = RequestDto(
          id: _currentRequest.id,
          creatingDate: _currentRequest.creatingDate,
          progressDate: _currentRequest.progressDate,
          closeDate: _currentRequest.closeDate,
          description: _currentRequest.description,
          status: newStatus, // Обновляем статус локально
          operatorId: _currentRequest.operatorId,
          tenantId: _currentRequest.tenantId,
          repairTeamId: _currentRequest.repairTeamId,
          result: _currentRequest.result,
          photoData: _currentRequest.photoData,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Статус обновлен!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Ошибка обновления статуса: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  Future<void> _addComment(RequestDto curReq, String comment) async {
    try {
      RequestDto curRequest = RequestDto(
        id: _currentRequest.id,
        creatingDate: _currentRequest.creatingDate,
        progressDate: _currentRequest.progressDate,
        closeDate: _currentRequest.closeDate,
        description: _currentRequest.description,
        status: _currentRequest.status,
        operatorId: _currentRequest.operatorId,
        tenantId: _currentRequest.tenantId,
        repairTeamId: _currentRequest.repairTeamId,
        result: comment,
        photoData: _currentRequest.photoData,
      );
      await _apiService.addRepairComment(_currentRequest.id!, curRequest);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Комментарий добавлен!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Ошибка добавления комментария: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  void _showStatusChangeDialog(BuildContext context) {
    // Local state for the dialog's dropdowns
    String? dialogSelectedStatus =
        _currentRequest?.status; // Pre-select current status
    int? dialogSelectedRepairTeamId;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          // Use StatefulBuilder to update dialog content
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Изменить статус заявки'),
              content: Column(
                mainAxisSize: MainAxisSize.min, // Keep column compact
                children: [
                  DropdownButtonFormField<String>(
                    value: dialogSelectedStatus,
                    hint: const Text('Выберите новый статус'),
                    items: <String>[
                      'CREATED',
                      'ASSIGNED',
                      'IN_PROGRESS',
                      'COMPLETED',
                      'CLOSED',
                      'CANCELLED'
                    ] // All possible statuses
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        // Update dialog's local state
                        dialogSelectedStatus = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Show repair team dropdown ONLY if status is ASSIGNED and user is OPERATOR
                  if (dialogSelectedStatus == 'ASSIGNED' &&
                      ApiService.userRole == 'ROLE_OPERATOR')
                    _isLoadingTeams
                        ? const CircularProgressIndicator() // Show loading indicator
                        : DropdownButtonFormField<int>(
                            value: dialogSelectedRepairTeamId,
                            hint: const Text('Выберите ремонтную бригаду'),
                            items: _repairTeams.map<DropdownMenuItem<int>>(
                                (RepairTeamDto team) {
                              return DropdownMenuItem<int>(
                                value: team.id,
                                child: Text(team.teamNumber),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              setDialogState(() {
                                // Update dialog's local state
                                dialogSelectedRepairTeamId = newValue;
                              });
                            },
                          ),
                  if (dialogSelectedStatus == 'ASSIGNED' &&
                      ApiService.userRole == 'OPERATOR' &&
                      _repairTeams.isEmpty &&
                      !_isLoadingTeams)
                    const Text('Нет доступных бригад',
                        style: TextStyle(color: Colors.red)),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Отмена'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Сохранить'),
                  onPressed: () {
                    if (dialogSelectedStatus != null) {
                      // Check for repair team selection if status is ASSIGNED
                      if (dialogSelectedStatus == 'ASSIGNED' &&
                          ApiService.userRole == 'OPERATOR' &&
                          dialogSelectedRepairTeamId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Пожалуйста, выберите ремонтную бригаду.')),
                        );
                        return; // Don't close dialog, let user select a team
                      }

                      // Update the state variable with selected team ID before calling _updateStatus
                      setState(() {
                        _selectedRepairTeamId = dialogSelectedRepairTeamId;
                      });

                      _updateStatus(dialogSelectedStatus!);
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRole = ApiService.userRole;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали заявки'),
        actions: [
          // Show status change button only for Operator and Repair Team
          if (userRole == 'OPERATOR' || userRole == 'REPAIR_TEAM')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showStatusChangeDialog(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Заявка #${_currentRequest.id}',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text('Описание: ${_currentRequest.description}'),
            Text('Статус: ${_currentRequest.status}'),
            if (_currentRequest.creatingDate != null)
              Text(
                  'Создана: ${_currentRequest.formatDateTime(_currentRequest.creatingDate)}'),
            if (_currentRequest.progressDate != null)
              Text(
                  'В работе: ${_currentRequest.formatDateTime(_currentRequest.progressDate)}'),
            if (_currentRequest.closeDate != null)
              Text(
                  'Закрыта: ${_currentRequest.formatDateTime(_currentRequest.closeDate)}'),
            if (_currentRequest.operatorId != null)
              Text('Оператор ID: ${_currentRequest.operatorId}'),
            Text('Арендатор ID: ${_currentRequest.tenantId}'),
            if (_currentRequest.repairTeamId != null)
              Text('Бригада ID: ${_currentRequest.repairTeamId}'),
            if (_currentRequest.result != null &&
                _currentRequest.result!.isNotEmpty)
              Text('Результат ремонта: ${_currentRequest.result}'),

            const SizedBox(height: 20),

            if (_currentRequest.photoData != null &&
                _currentRequest.photoData!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Фото:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  // Отображение Base64 изображения
                  Image.memory(
                    base64Decode(_currentRequest.photoData!),
                    fit: BoxFit.cover,
                    width: 200, // или любой другой размер
                    height: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text('Не удалось загрузить фото');
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // Логика для кнопок в зависимости от роли
            if (userRole == 'ROLE_OPERATOR') ...[
              const Divider(),
              const Text('Действия оператора:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () => _showStatusChangeDialog(context),
                child: const Text('Изменить статус'),
              ),
            ],
            if (userRole == 'ROLE_REPAIR_TEAM') ...[
              const Divider(),
              const Text('Действия бригады:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () => _showCommentDialog(context),
                child: const Text('Добавить комментарий о ремонте'),
              ),
              // Можно добавить кнопку для смены статуса на "Завершено"
              ElevatedButton(
                onPressed: () =>
                    _updateStatus('COMPLETED'), // Или другой статус
                child: const Text('Завершить ремонт'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCommentDialog(BuildContext context) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Добавить комментарий о ремонте'),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(labelText: 'Комментарий'),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Добавить'),
              onPressed: () {
                if (commentController.text.isNotEmpty) {
                  _addComment(_currentRequest, commentController.text);
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
