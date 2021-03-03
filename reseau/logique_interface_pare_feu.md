# Choix des interfaces et des adresses IP

Petits récapitulatif sur comment on était choisi les interfaces sur chaque conteneurs / VM.

**Un container = Une interface**

Rappel sur l'ordre des zones :
- WAN/DMZ/INTERNE pour la partie Kr[HACK]en
- WAN/DMZ/CTF pour la partie CTF


Voici les règles pour le choix de l'interface du conteneur :
- Les conteneurs qui agissent sur plusieurs zones seront dans la zone la plus élevée.
- Les autres conteneurs seront dans la zone sur laquelle ils agissent.

Les IP sont organisé avec la logique suivante :
- Plus le service est important plus sont numéro est petit,
- Les IP des services redondé ainsi que leur éventuelle IP virtuelle se suivent.

La liste est disponible [ici](mise_en_place.md).

# Règles de pare-feu

Afin de permettre à un conteneur d'une zone de communiquer avec un conteneur d'une autre zone il y aura du routage entre VLAN qui sera géré au niveau de OPNSense, tout cela sera détaillé dans la partie OPNSense. Il y aura aussi un pare-feu sur chaque conteneur qui autorisera que ce qui est nécessaire, le détails est disponible [ici](../proxmox/securisation/template_ferm.md).

Donc deux types de pare-feu :
- Global au niveau d'OPNSense.
- Local sur chaque conteneur.
