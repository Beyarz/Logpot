const int maxRotatedLogFiles = 5;
const int maxLinesToRead = 50;

const int chunkSize = 16 * 1024; // 16KB
const int maxBytes = 64 * 1024; // 16KB

const int defaultMaxLogFileSize = 10 * 1024 * 1024; // 10MB
const int maxRequestBodySize = 10 * 1024 * 1024; // 10MB

const int defaultMaxSizeBytes = 64 * 1024 * 1024; // 64MB
const int maxLogFileSize = 64 * 1024 * 1024; // 64MB

const String robotsTxtFile = 'robots.txt';
const Duration cacheExpiry = Duration(seconds: 5);

const String logFileName = 'request-logs.txt';
const String errorLogFileName = 'error-logs.txt';

const String certPath = 'certs/cert.pem';
const String keyPath = 'certs/key.pem';

const int exitSuccess = 0;
const int exitFailure = 1;

const int payloadTooLargeError = 413;
