# Introduction à la virtualisation

Proxmox est un hyperviseur de type 1 (« bare metal »), pour faire simple c’est une plateforme de virtualisation directement installé sur le serveur.

Contrairement à un hyperviseur de type 2 (VirtualBox par exemple), celui-ci n’exécute pas dans un autre OS. Il dispose de son propre OS adapté à la virtualisation.

Donc proxmox permet la virtualisation de plusieurs machine au sein d’un seul serveur. Il est aussi possible de monter deux ou plus serveur en cluster.

## Technologie de virtualisation propos

Proxmox propose deux types de virtualisation
- KVM qui est une technologie de virtualisation similaire à ce qui est offert par VirtualBox. Tout le matériel est émulé par l'hyperviseur. Ainsi, le système d'exploitation croit s'exécuter sur une vraie machine physique. Les ressource alloué sont considérer comme totalement utilisé par Proxmox.
- LXC qui utilise l'isolement pour séparer l'exécution de chaque machine. En comparaison à KVM, le matériel n'est pas émulé, il est partagé par le système hôte. Ainsi, chaque machine virtuelle utilise le même noyau.

Pour notre infrastructure nous utiliserons dès que possible des containers LXC. Cependant pour les environnements CTF nécessitant Docker et pour OPNSense nous utiliserons des VMs KVM.

## Qualité de Proxmox
Voilà un petit aperçu des fonctionnalité de Proxmox

- Création de containers LXC et de VM en quelques clics.
- Possibilité de modifier les ressources allouées aux contenants (RAM, disques, nombres d’interfaces réseau, VLANs...)
- La gestion des stockages (disques dur machines, images iso, templates LXC,...) est très simple est très bien intégré à l'interface web de Proxmox.
- L’interface permet une gestion complète des machines : Shell, éteindre, démarrer, redémarrer...
- Gestion de l’ensemble des VM depuis une seule interface web.
- Gestion des utilisateurs, de groupes d’utilisateurs et management de droits d’accès à des machines.
- Gestion de l’hyperviseur lui-même : Redémarrage, accès shell, monitoring réseau et charge cpu, RAM...
- La migration des contenants entre les nodes d'un cluster est également simple et rapide.
