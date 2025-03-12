class HealthCheckResult {
  const HealthCheckResult({required this.status, required this.latency});

  final String status;
  final String latency;

  Map<String, dynamic> toJson() => {'status': status, 'latency': latency};
}
