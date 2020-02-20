## Présentation de l'infrastructure

### Infrastructure matérielle

Du côté infrastructure, nous disposons d'un rack 1U avec deux PC à l'intérieur possédant chacun 24Go de DDR3-ECC et un Xeon x5670 6 Coeurs cadencé à 2.93 GHz. Côté stockage, nous allons mettre en place un RAID1 ZFS avec deux disque par PC (les données du premier disque seront aussi présente sur le second) ainsi le stockage sera répliqué pour éviter toute perte de données.

Les 2 nodes du serveurs, que nous appellerons Alpha et Beta, auront Proxmox comme hyperviseur et seront en cluster grâce à Proxmox.

### Infrastructure logicielle

#### Infrastructure réseau du serveur
Les containers/VMs sensibles seront répliqués entre les deux nodes

L'infrastructure réseau du club s'articulerait de la manière suivante (sur chaque node) :
- OPNSense qui servira de Firewall de routeur.
- HAProxy qui servira de loadbalanceur entre les reverses proxy.
- NGINX qui fera office de reverse proxy entre HAProxy et les serveurs web autre que ceux des environnements CTF.
- Uniquement sur Beta, un reverse proxy NGINX qui servira de reverse proxy entre HAProxy et l'environnement CTF.

#### Services permanents
Les containers/VMs permettant l'accès à ces services ne sont pas détaillés ici.

L'infrastructure web du club s'articulerait de la manière suivante :
- Un annuaire LDAP (slapd), qui permettra d'avoir un compte unique pour accéder à tous nos services, avec des groupes limitant l'accès à certain services.
- Un serveur mail pour remplacer le serveur actuel hébergé chez OVH.
- Le site web du club.
- Le Wiki du club.
- NextCloud pour mettre en commun des fichiers au sein du club et l'ordre du jour des réunions.
- Gitea sur lequel toutes les sources de tous les challenges du club seront stockées ainsi que toute la documentation du club.
- Un service de messagerie instantanée du type Mattermost

L'objectif de ces services est de regrouper tous les hébergements utilisés par le club.

#### Environnements CTF
L'objectif est de remplacer la banque de challenge du club stockée actuellement sur un serveur en B141, serveur qui n'est pas documenté ce qui réduit considérablement les modifications que nous pouvons y apporter.

L'infrastructure CTF du club s'organisera de la manière suivante :
- Un premier CTFd avec tous les challenges actuels du club utilisés pour les OpenCTF.
- Un autre CTFd que nous utiliserons pour les sessions en externe comme par exemple pour la session 0.
- Une VM avec différents environnements Docker temporaires pour les challenges système.
- Une VM avec différents environnements Docker pour les challenges Web.

## Gestion du serveur en interne

Pour la gestion en interne du serveur, nous nous organiserions de la manière suivante,

- Seulement deux personnes du bureau auront le rôle d'administrateur système soit un accès total au serveur. Limiter le nombre d'administrateur système permet d'éviter tout problème d'administration.
- Le responsable technique aura le rôle du webmestre c'est à dire qu'il pourra intervenir sur les services comme le site web, le cloud... Cependant il ne pourra pas toucher à l'infrastructure réseau.
- Pour ce qui est de l'accès aux services web, tous les membres actifs du club y auront accès.
