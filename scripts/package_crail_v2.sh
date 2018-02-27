#!/bin/bash

#set -x
set -e 

top_dir=${1:-`pwd`/deployment}
rm -rf $top_dir/log

echo "Packaging Crail in $top_dir"

# Scala related variables.
SCALA_VERSION=2.12.2
SCALA_BINARY_ARCHIVE_NAME=scala-${SCALA_VERSION}
SCALA_BINARY_DOWNLOAD_URL=http://downloads.lightbend.com/scala/${SCALA_VERSION}/${SCALA_BINARY_ARCHIVE_NAME}.tgz

# SBT related variables.
SBT_VERSION=0.13.15
SBT_BINARY_ARCHIVE_NAME=sbt-$SBT_VERSION
SBT_BINARY_DOWNLOAD_URL=https://dl.bintray.com/sbt/native-packages/sbt/${SBT_VERSION}/${SBT_BINARY_ARCHIVE_NAME}.tgz

APACHE_MIRROR=http://mirror.switch.ch/mirror/apache

#Hadoop related variables
HADOOP_VERSION=2.8.3
HADOOP_MIRROR=${APACHE_MIRROR}/dist/hadoop/common
HADOOP_BINARY_ARCHIVE_NAME=hadoop-${HADOOP_VERSION}.tar.gz
HADOOP_BINARY_DOWNLOAD_URL=${HADOOP_MIRROR}/hadoop-${HADOOP_VERSION}

# Spark related variables.
SPARK_VERSION=2.2.1
SPARK_MIRROR=http://mirror.switch.ch/mirror/apache/dist/spark
SPARK_BINARY_ARCHIVE_NAME=spark-${SPARK_VERSION}-bin-without-hadoop.tgz
SPARK_BINARY_DOWNLOAD_URL=${SPARK_MIRROR}/spark-${SPARK_VERSION}

# Download all required packages
download_binary() {
    set +e 
    # download archive $1 from URL $2 to directory $3 and extract to directory $4
    mkdir -p $3 && wget -c $2/$1 -P $3 >> $top_dir/log 2>&1
    mkdir -p $4 && tar -k -C $4 -xzf $3/$1  >> $top_dir/log 2>&1
    set -e 
}
download_binary $HADOOP_BINARY_ARCHIVE_NAME $HADOOP_BINARY_DOWNLOAD_URL $top_dir/binaries/hadoop-${HADOOP_VERSION} $top_dir/zrl-deployment
download_binary $SPARK_BINARY_ARCHIVE_NAME  $SPARK_BINARY_DOWNLOAD_URL  $top_dir/binaries/spark-${SPARK_VERSION}   $top_dir/zrl-deployment

# package Crail
mvn package -Phadoop-2.8 -DskipTests && \
   cp -r assembly/target/crail-1.0-bin  $top_dir/zrl-deployment/crail-1.0

# complain about mismatched jars
$(dirname $0)/validate_dependencies.sh $top_dir/zrl-deployment

pushd  $top_dir/zrl-deployment  > /dev/null && \
   ln -sfn crail-* crail && \
   ln -sfn spark-* spark && \
   ln -sfn hadoop-* hadoop && \
   popd  > /dev/null

# make Crail jars available to HDFS
pushd  $top_dir/zrl-deployment/hadoop  > /dev/null && \
    mkdir -p extra-jars/crail && \
    pushd extra-jars/crail  > /dev/null && \
    ln -sfn  ../../../crail/jars/*.jar . && \
    popd  > /dev/null && popd  > /dev/null

# make Crail jars available to Spark
pushd  $top_dir/zrl-deployment/spark  > /dev/null && \
    mkdir -p extra-jars/crail && \
    pushd extra-jars/crail  > /dev/null && \
    ln -sfn  ../../../crail/jars/*.jar . && \
    popd > /dev/null && popd > /dev/null


# create basic conf/spark-defaults.conf and conf/spark-env.sh

# create basic Crail configuration files
pushd  $top_dir/zrl-deployment/crail/conf > /dev/null && \
    cp crail-site.conf.template crail-site.conf && \
    cp slaves.template slaves && \
    cp core-site.xml.template core-site.xml && \
    popd > /dev/null

# ############################################################################################
# Create container
# #################
# copy dockerfile to top level deployment directory
cp $(dirname $0)/dockerfile $top_dir
# create container and optionally push container to remote repository
crail_ver=$(mvn -Dexec.executable='echo' -Dexec.args='${project.version}' --non-recursive exec:exec -q)
ts=$(date '+%Y%m%d-%H%M%S')
local_container_name="zrl:crail-${crail_ver}-$ts"
remote_container_name="raduioanstoica/crail:crail-$ts"
docker build -t $local_container_name deployment/  
docker tag $local_container_name $remote_container_name
#docker push $remote_container_name

