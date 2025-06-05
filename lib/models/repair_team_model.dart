class RepairTeamDto {
  final int id;
  final String teamNumber; // Or whatever field identifies the team

  RepairTeamDto({required this.id, required this.teamNumber});

  factory RepairTeamDto.fromJson(Map<String, dynamic> json) {
    return RepairTeamDto(
      id: json['id'],
      teamNumber: json['teamNumber'],
    );
  }
}
