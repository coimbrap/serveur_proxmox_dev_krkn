# Mise en place du cluster entre nos deux nodes
Nous avons déjà mis en place :
- Proxmox VE 6 sur les deux nodes (Alpha et Beta)
- Un RAID1 ZFS sur chacune des nodes

## Préparation des deux nodes
Avant de monter le cluster, il faut permettre aux deux nodes de communiquer localement. Pour cela, nous allons rajouter une interface qui utilisera une carte réseau à part.

### /etc/network/interfaces
L'interface eth0 est configurée pendant l'installation de Proxmox. Proxmox utilise la première carte réseau pour communiquer avec l'extérieur (eth0).
On va mettre en place une interface supplémentaire directement reliée à l'autre node sur la seconde carte réseau (eth3) pour ne pas altérer le débit fourni par la première.
*Pour avoir la liste des interfaces matérielles on utilise dmesg  | grep eth*
##### Depuis Alpha on ajoute
```
auto eth3
iface eth3 inet static
  address 10.30.0.1
  netmask 255.255.255.0
```
##### Depuis Beta on ajoute
```
auto eth3
iface eth3 inet static
  address 10.30.0.2
  netmask 255.255.255.0
```
Nous avons désormais un multicast en place entre Alpha et Beta. Ainsi les hyperviseurs dialogueront entre eux localement sur une interface et seront reliés au net sur une autre interface. Matériellement il faut un câble croisé entre les deux ports correspondant à eth3.

### /etc/hosts
##### Depuis Alpha
```
127.0.0.1 localhost.localdomain localhost
192.168.2.30 alpha.krhacken.org alpha pvelocalhost
#Corosync
10.30.0.1 alpha-corosync.krhacken.org alpha-corosync
10.30.0.2 beta-corosync.krhacken.org beta-corosync
```

##### Depuis Beta
```
127.0.0.1 localhost.localdomain localhost
192.168.2.31 beta.krhacken.org beta pvelocalhost
#Corosync
10.30.0.1 alpha-corosync.krhacken.org alpha-corosync
10.30.0.2 beta-corosync.krhacken.org beta-corosync
```
Le multicast entre Alpha et Beta est désormais accessible via des hostnames.

### Création du cluster
Nous allons maintenant créer le cluster Sigma depuis Alpha,
```
pvecm create sigma --link0 alpha-corosync
```
On ajoute Beta au cluster Sigma directement depuis Beta
```
pvecm add alpha-corosync --link0 beta-corosync
```
Notre cluster Sigma est maintenant créé et corosync utilise une interface différente de celle utilisée pour les communications avec l'extérieur.
