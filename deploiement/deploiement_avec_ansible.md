# Ansible

Nous allons utilisé Ansible pour la création et la configuration de base (mise à jours, proxy...) de tout les conteneurs.

## Création du conteneur Ansible
Avant de lancer la création et l'installation de tout les conteneurs il vous faut mettre en place le réseau et les pare-feux ainsi au minimum l'interface admin sur le pare-feu (avec ip virtuelle en .254).

Une fois que c'est fait, créer un conteneur Ansible avec un numéro élevée (253 max).

- Resource Pool : ADMIN
- Disk size : 16 Gib
- Cores : 1
- Memory : 1024 Mib

### Réseau
Au niveau des interfaces réseau, une sur la partie admin, l'autre sur le zone proxy pour l'accès au futur proxy interne.

- eth0 : vmbr2 VLAN: 100 IP: 10.1.0.253/24 GW: 10.1.0.254
- eth1 : vmbr1 VLAN: 20 IP:10.0.1.200/24 GW:10.0.1.254

### Configuration initiale
Vous allez générer une clé ed25519 qui servira à l'administation des conteneurs.
```
ssh-keygen -o -a 100 -t ed25519 -f /root/.ssh/id_ed25519_ansible
```

La clé publique est dans `/root/.ssh/id_ed25519_ansible.pub`

### /etc/ssh/ssh_config
```
Host *
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
   IdentityFile ~/.ssh/id_ed25519_ansible
```

Avant d'installer Ansible, il faut que vous mettiez en place (vous-même) le conteneur du proxy interne. C'est le seul conteneur, avec celui d'Ansible, que vous aurez à créer.

### Connexion au proxy
On doit connecter le conteneur au proxy pour qu'il puisse utiliser wget et apt.

#### /root/.wgetrc
```
http_proxy = http://10.0.1.252:3128/
https_proxy = http://10.0.1.252:3128/
use_proxy = on
```
#### /etc/apt/apt.conf.d/01proxy
```
Acquire::http {
 Proxy "http://10.0.1.252:9999";
};
```


## Installation d'Ansible

```
apt-get update
apt-get dist-upgrade
apt-get install -y ansible python python3-proxmoxer
```
Il faut remplacer `/usr/lib/python3/dist-packages/ansible/modules/cloud/misc/proxmox.py` par le fichier proxmox.py fourni car ce fichier génère une erreur.

Maintenant que Ansible est en place, on va pouvoir installer tous les conteneurs nécessaires. L'installation va se faire par zone, en commençant par la zone DMZ.

Pour la création des conteneurs, nous allons utiliser la librairie python `proxmoxer` qui s'exécute en local. Pour toutes les autres tâches, Ansible se connectera via SSH au conteneur. Pour savoir sur quel conteneur exécuter son playbook, Ansible utilise un inventaire trouvable dans `/etc/ansible/hosts`.

Pour notre usage, nous allons faire des groupes pour chaque type de conteneur et un groupe pour chaque zone.

Il vous faut mettre le mot de passe root de proxmox et la clé publique du conteneur Ansible dans un fichier à l'adresse `/root/src/source_pve.yml` et restreindre la lecture `chmod 640 /root/src/source_pve.yml`.

Structure du fichier source_pve.yml :
```
pass_pve:
ssh_pub:
```

Par exemple, il y aura un groupe HAProxy regroupant tous les conteneurs HAProxy et un groupe DMZ regroupant tous les groupes de conteneurs DMZ.

## Zone DMZ

Un playbook Ansible est disponible pour la préparation de la zone DMZ, il s'occupera de l'installation de base. A vous de suivre la documentation pour la suite des opérations (sauf mention contraire).

Voici les tâches à réaliser avant de lancer le playbook.

### /etc/ansible/hosts
Ajoutez
```
[haproxy]
10.1.0.102 #HAProxy Alpha
10.1.0.103 #HAProxy Beta

[proxyint] #Proxy Interne
10.1.0.104

[dns]
10.1.0.107 #DNS

[zonedmz:children]
haproxy
proxyint
dns
```

Pour les mots de passe à vous de les générer, il vous faut ensuite les mettre dans ce fichier. Le mot de passe pour hasync et le même sur les deux HAProxy.

### /root/src/password_dmz.yml
```
pass_haproxy_master:
pass_haproxy_slave:
pass_hasync_same:
pass_dns:
```

### Templace Ferm et scripts pour les conteneurs

Le playbook Ansible s'occupe aussi de la mise en place d'un pare-feu. Une template a été réalisée pour la sécurisation des conteneurs avec ferm. Le détail de cette template est dans `proxmox/securisation/template_ferm.md`

Il vous faut mettre dans `/root/src/ferm/` les fichiers de configuration qui sont dans `sources/zone_dmz`

Une fois que tout est fait, vous trouverez le playbook sous le nom de `ct_dmz.yml` dans le dossier zone_dmz.

Lancez le avec
```
ansible-playbook ct_dmz.yml
```

Normalement tout les conteneurs sont créer. Le playbook `configure_dmz.yml` permet de configurer automatiquement le proxy interne et le DNS. Pour le DNS si vous souhaitez modifier la configuration changé la configuration dans `sources/zone_dmz/dns/bind`.

Lancez le avec
```
ansible-playbook configure_dmz.yml
```

## Zone PROXY

Comme pour la zone DMZ un playbook Ansible est disponible pour l'installation et la sécurisation de base des conteneurs de base de la zone PROXY. Cela comprend les deux reverse proxy Nginx et la mail gateway.

Voici les tâches à réaliser avant de lancer le playbook.

### /etc/ansible/hosts
Ajoutez
```
[nginx]
10.1.0.104 #Reverse Alpha
10.1.0.105 #Reverse Beta

[zoneproxy:children]
nginx
```

Pour les mots de passe à vous de les générer, il vous faut ensuite les mettre dans ce fichier.

### /root/src/password_proxy.yml
```
pass_nginx_master:
pass_nginx_slave:
```

### Templace Ferm pour les conteneurs

Le playbook Ansible s'occupe aussi de la mise en place d'un pare-feu. Une template a été réalisée pour la sécurisation des conteneurs avec ferm. Le détail de cette template est dans `proxmox/securisation/template_ferm.md`

Il vous faut mettre dans `/root/src/ferm/` les fichiers de configuration qui sont dans `sources/zone_proxy`

Une fois que tout est fait, vous trouverez le playbook sous le nom de `ct_proxy.yml` dans le dossier zone_proxy.

Lancez le avec
```
ansible-playbook ct_proxy.yml
```

Normalement tout est prêt, vous pouvez passer à la configuration des services.

## Zone Interne

Comme pour les autres zones un playbook Ansible est disponible pour l'installation et la sécurisation de base des conteneurs de base de la zone Interne.

Voici les tâches à réaliser avant de lancer le playbook.

### /etc/ansible/hosts
Ajoutez
```
[ldap]
10.1.0.108 #LDAPMaster

[mail]
10.1.0.109 #MailBackend

[webinterface]
10.1.0.110 #LDAPUI
10.1.0.111 #NextCloud
10.1.0.112 #Gitea

[zoneinterne:children]
ldap
mail
webinterface
```

Pour les mots de passe à vous de les générer, il vous faut ensuite les mettre dans ce fichier.

### /root/src/password_interne.yml
```
pass_ldap_master:
pass_mailback:
pass_ldap_webui:
pass_nextcloud:
pass_gitea:
```

### Templace Ferm pour les conteneurs

Le playbook Ansible s'occupe aussi de la mise en place d'un pare-feu. Une template a été réalisée pour la sécurisation des conteneurs avec ferm. Le détail de cette template est dans `proxmox/securisation/template_ferm.md`

Il vous faut mettre dans `/root/src/ferm/` les fichiers de configuration qui sont dans `sources/zone_interne`

Une fois que tout est fait, vous trouverez le playbook sous le nom de `ct_interne.yml` dans le dossier zone_interne.

Lancez le avec
```
ansible-playbook ct_interne.yml
```

Normalement tout est prêt, vous pouvez passer à la configuration des services.
