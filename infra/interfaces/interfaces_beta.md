# Mise en place des interfaces de Beta

Nous allons ici mettre en place toutes les interfaces de Beta à l'exception du corosync qui utilisera  _eth2_.

## Configuration des interfaces
Nous disposons de deux cartes réseau avec chaqu'une deux ports ethernet. Nous allons utiliser ici _eth0_ qui sera l'interface relié à internet via le bridge entre Alpha et Beta.

### /etc/network/interfaces
```
auto lo
iface lo inet loopback

auto vmbr1
iface vmbr1 inet static
	address 10.10.0.2
	netmask 255.255.248.0
	bridge_ports none
	bridge_stp off
	bridge_fd 0
	post-up echo 1 > /proc/sys/net/ipv4/ip_forward

auto vmbr2
iface vmbr2 inet static
	address 10.20.0.2
	netmask	255.255.240.0
	bridge_ports none
	bridge_stp off
	bridge_fd 0
	post-up echo 1 > /proc/sys/net/ipv4/ip_forward
```

Nous avons configuré les interfaces de Beta. _vmbr0_ est un bridge sur _eth0_ et _vmbr1_ et _vmbr2_ sont des interfaces virtuelles géré avec shorewall.
