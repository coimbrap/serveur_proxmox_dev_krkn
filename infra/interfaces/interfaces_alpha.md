# Mise en place des interfaces de Alpha

Ici, nous allons mettre en place toutes les interfaces de Alpha à l'exception du bridge entre Alpha et Beta et du multicast pour le corosync qui utiliseront respectivement _eth1_ et _eth2_

## Configuration des interfaces
Nous disposons de deux cartes réseau avec chacune deux ports ethernet. Nous allons utiliser ici _eth0_ qui sera l'interface reliée à internet.

### /etc/network/interfaces
```
auto lo
iface lo inet loopback

iface eth0 inet manual

auto vmbr0
iface vmbr0 inet static
	address ip_publique
	netmask 255.255.252.0
	gateway ip_publique
	bridge_ports eth0
	bridge_stp off
	bridge_fd 0
	post-up echo 1 > /proc/sys/net/ipv4/ip_forward

auto vmbr1
iface vmbr1 inet static
	address 10.10.0.1
	netmask 255.255.248.0
	bridge_ports none
	bridge_stp off
	bridge_fd 0
	post-up echo 1 > /proc/sys/net/ipv4/ip_forward

auto vmbr2
iface vmbr2 inet static
	address 10.20.0.1
	netmask	255.255.240.0
	bridge_ports none
	bridge_stp off
	bridge_fd 0
	post-up echo 1 > /proc/sys/net/ipv4/ip_forward
```

Nous avons configuré les interfaces de Alpha. _vmbr0_ est un bridge sur _eth0_ et _vmbr1_ et _vmbr2_ sont des interfaces virtuelles gérées avec shorewall.
