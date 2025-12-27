TIMESTAMP=$(date +%Y%m%d-%H%M%S)
tar -czf logpot-source-${TIMESTAMP}.tar.gz \
    bin/ \
    Dockerfile \
    .dockerignore \
    robots.txt \
    pubspec.yaml \
    pubspec.lock

scp logpot-source-${TIMESTAMP}.tar.gz NAME@IP:/app
