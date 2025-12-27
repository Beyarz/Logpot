# Logpot

## Prerequises

Dart SDK version: 3.7.0

## Build

For current machine

`$ dart compile exe bin/main.dart -o build/main`

For server use

`$ dart compile exe bin/main.dart --target-os=linux --target-arch=arm64 -o build/main`

Run

```
$ build/main

Server listening on:
  http://0.0.0.0:8081
  http://:::8081
```

## Running with Dart

```
$ dart run

Server listening on:
  http://0.0.0.0:8081
  http://:::8081
```

## Running with Docker

```
$ docker build . -t logpot
$ docker run -it -p 8080:8081 logpot

Server listening on:
  http://0.0.0.0:8081
  http://:::8081
```

And then from a second terminal:
```
$ curl http://0.0.0.0:8081
Hello, World!
```

You should see logging printed:
```
2021-05-06T15:47:04.620417  0:00:00.000158 GET     [200] /
```
