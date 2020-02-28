# DNS Interne

Il y a deux types principaux de configurations possible pour les serveurs DNS :
- Les serveurs récursif-cache qui servent pour résoudre les adresses.
- Les serveurs d’autorité qui servent à faire la correspondance IP-NOM.

On conseille généralement de ne pas faire les deux sur un même serveur. En effet, une attaque peut être menée sur un serveur récursif ce qui impacterait le service d'autorité. Grâce à la gestion de vu pas de risque vu que seul les conteneurs / VM on accès au récursif.

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
Pour savoir depuis quelle zone de notre réseau la requête est faites nous allons utiliser les vues de bind9 ainsi le serveur pourra renvoyer une IP différente en fonction de la zone.

Le serveur aura une pâte sur chaque zone comme décrit ci-dessous :
- DMZ -> 10.0.0.253
- PROXY -> 10.0.1.253
- INT -> 10.0.2.253

On définit deux zones DNS, une première, **front**, qui regroupe les zones DMZ et PROXY et une seconde, **back** qui regroupe les zones PROXY et INT.

### /etc/bind/named.conf
```
include "/etc/bind/named.conf.options";

acl front {
  127.0.0.1;
  10.0.0.0/24;
};
acl back {
  10.0.1.0/24;
  10.0.2.0/24;
};

view "internalfront" {
  recursion yes;
  match-clients {front;};
  allow-query {front;};
  allow-recursion {front;};
  allow-query-cache {front;};
  include "/etc/bind/named.conf.default-zones";
  include "/etc/bind/zones.rfc1918";
  zone "krhacken.org" {
    notify no;
    type master;
    file "/etc/bind/zones/db.krhacken.org.front";
   };
  zone "1.0.10.in-addr.arpa" {
    notify no;
    type master;
    file "/etc/bind/zones/db.krhacken.org.intrafront.rev";
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
  zone "1.1.10.in-addr.arpa" {
    notify no;
    type master;
    file "/etc/bind/zones/db.krhacken.org.intraback.rev";
  };
};
```

### /etc/bind/zones/db.krhacken.org.front
```
$TTL    10800
@       IN      SOA     dns.krhacken.org. dnsmaster.krhacken.org. (
        2015010101      ; Serial
        5400            ; Refresh
        2700            ; Retry
        2419200         ; Expire
        300 )           ; Negative TTL
         IN      NS      dns.krhacken.org.        ;Nom du serveur
alpha.fw         IN      A       10.0.0.1
beta.fw          IN      A       10.0.0.2
vip.fw           IN      A       10.0.0.3
alpha.haproxy    IN      A       10.0.0.4
beta.haproxy     IN      A       10.0.0.5
vip.haproxy      IN      A       10.0.0.6
proxyint         IN      A       10.0.0.7
mail             IN      A       10.0.0.10
dns              IN      A       10.0.0.253
alpha.nginx      IN      A       10.0.1.3
beta.nginx       IN      A       10.0.1.4
```

### /etc/bind/zones/db.krhacken.org.back
```
$TTL    10800
@       IN      SOA     dns.krhacken.org. dnsmaster.krhacken.org. (
        2015010101      ; Serial
        5400            ; Refresh
        2700            ; Retry
        2419200         ; Expire
        300 )           ; Negative TTL
         IN      NS      dns.krhacken.org.        ;Nom du serveur
alpha.haproxy    IN      A       10.0.1.1
beta.haproxy     IN      A       10.0.1.2
alpha.ldap       IN      A       10.0.2.1
beta.ldap        IN      A       10.0.2.2
vip.ldap         IN      A       10.0.2.3
alpha.nginx      IN      A       10.0.2.4
beta.nginx       IN      A       10.0.2.5
dns              IN      A       10.0.2.253
proxyint         IN      A       10.0.2.254
```

INT

### /etc/bind/zones/db.krhacken.org.intrafront.rev
```
REV
$TTL    10800
@       IN      SOA     dns.krhacken.org. dnsmaster.krhacken.org. (
        2015021102      ; Serial
        5400            ; Refresh
        2700            ; Retry
        2419200         ; Expire
        300 )           ; Negative TTL
@       IN      NS      dns.krhacken.org.
253     IN      PTR     dns.krhacken.org.
1       IN      PTR     alpha.fw.krhacken.org.
2       IN      PTR     beta.fw.krhacken.org.
3       IN      PTR     vip.fw.krhacken.org.
4       IN      PTR     alpha.haproxy.krhacken.org.
5       IN      PTR     beta.haproxy.krhacken.org.
6       IN      PTR     vip.haproxy.krhacken.org.
7       IN      PTR     proxyint.krhacken.org.
10      IN      PTR     mail.krhacken.org.
3       IN      PTR     alpha.nginx.krhacken.org.
4       IN      PTR     beta.nginx.krhacken.org.
```


### /etc/bind/zones/db.krhacken.org.intraback.rev
```
REV
$TTL    10800
@       IN      SOA     dns.krhacken.org. dnsmaster.krhacken.org. (
        2015021102      ; Serial
        5400            ; Refresh
        2700            ; Retry
        2419200         ; Expire
        300 )           ; Negative TTL
@       IN      NS      dns.krhacken.org.
253     IN      PTR     dns.krhacken.org.
1       IN      PTR     alpha.haproxy.krhacken.org.
2       IN      PTR     beta.haproxy.krhacken.org.
1       IN      PTR     alpha.ldap.krhacken.org.
2       IN      PTR     beta.ldap.krhacken.org.
3       IN      PTR     vip.ldap.krhacken.org.
4       IN      PTR     alpha.nginx.krhacken.org.
5       IN      PTR     beta.nginx.krhacken.org.
254     IN      PTR     proxyint.krhacken.org.
```

Redémarrage de bind9
```
systemctl restart bind9
```
