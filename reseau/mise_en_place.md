# Mise en place du Réseau

Nous allons ici détaillé la configuration du réseau physique et virtuel. Il est préférable de lire la documentation sur leur topologie au préalable.

## Map des IPs principales.

Voilà les IPs attribuées aux services principaux qu'il faut impérativement respecter.

### WAN
Switch Wan VLAN 10
- IP publique ou privée selon le choix fait.

### DMZ
Switch Interne VLAN 10
- Proxmox Alpha :10.0.10.1
- Proxmox Beta : 10.0.10.2
- Firewall Alpha : 10.0.10.3
- Firewall Beta : 10.0.10.4
- HAProxy Alpha : 10.0.10.5
- HAProxy Beta : 10.0.10.6
- HAProxy VIP : 10.0.10.7
- Proxy Interne : 10.0.10.252
- DNS : 10.0.10.253
- Firewall VIP : 10.0.10.254

### INT
Switch Interne VLAN 20
- LDAP Beta : 10.0.20.1
- LDAP Beta : 10.0.20.2
- LDAP VIP : 10.0.20.3
- Mail Frontend : 10.0.20.4
- Mail Backend : 10.0.20.5
- LDAP WebUI : 10.0.20.6
- Site Web : 10.0.20.7
- Wiki : 10.0.20.8
- Nextcloud : 10.0.20.10
- Gitea : 10.0.20.11
- Mailvelope : 10.0.20.12
- Bitwarden : 10.0.20.13
- Firewall Alpha : 10.0.20.252
- Firewall Beta : 10.0.20.253
- Firewall VIP : 10.0.20.254

### CTF :
Switch Interne VLAN 30
- Nginx CTF : 10.0.30.1
- CTFd Open : 10.0.30.5
- CTFd Special : 10.0.30.6
- Environnement Système : 10.0.30.7
- Environnement Web : 10.0.30.8
- Firewall Alpha : 10.0.30.252
- Firewall Beta : 10.0.30.253
- Firewall VIP : 10.0.30.254

### DIRTY :
Switch Interne VLAN 50
- Firewall Alpha : 10.0.50.252
- Firewall Beta : 10.0.50.253
- Firewall VIP : 10.0.50.254

Pas de conteneurs permanent (10.0.50.0/24)


# Réseau virtuel
Cette partie consiste à mettre en place OpenvSwitch sur les deux nodes.

## Installation
Commune aux deux nodes
```
apt-get update
apt-get install openvswitch-switch
```

## Configuration de OpenvSwitch (a voir)

### Pour Alpha (/etc/network/interfaces)
```
#Bond eth1/eth3 pour vmbr1
allow-vmbr1 bond0
iface bond0 inet manual
	ovs_bonds eth1 eth3
	ovs_type OVSBond
	ovs_bridge vmbr1
	ovs_options bond_mode=active-backup

auto lo
iface lo inet loopback

iface eth0 inet manual

iface eth1 inet manual

iface eth2 inet manual

iface eth3 inet manual

# WAN
allow-vmbr0 wan
iface lan inet static
	address  X.X.X.X
	netmask  YY
	gateway  Z.Z.Z.Z
	ovs_type OVSIntPort
	ovs_bridge vmbr0
	ovs_options tag=10
#IP Publique

#OVS Bridge WAN
allow-ovs vmbr0
iface vmbr0 inet manual
	ovs_type OVSBridge
	ovs_ports eth0
#Switch WAN

#GRE vmbr1
allow-vmbr1 vx1
iface vx1 inet static
	address  10.0.10.1
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr1
	ovs_options tag=100
#Synchronisation Switch Interne

#DMZ vmbr1
allow-vmbr1 dmz
iface dmz inet static
	address  10.0.10.1
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr1
	ovs_options tag=10
#Accès à la DMZ

#OVS Bridge interne
auto vmbr1
iface vmbr1 inet manual
	ovs_type OVSBridge
	ovs_ports bond0 vx1 dmz
  up ovs-vsctl set Bridge ${IFACE} rstp_enable=true
	up ovs-vsctl --may-exist add-port vmbr1 gre1 -- set interface gre1 type=gre options:remote_ip='10.0.10.2'
	down ovs-vsctl --if-exists del-port vmbr1 gre1
#Switch Interne

#Corosync
allow-vmbr2 coro
iface coro inet static
	address  10.1.1.1
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr2
	ovs_options tag=10
#Synchronisation des hyperviseurs

#pfSync
allow-vmbr2 pfsync
iface pfsync inet static
	address  10.1.2.1
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr2
	ovs_options tag=20
#Synchronisation des FW

#GRE vmbr2
allow-vmbr2 vx2
iface vx2 inet static
	address  10.1.10.1
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr2
	ovs_options tag=30
#Synchronisation du switch Administration

#OVS Bridge administation
auto vmbr2
iface vmbr2 inet manual
	ovs_type OVSBridge
	ovs_ports eth2 vx2
	up ovs-vsctl set Bridge ${IFACE} rstp_enable=true
	up ovs-vsctl --may-exist add-port vmbr2 gre3 -- set interface gre3 type=gre options:remote_ip='10.1.10.2'
	down ovs-vsctl --if-exists del-port vmbr2 gre3
#Switch Administration
```

### Pour Beta (/etc/network/interfaces)
```
#Bond eth1/eth3 pour vmbr1
allow-vmbr1 bond0
iface bond0 inet manual
	ovs_bonds eth1 eth3
	ovs_type OVSBond
	ovs_bridge vmbr1
	ovs_options bond_mode=active-backup

auto lo
iface lo inet loopback

iface eth0 inet manual

iface eth1 inet manual

iface eth2 inet manual

iface eth3 inet manual

# WAN
allow-vmbr0 wan
iface lan inet static
	address  X.X.X.X
	netmask  YY
	gateway  Z.Z.Z.Z
	ovs_type OVSIntPort
	ovs_bridge vmbr0
	ovs_options tag=10
#IP Publique

#OVS Bridge WAN
allow-ovs vmbr0
iface vmbr0 inet manual
	ovs_type OVSBridge
	ovs_ports eth0
#Switch WAN

#GRE vmbr1
allow-vmbr1 vx1
iface vx1 inet static
	address  10.0.10.2
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr1
	ovs_options tag=100
#Synchronisation Switch Interne

#DMZ vmbr1
allow-vmbr1 dmz
iface dmz inet static
	address  10.0.10.2
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr1
	ovs_options tag=10
#Accès à la DMZ

#OVS Bridge interne
auto vmbr1
iface vmbr1 inet manual
	ovs_type OVSBridge
	ovs_ports bond0 vx1 dmz
  up ovs-vsctl set Bridge ${IFACE} rstp_enable=true
	up ovs-vsctl --may-exist add-port vmbr1 gre1 -- set interface gre1 type=gre options:remote_ip='10.0.10.1'
	down ovs-vsctl --if-exists del-port vmbr1 gre1
#Switch Interne

#Admin Task
allow-vmbr2 admintask
iface vmbr2 inet static
	address  10.1.0.5
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr2
	ovs_options tag=100
#Accès à la Admin

#Corosync
allow-vmbr2 coro
iface coro inet static
	address  10.1.1.2
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr2
	ovs_options tag=10
#Synchronisation des hyperviseurs

#pfSync
allow-vmbr2 pfsync
iface pfsync inet static
	address  10.1.2.2
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr2
	ovs_options tag=20
#Synchronisation des FW

#GRE vmbr2
allow-vmbr2 vx2
iface vx2 inet static
	address  10.1.10.2
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr2
	ovs_options tag=30
#Synchronisation du switch Administration

#OVS Bridge administation
auto vmbr2
iface vmbr2 inet manual
	ovs_type OVSBridge
	ovs_ports eth2 vx2
	up ovs-vsctl set Bridge ${IFACE} rstp_enable=true
	up ovs-vsctl --may-exist add-port vmbr2 gre3 -- set interface gre3 type=gre options:remote_ip='10.1.10.1'
	down ovs-vsctl --if-exists del-port vmbr2 gre3
#Switch Administration
```
