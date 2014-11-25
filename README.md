Introduction
============

This is an automated system for the installation of the [Redmine](http://www.redmine.org) project management server in arbitrary environment. [Vagrant](https://www.vagrantup.com/) is used to setup development environment.  [Sensible](http://www.ansible.com) is used for provisioning of software components on empty operating system in all environments.

Quick start
===========

Clone the repository:
   
    git clone https://github.com/majkinetor/redserver.git
    cd redserver/vagrant

Provision virtual machines:

    vagrant up

Provision redserver:

    vagrant ssh dominator -c "cd /ansible && ansible-playbook -i hosts_vagrant site.yml"

Verify that redmine is running:

    vagrant ssh redserver -c "sudo docker logs -f redmine"


Installation Details
====================

Setup requires Internet connection for all involved machines as various components pull their packages (docker, bundler, yum ...). If you have proxy in the environment make sure that [proxy environment variables](http://www.gnu.org/software/wget/manual/html_node/Proxies.html) are set in the console. This is usually already set in Linux like systems, but on Windows you will need to do this manually. 

Password is used for authentication. You can specify it in the ansible inventory files (`hosts_vagrant` and `hosts_prod`) or specify it using `-k (--ask-password`) parameter.

Prerequisites for testing
--------------------------

- Any x64 operating system.
- VirtualBox 3.18+.
- Vagrant 1.6+.
- If you have proxy, environment variables should be already defined. 

Prerequisites for production server
-----------------------------------

- CentOS 6.6.
- `sshd` with `root` password access enabled for ansible provisioning.
- If you have proxy, environment variables should be already defined in `/etc/environment`.


Provisioning
------------

- Open shell in vagrant directory and type `vagrant up`. This will create 2 machines - *dominator* and *redserver*. Dominator is used as an ansible master and its sole purpose is to provision ansible playbooks to redserver. Redserver is actual server that runs the Redmine web application in docker container which is linked to mysql container. Vagrantfile requires some plugins which will be automatically installed when you `up` it. After machines are provisioned both servers will contain bare minimum for ansible to work correctly.
- Once machines are up and running (`vagrant status`) you can use dominator to provision ansible playbook to redserver. Connect to dominator, cd to `/ansible` directory and then provision redserver. Examples:

```sh
# connect to dominator and provision everything in one line
vagrant ssh dominator -c "cd /ansible && ansible-playbook -i hosts_vagrant site.yml"

# provison only mysql and redmine docker services
ansible-playbook -i hosts_vagrant site.yml -t mysql,redmine

# Ask for root password so you don't have to specify it in hosts_prod
ansible-playbook -i hosts_prod site.yml -k

# Install latest kernel for docker
ansible-playbook -i hosts_vagrant site.yml -k -e latest_kernel=True
```

The following tags can be used to limit provisioning: `base`, `docker`, `mysql`, `redmine`, `redmine-data`.

Server is now ready. Access it via [http://redserver](http://redserver) or its IP address. Check it out by using administrative commands as `root` user:  

```sh
vagrant ssh redserver       # Connect to redserver
sudo su                     # Become root

d ps                        # List running containers 
d logs -f redmine           # Redmine supervisor logs
e redmine                   # Enter container 

service mysql restart       # docker mysql service, must be started before redmine for linking 
service redmine restart     # docker redmine service 
```

Configuration
=============

Vagrant
-------

- **Constant PUBLIC**  
In `Vagrantfile`, set it to true to create `public_network` with IP issued by a DHCP or false to create host only network. The default is `false` - private network will be created with the hard coded IP addresses 193.168.0.10 & 11 for dominator and redserver. Vagrant plugin [vagrant-hostsupdater](https://github.com/cogitatio/vagrant-hostsupdater) adds this IP to hosts files so that you can access server using names defined in Vagrantfile (this works only for private network).
- **PROXY variables**  
Plugin [vagrant-proxyconf](https://github.com/tmatilai/vagrant-proxyconf) is used to propagate local proxy config which it gets from standard linux environment variables to all virtual machines. In Windows, define those manually.
- **Vagrant plugins**  
You can disable automated plugin download if you comment out line `plugins` close to the start of the `Vagrantfile`. This will disable some features, most notably Windows provisioning for dominator may fail because Virtualbox feature "shared folders" requires synchronization between Virtualbox version and its Guest tools. This process is otherwise automated using [vagrant-vbguest](https://github.com/dotless-de/vagrant-vbguest)

Ansible
-------

There are 4 ansible roles that you can somewhat customize.

- **base**  
Role used to setup users and basic packages. Customize users and packages, default values are in file `default\main.yml`. You can override them in `site.yml` file `vars` section. Of interest are:  
  - `latest_kernel`  
    False by default, it can be used to install latest CentOS 6 mainline kernel from ELRepo because docker may work better with it.  
  - `packages`  
    Array containing list of base packages to install on redserver.  
  - `users`  
    Array of users with groups to be created on redserver. 
- **docker**  
Role used to install and setup docker and its shell aliases.
- **docker_mysql**  
Role used to install mysql container and init.d service. In its `vars\main.yml` customize container name and version. If you change container name it should conform to certain linking scheme (see [sameersbn/docker-redmine](https://github.com/sameersbn/docker-redmine)). The role exposes command `crete-db <name> <user> <pwd>` that other roles can use.
- **docker_redmine**  
Role used to install redmine container and service. In its `vars\main.yml` customize SMTP & database settings and container name and version. In `files` folder you can customize redmine plugins and languages (see bellow). 

Keep in mind that provisioning take extended time to finish. On first start redmine will take longer to start as it must install plugins. To make sure redserver is started check out logs:

    vagrant ssh redserver -C "sudo docker logs -f redmine"

Normally, this log ends with:

    2014-11-23 13:59:39,168 INFO success: unicorn entered RUNNING state, process has stay


Redmine Plugins
---------------

Script `roles\docker_redmine\files\data\plugins\redmine-plugins-install.sh` is used on `dominator` to obtain latest plugin versions from the Internet. It is invoked automatically if the redmine plugins directory doesn't contain file named `init` which is generated by the mentioned script. Current plugin folders will be deleted if needed. Edit the script to add more plugins and fix Gemfile problems (redundant gems, version conflicts etc..).

To customize plugins either edit the `redmine-plugins-install.sh` script, or, if plugins are already obtained, delete undesired plugin folders. If this is done after the redserver is already provisioned you must also delete redmine database or use script `redmine-plugin-rm <PLUGIN_NAME>`(script implements uninstallation as described [here](https://github.com/sameersbn/docker-redmine#uninstalling-plugins)). Just deleting plugin directory will not remove plugin database enteries which may or may not prevent redmine from working depending on plugin.

Directory `files/lang` contains plugin localisations.

Data
====

Database is in `/opt/redmine/data`. If it doesn't exist it will be created when `mysql` service starts.

Redmine data are `/opt/redmine/data`. Backup `/files` directory periodically which keeps redmine attachments and uploads.

Notes
=====

- Redmine is started by `supervisor` which starts `unicorn` (config: `/home/redmine/redmine/config/unicorn.rb`). Nginx serves static content.
- Dominator is used as ansible master instead of vagrant ansible provisioning directly on the redserver to be able to mimic production settings better and to avoid installing packages required by ansible master only.

