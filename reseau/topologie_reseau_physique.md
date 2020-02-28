# Topologie du réseau physique

Chacune des nodes possède 4 interfaces réseau. Pour des questions de redondance et de débit nous allons mettre 2 de ces interfaces en Bond pour le réseau interne et la communication entre les deux serveurs. Les deux interfaces restantes seront utilisées pour l'accès à internet et pour le réseau d'administration.

- eth0 sur une interface simple utilisée uniquement par OPNSense via WAN
- eth2 formera le bridge OVS ADMIN
- eth1 et eth3 formeront le bond OVS bond0 sur le bridge OVS interne

Pour faire communiquer entre elles les deux nodes, il y aura un switch physique sur lequel sera branché les quatres interfaces des nodes et l'entité de quorum.
