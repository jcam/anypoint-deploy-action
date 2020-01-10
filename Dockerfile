FROM maven:3.6-jdk-8

COPY LICENSE README.md m2_settings.xml /

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
