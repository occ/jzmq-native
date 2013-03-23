#!/usr/bin/env bash

I=1
gzip -9 -c $1 | base64 -b 79 | \
while read d; do
  echo DEPLOY_KEY_${I}=$d | travis encrypt --add
  I=`expr $I + 1`
done

