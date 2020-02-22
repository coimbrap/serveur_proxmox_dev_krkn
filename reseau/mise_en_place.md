# Mise en place du Réseau
Nous allons ici détaillé la configuration du réseau physique et virtuel. Il est préférable de lire la documentation sur leur topologie au préalable.

## Map des IPs principales.
Voilà les IPs attribuées aux services principaux qu'il faut impérativement respecter.
### DMZ
- Firewall Alpha : 10.0.0.1
- Firewall Beta : 10.0.0.2
- Firewall VIP : 10.0.0.3
- HAProxy Alpha : 10.0.0.4
- HAProxy Beta : 10.0.0.5
- HAProxy VIP : 10.0.0.6
- Proxy Interne : 10.0.0.7
- Mail : 10.0.0.10

### PROXY
- HAProxy Alpha : 10.0.1.1
- HAProxy Beta : 10.0.1.2
- Nginx Public Alpha : 10.0.1.3
- Nginx Public Beta : 10.0.1.4

### INT
- LDAP Alpha : 10.0.2.1
- LDAP Bêta : 10.0.2.2
- LDAP VIP : 10.0.2.3
- Nginx Public Alpha : 10.0.2.4
- Nginx Public Beta : 10.0.2.5
- [...] Voir DNS

### CTF :
- HAProxy Alpha : 10.0.3.1
- HAProxy Beta : 10.0.3.2
- Nginx CTF : 10.0.3.3
- CTFd Open : 10.0.3.10
- CTFd Special : 10.0.3.11
- Environnement Système : 10.0.3.12
- Environnement Web : 10.0.3.13
- [...] Rajout possible

### GRE internal
- Alpha : 10.0.4.1
- Beta : 10.0.4.2

### CoroSync internal
- Alpha : 10.0.5.1
- Beta : 10.0.5.2

### pfSync internal
- Alpha : 10.0.6.1
- Beta : 10.0.6.2

### GRE admin
- Alpha : 10.0.7.1
- Beta : 10.0.7.2

### Administration :
- Firewall Alpha : 10.1.0.1
- Firewall Bêta : 10.1.0.2
- Proxmox Alpha : 10.1.0.3
- Proxmox Beta : 10.1.0.4
- [...] Voir DNS


# Réseau physique

La configuration et les branchement à faire sur le switch sera détaillé plus tard.

# Réseau virtuel
Cette partie consiste à mettre en place OpenvSwitch sur les deux nodes.

## Installation
Commune aux deux nodes
```
apt-get update
apt-get install openvswitch-switch
```

## Configuration de OpenvSwitch

### Pour Alpha (/etc/network/interfaces)
```
#Bond eth1/eth3 pour interne
allow-interne bond0
iface bond0 inet manual
	ovs_bonds eth1 eth3
	ovs_type OVSBond
	ovs_bridge interne
	ovs_options bond_mode=active-backup

auto lo
iface lo inet loopback

iface eth0 inet manual

iface eth1 inet manual

iface eth2 inet manual

iface eth3 inet manual


#WAN OPNSense
auto wan
iface wan inet manual
	ovs_type OVSBridge
	ovs_ports eth0


#GRE interne
allow-interne vx1
iface gre1 inet static
	address  10.0.4.1
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge interne
	ovs_options tag=100

#OVS Bridge interne
auto interne
iface interne inet manual
	ovs_type OVSBridge
	ovs_ports bond0 vx1
  up ovs-vsctl set Bridge ${IFACE} rstp_enable=true
	up ovs-vsctl --may-exist add-port interne gre1 -- set interface gre1 type=gre options:remote_ip='10.0.4.2'
	down ovs-vsctl --if-exists del-port interne gre1


#Admin Task
allow-admin admintask
iface admintask inet static
	address  10.1.0.1
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge admin
	ovs_options tag=10

#Corosync
allow-admin coro
iface coro inet static
	address  10.0.5.1
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge admin
	ovs_options tag=10

#pfSync
allow-admin pfsync
iface pfsync inet static
	address  10.0.6.1
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge admin
	ovs_options tag=30

#GRE admin
allow-admin vx2
iface vx2 inet static
	address  10.0.7.1
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge admin
	ovs_options tag=100

#OVS Bridge administation
auto admin
iface admin inet manual
	ovs_type OVSBridge
	ovs_ports eth2 vx2
	up ovs-vsctl set Bridge ${IFACE} rstp_enable=true
	up ovs-vsctl --may-exist add-port admin gre2 -- set interface gre2 type=gre options:remote_ip='10.0.7.2'
	down ovs-vsctl --if-exists del-port admin gre2
```

### Pour Beta (/etc/network/interfaces)
```
#Bond eth1/eth3 pour interne
allow-interne bond0
iface bond0 inet manual
	ovs_bonds eth1 eth3
	ovs_type OVSBond
	ovs_bridge interne
	ovs_options bond_mode=active-backup

auto lo
iface lo inet loopback

iface eth0 inet manual

iface eth1 inet manual

iface eth2 inet manual

iface eth3 inet manual


#WAN OPNSense
auto wan
iface wan inet manual
	ovs_type OVSBridge
	ovs_ports eth0


#GRE interne
allow-interne vx1
iface gre1 inet static
	address  10.0.4.2
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge interne
	ovs_options tag=100

#OVS Bridge interne
auto interne
iface interne inet manual
	ovs_type OVSBridge
	ovs_ports bond0 vx1
  up ovs-vsctl set Bridge ${IFACE} rstp_enable=true
	up ovs-vsctl --may-exist add-port interne gre1 -- set interface gre1 type=gre options:remote_ip='10.0.4.1'
	down ovs-vsctl --if-exists del-port interne gre1


#Admin Task
allow-admin coro
iface coro inet static
	address  10.1.0.2
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge admin
	ovs_options tag=10

#Corosync
allow-admin coro
iface coro inet static
	address  10.0.5.2
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge admin
	ovs_options tag=10

#pfSync
allow-admin pfsync
iface pfsync inet static
	address  10.0.6.2
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge admin
	ovs_options tag=30

#GRE admin
allow-admin vx2
iface vx2 inet static
	address  10.0.7.2
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge admin
	ovs_options tag=100

#OVS Bridge administation
auto admin
iface admin inet manual
	ovs_type OVSBridge
	ovs_ports eth2 vx2
	up ovs-vsctl set Bridge ${IFACE} rstp_enable=true
	up ovs-vsctl --may-exist add-port admin gre2 -- set interface gre2 type=gre options:remote_ip='10.0.7.1'
	down ovs-vsctl --if-exists del-port admin gre2
```
