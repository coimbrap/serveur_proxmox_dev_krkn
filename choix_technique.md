# Choix technique

Afin de garantir la sécurité voici les mesures de sécurité que nous avons mis en place. Certaines de ces mesures sont différentes de celle présente dans la documentation.

## Création et configuration initiale

La création des CT/VM se fera via des rôles Ansible tout comme la configuration SSH et le déploiement des clés SSH.

- Création Conteneurs: https://github.com/coimbrap/ansible-role-create-ct
- Création VM: https://github.com/coimbrap/ansible-role-create-vm

## Déploiement

Le déploiement de l'intégralité de l'infrastructure se ferra via des rôles Ansible afin de permettre de tout remettre en place rapidement.

## Cloisonnement réseau

Les conteneurs/VMs seront séparés en plusieurs zones, chaque zone sera dans une VLAN séparée. La gestion des VLANs se ferra via OpenvSwitch.

- OpenvSwitch: https://github.com/coimbrap/ansible-role-openvswitch

## Firewall

Un firewall principal, de type OPNsense, sur chaque node avec une IP virtuelle sur la WAN,

Il s'occupera :

- Faire passer l'IP principale entre les deux nodes en fonction de la disponibilité
- D'autoriser que ce qui est nécessaire sur une zone
- Des communications entre zones qui sont nécessaire pour les proxy et l'administration
- De fournir un VPN pour l'administration du serveur

Chaque conteneur/VM aura un firewall plus léger du style UFW qui autorisera uniquement les ports nécessaire

- OPNsense: https://github.com/coimbrap/ansible-role-opnsense
- UFW: https://github.com/coimbrap/ansible-role-ufw

## Reverse proxy

Les reverse proxy sont séparés entre la partie CTF et la partie service,

- Un HAProxy en DMZ qui renvoie la partie CTF vers un reverse proxy spécifique pour la zone CTF et qui renvoie les requêtes sur la partie services sur le/les bons conteneurs
- Le reverse nginx pour la partie CTF est un choix, même si cela rajoute une seconde couche de proxy avant d'arriver au service cela permet de pouvoir modifier la configuration des environnements CTF sans toucher à HAProxy

En résumé : Zone CTF, deux couches de reverse proxy. Zone Interne pour les services, une seule couche de reverse proxy

- HAProxy: https://github.com/coimbrap/ansible-role-haproxy

Pour l'accès aux services il y aura obligatoirement un serveur internet nginx devant le service (ce n'est pas forcément le cas dans la documentationa actuelle).

## DNS

Gestion par vues avec une vue pour les résolutions depuis l'extérieur et une zone pour les résolutions interne.

- Un hidden master faisant autorité
- La vue externe sera accessible via un master/slave en frontend
- La vue interne sera accessible via un slave en backend

TSIG pour les transferts de zone et DNSSEC

- Bind: https://github.com/coimbrap/ansible-role-bind (en cours)

## Gestion des accès

### Partie Admin

Sans VPN il sera possible d'accéder au bastion et donc aux conteneurs du serveurs via SSH (limite à définir). Le VPN sera nécessaire pour accéder aux différents panels d'administration (PVE, PMG, OPNsense...)

- Pour ce qui est des accès sans VPN on utilisera un bastion avec des comptes nominatif et des logs, l'authentification se fera par clé SSH. La remonté des données se ferra probablement via l'annuaire LDAP.

- Pour la partie avec VPN ce sera des comptes nominatif soit locaux soit via l'annuaire LDAP en fonction des possibilités technique.

### Partie User

Pour la connexion aux services tout passera par un annuaire LDAP manageable via une interface web.

- Openldap: https://github.com/coimbrap/ansible-role-openldap

## Sauvegarde

Il faut tester Proxmox Backup Server, vérifier les ressources nécessaire et les fonctionnalités.

Deux options :

- Backup externalisé sur un tiers avec Borg Backup
- Backup entre nodes avec Proxmox Backup Server

Seul Borg Backup à été testé, il faut voir les performances avec Proxmox Backup Server

## Accès à l'extérieur, proxy cache et apt proxy

Les requêtes HTTP.S et APT passerons par
- Un proxy Squid pour HTTP.S
- Un proxy APT (apt-cacher-ng) pour apt

De cette manière les conteneurs n'auront pas directement accès à internet

- Squid: https://github.com/coimbrap/ansible-role-squid3
- Apt-Cacher: https://github.com/coimbrap/ansible-role-apt-cacher

## Certificats SSL/TLS

Pour Let's Encrypt on utilisera la validation par DNS ce qui permet de ne pas avoir de serveur à modifier pour l'obtention du certificats et de pouvoir obtenir des certificats wildcard

Pour ce qui des communication en "interne" (ex. entre un serveur et un proxy) on utilisera une autorité de certification locale cela nous sera aussi utile pour la partie LDAP

- Let's encrypt: https://github.com/coimbrap/ansible-role-letsencrypt-ovh (en cours)
- Selfsigned: https://github.com/coimbrap/ansible-role-self-signed-certs
