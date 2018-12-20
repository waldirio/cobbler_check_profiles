#!/bin/bash


DIR="/var/lib/cobbler/config/profiles.d"
LOG="/var/log/db_update.log"

update_db()
{
  name=$1
  uid=$2
  org=$3
 
  echo "updating uid: $uid from name: $name"								| tee -a $LOG
  echo "echo \"update rhnksdata set cobbler_id = '$uid' where label = '$name' and org_id='$org'\" | spacewalk-sql -i"	| tee -a $LOG
  echo "update rhnksdata set cobbler_id = '$uid' where label = '$name' and org_id='$org'" | spacewalk-sql -i	| tee -a $LOG
}

check_uid()
{
  name=$1
  uid=$2
  org=$3

  #echo - $name
  #echo - $uid
  
  db_cobbler_id=$(echo "select id, ks_type, org_id, label, kscfg, cobbler_id from rhnksdata \
			where label = '$name' and org_id='$org'" | spacewalk-sql -i | cut -d\| -f6 | grep -v ^$ \
			| grep -v ^- | grep -v ^\( | grep -v cobbler_id | sed -e 's/^ //g')

  if [ $uid == $db_cobbler_id ]; then
    echo "uid similar for name: $name and uid: $uid"							| tee -a $LOG
  else
    echo "uid different! name/org/uid/db_cobbler_id"							| tee -a $LOG
    echo "$name/$org/$uid/$db_cobbler_id"								| tee -a $LOG
    echo "Let's update the DB"										| tee -a $LOG
    update_db $name $uid $org
  fi

}



echo $(date)												| tee -a $LOG
ls -1 $DIR/*.json | while read line
do
  full_result=$(cat "$line" | python -m json.tool | grep -E '(uid|"name"|"kickstart")')
  ks=$(echo $full_result | cut -d, -f1)
  name=$(echo $full_result | cut -d, -f2 | cut -d\" -f4 | cut -d: -f1)
  org=$(echo $full_result | cut -d, -f2 | cut -d\" -f4 | cut -d: -f2)
  uid=$(echo $full_result | cut -d, -f3 | cut -d: -f2 | cut -d\" -f2)

#  echo $name
#  echo $org
  check_uid $name $uid $org
  echo													| tee -a $LOG
done
echo $(date)												| tee -a $LOG
