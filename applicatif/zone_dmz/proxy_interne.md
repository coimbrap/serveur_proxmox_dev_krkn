# Proxy Interne

Nous allons mettre en place un proxy interne pour permettre au services des zones n'ayant pas un accès direct à internet (PROXY, INT, CTF et DIRTY) d'accéder au gestionnaire de packet et à internet (via WGET). Le proxy interne sera dans la zone DMZ, il fera donc le lien entre l'extérieur et les services.

## Apt Cacher NG
Pour l'accès au gestionnaire de packet nous allons utiliser Apt-Cacher NG.

### Installation
```
apt-get install apt-cacher-ng -y
```
```
Allow HTTP tunnel throutgt Apt-Cacher NG? -> No
```

### /etc/apt-cacher-ng/acng.conf
```
Port: 9999
BindAddress: 10.0.1.254 10.0.2.254 10.0.3.254 10.0.4.254
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


## Accès au Proxy Interne depuis un container ou une VM

Les outils principaux sont WGET et APT-GET on va donc les reliées au Proxy Interne.

Le proxy interne sera accessible uniquement depuis les zones PROXY, INT, CTF et DIRTY voilà l'ip du proxy en fonction de la zone
- PROXY (VLAN 20) -> 10.0.1.254
- INT (VLAN 30) -> 10.0.2.254
- CTF (VLAN 40) -> 10.0.3.254
- DIRTY (VLAN 50) -> 10.0.4.254

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
