# Topologie du réseau virtuel

Rappel:
- eth0 sur un bridge OVS (WAN) accessible uniquement par OPNSense
- eth2 formera le bridge OVS Admin
- eth1 et eth3 formerons le bond OVS bond0 sur le bridge OVS Interne

Pour chacune des zones (INT ou CTF) il y a deux types de VM/CT,

- Ceux qui sont directement accessible depuis internet derrière OPNSense c'est les services frontend.
- Ceux qui sont accessible uniquement à travers une frontend c'est les services backend.

## Les switchs virtuel

- Un switch WAN pour le lien entre l'extérieur, les pares-feu et les hyperviseurs avec comme lien extérieur eth0.
- Un switch Administation pour toute les tâches d'administration avec comme lien extérieur eth2.
- Un switch Interne qui devra gérer, avec des VLANs, l'accès (filtré) à internet des services qui ne sont pas directement derrière le FW (Nextcloud, Git, Serveur Web...) en séparant le tout en plusieurs zones et les services qui sont directement derrière le FW (HAProxy, Proxy des services, Mail et DNS). Avec comme lien extérieur un bond entre eth1 et eth3.

## Communication des switchs entre les nodes

Tout les hyperviseurs auront une pâte sur le VLAN 100 sur chaque switch pour le protocole GRE qui permet l'échange entre les switchs virtuel de chaque nodes.

## Services Frontend

Concrètement les containers concernés auront des ports d'entrée DNAT vers eux ce qui signifie qu'ils seront accessible depuis internet à travers le firewall. C'est le cas de HAProxy, du serveur DNS et du Proxy des services.

Tout ces CT auront obligatoirement une pâte sur la VLAN 10 et une VLAN backend du switch Interne.

## Services Backend

Les containers ou VMs concerné ne seront pas accessible depuis internet cependant certain seront accessible par l'intermédiaire de HAProxy (entre autres).

Cette parti sera découpé en plusieurs zones,
- PROXY sur la VLAN 20 qui contiendra les reverses proxy public et le relais mail,
- INT sur la VLAN 30 qui contiendra tout les services de la partie krhacken,
- CTF sur la VLAN 40 qui contiendra le reverse proxy CTF et les environnement CTF,
- DIRTY sur la VLAN 50 qui contiendra les environnement de test.

## Partie Internet

Tout les containers et les VM Backend auront accès à internet via le proxy interne (en frontend). Pour cela ils auront tous une pâte sur la VLAN 80 du switch interne.

## Partie Administration

- Chaque hyperviseur ainsi que l'entité de Quorum aura une pâte sur la VLAN 10 du switch Administration pour le fonctionnement de Corosync.
- Toutes les VM, tout les CT, les hyperviseurs et l'entité de Quorum auront une pâte sur la VLAN 20 du switch Administration pour les tâches d'administration via le VPN ou localement en cas d'urgence.
- Chaque hyperviseur aura une pâte sur la VLAN 30 su switch Administration pour pfSync (HA du Firewall).
