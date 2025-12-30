# Logpot

Endpoint for logging incoming requests for analytical purposes

<hr>

All incoming requests are logged in `logs/request-logs.txt`

Requests for pages disallowed by `robots.txt` are recorded separately in `logs/private-request-logs.txt`, which includes additional details about the source of request

## Prerequises

Dart SDK version: 3.7.0

## Setup

Create ssl certificates and drop the `pem` files in folder `certs/`

Name them after following

- fullchain.pem
- privkey.pem

Create certificates

```shell
$ openssl req -x509 -newkey rsa:4096 -keyout certs/privkey.pem -out certs/fullchain.pem -days 365 -nodes -subj "/CN=localhost"
```

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

Build the container there

`docker build . -t logpot`

You must create the logs directory before running the container:

```
mkdir -p logs
touch logs/request-logs.txt
touch logs/error-logs.txt
touch logs/private-request-logs.txt
```

Run

```
docker run \
  -v ${PWD}/logs:/app/logs \
  -d -p 8081:8081 logpot
```

The logs can be viewed at `/logs`
