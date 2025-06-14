import 'package:json_annotation/json_annotation.dart';

part 'energy_models.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class EnergyProduct {
  final int? energySiteId;
  final String? resourceType;
  final String? siteName;
  final int? id;
  final String? gatewayId;
  final String? assetSiteId;
  final String? warpSiteNumber;
  final List<String>? components;

  EnergyProduct({
    this.energySiteId,
    this.resourceType,
    this.siteName,
    this.id,
    this.gatewayId,
    this.assetSiteId,
    this.warpSiteNumber,
    this.components,
  });

  factory EnergyProduct.fromJson(Map<String, dynamic> json) =>
      _$EnergyProductFromJson(json);

  Map<String, dynamic> toJson() => _$EnergyProductToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class EnergyHistory {
  final String? serialNumber;
  final String? period;
  final List<EnergyHistoryEntry>? timeSeries;

  EnergyHistory({
    this.serialNumber,
    this.period,
    this.timeSeries,
  });

  factory EnergyHistory.fromJson(Map<String, dynamic> json) =>
      _$EnergyHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$EnergyHistoryToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class EnergyHistoryEntry {
  final String? timestamp;
  final double? solarEnergyExported;
  final double? gridEnergyImported;
  final double? gridEnergyExported;
  final double? batteryEnergyImported;
  final double? batteryEnergyExported;
  final double? consumerEnergyImported;

  EnergyHistoryEntry({
    this.timestamp,
    this.solarEnergyExported,
    this.gridEnergyImported,
    this.gridEnergyExported,
    this.batteryEnergyImported,
    this.batteryEnergyExported,
    this.consumerEnergyImported,
  });

  factory EnergyHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$EnergyHistoryEntryFromJson(json);

  Map<String, dynamic> toJson() => _$EnergyHistoryEntryToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class EnergyLiveStatus {
  final double? solarPower;
  final double? energyLeft;
  final double? totalPackEnergy;
  final double? percentageCharged;
  final double? batteryPower;
  final double? loadPower;
  final double? gridPower;
  final String? gridServicesActive;
  final double? gridStatus;
  final String? islandStatus;
  final String? stormModeActive;
  final String? timestamp;

  EnergyLiveStatus({
    this.solarPower,
    this.energyLeft,
    this.totalPackEnergy,
    this.percentageCharged,
    this.batteryPower,
    this.loadPower,
    this.gridPower,
    this.gridServicesActive,
    this.gridStatus,
    this.islandStatus,
    this.stormModeActive,
    this.timestamp,
  });

  factory EnergyLiveStatus.fromJson(Map<String, dynamic> json) =>
      _$EnergyLiveStatusFromJson(json);

  Map<String, dynamic> toJson() => _$EnergyLiveStatusToJson(this);
}