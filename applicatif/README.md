# Applicatif
Vous trouverez ici toute la documentation relative à la partie applicative. Les services sont découpés en plusieurs zones qui sont décrites dans le premier point.

L'accès au réseau des services est décrit dans la partie réseau, il est donc impératif de mettre en place le réseau avant de s'occuper de l'applicatif.

# Table des matières
1. [Répartition des services dans les zones](repartition_en_zones.md)
2. [Zone WAN](zone_wan)
  1. [OPNSense](zone_wan/opnsense)
    1. [Configuration de base](zone_wan/opnsense/configuration_initiale.md)
  2. [Options possible pour l'accès extérieur](zone_wan/option_possible.md)
3. [Zone DMZ](zone_dmz)
  1. [HAProxy](zone_dmz/haproxy)
    1. [Container HAProxy](zone_dmz/haproxy/haproxy.md)
    2. [Certificat SSL Client](zone_dmz/haproxy/certificat_ssl_client.md)
  2. [Serveur DNS](zone_dmz/dns.md)
  3. [Proxy pour les conteneurs / VM](zone_dmz/proxy_interne.md)
4. [Zone Proxy](zone_proxy)
  1. [Reverse Proxy NGINX](zone_proxy/nginx_principal.md)
  2. [Relais mails](#)
5. [Zone Interne](zone_interne)
  1. [LDAP](zone_interne/ldap)
    1. [Serveur LDAP](zone_interne/ldap/serveur_ldap.md)
    2. [Inteface de gestion](zone_interne/ldap/interface_web_ldap.md)
  2. [Serveur Mail](zone_interne/mail.md)
  3. [NextCloud](zone_interne/nextcloud.md)
  4. [Gitea](zone_interne/gitea.md)
6. [Zone CTF](zone_ctf)
  1. [Reverse Proxy NGINX](zone_ctf/nginx_ctf.md)
  2. [Environnment Web](zone_ctf/environnement_web.md)
  3. [Environnment Système](zone_ctf/environnement_systeme.md)
  4. [CTFd](#)
