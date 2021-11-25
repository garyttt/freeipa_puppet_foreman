#! /bin/bash
FILE=templates/hostgroup.ipa
while IFS= read -r LINE
do
  echo $LINE
  HOSTGROUP=`echo $LINE | cut -d':' -f1`
  MEMBERS=`echo $LINE | cut -d':' -f2`
  for host in `echo ${MEMBERS} | tr ',' ' '`
  do
    ipa hostgroup-show $HOSTGROUP
    if [ $? -eq 0 ]; then
      ipa hostgroup-add-member ${HOSTGROUP} --hosts=$host
    fi
  done
done < $FILE
