# Zone WAN
Vous trouverez ici toute la documentation relative au fonctionnement et à la configuration applicative des services de la zone WAN.

Cela comprend les pare-feu et les hyperviseurs. C'est cette zone qui aura un accès direct à l'extérieur.

## Réseau

Les services DMZ devront avoir les interfaces réseau suivante
- Bridge WAN VLAN 10 (WAN)
- Bridge Admin VLAN 100 (ADMIN)

Pour OPNSense
- Bridge Interne VLAN 10 (DMZ)

# Table des matières
1. [OPNSense](opnsense)
  1. [Configuration de base](opnsense/configuration_initiale.md)
2. [Options possible pour l'accès extérieur](option_possible.md)
