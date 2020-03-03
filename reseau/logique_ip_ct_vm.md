# Interfaces des containes / VM
Les addresse IP des conteneurs (en fonction des zones) sont décrite dans leur fiche de documentation et mis en place automatiquement par les playbook Ansible.

Si vous n'utilisez pas Ansible, vous touverez ici les bonnes manière pour choisir les adresses IP

## Zone ADMIN

Tout les conteneurs doivent avoir une interface réseau sur la VLAN 100 du switch administation ce qui permettra d'utiliser Ansible ou de faire, a terme, du monitoring.

Les IP seront de la forme `10.1.0.ID_PROXMOX` ou l'ID Proxmox est le numéro du contenant dans Proxmox

## Le reste

Pour les autres interfaces chosissez une adresse cohérente vis à vis des adresses déjà allouées, la liste est disponible [ici](mise_en_place.md).

Les IP sont organisé avec la logique suivante :
- Plus le service est important plus sont numéro est petit,
- Les IP des services redondé ainsi que leur éventuelle IP virtuelle se suivent.
