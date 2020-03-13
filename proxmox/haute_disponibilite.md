# Haute Disponibilité

Nous allons utiliser deux types de Hautes Disponibilité (HA) :
- La solution de HA proposé par Proxmox qui permet de migrer des conteneurs entre des nodes,
- De la Haute Disponibilité via une IP Virtuelle grâce à Keep-alived.

Pour les services vitaux (HAProxy, NGINX, LDAP...) nous utiliserons une IP virtuelle, les services seront déjà présent sur toute les nodes c'est keepalived qui s'occupera de toujours rendre accessible le service.

Pour les services moins important (Cloud, Git...) nous utiliserons la solution proposé par Proxmox.

Nous avons fait cette distinction car ZFS ne permet pas la migration instantanée d'un conteneur en cas de chute d'une node, surtout s'il doit migrer plusieurs conteneurs en même temps.

Les services redondés et utilisant keepalived seront :
- HAProxy : un conteneur sur chaque node, celui de Alpha sera Master,
- NGINX : un conteneur sur chaque node load-balancing par HAProxy,
- LDAP : un conteneur sur chaque node, réplication des données grâce à slapd et accessibilité / loadbalancing via Keepalived,
- Redis : un conteneur sur Alpha, un sur Sigma,
- Service Mail : un conteneur sur Alpha, un sur Sigma,
- DNS : un conteneur sur Alpha un sur Sigma.


## Répartition non exhaustive des conteneurs entre les nodes

OPNSense -> Alpha, Beta et Sigma
HAProxy -> Alpha, Beta et Sigma
NGINX -> Alpha, Beta et Sigma
Redis -> Alpha et Sigma
LDAP -> Alpha et Sigma
Git -> Alpha
Mattermost -> Alpha
NextCloud -> Beta
Mail -> Alpha et Sigma
CTF -> Beta (3 services)
LDAPUI -> Alpha
DNS -> Beta
Proxy interne -> Beta
Ansible -> Alpha
Site Web KRKN -> Sigma
Wiki KRKN -> Beta
Etat des services -> Alpha

Possibilité d'héberger des VPS d'autres Club sur la node Sigma (VLAN dédié) si accord et si stabilité.
