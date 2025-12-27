// How many rows from the logfile to display
const int maxLinesToRead = 50;

// Read-write chunk buffer for storing logs and buffer size single op
const int chunkSize = 16 * 1024; // 16KB
const int maxReadBytes = 64 * 1024; // 64KB

// Max size for incoming request body size (in case someone wants to be funny)
const int maxRequestBodySize = 10 * 1024 * 1024; // 10MB

// Max size for each logfile before rotating
const int maxLogFileSize = 64 * 1024 * 1024; // 64MB
const int maxRotatedLogFiles = 5;

const String robotsTxtFile = 'robots.txt';
const Duration cacheExpiry = Duration(seconds: 5);

const String logFileName = 'request-logs.txt';
const String errorLogFileName = 'error-logs.txt';
const String privateLogFileName = 'private-request-logs.txt';

const String certPath = 'certs/cert.pem';
const String keyPath = 'certs/key.pem';

const int exitSuccess = 0;
const int exitFailure = 1;

const int payloadTooLargeError = 413;
