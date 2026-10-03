# Running Cruise Control in a container

## Build the image

```sh
docker build -t cruise-control .
```

Run this from the repository root.
Docker is the only prerequisite: the image builds Cruise Control from source.

## Provide your configuration

The image contains **no Cruise Control configuration**.
You must mount your own config directory at `/cc/config`.
Without it, the container fails at startup.

The directory must contain:

- `cruisecontrol.properties`, with at least `bootstrap.servers` and `capacity.config.file` set for your cluster.
- Every file `cruisecontrol.properties` refers to, e.g. the capacity file (`capacity.json`, `capacityJBOD.json` or `capacityCores.json`) and `clusterConfigs.json`.
  Relative paths are resolved from `/cc`, so `capacity.config.file=config/capacity.json` points at `/cc/config/capacity.json`.
- Optionally `cruise_control_jaas.conf`, which the start script picks up automatically.

Use the repository's [`config/`](../config) directory as a template.
Do not use its values unchanged: `bootstrap.servers` points at `localhost`, and the capacity files describe example brokers.

```sh
docker run -p 9090:9090 \
  -v $(pwd)/my-config:/cc/config \
  cruise-control
```

## Pass environment variables

Use environment variables for values that differ per environment or are secret, and keep the rest in your config files.

### In `cruisecontrol.properties`

Any value can reference an environment variable with `${env:NAME}`:

```properties
bootstrap.servers=${env:BOOTSTRAP_SERVERS}
webserver.ssl.keystore.password=${env:KEYSTORE_PASSWORD}
```

```sh
docker run -p 9090:9090 \
  -v $(pwd)/my-config:/cc/config \
  -e BOOTSTRAP_SERVERS=kafka-1:9092,kafka-2:9092 \
  -e KEYSTORE_PASSWORD=... \
  cruise-control
```

If a referenced variable is not set, the value is used as-is, e.g. the literal `${env:BOOTSTRAP_SERVERS}`.

### For the JVM

The start script reads these variables:

| Variable                     | Purpose                                         | Default in the image                       |
|:-----------------------------|:------------------------------------------------|:-------------------------------------------|
| `KAFKA_HEAP_OPTS`            | Heap settings                                   | `-Xmx1G`                                   |
| `KAFKA_JVM_PERFORMANCE_OPTS` | GC and other JVM tuning                         | G1 settings from the start script          |
| `KAFKA_OPTS`                 | Any other JVM options                           | empty                                      |
| `JMX_PORT`                   | Port for Cruise Control's JMX metrics           | not set                                    |
| `KAFKA_LOG4J_OPTS`           | Log4j2 configuration                            | `/cc/log4j2.properties`, console only      |

To use your own logging configuration, put `log4j2.properties` in your config directory and set:

```sh
-e KAFKA_LOG4J_OPTS="-Dlog4j.configurationFile=file:/cc/config/log4j2.properties"
```

## Persist state

`failed.brokers.file.path` defaults to `/cc/fileStore/failedBrokers.txt`.
Mount a volume there to keep the failed-broker list across restarts:

```sh
-v cc-filestore:/cc/fileStore
```
