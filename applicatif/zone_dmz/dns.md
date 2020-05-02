# DNS Interne

Il y a deux types principaux de configurations possible pour les serveurs DNS :
- Les serveurs récursif-cache qui servent pour résoudre les adresses.
- Les serveurs d’autorité qui servent à faire la correspondance IP-NOM.

On conseille généralement de ne pas faire les deux sur un même serveur. En effet, une attaque peut être menée sur un serveur récursif ce qui impacterait le service d'autorité. Grâce à la gestion de vu pas de risque vu que seul les conteneurs / VM on accès au récursif.

## Le conteneur
Numéro 107 (Beta)

#### Interface réseau
- eth0 : vmbr1 / VLAN 20 / IP 10.0.1.253 / GW 10.0.1.254

### Le proxy
#### /etc/apt/apt.conf.d/01proxy
```
Acquire::http {
 Proxy "http://10.0.0.252:9999";
};
```

## Installation
Faites par le playbook Ansible.

```
apt-get update
apt-get install -y bind9 dnsutils
```
Création des répertoires nécessaire,
```
mkdir /var/log/dns/
mkdir /etc/bind/zones
touch /var/log/dns/query.log
touch /var/log/dns/error.log
chown bind:bind /var/log/dns/ -R
```

## Configuration

### /etc/bind/named.conf.options
Configuration globale de bind9. Remplacer le contenu par ce qui suit,
```
options {
  directory "/var/cache/bind";
  dnssec-validation auto;
  auth-nxdomain no;
  listen-on { any;};
  version "V1.0";
  forwarders {
        80.67.169.12;
        80.67.169.40;
  };
  forward only;
  };
logging {
  channel query_log {
    file "/var/log/dns/query.log";
    severity debug 10;
    print-category yes;
    print-time yes;
    print-severity yes;
  };
  channel error_log {
    file "/var/log/dns/error.log";
    severity error;
    print-category yes;
    print-time yes;
    print-severity yes;
  };
  category queries { query_log;};
  category security { error_log;};
};
```

## Gestion par vue

Pour savoir depuis quelle zone de notre réseau la requête est faites nous allons utiliser les vues de bind9 ainsi le serveur pourra renvoyer une IP différente en fonction de la zone. Bind choisi la zone du client en fonction de l'adresse IP source.

On définit quatres zones DNS, une première, **front**, pour la zones DMZ, une seconde, **proxy** pour la zone PROXY, une troisième **back** pour la zone Interne et une quatrième **admin** qui regroupe toutes les zones.

### /etc/bind/named.conf
```
include "/etc/bind/named.conf.options";

acl proxy {
  10.0.0.0/24;
};
acl proxy {
  127.0.0.1;
  10.0.1.0/24;
};
acl back {
  10.0.2.0/24;
};
acl admin {
  10.1.0.0/24;
};

view "internalfront" {
  recursion yes;
  match-clients {proxy;};
  allow-query {proxy;};
  allow-recursion {proxy;};
  allow-query-cache {proxy;};
  include "/etc/bind/named.conf.default-zones";
  include "/etc/bind/zones.rfc1918";
  zone "krhacken.org" {
    notify no;
    type master;
    file "/etc/bind/zones/db.krhacken.org.proxy";
   };
  zone "0.0.10.in-addr.arpa" {
    notify no;
    type master;
    file "/etc/bind/zones/db.krhacken.org.intrafront.rev";
  };
};
view "internalproxy" {
  recursion yes;
  match-clients {proxy;};
  allow-query {proxy;};
  allow-recursion {proxy;};
  allow-query-cache {proxy;};
  include "/etc/bind/named.conf.default-zones";
  include "/etc/bind/zones.rfc1918";
  zone "krhacken.org" {
    notify no;
    type master;
    file "/etc/bind/zones/db.krhacken.org.proxy";
   };
  zone "1.0.10.in-addr.arpa" {
    notify no;
    type master;
    file "/etc/bind/zones/db.krhacken.org.intraproxy.rev";
  };
};
view "internalback" {
  recursion yes;
  match-clients {back;};
  allow-query {back;};
  allow-recursion {back;};
  allow-query-cache {back;};
  include "/etc/bind/named.conf.default-zones";
  include "/etc/bind/zones.rfc1918";
  zone "krhacken.org" {
    notify no;
    type master;
    file "/etc/bind/zones/db.krhacken.org.back";
   };
  zone "2.0.10.in-addr.arpa" {
    notify no;
    type master;
    file "/etc/bind/zones/db.krhacken.org.intraback.rev";
  };
};
view "internaladmin" {
  recursion yes;
  match-clients {admin;};
  allow-query {admin;};
  allow-recursion {admin;};
  allow-query-cache {admin;};
  include "/etc/bind/named.conf.default-zones";
  include "/etc/bind/zones.rfc1918";
  zone "krhacken.org" {
    notify no;
    type master;
    file "/etc/bind/zones/db.krhacken.org.admin";
   };
  zone "0.1.10.in-addr.arpa" {
    notify no;
    type master;
    file "/etc/bind/zones/db.krhacken.org.intraadmin.rev";
  };
};
```

## Les serveurs récursif-cache

Voici les trois fichiers pour la configuration pour les forward DNS.

Pour la zone **front** :

### /etc/bind/zones/db.krhacken.org.front
```
$TTL    10800
@       IN      SOA     dns.krhacken.org. r.krhacken.org. (
        2020050101      ; Serial
        5400            ; Refresh
        2700            ; Retry
        2419200         ; Expire
        300 )           ; Negative TTL
         IN      NS      dns.krhacken.org.
alpha.pve        IN      A       10.0.0.1
beta.pve         IN      A       10.0.0.2
alpha.fw         IN      A       10.0.0.3
beta.fw          IN      A       10.0.0.4
alpha.haproxy    IN      A       10.0.0.5
beta.haproxy     IN      A       10.0.0.6
vip.haproxy      IN      A       10.0.0.7
proxy            IN      A       10.0.0.252
dns              IN      A       10.0.1.253
vip.fw           IN      A       10.0.1.254
```

Pour la zone **proxy** :
```
$TTL    10800
@       IN      SOA     dns.krhacken.org. r.krhacken.org. (
        2020050101      ; Serial
        5400            ; Refresh
        2700            ; Retry
        2419200         ; Expire
        300 )           ; Negative TTL
         IN      NS      dns.krhacken.org.
alpha.nginx      IN      A       10.0.1.1
beta.nginx       IN      A       10.0.1.2
mail             IN      A       10.0.1.5
alpha.fw         IN      A       10.0.1.252
beta.fw          IN      A       10.0.1.253
vip.fw           IN      A       10.0.1.254
```

Pour la zones **back** :

### /etc/bind/zones/db.krhacken.org.back
```
$TTL    10800
@       IN      SOA     dns.krhacken.org. r.krhacken.org. (
        2020050101      ; Serial
        5400            ; Refresh
        2700            ; Retry
        2419200         ; Expire
        300 )           ; Negative TTL
         IN      NS      dns.krhacken.org.
                 IN      A       10.0.2.7
alpha.ldap       IN      A       10.0.2.1
beta.ldap        IN      A       10.0.2.2
vip.ldap         IN      A       10.0.2.3
mail             IN      A       10.0.2.4
back.mail        IN      A       10.0.2.5
ldapui           IN      A       10.0.2.6
wiki             IN      A       10.0.2.8
cloud            IN      A       10.0.2.10
git              IN      A       10.0.2.11
keyserver        IN      A       10.0.2.12
pass             IN      A       10.0.2.13
alpha.fw         IN      A       10.0.2.252
beta.fw          IN      A       10.0.2.253
vip.fw           IN      A       10.0.2.254
```

Pour la zone **admin** :

### /etc/bind/zones/db.krhacken.org.admin
```
$TTL    10800
@       IN      SOA     dns.krhacken.org. r.krhacken.org (
        2020050101      ; Serial
        5400            ; Refresh
        2700            ; Retry
        2419200         ; Expire
        300 )           ; Negative TTL
         IN      NS      dns.krhacken.org.        ;Nom du serveur
master.haproxy          IN      A       10.0.0.6
slave.haproxy           IN      A       10.0.0.7
proxy                   IN      A       10.0.0.252
master.nginx            IN      A       10.0.1.3
slave.nginx             IN      A       10.0.1.4
dns                     IN      A       10.0.0.253
ldap                    IN      A       10.0.2.1
mail                    IN      A       10.0.2.10
ldapui                  IN      A       10.0.2.15
nextcloud               IN      A       10.0.2.20
gitea                   IN      A       10.0.2.21
rocketchat              IN      A       10.0.2.30
drone                   IN      A       10.0.2.14
ctf.nginx               IN      A       10.0.3.4
club.ctfd               IN      A       10.0.3.10
ct.snt                  IN      A       10.0.3.50
blog                    IN      A       10.0.2.50
grafana                 IN      A       10.1.0.252
ansible                 IN      A       10.1.0.253
opn                     IN      A       10.0.0.254
vm.snt                  IN      A       10.0.3.10
```

## Les serveurs d’autorité

Voici les trois fichiers pour la configuration pour les reverses DNS.

Pour la zone **front** :

### /etc/bind/zones/db.krhacken.org.intrafront.rev
```
REV
$TTL    10800
@       IN      SOA     dns.krhacken.org. r.krhacken.org. (
        2020050101      ; Serial
        5400            ; Refresh
        2700            ; Retry
        2419200         ; Expire
        300 )           ; Negative TTL
@       IN      NS      dns.krhacken.org.
253     IN      PTR     dns.krhacken.org.
1       IN      PTR     alpha.pve.krhacken.org.
2       IN      PTR     beta.pve.krhacken.org.
3       IN      PTR     alpha.fw.krhacken.org.
4       IN      PTR     beta.fw.krhacken.org.
5       IN      PTR     alpha.haproxy.krhacken.org.
6       IN      PTR     beta.haproxy.krhacken.org.
7       IN      PTR     vip.haproxy.krhacken.org.
252     IN      PTR     proxy.krhacken.org.
254     IN      PTR     vip.fw.krhacken.org.
```

Pour la zone **proxy** :

### /etc/bind/zones/db.krhacken.org.intraproxy.rev
```
REV
$TTL    10800
@       IN      SOA     dns.krhacken.org. r.krhacken.org. (
        2020050101      ; Serial
        5400            ; Refresh
        2700            ; Retry
        2419200         ; Expire
        300 )           ; Negative TTL
@       IN      NS      dns.krhacken.org.
1       IN      PTR     alpha.nginx.krhacken.org.
2       IN      PTR     beta.nginx.krhacken.org.
5       IN      PTR     mail.krhacken.org.
252     IN      PTR     alpha.haproxy.krhacken.org.
253     IN      PTR     beta.haproxy.krhacken.org.
254     IN      PTR     vip.fw.krhacken.org.
```

Pour la zone **back** :

### /etc/bind/zones/db.krhacken.org.intraback.rev
```
REV
$TTL    10800
@       IN      SOA     dns.krhacken.org. r.krhacken.org. (
        2020050101      ; Serial
        5400            ; Refresh
        2700            ; Retry
        2419200         ; Expire
        300 )           ; Negative TTL
@       IN      NS      dns.krhacken.org.
1       IN      PTR     alpha.ldap.krhacken.org.
2       IN      PTR     beta.ldap.krhacken.org.
3       IN      PTR     vip.ldap.krhacken.org.
4       IN      PTR     mail.krhacken.org.
5       IN      PTR     back.mail.krhacken.org.
6       IN      PTR     ldapui.krhacken.org.
7       IN      PTR     krhacken.org.
8       IN      PTR     wiki.krhacken.org.
10      IN      PTR     cloud.krhacken.org.
11      IN      PTR     git.krhacken.org.
12      IN      PTR     keyserver.krhacken.org.
13      IN      PTR     pass.krhacken.org.
252     IN      PTR     alpha.fw.krhacken.org.
253     IN      PTR     beta.fw.krhacken.org.
254     IN      PTR     vip.fw.krhacken.org.
```

Pour la zone **admin** :

### /etc/bind/zones/db.krhacken.org.intraadmin.rev
```
$TTL    10800
@       IN      SOA     dns.krhacken.org. r.krhacken.org (
        2020050101      ; Serial
        5400            ; Refresh
        2700            ; Retry
        2419200         ; Expire
        300 )           ; Negative TTL
@       IN      NS      dns.krhacken.org.
6       IN      PTR     master.haproxy.krhacken.org.
7       IN      PTR     slave.haproxy.krhacken.org.
252     IN      PTR     proxy.krhacken.org.
3       IN      PTR     master.nginx.krhacken.org.
4       IN      PTR     slave.nginx.krhacken.org.
253     IN      PTR     dns.krhacken.org.
1       IN      PTR     ldap.krhacken.org.
10      IN      PTR     mail.krhacken.org.
15      IN      PTR     ldapui.krhacken.org.
20      IN      PTR     nextcloud.krhacken.org.
21      IN      PTR     gitea.krhacken.org.
30      IN      PTR     rocketchat.krhacken.org.
14      IN      PTR     drone.krhacken.org.
4       IN      PTR     ctf.nginx.krhacken.org.
10      IN      PTR     club.ctfd.krhacken.org.
50      IN      PTR     ct.snt.krhacken.org.
50      IN      PTR     blog.krhacken.org.
252     IN      PTR     grafana.krhacken.org.
253     IN      PTR     ansible.krhacken.org.
254     IN      PTR     opn.krhacken.org.
10      IN      PTR     vm.snt.krhacken.org.
```

Redémarrage de bind9
```
systemctl restart bind9
```
