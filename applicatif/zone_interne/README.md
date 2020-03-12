# Zone INT
Vous trouverez ici toute la documentation relative au fonctionnement et à la configuration applicative des services de la zone INT.

Cela comprend tous les conteneurs des services sensibles permanents (Nextcloud, Gitea...) et les services internes nécessaires au fonctionnement des services sensibles comme l'annuaire LDAP.

## Réseau
Les services de la zone INT devront avoir les interfaces réseau suivantes :
- Bridge Interne VLAN 30 (INT)
- Bridge Admin VLAN 100 (ADMIN)

# Table des matières
1. [LDAP](ldap/README.md)
2. [Serveur Mail](mail.md)
3. [NextCloud](nextcloud.md)
4. [Gitea](gitea.md)
