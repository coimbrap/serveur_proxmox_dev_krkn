# Introduction à OpenvSwitch

Pour l'infrastructure réseau nous utiliserons OpenvSwitch.

OpenvSwitch est une alternative aux bridges Linux classique. Il permet de créer des switchs (L2/L3) virtuel au seins de Proxmox qui peuvent communiquer entre eux via un lien trunk et qui gèrent très bien les VLANs.

## Explication rapide du fonctionnement

- OVS Bridge, c'est comme un switch, mais en virtualisé sur lequel on peu branché des CT et VM sur des VLANs et qui peux communiquer avec un autre Bridge via un tunnel GRE. Pour notre usage le bridge n'aura pas d'IP sur l'hôte.
- OVS Bond, permet d'attacher un groupe d'interface physique à un Bridge OVS ie. un groupe d'interface réseau à un switch virtuel.
- OVS IntPort, pas possible de bridge des VMs ou des CT dessus, il permet à l'hôte de se brancher au Bridge et d'avoir une IP et éventuellement une VLAN.
