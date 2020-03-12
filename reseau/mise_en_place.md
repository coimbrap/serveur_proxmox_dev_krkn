# Mise en place du Réseau
Nous allons ici détaillé la configuration du réseau physique et virtuel. Il est préférable de lire la documentation sur leur topologie au préalable.

## Map des IPs principales.
Voilà les IPs attribuées aux services principaux qu'il faut impérativement respecter.

### WAN
Switch Wan VLAN 10
- IP publique ou privée selon le choix fait.

### DMZ
Switch Interne VLAN 10
- Proxmox Alpha :10.0.0.1
- Proxmox Beta : 10.0.0.2
- Firewall Alpha : 10.0.0.3
- Firewall Beta : 10.0.0.4
- HAProxy Alpha : 10.0.0.6
- HAProxy Beta : 10.0.0.7
- HAProxy VIP : 10.0.0.8
- Proxy Interne : 10.0.0.252
- DNS : 10.0.0.253
- Firewall VIP : 10.0.0.254

### PROXY
Switch Interne VLAN 20
- HAProxy Alpha : 10.0.1.1
- HAProxy Beta : 10.0.1.2
- Nginx Public Alpha : 10.0.1.3
- Nginx Public Beta : 10.0.1.4
- Mail : 10.0.1.10
- Firewall Alpha : 10.0.1.250
- Firewall Bêta : 10.0.1.251
- Proxy Interne : 10.0.1.252
- DNS : 10.0.1.253
- Firewall VIP : 10.0.0.254

### INT
Switch Interne VLAN 30
- LDAP Alpha : 10.0.2.1
- LDAP Bêta : 10.0.2.2
- LDAP VIP : 10.0.2.3
- Nginx Public Alpha : 10.0.2.4
- Nginx Public Beta : 10.0.2.5
- Mail Frontend : 10.0.2.10
- Mail Backend : 10.0.2.11
- LDAP WebUI : 10.0.2.15
- Nextcloud : 10.0.2.20
- Gitea : 10.0.2.21
- [...]
- Firewall Alpha : 10.0.2.250
- Firewall Bêta : 10.0.2.251
- Proxy Interne : 10.0.2.252
- DNS : 10.0.2.253
- Firewall VIP : 10.0.2.254


### CTF :
Switch Interne VLAN 40
- HAProxy Alpha : 10.0.3.1
- HAProxy Beta : 10.0.3.2
- Nginx CTF : 10.0.3.3
- CTFd Open : 10.0.3.10
- CTFd Special : 10.0.3.11
- Environnement Système : 10.0.3.12
- Environnement Web : 10.0.3.13
- [...]
- Firewall Alpha : 10.0.3.250
- Firewall Bêta : 10.0.3.251
- Proxy Interne : 10.0.3.252
- Firewall VIP : 10.0.3.254


### DIRTY :
Switch Interne VLAN 50
- Firewall Alpha : 10.0.4.250
- Firewall Bêta : 10.0.4.251
- Proxy Interne : 10.0.4.252
- Firewall VIP : 10.0.4.254

Pas d'autres conteneurs permanent (10.0.4.0/24)

### GRE internal
Switch Interne VLAN 100
- Alpha : 10.0.10.1
- Beta : 10.0.10.2

### CoroSync internal
Switch Administration VLAN 10
- Alpha : 10.1.1.1
- Beta : 10.1.1.2

### pfSync internal
Switch Administration VLAN 20
- Alpha : 10.1.2.1
- Beta : 10.1.2.2

### GRE admin
Switch Administration VLAN 30
- Alpha : 10.1.10.1
- Beta : 10.1.10.2

### Administration :
Switch Administration VLAN 100
- Firewall Alpha : 10.1.0.1
- Firewall Bêta : 10.1.0.2
- Proxmox Alpha : 10.1.0.3
- Proxmox Beta : 10.1.0.4
- [...]
- Proxy Interne : 10.1.0.252
- DNS : 10.1.0.253
- Firewall VIP : 10.1.0.254



# Réseau physique

La configuration et les branchement à faire sur le switch sera détaillé plus tard.

# Réseau virtuel
Cette partie consiste à mettre en place OpenvSwitch sur les deux nodes.

## Installation
Commune aux deux nodes
```
apt-get update
apt-get install openvswitch-switch
```

## Configuration de OpenvSwitch

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

allow-ovs vmbr0
iface vmbr0 inet manual
	ovs_type OVSBridge
	ovs_ports eth0

#GRE vmbr1
allow-vmbr1 vx1
iface gre1 inet static
	address  10.0.10.1
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr1
	ovs_options tag=100

#OVS Bridge interne
auto vmbr1
iface vmbr1 inet manual
	ovs_type OVSBridge
	ovs_ports bond0 vx1
  up ovs-vsctl set Bridge ${IFACE} rstp_enable=true
	up ovs-vsctl --may-exist add-port vmbr1 gre1 -- set interface gre1 type=gre options:remote_ip='10.0.10.2'
	down ovs-vsctl --if-exists del-port vmbr1 gre1

#Admin Task
allow-vmbr0 admintask
iface vmbr0task inet static
	address  10.1.0.3
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr0
	ovs_options tag=100

#Corosync
allow-vmbr0 coro
iface coro inet static
	address  10.1.1.1
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr0
	ovs_options tag=10

#pfSync
allow-vmbr0 pfsync
iface pfsync inet static
	address  10.1.2.1
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr0
	ovs_options tag=20

#GRE vmbr0
allow-vmbr0 vx2
iface vx2 inet static
	address  10.1.10.1
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr0
	ovs_options tag=30

#OVS Bridge administation
auto vmbr0
iface vmbr0 inet manual
	ovs_type OVSBridge
	ovs_ports eth2 vx2
	up ovs-vsctl set Bridge ${IFACE} rstp_enable=true
	up ovs-vsctl --may-exist add-port vmbr0 gre2 -- set interface gre2 type=gre options:remote_ip='10.1.10.2'
	down ovs-vsctl --if-exists del-port vmbr0 gre2
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

allow-ovs vmbr0
iface vmbr0 inet manual
	ovs_type OVSBridge
	ovs_ports eth0

#GRE vmbr1
allow-vmbr1 vx1
iface gre1 inet static
	address  10.0.10.2
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr1
	ovs_options tag=100

#OVS Bridge interne
auto vmbr1
iface vmbr1 inet manual
	ovs_type OVSBridge
	ovs_ports bond0 vx1
  up ovs-vsctl set Bridge ${IFACE} rstp_enable=true
	up ovs-vsctl --may-exist add-port vmbr1 gre1 -- set interface gre1 type=gre options:remote_ip='10.0.10.1'
	down ovs-vsctl --if-exists del-port vmbr1 gre1

#Admin Task
allow-vmbr0 admintask
iface coro inet static
	address  10.1.0.4
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr0
	ovs_options tag=100

#Corosync
allow-vmbr0 coro
iface coro inet static
	address  10.1.1.2
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr0
	ovs_options tag=10

#pfSync
allow-vmbr0 pfsync
iface pfsync inet static
	address  10.1.2.2
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr0
	ovs_options tag=20

#GRE vmbr0
allow-vmbr0 vx2
iface vx2 inet static
	address  10.1.10.2
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr0
	ovs_options tag=30

#OVS Bridge administation
auto vmbr0
iface vmbr0 inet manual
	ovs_type OVSBridge
	ovs_ports eth2 vx2
	up ovs-vsctl set Bridge ${IFACE} rstp_enable=true
	up ovs-vsctl --may-exist add-port vmbr0 gre2 -- set interface gre2 type=gre options:remote_ip='10.1.10.1'
	down ovs-vsctl --if-exists del-port vmbr0 gre2
```
