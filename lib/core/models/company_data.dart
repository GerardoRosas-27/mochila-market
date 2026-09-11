class CompanyData {
  const CompanyData({
    this.name = '',
    this.address = '',
    this.locationText = '',
    this.latitude,
    this.longitude,
    this.floorPlanPath = '',
    this.hours = const {},
  });

  final String name;
  final String address;
  final String locationText;
  final double? latitude;
  final double? longitude;
  final String floorPlanPath;
  /// weekday 1=lunes … 7=domingo → "09:00-18:00" o "Cerrado"
  final Map<int, String> hours;

  static const defaultWeekdayLabels = {
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles',
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sábado',
    7: 'Domingo',
  };

  CompanyData copyWith({
    String? name,
    String? address,
    String? locationText,
    double? latitude,
    double? longitude,
    String? floorPlanPath,
    Map<int, String>? hours,
    bool clearLatLng = false,
  }) {
    return CompanyData(
      name: name ?? this.name,
      address: address ?? this.address,
      locationText: locationText ?? this.locationText,
      latitude: clearLatLng ? null : (latitude ?? this.latitude),
      longitude: clearLatLng ? null : (longitude ?? this.longitude),
      floorPlanPath: floorPlanPath ?? this.floorPlanPath,
      hours: hours ?? this.hours,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'locationText': locationText,
        'latitude': latitude,
        'longitude': longitude,
        'floorPlanPath': floorPlanPath,
        'hours': hours.map((k, v) => MapEntry(k.toString(), v)),
      };

  factory CompanyData.fromJson(Map<String, dynamic> json) {
    final rawHours = json['hours'];
    final Map<int, String> parsed = {};
    if (rawHours is Map) {
      rawHours.forEach((k, v) {
        final day = int.tryParse(k.toString());
        if (day != null && v != null) parsed[day] = v.toString();
      });
    }
    return CompanyData(
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      locationText: json['locationText'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      floorPlanPath: json['floorPlanPath'] as String? ?? '',
      hours: parsed,
    );
  }

  String hoursSummary() {
    if (hours.isEmpty) return 'Sin horario definido';
    return hours.entries
        .map((e) =>
            '${defaultWeekdayLabels[e.key] ?? e.key}: ${e.value}')
        .join('\n');
  }
}
