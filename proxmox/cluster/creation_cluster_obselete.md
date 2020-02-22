# Mise en place du cluster entre nos deux nodes
Il faut avoir mis en place le réseau avant de mettre les deux nodes en cluster.

Un lien externalisé entre Alpha et Beta est déjà en place grâce à un Int Port sur le VLAN 30 du switch administration.

Les nodes seront accessibles grâce au DNS interne via :
- alpha.krhacken.org -> 10.0.5.1
- beta.krhacken.org -> 10.0.5.2

La configuration des hostnames n'est normalement pas nécessaire car faite par le DNS interne. Cependant, il est préférable de la faire pour éviter les problèmes en cas de chute du DNS.

### /etc/hosts

##### Sur Alpha
```
127.0.0.1 localhost.localdomain localhost
X.X.X.X alpha.krhacken.org alpha pvelocalhost
#Corosync
10.0.5.1 alpha-corosync.krhacken.org alpha-corosync
10.0.5.2 beta-corosync.krhacken.org beta-corosync
```

##### Sur Beta
```
127.0.0.1 localhost.localdomain localhost
Y.Y.Y.Y beta.krhacken.org beta pvelocalhost
#Corosync
10.0.5.1 alpha-corosync.krhacken.org alpha-corosync
10.0.5.2 beta-corosync.krhacken.org beta-corosync
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
Notre cluster Sigma est maintenant créé et corosync utilise la VLAN 30 du switch administration pour communiquer.

Il est nécessaire de mettre rapidement en place l'instance de quorum pour éviter d'avoir des problèmes au seins du cluster.
