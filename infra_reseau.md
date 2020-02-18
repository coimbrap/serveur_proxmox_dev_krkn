# Réseau

Chacune des nodes possède 4 interfaces réseau, pour des questions de redondance et de débit nous allons mettre 2 de ces interfaces en bond pour le réseau interne et la communication entre les deux serveurs.

- eth0 sur une interface simple utilisé uniquement par OPNSense via wan
- eth2 formera le bridge OVS admin
- eth1 et eth3 formerons le bond OVS bond0 sur le bridge OVS interne

Pour la gestion des bonds, vlans... nous utiliserons openvswitch

Explication rapide du fonctionnement global d'OpenvSwitch,

- OVS Bridge, c'est comme un switch, mais en virtualisé sur lequel on peu branché des CT et VM sur des VLANs et qui peux communiquer avec un autre Bridge via un tunnel VXLAN ou un tunnel GRE. Pour notre usage le bridge n'aura pas d'IP sur l'hôte.
- OVS Bond, permet d'attache un groupe d'interface physique à un Bridge OVS ie. un groupe d'interface réseau à un switch virtuel.
- OVS IntPort, pas possible de bridge des VMs ou des CT dessus, il permet à l'hôte de se brancher au Bridge pour avoir une IP et éventuellement une VLAN.


Pour chacune des zones (KRKN ou CTF) il y a deux types de VM/CT,

- Ceux qui sont directement accessible depuis internet derrière OPNSense c'est les services frontend.
- Ceux qui sont accessible uniquement à travers une frontend c'est les services backend.

## Les switchs virtuel

- Un switch physique sur lequel sera branché les quatres interfaces des nodes et l'entité de quorum.
- Un switch Administation pour toute les tâches d'administration avec comme lien extérieur eth2
- Un switch Interne qui devra gérer, avec des VLANs, l'accès (filtré) à internet des services qui ne sont pas directement derrière le FW (Nextcloud, Git, Serveur Web...) en séparant le tout en plusieurs zones et les services qui sont directement derrière le FW (HAProxy, Proxy des services, Mail et DNS). Avec comme lien extérieur un bond entre eth1 et eth3.

## Communication des switchs entre les nodes

Tout les hyperviseurs auront une pâte sur le VLAN 100 sur chaque switch pour le protocole GRE qui permet l'échange entre les switchs virtuel de chaque nodes.

## Services Frontend

Concrètement les containers concernés auront des ports d'entrée DNAT vers eux ce qui signifie qu'ils seront accessible depuis internet à travers le firewall. C'est le cas de HAProxy, des Mails, du serveur DNS et du Proxy des services.

Tout ces CT auront obligatoirement une pâte sur la VLAN 10 et une VLAN backend du switch Interne.

## Services Backend

Les containers ou VMs concerné ne seront pas accessible depuis internet cependant certain seront accessible par l'intermédiaire de HAProxy (entre autres).

Cette parti sera découpé en plusieures zones,
- ROUTE sur la VLAN 20 qui contiendra les reverses proxy public,
- KRKN sur la VLAN 30 qui contiendra tout les services de la partie krhacken,
- CTF sur la VLAN 40 qui contiendra le reverse proxy CTF et les environnement CTF,
- EXT sur la VLAN 50 qui contiendra les environnement de test.

## Partie Internet

Tout les containers et les VM Backend auront accès à internet via le proxy interne (en frontend). Pour cela ils auront tous une pâte sur la VLAN 80 du switch interne.

## Partie Administration

- Chaque hyperviseur ainsi que l'entité de Quorum aura une pâte sur la VLAN 10 du switch Administration pour le fonctionnement de Corosync.
- Toutes les VM, tout les CT, les hyperviseurs et l'entité de Quorum auront une pâte sur la VLAN 20 du switch Administration pour les tâches d'administration via le VPN ou localement en cas d'urgence.
- Chaque hyperviseur aura une pâte sur la VLAN 30 su switch Administration pour pfSync (HA du Firewall).


## Map des IPs principales.

### FrontEnd (Juste après le FW)
- Firewall Alpha : 10.0.0.1
- Firewall Bêta : 10.0.0.2
- Firewall VIP : 10.0.0.3
- HAProxy Alpha : 10.0.0.4
- HAProxy Beta : 10.0.0.5
- HAProxy VIP : 10.0.0.6
- Proxy Interne : 10.0.0.7
- Mail : 10.0.0.10

### ROUTE (Juste après la frontend)
- HAProxy Alpha : 10.0.1.1
- HAProxy Beta : 10.0.1.2
- Nginx Public Alpha : 10.0.1.3
- Nginx Public Beta : 10.0.1.4


### KRKN
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
