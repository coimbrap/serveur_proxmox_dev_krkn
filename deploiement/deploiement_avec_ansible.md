# Ansible

Nous allons utilisé Ansible pour la création et la configuration de base (mise à jours, proxy...) de tout les container.

## Création du container Ansible
Avant de lancer la création et l'installation de tout les container il vous faut mettre en place le réseau et les pare-feux ainsi au minimum l'interface admin sur le pare-feu (avec ip virtuelle en .254).

Une fois que c'est fait, créer un container Ansible avec un numéro élevée (253 max).

### Réseau
Au niveau des interfaces réseau, une sur la partie admin, l'autre sur le zone proxy pour l'accès au futur proxy interne.

- eth0 : vmbr2 VLAN: 100 IP: 10.1.0.253/24 GW: 10.1.0.254
- eth1 : vmbr1 VLAN: 20 IP:10.0.1.200/24 GW:10.0.1.254

### Configuration initiale
Vous allez générer une clé ed25519 qui servira à l'administation des container.
```
ssh-keygen -o -a 100 -t ed25519 -f /root/.ssh/id_ed25519
```

Avant d'installer Ansible, il faut que vous mettiez en place (vous-même) le container du proxy interne. C'est le seul container, avec celui d'Ansible, que vous aurez à créer.

### Connexion au proxy
On doit connecter le container au proxy pour qu'il puisse utiliser wget et apt.

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
Il faut maintenant remplacer `/usr/lib/python3/dist-packages/ansible/modules/cloud/misc/proxmox.py` par le fichier proxmox.py qui est dans le même dossier.

Maintenant que Ansible est en place, on va pouvoir installer tous les container nécessaires. L'installation va se faire par zone, en commençant par la zone DMZ.

Pour la création des container, nous allons utiliser la librairie python `proxmoxer` qui s'exécute en local. Pour toutes les autres tâches, Ansible se connectera via SSH au container. Pour savoir sur quel container exécuter son playbook, Ansible utilise un inventaire trouvable dans `/etc/ansible/hosts`.

Pour notre usage, nous allons faire des groupes pour chaque type de container et un groupe pour chaque zone.

Il vous faut mettre le mot de passe root de proxmox et la clé publique du container Ansible dans un fichier à l'adresse `/root/src/source_pve.yml` et restreindre la lecture `chmod 640 /root/src/source_pve.yml`.

Structure du fichier source_pve.yml :
```
pass_pve:
ssh_pub:
```

Par exemple, il y aura un groupe HAProxy regroupant tous les container HAProxy et un groupe DMZ regroupant tous les groupes de container DMZ.


## Zone DMZ

Un playbook Ansible est disponible pour la préparation de la zone DMZ, il s'occupera de l'installation de base. A vous de suivre la documentation pour la suite des opérations (sauf mention contraire).

Voici les tâches à réaliser avant de lancer le playbook.

### /etc/ansible/hosts
Ajoutez
```
[haproxy]
10.1.0.100 #HAProxy Alpha
10.1.0.101 #HAProxy Beta

[dns]
10.1.0.106 #DNS

[zonedmz:children]
haproxy
dmz
```

Pour les mots de passe à vous de les générer, il vous faut ensuite les mettre dans ce fichier. Le mot de passe pour hasync et le même sur les deux HAProxy.

### /root/src/password_dmz.yml
```
pass_haproxy_master:
pass_haproxy_slave:
pass_hasync_same:
pass_dns:
```

### Templace Ferm pour les container

Le playbook Ansible s'occupe aussi de la mise en place d'un pare-feu. Une template a été réalisée pour la sécurisation des container avec ferm. Le détail de cette template est dans proxmox/securisation/template_ferm.md

Il vous faut mettre dans `/root/src/ferm/` les deux fichiers de configuration fournis (haproxy_ferm.conf & dns_ferm.conf)

Une fois que tout est fait, vous trouverez le playbook sous le nom de `ct_dmz.yml` dans le dossier zone_dmz.

Lancez le avec `ansible-playbook ct_dmz.yml`.

Normalement tout est prêt, vous pouvez passer à la configuration des services de la zone DMZ.
