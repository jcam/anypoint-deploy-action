FROM openjdk:8-alpine

RUN apk add --no-cache bash git maven

COPY LICENSE README.md m2_settings.xml /

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
