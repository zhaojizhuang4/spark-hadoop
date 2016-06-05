#!/usr/bin/env bash

# Read environment variables
source /etc/environment
echo 'source /etc/environment' >> /root/.bashrc 

run_master() {
  # zjz
  local svr=$1
  local ip=$(ip r | awk '/eth0/{print $9}' | tr -d '\n' | uniq)
  if [ -z "${svr}" ]; then
     svr=${ip}
  fi  

  # Start HDFS name node
  sed -i.bak "s|\[NAMENODE_HOST\]|${svr}|g" $HADOOP_CONF_DIR/core-site.xml
  rm -f $HADOOP_CONF_DIR/core-site.xml.bak
  if [ ! -f /opt/hdfs/name/current/VERSION ]; then
    hdfs namenode -format -force
  fi
  start-dfs.sh
  # zjz 
  hdfs dfs -mkdir /sparkLog
  sed -i.bak "s|\[NAMENODE_HOST\]|${svr}|g" $SPARK_HOME/conf/spark-defaults.conf
  
  # Run spark master
  # spark-class org.apache.spark.deploy.master.Master -h ${svr}
  $SPARK_HOME/sbin/start-master.sh
  $SPARK_HOME/sbin/start-history-server.sh
  while true; do sleep 1; done
}

run_worker() {
  # Check master argument
  local master=$1
  if [ -z "${master}" ]; then
    (>&2 echo "Please specify the IP or host for the Spark Master")
    exit 1
  fi
  # Wait for HDFS name node to be online
  while ! nc -z $master 50070; do
    sleep 2;
  done;
  # Start HDFS data node
  sed -i.bak "s|\[NAMENODE_HOST\]|${master}|g" $HADOOP_CONF_DIR/core-site.xml
  rm -f $HADOOP_CONF_DIR/core-site.xml.bak
  hadoop-daemon.sh start datanode
  # Wait for Spark master to be online
  while ! nc -z $master 7077; do
    sleep 2;
  done;
  # Run spark worker
  # zjz
  sed -i.bak "s|\[NAMENODE_HOST\]|${master}|g" $SPARK_HOME/conf/spark-defaults.conf
  spark-class org.apache.spark.deploy.worker.Worker spark://$master:7077
}

chown -R spark:spark /opt/hdfs
su spark
if [ "$1" == "master" ]; then
  run_master $2
elif [ "$1" == "worker" ]; then
  run_worker $2
else
  (>&2 echo "Unknown command '$1'")
  exit 1
fi
