# Projet auto-hébergement Kr[HACK]en

Documentation par Pierre Coimbra.

## Motivation du projet
D'abord, l'idée est d'héberger tous les outils utilisés par le club (Web, NextCloud,Git...) afin d'avoir un contrôle total sur les services que nous utilisons. Ensuite, nous voudrions mettre en place une structure capable d'accueillir des environnements de CTF correctement cloisonnée des services permanents du club.

## Porteurs du projet
- P. Coimbra
- D. Pressensé

## La philosophie
Le fait de reprendre le contrôle physique sur les infrastructures techniques utilisées au sein du club s'inscrit dans une démarche volontaire. Cela nous pemettra d'élargir le champs de nos connaissances sur des problématiques concrètes.

L'indépendance financière et la pérénité sont des points clefs dans un projet d'une telle ampleur un petit club étudiant. Ainsi le fait que nous ne soyions plus dépendants d'un service payant chez OVH, nous libère de beaucoup de contraintes à la fois pécunières et organisationnelles. La documentation et la transmission des connaissances sera primordiale.

## Les responsabilités
Nous sommes conscients que dans un tel projet, le plus dur n'est pas de monter l'infrastructure, mais de la maintenir au fil des années. Les responsabilités seront donc gérées de manière extrèmement strictes, avec plusieurs niveaux d'accès. Il faudra en effet différencier le poste du webmestre qui ne pourra agir que sur la partie applicative, de celui de l'administrateur système qui aura l'accès global. De grands pouvoirs appellant de grandes responsabilités, les adminsys en poste auront la
charge de former leur successeurs.

# Table des matières
0. [Présentation du Projet](presentation_projet.md)
0. [Proxmox](proxmox)
	0. [Introduction à la virtualisation](#)
	0. [Installation des hyperviseurs](#)
	0. [Systèmes de fichiers et sauvegardes](#)
	0. [Cluster](#)
	0. [Haute Disponibilitée](#)
	0. [Gestion de l'authentification](#)

0. [Réseau](reseau)
	0. [Introduction à OpenvSwitch](#)
	0. [Topologie du réseau matériel](#)
	0. [Topologie du réseau virtuel](#)
	0. [Mise en place du réseau](#)

0. [Applicatif](applicatif)
	0. [Répartition des services dans les zones](#)
	0. [Zone WAN](#)
	0. [Zone DMZ](#)
	0. [Zone Proxy](#)
	0. [Zone Interne](#)
	0. [Zone CTF](#)
	0. [Zone "Sale"](#)
