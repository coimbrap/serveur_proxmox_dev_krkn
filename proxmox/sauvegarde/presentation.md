# Présentation du système de sauvegarde

Afin de limiter encore plus le risque de perte de données nous allons mettre en place un système de sauvegarde de tout les conteneurs / VMs. Nous allons utilisé BorgBackup, le réseau de sauvegarde est un réseau local, en effet la quatrième node sera dédié au système de sauvegarde. De ce fait elle ne sera pas dans le cluster, au niveau du système de fichier nous utiliserons la encore un RAID-1 ZFS. Les sauvegardes passerons par la VLAN 100 du switch administration (10.1.0.0/24).

Au niveau du réseau, la nodes aura accès uniquement au switch administration, l'accès à internet se fera à travers le proxy interne qui porte l'adresse `10.1.0.103` sur la VLAN 100, les ports ne changent pas.

## BorgBackup

Les avantages de BorgBackup sont :
- Les sauvergardes incrémentales (historique des anciennes versions des fichiers),
- Les sauvergardes différentielles (sauvegarde uniquement les modifications),
- Compression lz4 qui est très rapide et efficace,
- Ne sauvegarde qu'une seule fois les fichiers doublons,
- Vérification de l'intégrité des données,
- Les sauvegardes sont accessible sous forme de dossier,
- Sauvegarde via SSH.
