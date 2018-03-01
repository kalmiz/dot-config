#!/bin/bash

DIR=$(dirname $0)

for i in `cat $DIR/packages.txt`; do
	brew install $i
done
