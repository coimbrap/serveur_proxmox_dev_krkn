# Zone DMZ
Vous trouverez ici toute la documentation relative au fonctionnement et à la configuration de la DMZ.

Cela comprend les deux HAProxy, le serveur DNS et le proxy pour l'accès à internet des contenants.

## Réseau
Les services DMZ devront avoir les interfaces réseau suivantes :
- Bridge Interne VLAN 10 (DMZ)
- Bridge Admin VLAN 100 (ADMIN)

Pour HAProxy
- Bridge Interne VLAN 20 (PROXY)
- Bridge Interne VLAN 40 (CTF)

Pour Bind9
- Bridge Interne VLAN 20 (PROXY)
- Bridge Interne VLAN 30 (INT)
- Bridge Interne VLAN 40 (CTF)

Pour Squid
- Bridge Interne VLAN 20 (PROXY)
- Bridge Interne VLAN 30 (INT)
- Bridge Interne VLAN 40 (CTF)
- Bridge Interne VLAN 50 (EXT)

# Table des matières
1. [HAProxy](haproxy.md)
2. [Serveur DNS](#)
3. [Proxy pour les contenants](#)
