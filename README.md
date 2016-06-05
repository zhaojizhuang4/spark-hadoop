# Apache Spark

An [Apache Spark](http://spark.apache.org/) container image for development and testing purposes. The image is meant to be used for creating an standalone cluster with one or several workers.

- [`1.5` (Dockerfile)](https://github.com/SingularitiesCR/spark-docker/blob/1.5/Dockerfile)
- [`1.6` (Dockerfile)](https://github.com/SingularitiesCR/spark-docker/blob/1.6/Dockerfile)

## Entrypoint

The default entrypoint is set to run with the command `master` or `worker`.

The `master` command will create a Spark master with an HDFS name node. It is advised to set an explicit hostname when running a master since HDFS might not support the hostnames generated by Docker.

The `worker` command will create a Spark worker with an HDFS data node. In order for the worker to find the master the hostname or IP Address must be specified as part of the command.

## Spark user

The image has a user named `spark`, who runs the main processes; nevertheless, the entrypoint script is run as `root`. This is necessary to ensure that the mounted volumes always have the appropriate owner and group.

## Creating a Cluster with Docker Compose

The easiest way to create a standalone cluster with this image is by using [Docker Compose](https://docs.docker.com/compose). The following snippet can be used as a `docker-compose.yml` for a simple cluster:

```YAML
version: "2"

services:
  sparkmaster:
    image: singularities/spark
    command: master
    hostname: sparkmaster
    ports:
      - "6066:6066"
      - "7070:7070"
      - "8080:8080"
      - "50070:50070"
  sparkworker:
    image: singularities/spark
    command: worker sparkmaster
    environment:
      SPARK_WORKER_CORES: 1
      SPARK_WORKER_MEMORY: 2g
    links:
      - sparkmaster
```

*All Spark and HDFS ports are exposed by the image. In the example compose file we only map the Spark submit ports and the ports for the web clients.*

### Persistence

The image has a volume mounted at `/opt/hdfs` in order to maintain states between restarts. Mount a volume at this location if you wish to map the HDFS data to your machine. This should be done for the master service and the worker services.

### Scaling

If you wish to increase the number of workers the `sparkworker` service can be scale using the `scale` command like follows:

```sh
docker-compose scale sparkworker=2
```

The workers will automatically register themselves with the master node.

## Versions

This version of the container image uses the following components:

- Java: `OpenJDK 8 JRE`
- Hadoop: `2.7.2 `
