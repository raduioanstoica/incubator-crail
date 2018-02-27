#!/bin/bash

HADOOP_HOME=${HADOOP_HOME:-$1}

defaults=$(find $HADOOP_HOME -name *default.xml)

for f in $defaults; do
	echo "# Extracted from $(basename $f)"
	grep -e ":[0-9][0-9][0-9]*" $f 	| 				# get all lines that look like a hostname/IP address + port
		grep value  		|  				# keep only XML property values
		sed -e 's/[<!-]*<[!-]*value>.*:\([0-9]*\).*<\/value-*>[->]*/\1/g'	|  # extract port number
		sort -n 	|  						# sort numerically 
		tr '\r\n' ' ' 	| 					# remove new lines
		sed "s/  / /g"  | sed "s/  / /g" | sed "s/  / /g"	# remove useless spaces
        echo ""
done

