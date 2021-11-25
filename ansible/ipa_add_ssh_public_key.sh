#! /bin/bash
[ $# -le 1 ] && echo "$0 [local_account] [IPA_account]" && exit 1
ipa user-mod $2 --sshpubkey="$(cat /home/$1/.ssh/id_rsa.pub)"
