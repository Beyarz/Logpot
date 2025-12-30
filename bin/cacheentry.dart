class CacheEntry {
  final String path;
  final String response;
  final DateTime timestamp;
  int accessCount;

  CacheEntry({
    required this.path,
    required this.response,
    required this.timestamp,
    this.accessCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'response': response,
    'timestamp': timestamp.toIso8601String(),
    'accessCount': accessCount,
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      path: json['path'] as String,
      response: json['response'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      accessCount: json['accessCount'] as int? ?? 0,
    );
  }
}
