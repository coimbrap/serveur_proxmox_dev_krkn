# Respect du quorum avec seulement deux nodes

La technologie corosync à besoin de minimum 3 votes (quorum) pour éviter les risques de splitbrain en cas de crash d'un des nodes.

Nous ne disposons que de deux nodes, nous allons donc mettre en place un "Corosync External Vote". Il suffit d'un containers sur une autre machine que nous appelerons instance de quorum.

## Mise en place de l'instance de quorum

#### Sur le container de l'instance de quorum
```
apt-get install corosync-qnetd
```

#### Sur nos deux nodes
```
apt-get install corosync-qdevice
```

#### Sur l'instance de quorum et les deux nodes
```
rm /etc/init.d/corosync-qdevice
systemctl enable corosync-qdevice
systemctl start corosync-qdevice
```

## Ajout de l'instance au cluster sigma depuis Alpha

Maintenant que notre instance de quorum est configuré nous allons l'ajouter au cluster Sigma
```
pvecm qdevice setup <ip_instance_quorum>
```

On vérifie que notre cluster contienne nos deux nodes et une instance de quorum
```
pvecm status
```

Nous avons maintenant trois votes, il y a donc suffisamment d'instance pour éviter le split-brain en cas de crash d'une nodes car même avec une nodes en moins le quorum sera respecté.
