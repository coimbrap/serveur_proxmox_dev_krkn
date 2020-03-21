# Déploiement de l'infrastructure

Ce document regroupe uniquement des notes et des conseils non ordonné, certains éléments peuvent être erronés.

## Bonne manière

- Des qu'un mot de passe est demandé, en générer un avec un gestionnaire de mot de passe (externalisé) du style KeePass (keepass2 ou keepassx).
- Toujours désactiver le Firewall Proxmox sur les interfaces
- En cas de soucis avec un service faire un `systemctl restart <service>` avant de tout modifier. Possibilité de problème dans les interfaces.


- Les adresses IP et VLAN à suivre sont dans mise_en_place.md

- Pour se connecter à un conteneur : SSH l'hyperviseur puis lxc-attact <number>
Voilà l'ordre à suivre

installation_hyperviseurs.md
mise_en_place.md
opnsense.md

Dans mon cas pas d'IP sur les VM donc adaptation
Rajout de vmbr3 pour link PVE et OPN via DNAT.

Lors de l'installation d'OPNSense on met le clavier en français et on met un mot de passe simple que l'on changera par la suite.

On alloue uniquement dmz et wan pour le moment

vmbr1.10 C9:64 (dmz) -> 10.0.0.{3,4}/24 GW None
vmbr2.100 42:85 (admin)
vmbr0 vlan20 (wan) -> 10.2.0.3/24 GW 10.2.0.1

Attribution du sous réseau 10.2.0.0/24 au lien entre PVE et OPNSense
PVE : 10.2.0.1
OPN : 10.2.0.3

Ferm nécessaire car pas d'IP publique possible sur les VM
```
@def $IF_OPN = opnwan;
@def $IF_EXT = vmbr0;
@def $IF_DMZ = dmz;
@def $IF_ADMIN = admintask;

@def $IP_PUBLIQUE = 195.154.163.18;
@def $IP_OPNSENSE = 10.2.0.2;
@def $NET_OPN = 10.2.0.0/24;

@def $PORTS_OPN = (80 443 8080);

@def &FORWARD_TCP($proto, $port, $dest) = {
    table filter chain FORWARD interface $IF_EXT outerface $IF_OPN daddr $dest proto $proto dport $port ACCEPT;
    table nat chain PREROUTING interface $IF_EXT daddr $IP_PUBLIQUE proto $proto dport $port DNAT to $dest;
}

table filter {
    chain INPUT {
        policy DROP;
        mod state state INVALID DROP;
        mod state state (ESTABLISHED RELATED) ACCEPT;
        interface lo ACCEPT;
        interface $IF_ADMIN ACCEPT;
        interface $IF_DMZ proto tcp dport 8006 ACCEPT;
        interface $IF_EXT proto tcp dport 8006 ACCEPT;
        proto icmp icmp-type echo-request ACCEPT;
        proto tcp dport 22 ACCEPT;
    }

    chain OUTPUT policy ACCEPT;

    chain FORWARD {
        policy DROP;
        mod state state INVALID DROP;
        mod state state (ESTABLISHED RELATED) ACCEPT;
        interface $IF_OPN {
            outerface $IF_EXT ACCEPT;
            REJECT reject-with icmp-net-prohibited;
        }
    }
}

table nat {
    chain POSTROUTING {
        saddr $NET_OPN outerface $IF_EXT SNAT to $IP_PUBLIQUE;
    }
}

&FORWARD_TCP((tcp udp), $PORTS_OPN, $IP_OPNSENSE);
```


Pour rentrer sur l'interface web via Wan

On désactive toute les protections

pfctl -d
touch /tmp/disable_security_checks


Faire une règle de DNAT

Interface : WAN
Protocole : TCP ou UDP ou les deux
Destination : A voir
Plage de ports de destination : Port Source
Rediriger Vers : IP du service
Rediriger port cible : Port Cible

NAT Redirection de ports
WAN 80 et 443 vers 10.0.0.8 80 et 443


Pour assuré nos arrière je vais faire le choix de laisser le port 8080 ouvert pour acceder au firewall. Destination : ce pare-feu de 8080 vers  10.0.0.3:443



haproxy.md

A la fin de la configuration de HAProxy tester le master surtout sur les zones admin (pve, opn...) et ensuite couper le master pour tester le slave. Les deux doivent fonctionner pareil et l'ip 10.0.0.8/32 doit passer d'un serveur à l'autre.

Maintenant que OPNSense est accessible à l'adresse
opn.sessionkrkn.fr il faut autorisé cet host à accéder au Panel.

Système/Paramètres/Administration/Nomsd'hôte alternatifs
et mettre `opn.sessionkrkn.fr`
il n'est donc plus neccessaire d'enlever la vérification web d'OPNSense.


Normalement à ce stade
pve.sessionkrkn.fr
opn.sessionkrkn.fr
sont accessible et fonctionne.

proxy_interne.md
Rien de bien dur pour la mise en place
Pour l'utilisation
- Chaque conteneur dans une zone autre que DMZ doit avoir comme gateway l'adresse du proxy dans la bonne zone
- Il faut configurer impérativement wget et apt vers l'adresse du proxy
- Mettre en place une interface dans chaque zone avec l'adresse en .252 avec comme gateway .254 (OPNSense)

nginx_principal.md

Création des deux conteneur et connexion au proxy interne

#### /root/.wgetrc
```
http_proxy = http://10.0.1.252:3128/
https_proxy = http://10.0.1.252:3128/
use_proxy = on
```
#### /etc/apt/apt.conf.d/01proxy
```
Acquire::http {
 Proxy "http://10.0.1.252:9999";
};
```

#### /root/.wgetrc
```
http_proxy = http://10.0.2.252:3128/
https_proxy = http://10.0.2.252:3128/
use_proxy = on
```
#### /etc/apt/apt.conf.d/01proxy
```
Acquire::http {
 Proxy "http://10.0.2.252:9999";
};
```

Pour tester le fonctionnement jusqu'ici redémarrer le serveur et vérifier que tout fonctionne.
Problème classique :
- Service non activé
- Interfaces mal configuré (firewall proxmox)
- Dans le cas de ferm bug a l'allumage

dns.md
Une interface DMZ gateway 10.0.0.3 ou VIP OPN
Une interface PROXY gateway 10.0.1.254
Une interface INT gateway 10.0.2.254

ldap.md

Vérification de la mise en place des certifs SSL

ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config |grep olcTLS
