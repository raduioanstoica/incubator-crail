#!/bin/bash
parent_dir="/home/rst/WORK/PROJECTS/CRAIL/code"
source_dirs="crail spark-io crail-terasort crail-netty crail-objectstore disni darpc stocator-1.0.9 stocator-s3-1.4 spark-2.1.1-bin-without-hadoop hadoop-2.8.1"
dest_dir=`pwd`/crail-jars
jar_ban_file=/home/rst/WORK/PROJECTS/CRAIL/code/crail-objectstore/scripts/crail-hadoop2.7-spark-2.1_jar_ban_list.txt

rm -rf $dest_dir
mkdir $dest_dir
for src in $source_dirs; do
	echo " --- Copying jars from $parent_dir/$src"
	jars=`find $parent_dir/$src -name $pat*.jar`
	for j in $jars; do
		fn=$(basename $j)
		if [ -f $dest_dir/$fn ]; then
			# Check if jar file exists and if the two version are the same
			./compare_jar_contents.sh  $dest_dir/$fn $j > /tmp/out
			if [ "$?" != "0" ]; then
				echo "Jar contents mismatch:  $dest_dir/$fn $j. Reason:"
				cat /tmp/out
			fi
		else
			#libname=$(echo $fn | sed 's/[0-9\-\.]*//g')			
			#if ls $dest_dir/*$libname*.jar > /dev/null 2>&1 ; then
			#	echo "Jar version mismatch -- dependency $libname$"
			#	ls $dest_dir/*$libname*.jar
			#	ls $j		
			#fi
			cp $j $dest_dir/
		fi
	done
done

#./validate_dependencies.sh $dest_dir

echo "Applying jar ban list "
badjars=$(cat $jar_ban_file)
#for j in $badjars; do
#	rm -rf $dest_dir/$j
#done

./validate_dependencies.sh $dest_dir
