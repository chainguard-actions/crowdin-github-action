FROM crowdin/cli:5.2.0@sha256:60e632130aebe5b26c577ae6b236fd92b4246e426499d4e0bac22fd240cb3cc7

RUN apk --no-cache add bash curl git git-lfs jq gnupg su-exec;

COPY . .
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
