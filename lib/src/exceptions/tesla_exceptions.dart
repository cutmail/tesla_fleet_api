class TeslaException implements Exception {
  final String message;
  final int? statusCode;
  
  const TeslaException(this.message, [this.statusCode]);
  
  @override
  String toString() => 'TeslaException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class TeslaAuthException extends TeslaException {
  const TeslaAuthException(String message, [int? statusCode]) : super(message, statusCode);
}

class TeslaApiException extends TeslaException {
  const TeslaApiException(String message, [int? statusCode]) : super(message, statusCode);
}

class TeslaRateLimitException extends TeslaException {
  final Duration retryAfter;
  
  const TeslaRateLimitException(String message, this.retryAfter, [int? statusCode]) 
      : super(message, statusCode);
}

class TeslaVehicleException extends TeslaException {
  final String vehicleId;
  
  const TeslaVehicleException(String message, this.vehicleId, [int? statusCode]) 
      : super(message, statusCode);
}