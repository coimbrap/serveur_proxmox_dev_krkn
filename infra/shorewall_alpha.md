# Mise en place du firewall de Alpha

Nous avons déjà deux interfaces virtuelle qui ne bridge pas vers l'extérieur. Le raccord avec l'extérieur va se faire avec shorewall.

## Installation de Shorewall
```
apt-get update
apt-get install shorewall
cp /usr/share/doc/shorewall/examples/Universal/* /etc/shorewall/
```
Shorewall est maintenant installé

## Configuration de Shorewall

### /etc/shorewall/conntrack
Garder le fichier d'origine

## /etc/shorewall/interfaces
Associations des interfaces du système avec les zones du parefeu
```
?FORMAT 2
#ZONE	  INTERFACE  OPTIONS
int       eth1       tcpflags,nosmurfs,bridge,logmartians,routefilter
coro      eth2       tcpflags,nosmurfs,logmartians
net       vmbr0	     tcpflags,nosmurfs,bridge,routefilter,logmartians,routeback
krkn      vmbr1      tcpflags,nosmurfs,bridge,routefilter,logmartians,routeback
ext       vmbr2      tcpflags,nosmurfs,bridge,routefilter,logmartians,routeback
```

### /etc/shorewall/policy
Définition de la politique globale du pare-feu
```
#SOURCE	DEST	POLICY		LOGLEVEL
$FW     net     ACCEPT
$FW	int	ACCEPT
krkn    net     ACCEPT
ext     net     ACCEPT
int     net     ACCEPT

ext     krkn    DROP      	info
net	all	DROP	  	info
all	all	REJECT		info

```

## /etc/shorewall/rules
Définition des exceptions aux règles définies dans le fichier policy
```
#ACTION		SOURCE		DEST		PROTO	DEST	SOURCE
?SECTION ALL
?SECTION ESTABLISHED
?SECTION RELATED
?SECTION INVALID
?SECTION UNTRACKED
?SECTION NEW

Invalid(DROP)	net		all		tcp
DNS(ACCEPT)	$FW		net
Ping(ACCEPT)    all             $FW

#Connexion SSH vers et depuis Beta et extérieur
SSH(ACCEPT)	int		$FW
SSH(ACCEPT)     net             all
SSH(ACCEPT)     $FW             int

#Nécessaire pour l'initialisation du corosync
ACCEPT		coro	        $FW		icmp

ACCEPT          $FW             krkn            icmp
ACCEPT          $FW             ext             icmp
ACCEPT          $FW             net             icmp
ACCEPT          krkn            ext             icmp

#Interface web proxmox
ACCEPT          krkn:10.10.0.3  $FW             tcp         8006,5902
ACCEPT          net	        $FW             tcp         8006

#DNAT pour le proxy Nginx
DNAT            net             krkn:10.10.0.3  tcp         80,443
```
### /etc/shorewall/snat
Configuration SNAT permettant de faire du "masquerading", ainsi les paquets qui sortent des CT LXC ont comme IP source, l'IP de l'interface externe _eth0_ à travers _vmbr0_.  
```
#ACTION			SOURCE			DEST           
MASQUERADE              vmbr1                   vmbr0
MASQUERADE              vmbr2                   vmbr0
MASQUERADE		enp0s8			vmbr0
```
### /etc/shorewall/zones
Définition des zones et de leur type.
```
#ZONE   TYPE
fw	firewall
net	ipv4
krkn	ipv4
ext	ipv4
coro    ipv4
int	ipv4
```

Le firewall de Alpha est maintenant configuré comme décrit dans le shéma global du réseau.