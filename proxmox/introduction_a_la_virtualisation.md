# Introduction à la virtualisation

Proxmox est un hyperviseur de type 1 (bare metal). C’est une plateforme de virtualisation directement installée sur le serveur.

Contrairement à un hyperviseur de type 2 (VirtualBox par exemple), Proxmox ne s'exécute pas dans un autre OS mais dispose de son propre OS (basé sur Debian) adapté à la virtualisation.

Donc, Proxmox permet la virtualisation de plusieurs machines au sein d’un seul serveur. Proxmox nous permettra aussi des mettre les quatres nodes du serveur en cluster permettant entre autre de migrer des contenants d'une node à l'autre en cas de chute de l'une d'elles grâce aux fonctions de Haute Disponibilité de Proxmox.

## Technologie de virtualisation

Proxmox propose deux types de virtualisation :
- Une technologie de virtualisation (KVM) similaire à celle qui est offerte par VirtualBox. Tout le matériel est émulé par l'hyperviseur, ainsi le système d'exploitation croit s'exécuter sur une machine physique. Les ressources allouées sont considérées comme totalement utilisées par Proxmox. Si la VM a 2Go de RAM, l'hyperviseur lui alloue en permanence 2Go de RAM.
- Une technologie de conteneurisation (LXC) qui utilise l'isolement pour séparer l'exécution de chaque environnement virtuel. En comparaison à KVM, le matériel n'est pas émulé, il est partagé par le système hôte, ainsi tous les conteneurs utilisent le même noyau. Seules les ressources vraiment utilisées par le conteneur sont considérées comme utilisées par Proxmox. Si on alloue 2Go de RAM au conteneur et qu'il en utilise un seul, l'hyperviseur ne lui alloue qu'un 1Go.

Pour notre infrastructure, nous utiliserons le plus possible des conteneurs LXC. Cependant, pour les environnements CTF nécessitant Docker et pour le pare-feu (OPNSense), nous utiliserons des VM KVM.

## Qualité de Proxmox
Voici un petit aperçu des fonctionnalités de Proxmox :
- Création de conteneurs LXC et de VM en quelques clics.
- Possibilité de modifier les ressources allouées aux contenants (RAM, disques, nombres d’interfaces réseau, VLANs...)
- Gestion des stockages (disques durs des machines, images iso, templates LXC,...) très simple et très bien intégrée à l'interface web.
- Gestion complète des machines : Shell, éteindre, démarrer, redémarrer...
- Gestion de l’ensemble des machines depuis une seule interface web.
- Gestion des utilisateurs, de groupes d’utilisateurs et management des droits d’accès aux machines.
- Gestion de l’hyperviseur lui-même : Redémarrage, accès shell, monitoring réseau et charge CPU, RAM...
- Migration des contenants entre les nodes d'un cluster simple et rapide.
