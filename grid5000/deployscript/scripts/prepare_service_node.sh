#!/bin/bash
#
# Copyright (C) 2011-2012 Eugen Feller, INRIA <eugen.feller@inria.fr>
# Matthieu Simonin
# This file is part of Snooze. Snooze is free software: you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation, version 2.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA
#

# Copy and install packages


prepare_service_node()
{


   local job_id=$(get_job_id)
   if [ -z "$job_id" ];
   then
     echo "$log_tag Did you connect to your job?!"
   fi
   
   local virtual_machine_subnet=$(save_virtual_machine_subnet $job_id)   
   if [ -z "$virtual_machine_subnet" ];
   then
     echo "$log_tag You must have a reservation with a subnet reserved!"
     return $error_code
   fi

  copy_and_deploy_keys

  install_taktuk
  install_genisoimage
  install_rabbitmq
 
  copy_files

  tuning_arp_on_nodes 
  
  changing_settings_file
 
  echo "$log_tag +------------------------------------------------"
  echo "$log_tag | Service node is : `cat $tmp_directory/service_node.txt `"
  echo "$log_tag +------------------------------------------------"
}

prepare_snooze_system_and_launch()
{

  echo "$log_tag Launching the snooze system from : `cat $tmp_directory/service_node.txt `"

  # Launch the deployment from the service
  echo "$log_tag $exported_directory_service_node/$relative_script_directory/service_node.sh -a"
  service_node=`cat $tmp_directory/service_node.txt`  
  run_taktuk_single_machine "$service_node" exec "[ $exported_directory_service_node/$relative_script_directory/service_node.sh -a 2> /dev/null ]"     
}
generate_keys()
{
   echo "$log_tag generating keys"
   rm -rf $tmp_directory/keys
   mkdir -p $tmp_directory/keys
   ssh-keygen -t rsa -f $tmp_directory/keys/hosts_keys -N ''
}

deploy_keys(){
   echo "$log_tag deploying keys"
   for host in $(cat $tmp_directory/hosts_list.txt)
   do
      echo "$log_tag copying keys on $host"
      scp $tmp_directory/keys/hosts_keys.pub root@$host:/root/.ssh/$ssh_private_key_name.pub 
      scp $tmp_directory/keys/hosts_keys root@$host:/root/.ssh/$ssh_private_key_name
      cat $tmp_directory/keys/hosts_keys.pub > $tmp_directory/keys/authorized_keys  
      scp $tmp_directory/keys/authorized_keys root@$host:/root/.ssh/tmp_key_file  
      ssh root@$host "cat /root/.ssh/tmp_key_file >> /root/.ssh/authorized_keys; rm /root/.ssh/tmp_key_file" 
   done
}

copy_and_deploy_keys()
{

   generate_keys
  
   deploy_keys
   
   nb_hosts=`cat $tmp_directory/hosts_list.txt | wc -l`
   service_node=` head -n 1 $tmp_directory/hosts_list.txt `
   echo $service_node > $tmp_directory/service_node.txt
   tail -n $(($nb_hosts-1)) $tmp_directory/hosts_list.txt > $tmp_directory/hosts_list.txt2
   mv $tmp_directory/hosts_list.txt2 $tmp_directory/hosts_list.txt      
 
}

install_taktuk(){
 echo "$log_tag Installing taktuk on service node `cat $tmp_directory/service_node.txt`" 
 run_taktuk "$tmp_directory/service_node.txt" exec "[ apt-get install -y --force-yes taktuk ]"
}

install_genisoimage(){
 echo "$log_tag Installing taktuk on service node `cat $tmp_directory/service_node.txt`" 
 run_taktuk "$tmp_directory/service_node.txt" exec "[ apt-get install -y --force-yes genisoimage ]"
}

install_genisoimage(){
 echo "$log_tag Installing taktuk on service node `cat $tmp_directory/service_node.txt`" 
 run_taktuk "$tmp_directory/service_node.txt" exec "[ apt-get install -y --force-yes rabbitmq-server ]"
}

copy_files(){
  service_node=`cat $tmp_directory/service_node.txt`
  echo "$log_tag Copying files ..."
  run_taktuk "$tmp_directory/service_node.txt" exec "[ mkdir -p $exported_directory_service_node ]"
  rsync -avz $base_directory/$root_script_directory root@$service_node:$exported_directory_service_node/.
  rsync --progress -avz $source_images_directory root@$service_node:$exported_directory_service_node/.
}

tuning_arp_on_nodes(){
  echo "$log_tag "Tuning ARP on nodes"" 
  run_taktuk "$tmp_directory/hosts_list.txt" exec "[ echo 4096 > /proc/sys/net/ipv4/neigh/default/gc_thresh3 ]"
  run_taktuk "$tmp_directory/hosts_list.txt" exec "[ echo 2048 > /proc/sys/net/ipv4/neigh/default/gc_thresh2 ]"
  run_taktuk "$tmp_directory/hosts_list.txt" exec "[ echo 1024 > /proc/sys/net/ipv4/neigh/default/gc_thresh1 ]"
}

changing_settings_file(){
  # modify path to sthe script settings
  perl -p -e "s#^base_directory.*#base_directory=\"$exported_directory_service_node\"#" "$deploy_script_directory/scripts/settings.sh" > $tmp_directory/settings.sh
  put_taktuk "$tmp_directory/service_node.txt" "$tmp_directory/settings.sh" "$exported_directory_service_node/$relative_script_directory/scripts/settings.sh" 
}
