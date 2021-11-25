#! /bin/bash
FILE=templates/passwd.ipa
while IFS= read -r LINE
do
  echo $LINE
  USERNAME=`echo $LINE | cut -d':' -f1`
  UIDNUMBER=`echo $LINE | cut -d':' -f3`
  GIDNUMBER=`echo $LINE | cut -d':' -f4`
  COMMENT=`echo $LINE | cut -d':' -f5`
  HOMEDIR=`echo $LINE | cut -d':' -f6`
  LOGINSHELL=`echo $LINE | cut -d':' -f7`
  FIRST=`echo $USERNAME | cut -d'.' -f1`
  FIRST=`echo ${FIRST^}`
  LAST=`echo $USERNAME | cut -d'.' -f2-`
  LAST=`echo ${LAST^}`
  FULLNAME="$FIRST $LAST"
  ipa user-show $USERNAME
  if [ $? -ne 0 ]; then 
    ipa user-add $USERNAME --uid=$UIDNUMBER --gid=$GIDNUMBER --displayname="$COMMENT" --homedir=$HOMEDIR --shell=$LOGINSHELL \
      --first=$FIRST --last=$LAST --cn="$FULLNAME" --gecos="$COMMENT"
  fi
done < $FILE
