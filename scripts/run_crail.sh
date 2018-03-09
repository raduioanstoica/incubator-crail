#!/bin/bash

trap 'killall' INT

killall() {
    trap '' INT TERM     # ignore INT and TERM while shutting down
    echo "**** Shutting down... ****"     # added double quotes
    kill -TERM 0         # fixed order, send TERM not INT
    wait
    echo DONE
}

set -e
script_dir=$(dirname $0)
top_dir=${1:-`pwd`}
test_dir="$top_dir/deployment/test"
export CRAIL_HOME=$test_dir/crail

#setup
rm -rf $test_dr
rm -rf $CRAIL_HOME
mkdir -p $test_dir
mvn -DskipTests install -Phadoop-2.8
cp -r $top_dir/assembly/target/crail-1.0-bin $CRAIL_HOME
cp -r $top_dir/test/object/conf/* $CRAIL_HOME/conf/
mkdir -p $CRAIL_HOME/data
mkdir -p $CRAIL_HOME/logs

if [ -f `which ttab` ]; then 
    echo "Launching crail processes in new tabs"
    ttab -a iTerm2 -t minio -d $CRAIL_HOME ". conf/crail-env.sh ; minio server $CRAIL_HOME/data"
    sleep 0.25
    ttab -a iTerm2 -t namenode -d $CRAIL_HOME ". conf/crail-env.sh ; bin/crail namenode"
    ttab -a iTerm2 -t datanode -d $CRAIL_HOME ". conf/crail-env.sh ; bin/crail datanode"
    ttab -a iTerm2 -t crailclient -d $CRAIL_HOME ". conf/crail-env.sh "
else 
    # o "Namenode exited" &
    #$CRAIL_HOME/bin/crail datanode 2>&1 > $CRAIL_HOME/logs/datanode || echo "Datanode exited" &
    wait
fi
