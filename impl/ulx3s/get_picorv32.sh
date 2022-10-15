#!/bin/bash

if [ -d picorv32 ]
then
	rm -rf picorv32
fi

mkdir -p picorv32

wget https://github.com/YosysHQ/picorv32/archive/refs/heads/master.zip

unzip master.zip -d picorv32

rm -f master.zip

touch picorv32/picorv32-master/picorv32.v
