FROM crowdin/cli:5.4.0

RUN apk --no-cache add bash curl git git-lfs jq gnupg su-exec;

COPY . .
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
