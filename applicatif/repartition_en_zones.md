# Répartition des services en zones

Les services seront répartis en plusieurs zones à la manière du découpage du réseau. Il est donc recommandé d'avoir compris l'infrastructure réseau avant de lire cette partie.


## Services Frontend

Les services Frontend sont directement accessibles depuis internet derrière OPNSense.

### Zone WAN

Cette zone regroupe les pare-feux et les hyperviseurs.

Les services DMZ devront avoir les interfaces réseau suivantes :
- Bridge WAN VLAN 10 (WAN)
- Bridge Admin VLAN 100 (ADMIN)

Pour OPNSense
- Bridge Interne VLAN 10 (DMZ)


### Zone DMZ

Cette zone regroupe les services qui nécessitent un accès direct à internet.

C'est le cas de,
- HAProxy, le proxy / loadbalanceur qui filtre les accès aux services depuis l'extérieur.
- Bind9, le serveur DNS qui servira à la fois de résolveur interne et de zone DNS pour le domaine krhacken.org.
- Squid, le proxy filtrant qui s'occupe de gérer l'accès à internet des conteneurs/VM

Les services DMZ devront avoir les interfaces réseau suivantes :
- Bridge Interne VLAN 10 (DMZ)
- Bridge Admin VLAN 100 (ADMIN)

Pour HAProxy
- Bridge Interne VLAN 20 (PROXY)
- Bridge Interne VLAN 40 (CTF)

Pour Bind9
- Bridge Interne VLAN 20 (PROXY)
- Bridge Interne VLAN 30 (INT)
- Bridge Interne VLAN 40 (CTF)

Pour Squid
- Bridge Interne VLAN 20 (PROXY)
- Bridge Interne VLAN 30 (INT)
- Bridge Interne VLAN 40 (CTF)
- Bridge Interne VLAN 50 (DIRTY)

## Services Backend

### Zone PROXY
Cette zone est une sorte de DMZ de DMZ, c'est à dire qu'elle se place entre la DMZ et la zone INT. Elle accueille les services faisant le lien entre la Frontend et la backend.

C'est le cas de
- NGINX qui servira de reverse proxy http
- Proxmox Mail Gateway, le relais entre l'extérieur et le serveur mail en backend qui s'occupe aussi de filtrer les mails (antispam et antivirus).

Les services de la zone PROXY devront avoir les interfaces réseau suivantes :
- Bridge Interne VLAN 20 (PROXY)
- Bridge Interne VLAN 30 (INT)
- Bridge Admin VLAN 100 (ADMIN)

### Zone INT
Cette zone regroupe les services sensibles permanents, donc tout sauf ce qui concerne les tests et les CTF. Elle contient uniquement des services backend.

C'est le cas de
- L'annuaire LDAP (slapd) qui permettra d'avoir un compte unique pour accéder à tous nos services, avec des groupes limitant l'accès à certains services.
- Du serveur mail qui sera en lien avec le relais mail présent dans le zone PROXY.
- Tous les autres services plus classiques (serveurs web, cloud, git...).

Les services de la zone INT devront avoir les interfaces réseau suivantes :
- Bridge Interne VLAN 30 (INT)
- Bridge Admin VLAN 100 (ADMIN)

### Zone CTF
Cette zone regroupe les différents services en rapport avec la partie CTF.

C'est le cas de
- NGINX qui servira de reverse proxy dédié à la partie CTF.
- VM avec du Docker pour les environnements Web et Système.
- CTFd qui servira d'interface utilisateur pour les CTF.

Les services de la zone CTF devront avoir les interfaces réseau suivantes :
- Bridge Interne VLAN 40 (CTF)
- Bridge Admin VLAN 100 (ADMIN)

### Zone DIRTY

Cette zone ne regroupe rien de spécial mis à part d'éventuels containers de test. Elle ne sera d'ailleurs pas documentée ici.

Les services de la zone DIRTY devront avoir les interfaces réseau suivantes :
- Bridge Interne VLAN 50 (DIRTY)
- Bridge Admin VLAN 100 (ADMIN)
