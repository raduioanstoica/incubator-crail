#!/bin/bash

#set -x
set -e 

# ############################################################################################
# Create Crail container
# #################
top_dir=${1:-`pwd`/deployment}
script_dir=$(dirname $0)
mkdir -p$top_dir
rm -rf $top_dir/container.log

$script_dir/package_crail_v2.sh $top_dir

# copy dockerfile to top level deployment directory
cp $script_dir/dockerfile $top_dir
# create container and optionally push container to remote repository
crail_ver=$(mvn -Dexec.executable='echo' -Dexec.args='${project.version}' --non-recursive exec:exec -q)
ts=$(date '+%Y%m%d-%H%M%S')
local_container_name="zrl:crail-${crail_ver}-$ts"
remote_container_name="raduioanstoica/crail:crail-$ts"
docker build -t $local_container_name deployment/  
docker tag $local_container_name $remote_container_name
#docker push $remote_container_name

