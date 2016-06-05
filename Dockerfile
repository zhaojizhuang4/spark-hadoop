FROM singularities/spark
MAINTAINER zhaojizhuang

RUN apt-get update && apt-get install -y net-tools vim

COPY entrypoint.sh /opt/
COPY hadoop/*.xml /usr/local/hadoop-2.7.2/etc/hadoop/
COPY spark/* /usr/local/spark/conf/


ENTRYPOINT ["/opt/entrypoint.sh"]
EXPOSE 6066 7077 8020 8080 8081 19888 50010 50020 50070 50075 50090 4040 18080

