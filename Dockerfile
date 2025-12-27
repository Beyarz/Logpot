FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN mkdir -p build
RUN dart compile exe bin/main.dart -o build/main

FROM scratch

WORKDIR /app

COPY --from=build /runtime/ /
COPY --from=build /app/robots.txt /app/
COPY --from=build /app/build/main /app/bin/

COPY certs/ /app/certs/

ENV PORT=8081
EXPOSE ${PORT}

CMD ["/app/bin/main"]
