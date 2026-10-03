# Build Cruise Control in its own stage
FROM amazoncorretto:21-alpine-jdk AS build
WORKDIR /workspace
COPY . .
RUN ./gradlew clean jar copyDependantLibs --warning-mode all

# Fetch the jars and the startup script and run Cruise Control.
# The image contains no Cruise Control configuration: mount your own at /cc/config (see docker/README.md).
FROM amazoncorretto:21-alpine AS runtime
RUN apk add --no-cache bash
WORKDIR /cc
COPY --from=build /workspace/cruise-control/build/ /cc/cruise-control/build/
COPY --from=build /workspace/kafka-cruise-control-start.sh /cc/
COPY docker/log4j2.properties /cc/log4j2.properties
ENV KAFKA_LOG4J_OPTS="-Dlog4j.configurationFile=file:/cc/log4j2.properties"
EXPOSE 9090
CMD ["./kafka-cruise-control-start.sh", "config/cruisecontrol.properties", "9090"]
