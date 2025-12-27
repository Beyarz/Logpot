# Logpot

Endpoint for logging incoming requests for analytical purposes

## Prerequises

Dart SDK version: 3.7.0

## Setup

Create ssl certificates and drop the `pem` files in folder `certs/`

Name them after following

- fullchain.pem
- privkey.pem

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
$ docker run -d -it -p 8081:8081 logpot

Server listening on:
  https://localhost:8081
```

You should see logging printed when visiting the site:
```
2021-05-06T15:47:04.620417  0:00:00.000158 GET     [200] /
```

## Deploy

Run on this machine

`$ ./deploy.sh`

Then on the other machine you will receive the tarball

`tar -xzvf logpot-source-XXX.tar.gz`

You also need to create following files in the same folder, these are the logs

```
touch /home/logpot/request-logs.txt
touch /home/logpot/error-logs.txt
touch /home/logpot/private-request-logs.txt
```

`docker build . -t logpot`

```
docker run \
  -v /home/logpot/request-logs.txt:/app/request-logs.txt \
  -v /home/logpot/error-logs.txt:/app/error-logs.txt \
  -v /home/logpot/private-request-logs.txt:/app/private-request-logs.txt \
  -d -p 8081:8081 logpot
```
