# Logpot

## Prerequises

Dart SDK version: 3.7.0

## Build

For current machine

`$ dart compile exe bin/main.dart -o build/main`

## Run

Run compiled

```
$ build/main

Server listening on:
  https://localhost:8081
```

Running with Dart

```
$ dart run

Server listening on:
  https://localhost:8081
```

Running with container

```
$ docker build . -t logpot
$ docker run -it -p 8081:8080 logpot

Server listening on:
  https://localhost:8081
```

You should see logging printed when visiting the site:
```
2021-05-06T15:47:04.620417  0:00:00.000158 GET     [200] /
```
