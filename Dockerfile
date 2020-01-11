FROM zenika/alpine-maven:3-jdk8

COPY LICENSE README.md m2_settings.xml /

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
