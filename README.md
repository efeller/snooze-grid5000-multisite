# snoozedeploy

The Snooze Grid`5000 multi site deployement script

## Installation and Usage

Configure the proxy : 

  (frontend)$ export https_proxy="http://proxy:3128"

On a grid5000 frontend in your home directory :

  (frontend)$ git clone https://github.com/msimonin/snooze-grid5000-multisite.git 

Download latest version of debian package (snoozenode is require, snoozeclient is optional) : 

  (frontend)$ cd snooze-grid5000-multisite.git
  (frontend)$ wget https://ci.inria.fr/snooze-software/job/master-snoozenode/ws/distributions/deb-package/snoozenode_1.1.0-0_all.deb  
  (frontend)$ wget https://ci.inria.fr/snooze-software/job/master-snoozeclient/ws/distributions/deb-package/snoozeclient_1.1.0-0_all.deb  

Other packages could be found in https://ci.inria.fr/snooze-software/.

Place them in ~/snooze-grid5000-multisite/grid5000/deployscript/deb_packages/.

Make a reservation : 

  (frontend)$ oargridsub -t deploy -w 1:00:00 rennes:rdef="{\\\\\\\"type='kavlan-global'\\\\\\\"}/vlan=1+/slash_22=1+/nodes=3",lyon:rdef=/nodes=3,sophia:rdef=/nodes=3 > ~/oargrid.out

NB : the file oargrid.out is used by the script so it must be placed in your home directory.

Configure the number of nodes in the **settings.sh**.

  (frontend)$ cd ~/snooze-grid5000-multisite/grid5000/deployscript/
  (frontend)$ vi scripts/settings.sh

  number_of_bootstrap_nodes=1
  number_of_group_managers=2
  number_of_local_controllers=5

NB : Since we use a "service node" for the deployment you will get a Snooze cluster running with n-1 nodes.

Launch the automatic script :

  (frontend)$ ./snooze_deploy.sh -a

Connection to the service node : 

  (frontend)$ cat tmp/service_node.txt
  (frontend)$ ssh -l root <service node>

Connection to the first bootstrap : 
 
  (service)$ cd /tmp/service/snooze-grid5000-multisite/grid5000/deployscript/
  (service)$ cat tmp/bootstrap_nodes.txt
  (service)$ ssh -l root <first bootstrap>

Launching VMs : 

The first bootstrap node host some helper to launch VMs.

  (bootstrap)$ cd /tmp/snooze/experiments
  (bootstrap)$ ./experiments -c test 5
  (bootstrap)$ snoozeclient start -vcn test

These commands will create and start 10 VMs.

Visualizing the system : 
Make a tunnel from your laptop to the bootstrap through the grid'5000 frontend on port 5000. If snoozeclient is installed on your PC, you can launch :
  (PC) snoozeclient visualize.

## Copyright

Snooze is copyrighted by INRIA and released under the GPL v2 license (see LICENSE.txt for details). It is registered at the APP (Agence de Protection des Programmes)
under the number IDDN.FR.001.100033.000.S.P.2012.000.10000

