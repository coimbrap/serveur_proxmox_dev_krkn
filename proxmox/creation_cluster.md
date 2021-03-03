# Mise en place du cluster entre nos nodes

Il faut avoir mis en place le réseau avant de mettre les nodes en cluster.

Un lien externalisé entre les deux nodes est déjà en place grâce à un Int Port sur le VLAN 30 du switch administration.

Les nodes seront accessibles grâce au DNS interne via :
- alpha.krhacken.org -> 10.0.5.1
- beta.krhacken.org -> 10.0.5.2

Le cluster de production s'appellera Sigma et regroupera Alpha et Beta.

La configuration des Hostnames n'est normalement pas nécessaire car faite par le DNS interne. Cependant, il est préférable de la faire pour éviter les problèmes en cas de chute du DNS (car /etc/hosts consulté avant le DNS)

### /etc/hosts

##### Sur Alpha
```
127.0.0.1 localhost.localdomain localhost
X.X.X.X alpha.krhacken.org alpha pvelocalhost
#Corosync (pas toucher)
10.0.5.1 alpha-corosync.krhacken.org alpha-corosync
10.0.5.2 beta-corosync.krhacken.org beta-corosync
```

##### Sur Beta
```
127.0.0.1 localhost.localdomain localhost
Y.Y.Y.Y beta.krhacken.org beta pvelocalhost
#Corosync (pas toucher)
10.0.5.1 alpha-corosync.krhacken.org alpha-corosync
10.0.5.2 beta-corosync.krhacken.org beta-corosync
```

Alpha et Beta sont désormais accessibles via des Hostnames.

### Création du cluster
Nous allons maintenant créer le cluster Sigma depuis Alpha,
```
pvecm create sigma --link0 alpha-corosync
```
Puis on ajoute Beta au cluster Sigma directement depuis Beta,
```
pvecm add alpha-corosync --link0 beta-corosync
```
Notre cluster Sigma est maintenant créé et Corosync utilise la VLAN 30 du switch administration pour communiquer.
