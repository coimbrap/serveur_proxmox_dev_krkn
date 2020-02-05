# Différentes option pour la zone WAN

Pour l'accès au pare feu du serveur plusieurs options sont envisageable,

## En ipv4

NB: Il y aura un firewall de type OPNSense dans un VM sur chaque nodes il faut donc que l'ipv4 puisse être alloué à une VM.

### Une seule ipv4 
Un firewall sur chaque serveur et une ipv4 publique (virtuelle) qui se déplacerait entre les deux firewall en fonction de leur disponibilité.

### Deux ipv4 
Deux combinaisons possible
- Une par serveur avec un firewall sur chaque serveur, le choix du serveur se ferrait au niveau des entrée DNS.
- Une pour l'accès au firewall sur le même modèle que décrit pour une seule ipv4 et une autre pour un accès direct au serveur sans passé par le firewall principal.

## En ipv6 
Un réseau uniquement ipv6 serait plus compliqué à mettre en place au niveau des accès depuis des client ipv4. Cependant un bloc d'ipv6 en plus d'une ou deux ipv4 serait un plus.

## Conclusion

Le choix qui serait le plus fiable au niveau de la gestion de la disponibilité du serveurs serait une ipv4 pour l'accès au firewall et une seconde ipv4 pour l'accès direct au serveur car plus sur en cas de crash des deux VM. Avec un bloc d'ipv6 pour pouvoir rajouter progressivement le support de l'ipv6.