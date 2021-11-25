#! /bin/bash
FILE=templates/hostgroup.ipa
while IFS= read -r LINE
do
  echo $LINE
  HOSTGROUP=`echo $LINE | cut -d':' -f1`
  ipa hostgroup-show $HOSTGROUP 
  if [ $? -ne 0 ]; then
    ipa hostgroup-add $HOSTGROUP
  fi
done < $FILE
