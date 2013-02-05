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
 
  copy_and_deploy_keys

  install_taktuk
  install_genisoimage
 
  copy_files

  add_route_rules_on_nodes

  echo "$log_tag +------------------------------------------------"
  echo "$log_tag | Service node is : `cat $tmp_directory/service_node.txt `"
  echo "$log_tag +------------------------------------------------"
}

prepare_snooze_system_and_launch()
{

  echo "$log_tag Launching the snooze system from : `cat $tmp_directory/service_node.txt `"
  # modify path to sthe script settings
  perl -p -e "s#^base_directory.*#base_directory=\"$exported_directory_service_node\"#" "$deploy_script_directory/scripts/settings.sh" > $tmp_directory/settings.sh
  put_taktuk "$tmp_directory/service_node.txt" "$tmp_directory/settings.sh" "$exported_directory_service_node/$relative_script_directory/scripts/settings.sh" 
  # Launch the deployment from the service
  echo "$log_tag $exported_directory_service_node/$relative_script_directory/service_node.sh -a"
  service_node=`cat $tmp_directory/service_node.txt`  
  run_taktuk_single_machine "$service_node" exec "[ $exported_directory_service_node/$relative_script_directory/service_node.sh -a ]"    
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
      scp $tmp_directory/keys/hosts_keys.pub root@$host:/root/.ssh/id_rsa.pub 
      scp $tmp_directory/keys/hosts_keys root@$host:/root/.ssh/id_rsa 
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

copy_files(){
  service_node=`cat $tmp_directory/service_node.txt`
  echo "$log_tag Copying files ..."
  run_taktuk "$tmp_directory/service_node.txt" exec "[ mkdir -p $exported_directory_service_node ]"
  rsync -avz $base_directory/$root_script_directory root@$service_node:$exported_directory_service_node/.
  rsync --progress -avz $source_images_directory root@$service_node:$exported_directory_service_node/.
}

add_route_rules_on_nodes(){
   echo "$log_tag "Adding route rules to nodes"" 
  
  source "$tmp_directory/common_network.txt"
  run_taktuk "$tmp_directory/service_node.txt" exec "[ route add -net $NETWORK netmask $NETMASK dev br100 ]" 
  run_taktuk "$tmp_directory/hosts_list.txt" exec "[ route add -net $NETWORK netmask $NETMASK dev br100 ]" 
}
