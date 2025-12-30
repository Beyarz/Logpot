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

const String responseCacheFile = 'cache/response-cache.json';
const int maxCacheEntries = 1000;
// Don't want to save too often, it will wear out the storage
// If request keep coming, it will reset timer
// After this amount of time since last request, store to file
const int cacheSaveDelaySec = 60;

const String logFileName = 'logs/request-logs.txt';
const String errorLogFileName = 'logs/error-logs.txt';
const String privateLogFileName = 'logs/private-request-logs.txt';

const String certPath = 'certs/fullchain.pem';
const String keyPath = 'certs/privkey.pem';

const int exitSuccess = 0;
const int exitFailure = 1;

const int payloadTooLargeError = 413;
const int httpOk = 200;

const String llmModel = 'openai/gpt-oss-20b';

const String openaiEndpoint = 'https://api.hyperbolic.xyz/v1/chat/completions';

// Leave empty to disable LLM hallucination
const String openaiApikey = '...';
