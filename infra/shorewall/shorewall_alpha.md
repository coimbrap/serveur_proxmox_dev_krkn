# Mise en place du firewall de Alpha

Nous avons une interface _eth1_ pour le routage de la connexion avec beta, une interface _eth2_ pour le corosync, une interface virtuelle _vmbr0_ qui bridge sur _eth0_ pour l'accès à internet et deux interfaces virtuelle _vmbr1_ et _vmbr2_ qui ne bridge pas vers l'extérieur, le bridge va se faire avec shorewall.

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

### /etc/shorewall/interfaces
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
$FW     int	    ACCEPT
$FW     coro    ACCEPT
krkn    net     ACCEPT
ext     net     ACCEPT
int     net     ACCEPT

ext     krkn    DROP      	info
net	    all	    DROP	  	info
all	    all	    REJECT		info

```

### /etc/shorewall/rules
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
DNS(ACCEPT)	    $FW		net
Ping(ACCEPT)    all     $FW

#Connexion SSH vers et depuis Beta et extérieur
SSH(ACCEPT)	    int		        $FW
SSH(ACCEPT)     net             all
SSH(ACCEPT)     $FW             int

#Nécessaire pour l'initialisation du corosync
ACCEPT		    coro	        $FW		        icmp

ACCEPT          $FW             krkn            icmp
ACCEPT          $FW             ext             icmp
ACCEPT          $FW             net             icmp

ACCEPT          krkn            int             tcp        80,443
ACCEPT          krkn            ext             tcp        80,443

ACCEPT          net             $FW             tcp        8006
```
### /etc/shorewall/snat
Configuration SNAT permettant de faire du "masquerading", ainsi les paquets qui sortent des CT LXC ont comme IP source, l'IP de l'interface externe _eth0_.  
```
#ACTION			SOURCE			DEST           
MASQUERADE      vmbr1           vmbr0
MASQUERADE      vmbr1           eth1
MASQUERADE      vmbr2           vmbr0
MASQUERADE		eth1      		vmbr0
```
### /etc/shorewall/zones
Définition des zones et de leur type.
```
#ZONE   TYPE
fw      firewall
net     ipv4
krkn    ipv4
ext     ipv4
coro    ipv4
int     ipv4
```

Le firewall de Alpha est maintenant configuré comme décrit dans le shéma global du réseau.