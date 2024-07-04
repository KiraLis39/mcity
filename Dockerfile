FROM bellsoft/liberica-openjdk-alpine:21.0.2-x86_64

ARG RP_CONTAINER_IMAGE_TAG

ENV SENTRY_RELEASE=$RP_CONTAINER_IMAGE_TAG

ENV LANG C.UTF-8

WORKDIR /app

COPY target/app.jar app.jar

RUN adduser --system --group app && chown -R app:app .

USER app:app

ENTRYPOINT ["java", "-Xmx1536M", "-Xms1536M", "-jar", "app.jar"]
