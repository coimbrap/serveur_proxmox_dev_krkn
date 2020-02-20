# Firewall

Au niveau du pare-feu nous allons utiliser OPNSense (fork de pfSense). Les deux nodes auront une VM avec OPNSense pour la Haute Disponibilité, l'IP publique (WAN) se déplacera entre les deux VM grâce à une IP virtuelle à CARP et à pfSense. Ca sera la même chose pour la gateway sur chaque interface.

## Les interfaces
- Interface d'entrée WAN (vmbr0)
- Interfaces de sortie ROUTE, KRKN, CTF, EXT (vmbr1 et vmbr2)

Toutes les autres interfaçe seront pour des liens purement locaux (Corosync, pfSync et VXLAN) donc géré avec un parefeu local type UFW et non par OPNSense.

## Configuration de la VM
- Guest OS : Other
- Bus Device : VirtIO Block
- Network device model : VirtIO (paravirtualized)

Il faudra ensuite ajouter au moins deux interfaces réseau.

## Installation du système
Il faut récupérer une image iso "DVD" sur le site d'OpnSense

Lors du démarrage il faut utiliser,
- login : installer
- pass : opnsense

Ne pas configurer de VLANs.

Une fois installation terminée, quitter le programme d'installation et redémarrer la VM.

## Premiers paramétrages d'OPNSense
### Interfaces
Une fois la VM rédémarrée pour la première fois, il faut faut assigner les interfaces, choix 1 dans le menu (assign interfaces).
Il faut configurer 2 interfaces pour commencer, une le WAN (vmbr0) et une pour le LAN (vmbr1). On ajoutera le reste plus tard.


# En attente du choix WAN...

### Règles (uniquement DNAT)
- DNAT 80,443 route:10.0.0.5
- DNAT 25,465,587,143,993,4190 krkn:10.0.1.10
- DNAT 2222 ctf:10.0.2.12
- DNAT 8081,8082,8083,8084,8085,8086,8087,8088,8089,8090,8091 ctf:10.0.2.13