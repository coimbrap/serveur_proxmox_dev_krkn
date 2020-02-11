# Présentation du projet
Documentation par Pierre Coimbra.

Nous allons détailler ici l'usage que nous voudrions faire de ce serveur ainsi que tous nos choix sur la configuration et l'infrastructure.

## Objectif

Nos objectifs à la mise en place du serveur sont doubles. D'un côté, déplacer tous les services utilisés par le club (Web, NextCloud,Git...) afin d'avoir un contrôle total sur les services que nous utilisons. D'un autre côté, nous voudrions mettre en place une structure de CTF plus complète et plus documentée, accessible uniquement aux membres du club, et une autre infrastructure CTF que nous utiliserions à l'occasion d'événements du club comme par exemple pour la session 0. L'infrastructure que nous souhaitons mettre en place sera détaillée plus bas.

## Présentation de l'infrastructure

### Infrastructure matérielle
Du côté infrastructure, nous disposons d'un rack 1U avec deux PC à l'intérieur possédant chacun 24Go de DDR3-ECC et un Xeon x5670 6 Coeur cadencé à 2.93 GHz. Côté stockage, nous allons mettre en place un RAID1 ZFS pour chacune des nodes ainsi le stockage sera répliqué pour éviter toute perte de données.

Les 2 serveurs seront en cluster 2 noeuds avec Proxmox 6. Tous les services hébergés seront dans des containers différents.

L'un des buts de cette installation est d'avoir une documentation complète sur toute la mise en place du serveur et de Proxmox, mais aussi une documentation pour toutes les tâches d'administration ce qui permettra à nos successeurs de maintenir le serveur sans difficulté.

### Infrastructure logicielle

#### Infrastructure réseau du serveur
Tous les containers/VMs seront répliqués entre les deux nodes car ce sont des services sensibles
L'infrastructure réseau du club s'articulerait de la manière suivante (sur chaque node) :
- Une VM OPNSense qui servira de Firewall de routeur
- Un container HAProxy qui servira de loadbalancing entre les reverses proxy
- Un container NGINX Public qui servira de reverse proxy entre HAProxy et les services publics.
- Uniquement sur Bêta, un container avec NGINX qui servira de reverse proxy entre HAProxy l'environnement CTF.

#### Infrastructure publique du serveur
Les containers/VMs permettant l'accès à ces services ne sont pas détaillés ici.

L'infrastructure web du club s'articulerait de la manière suivante :
- Un container pour héberger le site web du club.
- Un container pour héberger le Wiki du club.
- Un NextCloud pour mettre en commun des fichiers au sein du club et l'ordre du jour des réunions.
- Un Git sur lequel toutes les sources de tous les challenges du club seront stockées ainsi que toute la documentation des services pour qu'ils puissent être maintenus dans le temps.
- Un service de messagerie instantanée du type Mattermost pour pouvoir communiquer simplement entre membres du club.
- Un serveur mail pour remplacer le serveur actuel hébergé chez OVH.
- Un annuaire LDAP (slapd), géré avec FusionDirectory, qui permettra d'avoir un compte unique pour accéder à tous nos services. Ces comptes seront créés uniquement pour les membres actifs du club et pour un responsable.

L'objectif de l'infrastructure web est de regrouper tous les hébergements utilisés par le club.

#### Infrastructure CTF du club
L'objectif est de remplacer la banque de challenge du club stockée actuellement sur un serveur en B141, serveur qui est très mal documenté ce qui réduit considérablement les modifications que nous pouvons y apporter.

L'infrastructure CTF du club s'organisera de la manière suivante :
- Un container CTFd avec tous les challenges actuels du club utilisés pour les OpenCTF.
- Un autre container CTFd que nous utiliserons pour les sessions en externe comme par exemple pour la session 0 ou il n'y a ni classement ni challenge récurrent.
- Une VM avec différents environnements Docker temporaires pour les challenges système.
- Une VM avec différents environnements Docker pour les challenges Web.

L'objectif de l'infrastructure CTF est de retrouver un contrôle sur notre banque de challenges pour pouvoir y ajouter des challenges et de pouvoir mettre en place des CTF temporaires pour les événements du club.

## Gestion du serveur en interne

Pour la gestion en interne du serveur, nous nous organiserions de la manière suivante : seulement deux personnes du bureau auront un accès total au serveur pour éviter tout problème d'administration. Les accès seront logés et les comptes nominatifs.
Pour ce qui est de l'accès aux services web, tous les membres actifs du club y auront accès, mais seul le responsable technique et les 2 personnes s'occupant du serveur auront les droits d'administration.
Pour ce qui est de l'accès au service CTF, seulement les responsables événements, technique et serveur y auront accès en tant qu'administrateurs, toutes les personnes participant à l'événement auront un accès à l'interface utilisateur de CTFd, les accès seront loggés.