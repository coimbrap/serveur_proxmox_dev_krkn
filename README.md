# Présentation du projet
Nous allons détailler ici l'usage que nous voudrions faire de ce serveur ainsi que tout nos choix sur la configuration et l'infrastructure.

## Objectif

Nos objectifs à la mise en place du serveur sont double. D'un côté déplacer tous les services utilisés par le club (Web, NextCloud,Git...) afin d'avoir un contrôle total sur les services que nous utilisons. D'un autre côté, nous voudrions mettre en place une structure de CTF plus complète et plus documentée accessible uniquement aux membres du club et une autre infrastructure CTF que nous utiliserions à l'occasion d'évènement du club comme par exemple pour la session 0. L'infrastructure que nous souhaitons mettre en place sera détaillée plus bas.

## Présentation de l'infrastructure

### Infrastructure matérielle
Du côté infrastructure, nous disposons d'un rack 1U avec deux PC à l'intérieur possédant chacun 24Go de DDR3-ECC et un Xeon x5670 6 Coeur cadencé à 2.93 GHz. Côté stockage nous allons mettre en place un RAID1 ZFS pour chacune des nodes ainsi le stockage sera répliqué pour éviter toute perte de donnée.

Les 2 serveurs seront en cluster 2 noeuds avec Proxmox 6. Tous les services hébergés seront dans des containers différents.

Un des but de cette installation est d'avoir une documentation complète sur toute la mise en place du serveur et de Proxmox, mais aussi une documentation pour toutes les tâches d'administration ce qui permettra à nos sucesseur de maintenir le serveur sans difficulté.

### Infrastructure logicielle


#### Infrastructure web du Club

L'infrastructure web du club s'articulerait de la manière suivante :


- Un serveur web pour héberger le site et le wiki du club accessible depuis www.krhacken.org,
- Un NextCloud pour mettre en commun des fichiers au sein du club, pour la gestion des mots de passe et de l'ordre du jour des réunions,
- Un Git sur lequel tout les sources de tout les challenges du club seront stockées ainsi que toute la documentation des services du club pour qu'ils puissent être maintenu dans le temps,
- Un service de messagerie instantanée du type Mattermost pour pouvoir communiquer simplement entre les membres du club,
- Un serveur mail pour remplacer le serveur actuel hébergé chez OVH,
- Un annuaire LDAP qui sera géré avec la future interfaçe de NexCloud 17 qui permettra d'avoir un compte unique pour accéder à tous nos services. Ces comptes seront créé uniquement pour les membres actifs du club pour un responsable.

L'objectif de l'infrastructure web est de regrouper tous les hébergements utilisés par le club.


#### Infrastructure CTF du club

L'infrastructure CTF du club s'organisera de la manière suivante :

- Un container avec la banque de challenge du club stockée actuellement sur le serveur en B141, serveur qui est très mal documenté ce qui réduit considérablement les modifications que nous pouvons y apporter,
- Un autre container CTFd que nous utiliserons pour les sessions en externe comme par exemple pour la session 0 ou il n'y a ni classement ni challenge récurrent.

L'objectif de l'infrastructure CTF est de retrouver un contrôle sur notre banque de challenges pour pouvoir y ajouter des challenges et de pouvoir mettre en place des CTF temporaires pour les événements du club.

## Gestion du serveur en interne

Pour la gestion en interne du serveur, nous nous organiserions de la manière suivante, seulement deux personnes du bureau auront un accès total au serveur pour éviter tout problème d'administration. Les accès seront logés et les comptes nominatif.
Pour ce qui est de l'accès aux services web, tous les membres actifs du club y auront accès, mais seul le responsable technique et les 2 personnes s'occupant du serveur auront les droits d'administration.
Pour ce qui est de l'accès au service CTF, seulement les responsables événements, technique et serveur y auront accès en tant qu'administrateur, toutes les personnes participant à l'événement auront un accès à le parti utilisateur de CTFd, les accès seront loggés.