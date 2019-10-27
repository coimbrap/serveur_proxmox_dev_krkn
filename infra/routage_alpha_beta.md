# Mise en place d'un bridge de Alpha à Beta pour l'accès à internet

Nous allons ici mettre en place un bridge entre Alpha et Beta. Seul Alpha disposera d'une IP publique et d'un accès à internet. Alpha joura le rôle de routeur en fournissant à Beta un accès à internet à travers son firewall.

## Configuration des interfaces
Nous allons configurer la carte réseau eth1 sur Alpha et eth0 sur Beta pour mettre en place le bridge.

- eth1 sera le port du bridge sur Alpha
- eth0 sera le port du bridge sur Beta

Un câble relira eth1 et eth0 pour donner à Beta l'accès à internet

### Sur Alpha
### /etc/network/interfaces
```
allow-hotplug eth1
iface eth1 inet static
	address 10.40.0.1
	netmask 255.255.255.0
	gateway	10.40.0.1
```

### Sur Beta
### /etc/network/interfaces

```
iface eth0 inet manual

auto vmbr0
iface vmbr0 inet static
	address 10.40.0.2
	netmask 255.255.255.0
	gateway 10.40.0.1
	bridge_ports eth0
	bridge_stp off
	bridge_fd 0
	post-up echo 1 > /proc/sys/net/ipv4/ip_forward
	
```

Nous avons maintenant un bridge entre Alpha et Beta. La configuration du firewall pour que le bridge soit opérationnel se trouve dans _infra/shorewall_