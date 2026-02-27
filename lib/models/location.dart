class LocationResponseDto {
  final String id;
  final String? userId;
  final String name;
  final String? type;
  final DateTime? createdInstant;

  LocationResponseDto({
    required this.id,
    this.userId,
    required this.name,
    this.type,
    this.createdInstant,
  });

  factory LocationResponseDto.fromJson(Map<String, dynamic> json) {
    return LocationResponseDto(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      type: json['type'],
      createdInstant: json['createdInstant'] != null ? DateTime.parse(json['createdInstant']) : null,
    );
  }
}

class LocationDto {
  final String name;
  final String? type;

  LocationDto({
    required this.name,
    this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (type != null) 'type': type,
    };
  }
}
