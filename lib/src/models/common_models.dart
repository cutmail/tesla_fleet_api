import 'package:json_annotation/json_annotation.dart';

part 'common_models.g.dart';

class ApiResponse<T> {
  final T? response;
  final String? error;
  final List<String>? errorDescription;
  final bool? errorAndMessages;

  ApiResponse({
    this.response,
    this.error,
    this.errorDescription,
    this.errorAndMessages,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) => ApiResponse<T>(
    response: json['response'] as T?,
    error: json['error'] as String?,
    errorDescription: (json['error_description'] as List<dynamic>?)?.cast<String>(),
    errorAndMessages: json['error_and_messages'] as bool?,
  );

  Map<String, dynamic> toJson() => {
    'response': response,
    'error': error,
    'error_description': errorDescription,
    'error_and_messages': errorAndMessages,
  };
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Location {
  final double? latitude;
  final double? longitude;

  Location({this.latitude, this.longitude});

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);

  Map<String, dynamic> toJson() => _$LocationToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CommandResponse {
  final bool result;
  final String? reason;

  CommandResponse({required this.result, this.reason});

  factory CommandResponse.fromJson(Map<String, dynamic> json) =>
      _$CommandResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CommandResponseToJson(this);
}