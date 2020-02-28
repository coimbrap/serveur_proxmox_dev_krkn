# Topologie du réseau virtuel

Rappel:
- eth0 sur un bridge OVS (vmbr0) accessible uniquement par OPNSense
- eth2 formera le bridge OVS Admin (vmbr2)
- eth1 et eth3 formerons le bond OVS bond0 sur le bridge OVS Interne (vmbr1)

Pour chacune des zones (INT ou CTF), il y a deux types de contenants (VM / CT) :
- Les services frontend qui sont directement accessibles depuis internet, derrière le pare-feu (OPNSense).
- Les services backend qui sont accessibles uniquement à travers une frontend.

## Les switchs virtuels

- Un switch WAN (vmbr0), qui permettra de réaliser le lien entre l'extérieur (via eth0) et les pare-feux et entre les pare-feux et les hyperviseurs.
- Un switch virtuel (vmbr1), en séparant le tout en plusieurs zones avec des VLANs, gèrera l'accès à Internet des services qui ne sont pas directement derrière le pare-feu (Nextcloud, Git, Serveur Web...) et les services qui sont directement derrière le pare-feu (HAProxy, DNS et Proxy Interne). Avec comme lien extérieur un bond entre eth1 et eth3.
- Un switch Administation (vmbr2) pour toute les tâches d'administration (Ansible, monitoring). Avec eth2 pour communiquer avec l'autre node.

## Communication des switchs entre les nodes

Tous les hyperviseurs auront une interface pour le protocole GRE qui permet l'échange entre les switchs virtuels de chaque node.
- Switch Interne -> VLAN 100
- Switch Administration -> VLAN 30

## Services Frontend

Concrètement, les conteneurs / VM frontend auront des ports d'entrée DNAT via le pare-feu, les rendant accessibles depuis internet. C'est le cas de HAProxy, du serveur DNS et du Proxy des services.

Tout ces conteneurs auront obligatoirement une interface sur le VLAN 10 et une VLAN backend du switch Interne.

## Services Backend

Les conteneurs ou VMs concernés ne seront pas accessibles depuis internet. Cependant, certains seront accessibles par l'intermédiaire de HAProxy (entre autres).

Cette partie sera découpée en plusieurs zones :
- PROXY sur le VLAN 20 qui contiendra les reverses proxy public et le relais mail,
- INT sur le VLAN 30 qui contiendra tous les services de la partie krhacken,
- CTF sur le VLAN 40 qui contiendra le reverse proxy CTF et les environnements CTF,
- DIRTY sur le VLAN 50 qui contiendra les environnements de test.

## Partie Internet

Tout les conteneurs et les VM Backend auront accès à internet via le proxy interne (en frontend). L'accès se fera depuis toutes les zones sur l'adresse terminant en .252.

## Partie Administration

- Chaque hyperviseur ainsi que l'entité de Quorum aura une interface sur le VLAN 10 du switch Administration. Elle servira au fonctionnement de Corosync (nécessaire au cluster Proxmox).
- Chaque hyperviseur aura une interface sur le VLAN 20 du switch Administration pour pfSync (HA du Firewall).
- Toutes les VM, tous les CT, les hyperviseurs et l'entité de Quorum auront une interface sur le VLAN 100 du switch Administration pour les tâches d'administration via le VPN ou localement en cas d'urgence.
