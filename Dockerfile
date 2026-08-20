FROM crowdin/cli:4.15.1

RUN apk --no-cache add curl git git-lfs jq gnupg su-exec;

COPY . .
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
