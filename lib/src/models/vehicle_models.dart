import 'package:json_annotation/json_annotation.dart';

part 'vehicle_models.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Vehicle {
  final int id;
  final String? userId;
  final int? vehicleId;
  final String? vin;
  final String? displayName;
  final String? optionCodes;
  final String? color;
  final List<String>? tokens;
  final String? state;
  final bool? inService;
  final int? idS;
  final int? calendarEnabled;
  final int? apiVersion;
  final String? backseatToken;
  final String? backseatTokenUpdatedAt;

  Vehicle({
    required this.id,
    this.userId,
    this.vehicleId,
    this.vin,
    this.displayName,
    this.optionCodes,
    this.color,
    this.tokens,
    this.state,
    this.inService,
    this.idS,
    this.calendarEnabled,
    this.apiVersion,
    this.backseatToken,
    this.backseatTokenUpdatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) =>
      _$VehicleFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class VehicleData {
  final int? id;
  final int? userId;
  final int? vehicleId;
  final String? vin;
  final String? displayName;
  final String? optionCodes;
  final String? color;
  final String? state;
  final bool? inService;
  final int? idS;
  final int? calendarEnabled;
  final int? apiVersion;
  final String? backseatToken;
  final String? backseatTokenUpdatedAt;
  final DriveState? driveState;
  final ClimateState? climateState;
  final ChargeState? chargeState;
  final GuiSettings? guiSettings;
  final VehicleState? vehicleState;
  final VehicleConfig? vehicleConfig;

  VehicleData({
    this.id,
    this.userId,
    this.vehicleId,
    this.vin,
    this.displayName,
    this.optionCodes,
    this.color,
    this.state,
    this.inService,
    this.idS,
    this.calendarEnabled,
    this.apiVersion,
    this.backseatToken,
    this.backseatTokenUpdatedAt,
    this.driveState,
    this.climateState,
    this.chargeState,
    this.guiSettings,
    this.vehicleState,
    this.vehicleConfig,
  });

  factory VehicleData.fromJson(Map<String, dynamic> json) =>
      _$VehicleDataFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleDataToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class DriveState {
  final int? gpsAsOf;
  final int? heading;
  final double? latitude;
  final double? longitude;
  final double? nativeLatitude;
  final double? nativeLongitude;
  final String? nativeLocationSupported;
  final String? nativeType;
  final double? power;
  final String? shiftState;
  final double? speed;
  final int? timestamp;

  DriveState({
    this.gpsAsOf,
    this.heading,
    this.latitude,
    this.longitude,
    this.nativeLatitude,
    this.nativeLongitude,
    this.nativeLocationSupported,
    this.nativeType,
    this.power,
    this.shiftState,
    this.speed,
    this.timestamp,
  });

  factory DriveState.fromJson(Map<String, dynamic> json) =>
      _$DriveStateFromJson(json);

  Map<String, dynamic> toJson() => _$DriveStateToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ClimateState {
  final bool? batteryHeater;
  final int? batteryHeaterNoPower;
  final String? climateKeeperMode;
  final int? defrostMode;
  final double? driverTempSetting;
  final int? fanStatus;
  final double? insideTemp;
  final bool? isAutoConditioningOn;
  final bool? isClimateOn;
  final bool? isFrontDefrosterOn;
  final bool? isPreconditioning;
  final bool? isRearDefrosterOn;
  final int? leftTempDirection;
  final double? maxAvailTemp;
  final double? minAvailTemp;
  final double? outsideTemp;
  final double? passengerTempSetting;
  final bool? remoteHeaterControlEnabled;
  final int? rightTempDirection;
  final int? seatHeaterLeft;
  final int? seatHeaterRight;
  final bool? sideMirrorHeaters;
  final int? timestamp;
  final bool? wiperBladeHeater;

  ClimateState({
    this.batteryHeater,
    this.batteryHeaterNoPower,
    this.climateKeeperMode,
    this.defrostMode,
    this.driverTempSetting,
    this.fanStatus,
    this.insideTemp,
    this.isAutoConditioningOn,
    this.isClimateOn,
    this.isFrontDefrosterOn,
    this.isPreconditioning,
    this.isRearDefrosterOn,
    this.leftTempDirection,
    this.maxAvailTemp,
    this.minAvailTemp,
    this.outsideTemp,
    this.passengerTempSetting,
    this.remoteHeaterControlEnabled,
    this.rightTempDirection,
    this.seatHeaterLeft,
    this.seatHeaterRight,
    this.sideMirrorHeaters,
    this.timestamp,
    this.wiperBladeHeater,
  });

  factory ClimateState.fromJson(Map<String, dynamic> json) =>
      _$ClimateStateFromJson(json);

  Map<String, dynamic> toJson() => _$ClimateStateToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ChargeState {
  final bool? batteryHeaterOn;
  final int? batteryLevel;
  final double? batteryRange;
  final int? chargeCurrentRequest;
  final int? chargeCurrentRequestMax;
  final bool? chargeEnableRequest;
  final double? chargeEnergyAdded;
  final int? chargeLimitSoc;
  final int? chargeLimitSocMax;
  final int? chargeLimitSocMin;
  final int? chargeLimitSocStd;
  final double? chargeMilesAddedIdeal;
  final double? chargeMilesAddedRated;
  final String? chargePortDoorOpen;
  final String? chargePortLatch;
  final double? chargeRate;
  final bool? chargeToMaxRange;
  final int? chargerActualCurrent;
  final int? chargerPhases;
  final int? chargerPilotCurrent;
  final int? chargerPower;
  final int? chargerVoltage;
  final String? chargingState;
  final String? connChargeCable;
  final double? estBatteryRange;
  final String? fastChargerBrand;
  final bool? fastChargerPresent;
  final String? fastChargerType;
  final double? idealBatteryRange;
  final bool? managedChargingActive;
  final String? managedChargingStartTime;
  final bool? managedChargingUserCanceled;
  final int? maxRangeChargeCounter;
  final int? minutesToFullCharge;
  final bool? notEnoughPowerToHeat;
  final bool? scheduledChargingPending;
  final String? scheduledChargingStartTime;
  final double? timeToFullCharge;
  final int? timestamp;
  final bool? tripCharging;
  final int? usableBatteryLevel;
  final String? userChargeEnableRequest;

  ChargeState({
    this.batteryHeaterOn,
    this.batteryLevel,
    this.batteryRange,
    this.chargeCurrentRequest,
    this.chargeCurrentRequestMax,
    this.chargeEnableRequest,
    this.chargeEnergyAdded,
    this.chargeLimitSoc,
    this.chargeLimitSocMax,
    this.chargeLimitSocMin,
    this.chargeLimitSocStd,
    this.chargeMilesAddedIdeal,
    this.chargeMilesAddedRated,
    this.chargePortDoorOpen,
    this.chargePortLatch,
    this.chargeRate,
    this.chargeToMaxRange,
    this.chargerActualCurrent,
    this.chargerPhases,
    this.chargerPilotCurrent,
    this.chargerPower,
    this.chargerVoltage,
    this.chargingState,
    this.connChargeCable,
    this.estBatteryRange,
    this.fastChargerBrand,
    this.fastChargerPresent,
    this.fastChargerType,
    this.idealBatteryRange,
    this.managedChargingActive,
    this.managedChargingStartTime,
    this.managedChargingUserCanceled,
    this.maxRangeChargeCounter,
    this.minutesToFullCharge,
    this.notEnoughPowerToHeat,
    this.scheduledChargingPending,
    this.scheduledChargingStartTime,
    this.timeToFullCharge,
    this.timestamp,
    this.tripCharging,
    this.usableBatteryLevel,
    this.userChargeEnableRequest,
  });

  factory ChargeState.fromJson(Map<String, dynamic> json) =>
      _$ChargeStateFromJson(json);

  Map<String, dynamic> toJson() => _$ChargeStateToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GuiSettings {
  final bool? gui24HourTime;
  final String? guiChargeRateUnits;
  final String? guiDistanceUnits;
  final String? guiRangeDisplay;
  final String? guiTemperatureUnits;
  final int? timestamp;

  GuiSettings({
    this.gui24HourTime,
    this.guiChargeRateUnits,
    this.guiDistanceUnits,
    this.guiRangeDisplay,
    this.guiTemperatureUnits,
    this.timestamp,
  });

  factory GuiSettings.fromJson(Map<String, dynamic> json) =>
      _$GuiSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$GuiSettingsToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class VehicleState {
  final int? apiVersion;
  final String? autoparkState;
  final String? autoparkStateV2;
  final String? autoparkStyle;
  final bool? calendarSupported;
  final String? carVersion;
  final int? centerDisplayState;
  final int? df;
  final int? dr;
  final int? ft;
  final bool? homelinkNearby;
  final bool? isUserPresent;
  final String? lastAutoparkError;
  final bool? locked;
  final bool? notificationsSupported;
  final double? odometer;
  final bool? parsedCalendarSupported;
  final int? pf;
  final int? pr;
  final bool? remoteStart;
  final bool? remoteStartSupported;
  final int? rt;
  final int? sunRoofPercentOpen;
  final String? sunRoofState;
  final int? timestamp;
  final bool? valetMode;
  final String? vehicleName;

  VehicleState({
    this.apiVersion,
    this.autoparkState,
    this.autoparkStateV2,
    this.autoparkStyle,
    this.calendarSupported,
    this.carVersion,
    this.centerDisplayState,
    this.df,
    this.dr,
    this.ft,
    this.homelinkNearby,
    this.isUserPresent,
    this.lastAutoparkError,
    this.locked,
    this.notificationsSupported,
    this.odometer,
    this.parsedCalendarSupported,
    this.pf,
    this.pr,
    this.remoteStart,
    this.remoteStartSupported,
    this.rt,
    this.sunRoofPercentOpen,
    this.sunRoofState,
    this.timestamp,
    this.valetMode,
    this.vehicleName,
  });

  factory VehicleState.fromJson(Map<String, dynamic> json) =>
      _$VehicleStateFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleStateToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class VehicleConfig {
  final bool? canAcceptNavigationRequests;
  final bool? canActuateTrunks;
  final String? carSpecialType;
  final String? carType;
  final String? chargePortType;
  final bool? euVehicle;
  final String? exteriorColor;
  final bool? hasAirSuspension;
  final bool? hasLudicrousMode;
  final bool? motorizedChargePort;
  final String? perfConfig;
  final bool? plg;
  final int? rearSeatHeaters;
  final int? rearSeatType;
  final bool? rhd;
  final String? roofColor;
  final int? seatType;
  final String? spoilerType;
  final int? sunRoofInstalled;
  final String? thirdRowSeats;
  final int? timestamp;
  final String? trimBadging;
  final String? wheelType;

  VehicleConfig({
    this.canAcceptNavigationRequests,
    this.canActuateTrunks,
    this.carSpecialType,
    this.carType,
    this.chargePortType,
    this.euVehicle,
    this.exteriorColor,
    this.hasAirSuspension,
    this.hasLudicrousMode,
    this.motorizedChargePort,
    this.perfConfig,
    this.plg,
    this.rearSeatHeaters,
    this.rearSeatType,
    this.rhd,
    this.roofColor,
    this.seatType,
    this.spoilerType,
    this.sunRoofInstalled,
    this.thirdRowSeats,
    this.timestamp,
    this.trimBadging,
    this.wheelType,
  });

  factory VehicleConfig.fromJson(Map<String, dynamic> json) =>
      _$VehicleConfigFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleConfigToJson(this);
}