import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Layer {
  String id;
  String soilType;
  double depthFrom;
  double depthTo;
  String sampleDepth;

  Layer({
    required this.id,
    required this.soilType,
    required this.depthFrom,
    required this.depthTo,
    this.sampleDepth = '',
  });

  double get thickness => depthTo - depthFrom;

  Map<String, dynamic> toJson() => {
        'id': id,
        'soilType': soilType,
        'depthFrom': depthFrom,
        'depthTo': depthTo,
        'sampleDepth': sampleDepth,
      };

  factory Layer.fromJson(Map<String, dynamic> json) => Layer(
        id: json['id'] as String,
        soilType: json['soilType'] as String,
        depthFrom: (json['depthFrom'] as num).toDouble(),
        depthTo: (json['depthTo'] as num).toDouble(),
        sampleDepth: (json['sampleDepth'] as String?) ?? '',
      );

  Layer copyWith({
    String? id,
    String? soilType,
    double? depthFrom,
    double? depthTo,
    String? sampleDepth,
  }) =>
      Layer(
        id: id ?? this.id,
        soilType: soilType ?? this.soilType,
        depthFrom: depthFrom ?? this.depthFrom,
        depthTo: depthTo ?? this.depthTo,
        sampleDepth: sampleDepth ?? this.sampleDepth,
      );
}

class Borehole {
  String id;
  String number;
  String date;
  String elevation;
  List<Layer> layers;
  bool? hasGroundwater;
  String groundwaterDepth;
  String notes;
  String createdAt;
  String updatedAt;

  Borehole({
    required this.id,
    this.number = '',
    this.date = '',
    this.elevation = '',
    List<Layer>? layers,
    this.hasGroundwater,
    this.groundwaterDepth = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  }) : layers = layers ?? [];

  double get totalDepth => layers.isEmpty ? 0.0 : layers.last.depthTo;

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'date': date,
        'elevation': elevation,
        'layers': layers.map((l) => l.toJson()).toList(),
        'hasGroundwater': hasGroundwater,
        'groundwaterDepth': groundwaterDepth,
        'notes': notes,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory Borehole.fromJson(Map<String, dynamic> json) => Borehole(
        id: json['id'] as String,
        number: (json['number'] as String?) ?? '',
        date: (json['date'] as String?) ?? '',
        elevation: (json['elevation'] as String?) ?? '',
        layers: (json['layers'] as List?)
                ?.map((e) => Layer.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        hasGroundwater: json['hasGroundwater'] as bool?,
        groundwaterDepth: (json['groundwaterDepth'] as String?) ?? '',
        notes: (json['notes'] as String?) ?? '',
        createdAt: (json['createdAt'] as String?) ?? '',
        updatedAt: (json['updatedAt'] as String?) ?? '',
      );

  Borehole copyWith({
    String? id,
    String? number,
    String? date,
    String? elevation,
    List<Layer>? layers,
    bool? hasGroundwater,
    String? groundwaterDepth,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) =>
      Borehole(
        id: id ?? this.id,
        number: number ?? this.number,
        date: date ?? this.date,
        elevation: elevation ?? this.elevation,
        layers: layers ?? List<Layer>.from(this.layers),
        hasGroundwater: hasGroundwater ?? this.hasGroundwater,
        groundwaterDepth: groundwaterDepth ?? this.groundwaterDepth,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  static Borehole create({String number = '', String date = ''}) {
    final now = DateTime.now().toIso8601String();
    return Borehole(
      id: _uuid.v4(),
      number: number,
      date: date,
      createdAt: now,
      updatedAt: now,
    );
  }
}

class Project {
  String id;
  String name;
  String address;
  String description;
  List<Borehole> boreholes;
  String createdAt;
  String updatedAt;

  Project({
    required this.id,
    required this.name,
    this.address = '',
    this.description = '',
    List<Borehole>? boreholes,
    required this.createdAt,
    required this.updatedAt,
  }) : boreholes = boreholes ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'description': description,
        'boreholes': boreholes.map((b) => b.toJson()).toList(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        address: (json['address'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        boreholes: (json['boreholes'] as List?)
                ?.map((e) => Borehole.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: (json['createdAt'] as String?) ?? '',
        updatedAt: (json['updatedAt'] as String?) ?? '',
      );

  Project copyWith({
    String? id,
    String? name,
    String? address,
    String? description,
    List<Borehole>? boreholes,
    String? createdAt,
    String? updatedAt,
  }) =>
      Project(
        id: id ?? this.id,
        name: name ?? this.name,
        address: address ?? this.address,
        description: description ?? this.description,
        boreholes: boreholes ?? List<Borehole>.from(this.boreholes),
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  static Project create({
    required String name,
    String address = '',
    String description = '',
  }) {
    final now = DateTime.now().toIso8601String();
    return Project(
      id: _uuid.v4(),
      name: name,
      address: address,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
  }
}
