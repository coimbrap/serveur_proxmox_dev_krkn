# Installation des hyperviseurs

Proxmox étant un hyperviseur de type 1 il possède son propre OS, c'est donc ça que nous devons installer sur les deux nodes du serveur.

Pour cette installation nous partons du principe que les deux nodes on accès à internet soit via une IP publique soit via une réseau privée. Cela ne change rien car nous modifierons la configuration réseau par la suite.

Pour l'installation il faut
- Une clé USB
- Deux disques dur de même taille pour chaque node

## Installation de Proxmox
Procurez-vous la dernière version de Proxmox, attention l'installation initiale à été faire sous Proxmox 6.

Voilà le [lien](https://www.proxmox.com/en/downloads/category/iso-images-pve) de l'installateur

A vous de rendre une clé bootable avec cet iso.

### Sur la première node (Alpha)
Mettez la clé USB sur un des ports USB de la première nodes (celle de droite), branchez un clavier et un écran puis démarrer l'installation.

Choissisez Install Proxmox VE et acceptez l'EULA.
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

Normalement un IP est automatiquement attribué. Si ce n'est pas le cas à vous de le faire.

#### Summary
Vérifier la cohérence et lancer l'installation.

### Sur la deuxième node (Beta)
Même procédure, il faut juste dans "Management Network Configuration" remplacer le Hostname par **beta.krhacken.org**

## Préparation des hyperviseurs
La procédure est la même sur les deux nodes. Elle peux être faites via SSH (recommandé) ou sur l'interface d'administration **https://IP:8006**

### Mise à jour
```
apt-get update
apt-get full-upgrade
```

### Templates LXC
Mise à jours de la liste
```
pveam update
```
Liste les templates disponible
```
pveam available
```
Téléchargement le la dernière debian system
```
pveam download local debian-10.0-standard_10.0-1_amd64.tar.gz
```

### Images VM
Nous aurons besoin de VM OPNSense (Pare-Feu) et de VM debian, il faut donc télécharger les derniers ISO disponible

#### OPNSense
VM nécessaire car c'est une distribution Free-BSD

Obtention du lien de Téléchargement sur le [site officiel](https://opnsense.org/download/)

- Architecture -> amd64
- Select the image type -> dvd
- Mirror Location -> A vous de voir

Le lien donné sera utilisé par la suite

```
wget -P /var/lib/vz/template/iso <lien_obtenu>
```

#### Debian
VM nécessaire pour faire tourner efficacement Docker

Obtention du lien de Téléchargement sur le [site officiel](https://www.debian.org/distrib/netinst)

- Architecture -> amd64

Le lien donné sera utilisé par la suite

```
wget -P /var/lib/vz/template/iso <lien_obtenu>
```
