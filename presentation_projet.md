## Présentation de l'infrastructure

### Infrastructure matérielle

Du côté infrastructure, nous disposons d'un rack 1U avec deux PC à l'intérieur possédant chacun 24Go de DDR3-ECC et un Xeon x5670 6 Coeurs cadencé à 2.93 GHz. Côté stockage, nous allons mettre en place un RAID1 ZFS avec deux disques par PC (les données du premier disque seront aussi présentes sur le second) ainsi le stockage sera répliqué pour éviter toute perte de données.

Les 2 nodes du serveur, que nous appellerons Alpha et Beta, auront Proxmox comme hyperviseur et seront en cluster grâce à Proxmox.

### Infrastructure logicielle

#### Infrastructure réseau du serveur
Les containers/VMs sensibles seront répliqués entre les deux nodes

L'infrastructure réseau du club s'articulerait de la manière suivante (sur chaque node) :
- Un bloc pare-feu / routeur (OPNSense).
- Un répartiteur de charge qui permettra de répartir les requêtes web entre le reverse proxy de la partie CTF et les reverse proxy de la partie Club (HAProxy).
- Les reverse proxy (NGINX) de la partie Club redirigeront les requêtes vers les serveurs web internes (Site Web, Cloud...).
- Le reverse proxy (NGINX) de la partie CTF redirigera les requêtes vers les différents environnements CTF (CTFd, Challenges Web...).

#### Services permanents
Les containers/VMs permettant l'accès à ces services ne sont pas détaillés ici.

L'infrastructure du club s'articulerait de la manière suivante :
- Le site web du club.
- Le Wiki du club.
- Un serveur mail pour remplacer le service fourni par OVH.

Avec en plus,
- Un annuaire LDAP (slapd), qui permettra d'avoir un compte unique pour chaque utilisateur et de définir différents groupes d'utilisateurs.
- Un cloud (NextCloud) pour mettre en commun des fichiers au sein du club et l'ordre du jour des réunions.
- Un serveur Git (Gitea) sur lequel toutes les sources des challenges du club seront stockées ainsi que la documentation du club.
- Un service de messagerie instantanée du type Mattermost.
- Et d'autres services...

Ce qui permettrait d'auto-héberger tous les services du club.

#### Environnements CTF
L'objectif est de remplacer la banque de challenge du club stockée actuellement sur un poste en B141. Celui-ci n'est pas documenté, ce qui réduit les modifications que nous pouvons y apporter.

A partir des sources des challenges actuels une nouvelle infrastructure CTF prendra forme, elle s'organisera de la manière suivante :
- Un premier CTFd avec tous les challenges du club utilisés pour les OpenCTF.
- Un autre CTFd que nous utiliserons pour les sessions en externe, comme par exemple pour la session 0.
- Une VM avec différents environnements Docker temporaires pour les challenges système.
- Une VM avec différents environnements Docker pour les challenges Web.

## Gestion du serveur en interne

Pour la gestion en interne du serveur, nous nous organiserions de la manière suivante :
- Seules deux personnes du bureau auront le rôle d'administrateur système, soit tous les droits sur le serveur.
- Le responsable technique du club aura le rôle du webmestre, il pourra intervenir sur les services comme le site web, le cloud... Cependant, il ne pourra pas toucher à l'infrastructure autour.
- Tous les membres actifs du club auront accès aux services web.
