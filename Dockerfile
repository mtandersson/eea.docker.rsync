FROM alpine:3.17.2

RUN apk add --no-cache --virtual .run-deps rsync openssh tzdata curl ca-certificates && rm -rf /var/cache/apk/*
COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["sh"]
