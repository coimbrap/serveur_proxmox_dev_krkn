# Zone INT
Vous trouverez ici toute la documentation relative au fonctionnement et à la configuration applicative des services de la zone INT.

Cela comprend tous les containers des services sensible permanents (Nextcloud, Gitea...) et les services internes nécessaires au fonctionnement des services sensible comme l'annuaire LDAP.

## Réseau
Les services de la zone PROXY devront avoir les interfaces réseau suivante
- Bridge Interne VLAN 20 (PROXY)
- Bridge Interne VLAN 30 (INT)
- Bridge Admin VLAN 100 (ADMIN)

# Table des matières
1. [LDAP](ldap.md)
2. [Serveur Mail](mail.md)
