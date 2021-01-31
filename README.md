# Projet auto-hébergement Kr[HACK]en

Documentation par Pierre Coimbra.

Ce dépôt à surtout servis de déclencheur dans l'apprentissage de l'administration système. Il contient donc des erreurs qui seront corrigé et qui le sont dans mes différents roles ansible. La partie Ansible de ce projet n'est pas correcte je l'adapterai avec des roles ansible dans le futur.

## Motivation du projet
D'abord, l'idée est d'héberger tous les outils utilisés par le club (Web, NextCloud,Git...) afin d'avoir un contrôle total sur les services que nous utilisons. Ensuite, nous voudrions mettre en place une structure capable d'accueillir des environnements de CTF correctement cloisonnés par rapport aux services permanents du club.

## Porteurs du projet
- P. Coimbra
- D. Pressensé

## La philosophie
Le fait de reprendre le contrôle physique sur les infrastructures techniques utilisées au sein du club s'inscrit dans une démarche volontaire. Cela nous permettra d'élargir le champ de nos connaissances sur des problématiques concrètes.

L'indépendance financière et la pérennité sont des points clefs dans un projet d'une telle ampleur pour un petit club étudiant. Ainsi, le fait que nous ne soyons plus dépendants d'un service payant chez OVH nous libère de beaucoup de contraintes à la fois pécuniaires et organisationnelles. La documentation et la transmission des connaissances seront primordiales.

## Les responsabilités
Nous sommes conscients que dans un tel projet, le plus dur n'est pas de monter l'infrastructure, mais de la maintenir au fil des années. Les responsabilités seront donc gérées de manière extrêmement strictes, avec plusieurs niveaux d'accès. Il faudra en effet différencier le poste de webmestre, qui ne pourra agir que sur la partie applicative, de celui de l'administrateur système qui aura l'accès global. De grands pouvoirs appelant de grandes responsabilités, les adminsys en poste auront la
charge de former leur successeurs.

# Table des matières
1. [Présentation du Projet](presentation_projet.md)
2. [Proxmox](proxmox)
	1. [Introduction à la virtualisation](proxmox/introduction_a_la_virtualisation.md)
	2. [Installation des hyperviseurs](proxmox/installation_hyperviseurs.md)
	3. [Système de fichiers](proxmox/systeme_de_fichier.md)
	4. [Cluster](proxmox/creation_cluster.md)
	5. [Sécurisation](proxmox/securisation)
		1. [Sécurisation des accès aux hyperviseurs](proxmox/securisation/systeme_authentification_base.md)
		2. [Sécurisation des conteneurs / VM avec Ferm](proxmox/securisation/template_ferm.md)
	6. [Haute Dreisponibilité](proxmox/haute_disponibilite.md)
	7. [Système de sauvegarde](proxmox/sauvegarde)
3. [Réseau](reseau)
	1. [Introduction à OpenvSwitch](reseau/introduction_ovs.md)
	2. [Topologie globale du réseau](reseau/topologie_globale.md)
	3. [Topologie du réseau matériel](reseau/topologie_reseau_physique.md)
	4. [Topologie du réseau virtuel](reseau/topologie_reseau_virtuel.md)
	5. [Logique de l'assignation des adresses IP](reseau/logique_ip_ct_vm.md)
	6. [Mise en place du réseau](reseau/mise_en_place.md)
4. [Applicatif](applicatif)
	1. [Répartition des services dans les zones](applicatif/repartition_en_zones.md)
	2. [Zone WAN](applicatif/zone_wan)
		1. [OPNSense](applicatif/zone_wan/opnsense)
		2. [Options possible pour l'accès extérieur](applicatif/zone_wan/option_possible.md)
	3. [Zone DMZ](applicatif/zone_dmz)
		1. [HAProxy](applicatif/zone_dmz/haproxy)
		2. [Serveur DNS](applicatif/zone_dmz/dns.md)
		3. [Proxy pour les conteneurs / VM](applicatif/zone_dmz/proxy_interne.md)
	4. [Zone Proxy](applicatif/zone_proxy)
		1. [Reverse Proxy NGINX](applicatif/zone_proxy/nginx_principal.md)
		2. [Relais mails](#)
	5. [Zone Interne](applicatif/zone_interne)
		1. [LDAP](applicatif/zone_interne/ldap)
		2. [Serveur Mail](applicatif/zone_interne/mail.md)
		3. [NextCloud](applicatif/zone_interne/nextcloud.md)
		4. [Gitea](applicatif/zone_interne/gitea.md)
	6. [Zone CTF](applicatif/zone_ctf)
		1. [Reverse Proxy NGINX](applicatif/zone_ctf/nginx_ctf.md)
		2. [Environnement Web](applicatif/zone_ctf/environnement_web.md)
		3. [Environnement Système](applicatif/zone_ctf/environnement_systeme.md)
		4. [CTFd](#)
5. [Déploiement](deploiement)
	1. [Introduction à Ansible](#)
	2. [Déploiement via Ansible](deploiement/deploiement_avec_ansible.md)
