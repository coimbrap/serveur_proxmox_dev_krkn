# Le réseau
Chacune des nodes possède 4 interfaces réseau, pour des questions de redondance et de débit nous allons mettre 2 de ces interfaces en bond pour le réseau interne et la communication entre les deux serveurs.

eth0 sur une interface simple utilisé uniquement par OPNSense via vmbr0

eth2 formera le bridge OVS vmbr1

eth1 et eth3 formerons le bond OVS bond0 sur le bridge OVS vmbr2

Pour la gestion des bonds, vlans... nous utiliserons openvswitch

Explication rapide du fonctionnement global d'OpenvSwitch :
- OVS Bridge, c'est comme un switch, mais en virtualisé sur lequel on peu branché des CT et VM sur des VLANs et qui peux communiquer avec un autre Bridge via un tunnel VXLAN ou un tunnel GRE. Pour notre usage le bridge n'aura pas d'IP sur l'hôte.
- OVS Bond, permet d'attache un groupe d'interface physique à un Bridge OVS ie. un groupe d'interface réseau à un switch virtuel.
- OVS IntPort, pas possible de bridge des VMs ou des CT dessus, il permet à l'hôte de se brancher au Bridge pour avoir une IP et éventuellement une VLAN.

## Répartition des sous réseaux en VLAN et en bond
### eth0 
- VLAN 10 : WAN (Entrée du parefeu)
- VLAN 10 : Réseau privée entre les hôtes pour CARP

### vmbr1 OVS Bridge
- VLAN 10 : VXLAN 
- VLAN 20 : Corosync (Cluster Proxmox)
- VLAN 30 : pfSync (Redondance OPNSense)

### bond0 sur vmbr2 OVS Bridge sur OVS Bond
- VLAN 10 : VXLAN
- VLAN 20 : ROUTE (Sortie du parefeu)
- VLAN 30 : KRKN (Pour tout les services krhacken)
- VLAN 40 : CTF (Pour toute la partie CTF)
- VLAN 50 : EXT (Pour les VM et CT de test)

## Map des IPs principales.
### Route
- Proxmox Alpha : 10.0.0.1
- Proxmox Beta : 10.0.0.2
- HAProxy Alpha : 10.0.0.3
- HAProxy Beta : 10.0.0.4
- VIP HAProxy : 10.0.0.5
- Nginx Public Alpha : 10.0.0.6
- Nginx Public Beta : 10.0.0.7


### VXLAN vmbr1
- Alpha : 10.0.4.1
- Beta : 10.0.4.2

### CoroSync vmbr1
- Alpha : 10.0.5.1
- Beta : 10.0.5.2

### pfSync vmbr1
- Alpha : 10.0.6.1
- Beta : 10.0.6.2

### VXLAN vmbr2
- Alpha : 10.0.7.1
- Beta : 10.0.7.2

### KRKN
- Firewall Alpha : 10.0.1.1
- Firewall Bêta : 10.0.1.2
- Firewall VIP : 10.0.1.3
- LDAP Alpha : 10.0.1.4
- LDAP Bêta : 10.0.1.5
- LDAP VIP : 10.0.1.6
- Nginx Public Alpha : 10.0.1.7
- Nginx Public Beta : 10.0.1.8
- Postfix/Dovecot : 10.0.1.10
- RoundCube : 10.0.1.11
- Nextcloud : 10.0.1.12
- WebSite : 10.0.1.13
- SysPass : 10.0.1.14
- Gitea : 10.0.1.15
- Mattermost : 10.0.1.16
...

### CTF :
- Firewall Alpha : 10.0.2.1
- Firewall Bêta : 10.0.2.2
- Firewall VIP : 10.0.2.3
- HAProxy Alpha : 10.0.2.4
- HAProxy Beta : 10.0.2.5
- Nginx CTF : 10.0.2.6
- CTFd Open : 10.0.2.10
- CTFd Spécial : 10.0.2.11
- Environnement Système : 10.0.2.12
- Environnement Web : 10.0.2.13
...


## Configuration d'OpenvSwitch
- Sur eth0 le câble WAN qui bridge sur vmbr0 via un bridge Linux pour OPNSense.
- Sur eth2 un câble qui relit les deux nodes pour le corosync et pfSync via un bridge OpenvSwitch
- Sur bond0 (eth1 et eth3), avec les interfaces reliées entre elles pour le réseau interne via un bridge OpenvSwitch.

Pour attribuer une VLAN à un serveur, on utilise un Int Port avec une VLAN. Sinon on relie la VM ou le CT au bridge OpenvSwitch en spécifiant une VLAN.



### Pour Alpha (/etc/network/interfaces)
```
#Bond eth1/eth3 pour vmbr2
allow-vmbr2 bond0
iface bond0 inet manual
	ovs_bonds eth1 eth3
	ovs_type OVSBond
	ovs_bridge vmbr2
	ovs_options bond_mode=active-backup

auto lo
iface lo inet loopback

iface eth0 inet manual

iface eth1 inet manual

iface eth2 inet manual

iface eth3 inet manual

#WAN OPNSense
auto vmbr0
iface vmbr0 inet static
	address  X.X.X.X
	netmask  255.255.255.0
	gateway  Y.Y.Y.Y
	bridge-ports eth0
	bridge-stp off
	bridge-fd 0

#VXLAN vmbr1
allow-vmbr1 vx1
iface vx1 inet static
	address  10.0.4.1
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr1
	ovs_options tag=10

#Corosync
allow-vmbr1 coro
iface coro inet static
	address  10.0.5.1
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr1
	ovs_options tag=20

#pfSync
allow-vmbr1 pfsync
iface pfsync inet static
	address  10.0.6.1
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr1
	ovs_options tag=30

#VXLAN vmbr2
allow-vmbr2 vx2
iface vx2 inet static
	address  10.0.7.1
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr2
	ovs_options tag=10

#OVS Bridge vmbr1
auto vmbr1
iface vmbr1 inet manual
	ovs_type OVSBridge
	ovs_ports bond0 vx1
	up ovs-vsctl add-port vmbr1 vxlan1 -- set interface vxlan1 type=vxlan options:remote_ip=10.0.4.2 options:key=flow

#OVS Bridge vmbr2
auto vmbr2
iface vmbr2 inet manual
	ovs_type OVSBridge
	ovs_ports bond0 vx2
	up ovs-vsctl add-port vmbr1 vxlan1 -- set interface vxlan1 type=vxlan options:remote_ip=10.0.7.2 options:key=flow
```

#### Sur Beta
```
#Bond eth1/eth3 pour vmbr2
allow-vmbr2 bond0
iface bond0 inet manual
	ovs_bonds eth1 eth3
	ovs_type OVSBond
	ovs_bridge vmbr2
	ovs_options bond_mode=active-backup

auto lo
iface lo inet loopback

iface eth0 inet manual

iface eth1 inet manual

iface eth2 inet manual

iface eth3 inet manual

#WAN OPNSense
auto vmbr0
iface vmbr0 inet static
	address  X.X.X.X
	netmask  255.255.255.0
	gateway  Y.Y.Y.Y
	bridge-ports eth0
	bridge-stp off
	bridge-fd 0

#VXLAN vmbr1
allow-vmbr1 vx1
iface vx1 inet static
	address  10.0.4.2
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr1
	ovs_options tag=10

#Corosync
allow-vmbr1 coro
iface coro inet static
	address  10.0.5.2
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr1
	ovs_options tag=20

#pfSync
allow-vmbr1 pfsync
iface pfsync inet static
	address  10.0.6.2
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr1
	ovs_options tag=30

#VXLAN vmbr2
allow-vmbr2 vx2
iface vx2 inet static
	address  10.0.7.2
	netmask  24
	ovs_type OVSIntPort
	ovs_bridge vmbr2
	ovs_options tag=10

#OVS Bridge vmbr1
auto vmbr1
iface vmbr1 inet manual
	ovs_type OVSBridge
	ovs_ports bond0 vx1
	up ovs-vsctl add-port vmbr1 vxlan1 -- set interface vxlan1 type=vxlan options:remote_ip=10.0.4.1 options:key=flow

#OVS Bridge vmbr2
auto vmbr2
iface vmbr2 inet manual
	ovs_type OVSBridge
	ovs_ports bond0 vx2
	up ovs-vsctl add-port vmbr1 vxlan1 -- set interface vxlan1 type=vxlan options:remote_ip=10.0.7.1 options:key=flow
```

Voilà c'est tout pour l'infrastructure réseau, il faut faire en sorte de tout respecter et de bien comprendre car tout le reste sera basé sur cette configuration.