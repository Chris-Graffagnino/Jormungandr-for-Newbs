#!/bin/bash

# Author: Andrew Westberg

cp /home/$USERNAME/files/node-config.yaml /home/$USERNAME/files/node-config.yaml.new

# find all addresses that are not commented out
sed -e '/ address/!d' -e '/^[[:space:]]*#/d' -e '/Brainy/d' -e 's@^.*/ip./\([^/]*\)/tcp/\([0-9]*\).*@\1 \2@' /home/$USERNAME/files/node-config.yaml | \
while read addr port
do
    echo "Checking $addr:$port"
    RESULT=$(tcpping -x 1 $addr $port)
    echo "$RESULT"
    if [[ ! $RESULT == *"open"* ]]; then
      # comment out the line
      sed -i -e "/.*$addr\/tcp\/$port/,+1 s/^/#&/" /home/$USERNAME/files/node-config.yaml.new
    fi
done

# find all addresses that are commented out
sed -e '/ address/!d' -e '/^[[:space:]]*#/!d' -e '/Brainy/d' -e 's@^.*/ip./\([^/]*\)/tcp/\([0-9]*\).*@\1 \2@' /home/$USERNAME/files/node-config.yaml | \
while read addr port
do
    echo "Checking $addr:$port"
    RESULT=$(tcpping -x 1 $addr $port)
    echo "$RESULT"
    if [[ $RESULT == *"open"* ]]; then
      sed -i -e "/.*$addr\/tcp\/$port/,+1 s/^#//" /home/$USERNAME/files/node-config.yaml.new
    fi
done
mv /home/$USERNAME/files/node-config.yaml.new /home/$USERNAME/files/node-config.yaml
