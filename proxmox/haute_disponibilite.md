# Haute Disponibilité

**Partie Brouillon**

Nous allons utiliser deux types de Haute Disponibilité (HA) :
- La solution de HA proposée par Proxmox qui permet de migrer des conteneurs entre des nodes,
- De la Haute Disponibilité via une IP Virtuelle grâce à Keep-alived.

Pour les services vitaux (HAProxy, NGINX, LDAP...) nous utiliserons une IP virtuelle, les services seront déjà présents sur toute les nodes c'est keepalived qui s'occupera de toujours rendre accessible le service.

Pour les services moins importants (Cloud, Git...) nous utiliserons la solution proposée par Proxmox.

Nous avons fait cette distinction car ZFS ne permet pas la migration instantanée d'un conteneur en cas de chute d'une node, surtout s'il doit migrer plusieurs conteneurs en même temps.

Les services redondés et utilisant keepalived seront :
- HAProxy : un conteneur sur chaque node, celui de Alpha sera Master,
- NGINX : un conteneur sur chaque node load-balancing par HAProxy,
- LDAP : un conteneur sur chaque node, réplication des données grâce à slapd et accessibilité / loadbalancing via Keepalived,
- Redis : un conteneur sur Alpha, un sur Beta,
- Service Mail : un conteneur sur Alpha,
- DNS : un conteneur sur Alpha


## Répartition non exhaustive des conteneurs entre les nodes

En réflexion

- OPNSense -> Alpha et Beta
- HAProxy -> Alpha et Beta
- NGINX -> Alpha et Beta
- Redis -> Alpha et Beta
- LDAP -> Alpha et Beta
- Git -> Alpha
- Mattermost -> Alpha
- NextCloud -> Beta
- Mail -> Alpha
- CTF -> Beta (3 services)
- LDAPUI -> Alpha
- DNS -> Beta
- Proxy interne -> Beta
- Ansible -> Alpha
- Site Web KRKN -> Alpha
- Wiki KRKN -> Beta
- Etat des services -> Alpha

Possibilité d'héberger des VPS d'autres Clubs sur la node Sigma (VLAN dédié) si accord et si stabilité.
