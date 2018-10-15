#!/bin/bash

for switch in $(seq 1 6)
do
	echo "reseting ports for switch $switch..."
	for port in $(seq 1 24)
	do
		./port_update.pl $switch $port 1
	done
done

echo "done"

