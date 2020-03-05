# Proxy Interne

Nous allons mettre en place un proxy interne pour permettre au services des zones n'ayant pas un accès direct à internet (PROXY, INT, CTF et DIRTY) d'accéder au gestionnaire de packet et à internet (via WGET). Le proxy interne sera dans la zone DMZ, il fera donc le lien entre l'extérieur et les services.

## Création du conteneur
Comme dit dans la partie déploiement, c'est le seul conteneur qu'il faut mettre en place manuellement. Avant de le mettre en place il faut avoir mis en place le réseau et générer la clé SSH du conteneur Ansible.

Pour mon installation ce conteneur porte le numéro 103.

Au niveau de la clé SSH, mettez celle que vous avez générer dans le conteneur Ansible. Elle se trouve dans `/root/.ssh/id_ed25519.pub`


Au niveau des ressources allouées :
- 2Gb de RAM
- 1Gb de SWAP
- 24Gb de Stockage

Au niveau des interfaces réseaux :
Firewall toujours désactiver.
- eth0: vmbr1 / VLAN: 10 / IP: 10.0.0.9/24 / GW: 10.0.0.254
- eth1: vmbr1 / VLAN: 20 / IP: 10.0.1.252/24
- eth2: vmbr1 / VLAN: 30 / IP: 10.0.2.252/24
- eth3: vmbr1 / VLAN: 40 / IP: 10.0.3.252/24
- eth4: vmbr1 / VLAN: 50 / IP: 10.0.4.252/24
- eth0: vmbr2 / VLAN: 100 / IP: 10.1.0.103/24 / GW: 10.1.0.254

## Apt Cacher NG
Pour l'accès au gestionnaire de packet nous allons utiliser Apt-Cacher NG.

### Installation
```
apt-get install -y apt-cacher-ng
```
```
Allow HTTP tunnel throutgt Apt-Cacher NG? -> No
```

### /etc/apt-cacher-ng/acng.conf
```
Port: 9999
BindAddress: 10.0.1.252 10.0.2.252 10.0.3.252 10.0.4.252
```
```
systemctl restart apt-cacher-ng.service
```
Apt-Cacher est désormais sur le port 9999 du proxy interne. Il n'est accessible que depuis les zones PROXY, INT, CTF et DIRTY. Les requêtes depuis d'autres zones seront rejetées.

## Squid

Pour l'accès à internet via WGET nous allons utiliser Squid.

### Installation
```
apt-get install -y squid3 ca-certificates
```

### /etc/squid/squid.conf
```
#acl localnet src 0.0.0.1-0.255.255.255 # RFC 1122 "this" network (LAN)
#acl localnet src 10.0.0.0/8            # RFC 1918 local private network (LAN)
#acl localnet src 100.64.0.0/10         # RFC 6598 shared address space (CGN)
#acl localnet src 169.254.0.0/16        # RFC 3927 link-local (directly plugged) machines
#acl localnet src 172.16.0.0/12         # RFC 1918 local private network (LAN)
#acl localnet src 192.168.0.0/16                # RFC 1918 local private network (LAN)
#acl localnet src fc00::/7              # RFC 4193 local private network range
#acl localnet src fe80::/10             # RFC 4291 link-local (directly plugged) machines
acl localnet src 10.0.1.0/24   # Zone Proxy
acl localnet src 10.0.2.0/24   # Zone Int
acl localnet src 10.0.3.0/24   # Zone CTF
acl localnet src 10.0.4.0/24   # Zone Dirty

[...]

http_access allow localnet
http_access allow localhost
```
```
systemctl restart squid.service
```

Squid est maintenant accessible depuis le port 3128 du proxy interne uniquement depuis les zones PROXY, INT, CTF et DIRTY. Les requêtes depuis d'autres zones seront rejetées.


## Accès au Proxy Interne depuis un conteneur ou une VM

Les outils principaux sont WGET et APT-GET on va donc les reliées au Proxy Interne.

Le proxy interne sera accessible uniquement depuis les zones PROXY, INT, CTF et DIRTY voilà l'ip du proxy en fonction de la zone :
- PROXY (VLAN 20) -> 10.0.1.252
- INT (VLAN 30) -> 10.0.2.252
- CTF (VLAN 40) -> 10.0.3.252
- DIRTY (VLAN 50) -> 10.0.4.252

### WGET
Les requêtes passerons désormais par le proxy interne sur le port 3128 pour les requêtes http et https. Seul le root aura accès au proxy.

#### /root/.wgetrc
```
http_proxy = http://<ip_proxy_zone>:3128/
https_proxy = http://<ip_proxy_zone>:3128/
use_proxy = on
```
WGET doit maintenant fonctionner.

### APT-GET
On va maintenant faire passer apt-get par le proxy apt qui est sur le port 9999 du proxy interne.

#### /etc/apt/apt.conf.d/01proxy
```
Acquire::http {
 Proxy "http://<ip_proxy_zone>:9999";
};
```
APT-GET doit maintenant fonctionner.

Voilà c'est tout pour la mise en place du Proxy Interne.

### Git
Les requêtes passerons désormais par le proxy interne sur le port 3128 pour les requêtes git via http.

#### /root/.gitconfig
```
[http]
        proxy = http://<ip_proxy_zone>:3128
[https]
        proxy = https://<ip_proxy_zone>:3128
```
