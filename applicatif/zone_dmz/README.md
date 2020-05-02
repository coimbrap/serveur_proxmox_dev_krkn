# Zone DMZ
Vous trouverez ici toute la documentation relative au fonctionnement et à la configuration de la DMZ.

Cela comprend les deux HAProxy, le serveur DNS et le proxy pour l'accès à internet des contenants.

## Réseau
Les services DMZ devront avoir l'interface réseau suivante :
- Bridge Interne VLAN 10 (DMZ)

# Table des matières
1. [HAProxy](haproxy)
  1. [Container HAProxy](haproxy/haproxy.md)
  2. [Certificat SSL Client](haproxy/certificat_ssl_client.md)
2. [Serveur DNS](dns.md)
3. [Proxy pour les conteneurs / VM](proxy_interne.md)
