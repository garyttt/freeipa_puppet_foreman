#! /bin/bash
FILE=templates/group.ipa
while IFS= read -r LINE
do
  echo $LINE
  GROUPNAME=`echo $LINE | cut -d':' -f1`
  GIDNUMBER=`echo $LINE | cut -d':' -f3`
  ipa group-show $GROUPNAME 
  if [ $? -ne 0 ]; then
    ipa group-add $GROUPNAME --gid=$GIDNUMBER
  fi
done < $FILE
