# Zone PROXY
Vous trouverez ici toute la documentation relative au fonctionnement et à la configuration applicative des services de la zone PROXY.

Cela comprend tous les services faisant le lien entre la frontend et la backend (Reverse NGINX et Relais Mail).

## Réseau
Les services de la zone PROXY devront avoir les interfaces réseau suivantes :
- Bridge Interne VLAN 20 (PROXY)
- Bridge Interne VLAN 30 (INT)
- Bridge Admin VLAN 100 (ADMIN)

# Table des matières
1. [Reverse Proxy NGINX](nginx_principal.md)
2. [Relais mails](#)
