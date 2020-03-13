# Installation des hyperviseurs

Proxmox étant un hyperviseur de type 1, nous allons l'installer sur les quatres nodes du serveur.

Pour cette installation, nous partons du principe que les quatres nodes ont accès à internet soit via une IP publique soit via un réseau privé. Cela ne change rien car nous modifierons la configuration réseau par la suite.

Pour l'installation il faut :
- Une clé USB,
- Deux disques durs de même taille pour chaque node.

## Installation de Proxmox
Procurez-vous la dernière version de Proxmox. Attention, l'installation initiale à été faite sous Proxmox 6.

Voilà le [lien](https://www.proxmox.com/en/downloads/category/iso-images-pve) de l'installateur

A vous de rendre une clé bootable avec cet iso.

### Sur la première node (Alpha)
- Mettre la clé USB sur l'un des ports USB de la première node (celle de droite),
- Brancher un clavier et un écran puis
- Démarrer l'installateur en allumant la node.
- Choisir "Install Proxmox VE" et accepter l'EULA.

#### Dans Proxmox Virtualization Environment

Target Harddisk -> Options
- Filesystem -> zfs (RAID1)

Disk Setup

- Harddisk 0 -> Un des 2 disques
- Harddisk 1 -> L'autre

#### Location and Time Zone selection
- Contry -> France
- Time zone -> Europe/Paris
- Keyboard Layout -> French

#### Administration Password and E-Mail Address

- Password -> Celui du gestionnaire keepass adminsys
- Confirm -> Pareil
- Email -> adminsys@krhacken.org

#### Management Network Configuration
- Hostname (FQDN) -> alpha.krhacken.org

Normalement une IP est automatiquement attribuée. Si ce n'est pas le cas, à vous de le faire.

#### Summary
Vérifier la cohérence et lancer l'installation.

### Sur la deuxième node (Beta)
Même procédure, dans "Management Network Configuration" il faut juste remplacer le Hostname par **beta.krhacken.org**

### Sur la troisième node (Gamma)
Même procédure, dans "Management Network Configuration" il faut juste remplacer le Hostname par **gamma.krhacken.org**

### Sur la deuxième node (Delta)
Même procédure, dans "Management Network Configuration" il faut juste remplacer le Hostname par **delta.krhacken.org**

## Préparation des hyperviseurs
La procédure est la même sur les quatres nodes. Elle peut être faite via SSH (recommandé) ou sur l'interface d'administration **https://IP:8006**

### Mise à jour
```
apt-get update
apt-get full-upgrade
```

### IP Forwarding
Activation permanente de l'IP Forwarding
#### /etc/sysctl.conf
Ajouter
```
net.ipv4.ip_forward = 1
```
```
sysctl -p /etc/sysctl.conf
```

### Templates LXC
Mise à jour de la liste
```
pveam update
```
Liste les templates disponibles
```
pveam available
```
Téléchargement de la dernière debian system
```
pveam download local debian-10.0-standard_10.0-1_amd64.tar.gz
```

### Images VM
Nous aurons besoin de VM OPNSense (Pare-Feu) et de VM debian, il faut donc télécharger les derniers ISO disponibles.

#### OPNSense
VM nécessaire car c'est une distribution Free-BSD

Obtention du lien de Téléchargement sur le [site officiel](https://opnsense.org/download/)

- Architecture -> amd64
- Select the image type -> dvd
- Mirror Location -> A vous de voir

Le lien donné sera utilisé par la suite

```
wget -P /var/lib/vz/template/iso <lien_obtenu>
bunzip2 /var/lib/vz/template/iso/*.bz2
```

#### Debian
VM nécessaire pour faire tourner efficacement Docker

Obtention du lien de Téléchargement sur le [site officiel](https://www.debian.org/distrib/netinst)

- Architecture -> amd64

Le lien donné sera utilisé par la suite

```
wget -P /var/lib/vz/template/iso <lien_obtenu>
```
