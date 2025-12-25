FROM dart:stable AS build

WORKDIR /app
COPY robots.txt ./
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart compile exe bin/main.dart -o build/main

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/build/main /app/bin/

ENV PORT=8080
EXPOSE ${PORT}
CMD ["/app/bin/main"]
