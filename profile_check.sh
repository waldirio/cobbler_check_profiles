#!/bin/bash

DIR="/var/lib/cobbler/config/profiles.d"
LOG="/var/log/profile_update.log"

PROF_LIST="/tmp/cobbler_profile_list.log"
cobbler profile list | sed -e 's/^ *//g' >/tmp/cobbler_profile_list.log

fix_profile()
{
  distro=$1
  ks=$2
  name=$3

  echo "## Fixing profile $name"									| tee -a $LOG
  echo "cobbler profile add --name=$name --distro=$distro --kickstart=$ks"				| tee -a $LOG

  if [ $fix_me == true ]; then
    echo "Fix Me ENABLED, creating the profile $name based on the json file"				| tee -a $LOG
    cobbler profile add --name=$name --distro=$distro --kickstart=$ks					| tee -a $LOG
  fi

}

check_file()
{
  distro=$1
  ks=$2
  name=$3
  file_name=$4

  check_on_profile_file=$(grep $name $PROF_LIST | wc -l)

  if [ $check_on_profile_file -eq 1 ]; then
    echo "$name is on the Cobbler Profile List"								| tee -a $LOG
    #:
  else
    echo "$name IS NOT on the Cobbler Profile List"							| tee -a $LOG
    fix_profile $distro $ks $name
  fi
}



## Main
fix_me=false

if [ "$1" == "--fix" ]; then
  fix_me=true
  echo "fix_me value: $fix_me"
else
  echo "fix_me value: $fix_me"
fi

echo $(date)												| tee -a $LOG
count_total_json=$(ls -1 $DIR/*.json | wc -l)
count_total_cobbler=$(wc -l $PROF_LIST | awk '{print $1}')

echo "Total JSON Files ........: $count_total_json"							| tee -a $LOG
echo "Total Cobbler Profiles ..: $count_total_cobbler"							| tee -a $LOG
echo													| tee -a $LOG
echo													| tee -a $LOG

ls -1 $DIR/*.json | while read line
do
  file_name=$line
  full_result=$(cat "$line" | python -m json.tool | grep -E '(name"|distro|kickstart")')
  distro=$(echo $full_result | cut -d, -f1 | cut -d\" -f4)
  ks=$(echo $full_result | cut -d, -f2 | cut -d: -f2 | cut -d\" -f2)
  name=$(echo $full_result | cut -d, -f3 | cut -d\" -f4)


#  echo distro - $distro
#  echo ks - $ks
#  echo name - $name
#  echo file name - $file_name
  check_file $distro $ks $name $file_name
done
echo $(date)												| tee -a $LOG
