#!/bin/bash

aws --endpoint-url http://192.168.10.11 s3 cp s3://vault1/$1  /tmp/tmp_obj && head -c 4096  tmp
rm -f /tmp/tmp_obj
