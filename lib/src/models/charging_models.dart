import 'package:json_annotation/json_annotation.dart';
import 'common_models.dart';

part 'charging_models.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ChargingSession {
  final String? sessionId;
  final String? vin;
  final int? countryCode;
  final String? siteLocationName;
  final String? chargeStartDateTime;
  final String? chargeStopDateTime;
  final String? unlatchDateTime;
  final Location? location;
  final String? vehicleMakeType;
  final String? connectorType;
  final double? chargingStarted;
  final double? chargingStopped;
  final String? chargeStartSoc;
  final String? chargeStopSoc;
  final String? chargeStartIdealRange;
  final String? chargeStopIdealRange;
  final double? energyUsed;
  final double? chargeCost;
  final String? chargeDiscounts;
  final String? chargeDiscountType;
  final String? hasChargeDiscounts;
  final String? userId;
  final String? chargeStartRatedRange;
  final String? chargeStopRatedRange;

  ChargingSession({
    this.sessionId,
    this.vin,
    this.countryCode,
    this.siteLocationName,
    this.chargeStartDateTime,
    this.chargeStopDateTime,
    this.unlatchDateTime,
    this.location,
    this.vehicleMakeType,
    this.connectorType,
    this.chargingStarted,
    this.chargingStopped,
    this.chargeStartSoc,
    this.chargeStopSoc,
    this.chargeStartIdealRange,
    this.chargeStopIdealRange,
    this.energyUsed,
    this.chargeCost,
    this.chargeDiscounts,
    this.chargeDiscountType,
    this.hasChargeDiscounts,
    this.userId,
    this.chargeStartRatedRange,
    this.chargeStopRatedRange,
  });

  factory ChargingSession.fromJson(Map<String, dynamic> json) =>
      _$ChargingSessionFromJson(json);

  Map<String, dynamic> toJson() => _$ChargingSessionToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ChargingInvoice {
  final String? fileName;
  final String? invoiceType;
  final String? contentType;
  final String? content;

  ChargingInvoice({
    this.fileName,
    this.invoiceType,
    this.contentType,
    this.content,
  });

  factory ChargingInvoice.fromJson(Map<String, dynamic> json) =>
      _$ChargingInvoiceFromJson(json);

  Map<String, dynamic> toJson() => _$ChargingInvoiceToJson(this);
}