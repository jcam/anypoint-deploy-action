FROM zenika/alpine-maven:3-jdk8

RUN apk add --no-cache bash git

COPY LICENSE README.md m2_settings.xml /

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
