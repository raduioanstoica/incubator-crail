#! /bin/bash

S3_ENDPOINT=${S3_ENDPOINT:="127.0.0.1:9000"}
S3_ACCESS_KEY=${MINIO_ACCESS_KEY}
S3_SECRET_KEY=${MINIO_SECRET_KEY}
TEST=${1:-"S3Test"}

cmd="mvn clean test -e -Dtest=org.apache.crail.storage.object.${TEST} -Dsurefire.useFile=false -DS3_ACCESS_KEY=${S3_ACCESS_KEY} -DS3_SECRET_KEY=${S3_SECRET_KEY} -DS3_ENDPOINT=${S3_ENDPOINT}"
eval $cmd
