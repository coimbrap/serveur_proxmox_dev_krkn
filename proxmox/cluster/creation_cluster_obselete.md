# Mise en place du cluster entre nos deux nodes
Il faut avoir mis en place le réseau avant de mettre les deux nodes en cluster.

Les nodes seront accessible grâce au DNS interne via
```
alpha.krhacken.org
beta.krhacken.org
```

Un lien externalisé entre Alpha et Beta est déjà en place.

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
