#! /bin/bash
FILE=templates/group.ipa
while IFS= read -r LINE
do
  echo $LINE
  GROUP_NAME=`echo $LINE | cut -d':' -f1`
  GROUP_MEMBERS=`echo $LINE | cut -d':' -f4`
  for user in `echo ${GROUP_MEMBERS} | tr ',' ' '`
  do
    ipa user-show $user
    if [ $? -eq 0 ]; then
      ipa group-add-member ${GROUP_NAME} --users=$user
    fi
  done
done < $FILE
