#! /bin/bash
# Email Alert Pre-requisites for Ubuntu:
# Postfix package Mail Transfer Agent must be installed and configured 
# mailutils package which provides mailx command must be installed
FILE=templates/passwd_reset.ipa
EMAILDOMAIN=example.local
for user in `cat $FILE | egrep -v "^#|^$"`
do 
  ipa user-mod $user --random | mailx -s "Your IPA user password has been reset randomly" $user@$EMAILDOMAIN
  [ $? -eq 0 ] && echo "IPA user password has been successfully reset for $user"
  #read a
done
