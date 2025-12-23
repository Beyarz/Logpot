FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart compile exe bin/main.dart -o build/main

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/build/main /app/bin/

EXPOSE 1234
CMD ["PORT=1234", "/app/bin/server"]
