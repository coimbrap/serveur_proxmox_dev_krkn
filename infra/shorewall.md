# Mise en place du firewall
Nous allons ici configurer le firewall qui respectera les règles suivantes,
- DNAT ports 80,443 vers le ct du proxy NGINX (10.10.0.2) depuis NET vers KRKN
- SNAT pour faire du masquerading des packets sortant des CT
- Accès SSH vers toutes les zones 
- Accès à l'interface web Proxmox port 8006 depuis NET vers le firewall
- Reverse-Proxy NGINX pour l'interface web Proxmox ports 8006,5902 depuis le CT NGINX vers le firewall

Nous utilisons Shorewall et non iptables ou le firewall de Proxmox pour des raisons de simplicité.

## Ajout des interfaces virtuelle
On va ajouter nos deux interfaces virtuelles (vmbr0 et vmbr1) non bridgé sur eth0 et disposant chacune d'une plage ipv4 différente. 

### /etc/network/interface
##### Depuis Alpha et Beta on ajoute
```
auto vmbr0
iface vmbr0 inet static
        address 10.10.0.1
        netmask 255.255.250.0
        bridge_ports none
        bridge_stp off
        bridge_fd 0

auto vmbr1
iface vmbr1 inet static
        address 10.10.1.1
        netmask 255.255.240.0
        bridge_ports none
        bridge_stp off
        bridge_fd 0
```

Nous avons maintenant deux interfaces virtuelle qui ne bridge pas vers l'extérieur. Le raccord avec l'extérieur va se faire avec shorewall.

### /etc/shorewall/conntrack
Garder le fichier d'origine

##< /etc/shorewall/interfaces
Associations interfaces/zones.
```
#ZONE	INTERFACE	BROADCAST	OPTIONS
net	eth0	ip_publique	tcpflags,nosmurfs,routefilter,logmartians,sourceroute=0
krkn	vmbr1		-		tcpflags,nosmurfs,routefilter,logmartians
ext	vmbr2		-		tcpflags,nosmurfs,routefilter,logmartians
```

### /etc/shorewall/policy
Définition de la politique global du pare-feu.
```
#SOURCE		DEST		POLICY		LOG LEVEL	LIMIT:BURST
$FW		net		ACCEPT
krkn		net		ACCEPT
ext		net		ACCEPT
krkn		ext		ACCEPT
net		all		DROP		info
#THE FOLLOWING POLICY MUST BE LAST
all		all		REJECT		info

```

### /etc/shorewall/rules
Définition des exceptions aux règles définies dans le fichier policy.
```
#ACTION		SOURCE		DEST		PROTO	DEST	SOURCE		ORIGINAL	RATE		USER/	MARK	CONNLIMIT	TIME		HEADERS		SWITCH		HELPER
#							PORT	PORT(S)		DEST		LIMIT		GROUP
?SECTION ALL
?SECTION ESTABLISHED
?SECTION RELATED
?SECTION INVALID
?SECTION UNTRACKED
?SECTION NEW
Invalid(DROP)	net		all		tcp
DNS(ACCEPT)	$FW		net
SSH(ACCEPT)	net		all
Ping(ACCEPT)	all		$FW
#Ping(DROP)	net		$FW
ACCEPT		$FW		krkn		icmp
ACCEPT		$FW		ext		icmp
ACCEPT		$FW		net		icmp
ACCEPT		net		$FW		icmp
#Nginx reverse-proxy Proxmox web interface
ACCEPT		krkn:10.10.0.2	$FW		tcp	8006,5902
#Proxmox web interface
ACCEPT		net		$FW		tcp	8006
#LXC Nginx
DNAT		net		krkn:10.10.0.2	tcp	80,443
```
### /etc/shorewall/snat
Configuration SNAT permettant de faire du "masquerading", ainsi les paquets qui sortent des CT LXC ont comme IP source, l'IP de l'interface externe _eth0_.  
```
#ACTION		SOURCE			DEST
MASQUERADE	vmbr1			eth0
MASQUERADE	vmbr2			eth0
```
### /etc/shorewall/zones
Définition des zones et de leur type.
```
#ZONE	TYPE
fw	firewall
net	ipv4
krkn	ipv4
ext	ipv4
```

Nous avons maintenant un firewall qui respecte les règles défini.
A noté qu'il n'y a pas de firewall sur l'interface eth3 car elle est en local.