# Respect du quorum avec seulement deux nodes

La technologie corosync a besoin de 3 votes minimum pour avoir le quorum et éviter les risques de splitbrain en cas de crash d'une des nodes.

Nous ne disposons que de deux nodes, nous allons donc mettre en place un "Corosync External Vote". Il suffit d'un conteneur sur une autre machine que nous appellerons instance de quorum.

## Mise en place de l'instance de quorum

#### Sur le conteneur de l'instance de quorum
```
apt-get install corosync-qnetd
systemctl enable corosync-qnetd
systemctl start corosync-qnetd
```

#### Sur nos deux nodes
```
apt-get install corosync-qdevice
systemctl enable corosync-qdevice
systemctl start corosync-qdevice
```

#### Depuis chacune de nos nodes
```
ssh-copy-id -i /root/.ssh/id_rsa root@ip_autre_node
ssh-copy-id -i /root/.ssh/id_rsa root@ip_instance_quorum
```
## Ajout de l'instance au cluster sigma depuis Alpha

Maintenant que notre instance de quorum est configurée, nous allons l'ajouter au cluster Sigma
```
pvecm qdevice setup <ip_instance_quorum>
```

On vérifie que notre cluster contienne nos deux nodes et une instance de quorum
```
pvecm status
```

Nous avons maintenant trois votes, il y a donc suffisamment d'instances pour éviter le split-brain en cas de crash d'une node car, même avec une node en moins, le quorum sera respecté.
