# Projet auto-hébergement Kr[HACK]en

Documentation par Pierre Coimbra.

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
	3. [Systèmes de fichiers et sauvegardes](#)
	4. [Cluster](proxmox/cluster)
	5. [Haute Disponibilitée](#)
	6. [Gestion de l'authentification](#)
	7. [Sécurisation des container / VM](#)
3. [Réseau](reseau)
	1. [Introduction à OpenvSwitch](reseau/introduction_ovs.md)
	2. [Topologie du réseau matériel](reseau/topologie_reseau_physique.md)
	3. [Topologie du réseau virtuel](reseau/topologie_reseau_virtuel.md)
	4. [Mise en place du réseau](reseau/mise_en_place.md)
	5. [Logique de l'assignation des adresses IP](reseau/logique_ip_ct_vm.md)
4. [Applicatif](applicatif)
	1. [Répartition des services dans les zones](applicatif/repartition_en_zones.md)
	2. [Zone WAN](applicatif/zone_wan)
	3. [Zone DMZ](applicatif/zone_dmz)
	4. [Zone Proxy](applicatif/zone_proxy)
	5. [Zone Interne](applicatif/zone_interne)
	6. [Zone CTF](applicatif/zone_ctf)
5. [Aide au déploiement](deploiement)
	1. [Introduction à Ansible](#)
	1. [Déploiement via Ansible](deploiement/deploiement_avec_ansible.md)
	3. [Notes et conseils](#)
