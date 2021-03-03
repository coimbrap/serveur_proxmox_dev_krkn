# Différentes options pour la zone WAN

Pour l'accès au pare-feu du serveur, plusieurs options sont envisageables :

## En IPv4

NB: Il y aura un firewall de type OPNSense dans un VM sur chaque node. Il faut donc que l'IPv4 puisse être alloué à une VM.

Un firewall sur chaque serveur et une IPv4 publique (virtuelle) qui se déplacerait entre les deux firewall en fonction de leur disponibilité.

## En IPv6

Un réseau uniquement IPv6 serait plus compliqué à mettre en place au niveau des accès depuis des clients IPv4. Cependant un bloc d'IPv6 en plus d'une ou deux IPv4 serait un plus.

## Conclusion

Le choix qui serait le plus fiable au niveau de la gestion de la disponibilité du serveur serait une IPv4 pour l'accès au firewall avec un bloc d'IPv6 pour pouvoir rajouter progressivement le support de l'IPv6.
