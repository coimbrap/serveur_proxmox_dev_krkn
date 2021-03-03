# Introduction à OpenvSwitch

Pour l'infrastructure réseau, nous utiliserons OpenvSwitch.

OpenvSwitch est une alternative aux bridges Linux classiques. Il permet de créer des switchs (L2/L3) virtuels au sein de Proxmox. Ces switchs virtuels gèrent très bien les VLANs. OpenvSwitch permet aussi à plusieurs switchs de communiquer entre eux via un lien trunk (GRE, VXLAN...).

## Explication rapide du fonctionnement

Fonctionnalités principales d'OpenvSwitch :
- OVS Bridge peut être comparé à un switch virtuel sur lequel on peut brancher des CT et VM sur des VLANs et qui peut communiquer avec un autre switch (bridge) via un tunnel GRE. Pour notre usage, le bridge n'aura pas d'IP sur l'hôte.
- OVS Bond permet d'attacher un groupe d'interfaces physiques (cartes réseau) à un Bridge OVS. Ce groupe d'interfaces physiques est considéré comme une seule interface virtuelle par le switch. Si deux cartes réseau forment un Bond, leur bande passante est additionnée et si l'une d'entre elles casse, l'autre prend le relais.
- OVS IntPort permet à l'hôte de se brancher au Bridge, d'avoir une IP et éventuellement une VLAN mais il est impossible de brancher des VMs ou des CT dessus.
