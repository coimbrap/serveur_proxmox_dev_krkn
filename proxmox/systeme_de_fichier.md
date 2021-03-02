# ZFS et de l'articulation des nodes

On a deux nodes en production il faut donc limiter au maximum le risque de perte de données. Pour cela nous allons mettre en place sur chaque node deux disques identique en RAID-1. Nous avons choisi ZFS comme système de fichier, CEPH à été envisagé puis abandonné car trop compliqué à mettre en place sur l'infrastructure sans grosse dépense.

Nous avons choisi d'avoir 2 pools ZFS indépendante pour que la réplication des données soit indépendante d'une node à l'autre.
