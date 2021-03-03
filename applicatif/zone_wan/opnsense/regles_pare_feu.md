# Règles du pare-feu

Ces règles sont à faire sur le firewall de Alpha, elles seront automatiquement répliquées sur Beta.

Nous avons déjà mis en place les règles de NAT dans la configuration initiale. Nous allons maintenant nous occuper le définir et de mettre en place les règles pour les communications entre VLAN.

### Table de routage inter-VLAN

Doit être lu de la manière suivante :

- Les colonnes peuvent communiquer avec les lignes.
- Exemple : ADMIN peut communiquer avec DMZ mais l'inverse est impossible.

|             | WAN  | DMZ  | INTERNE | CTF  | DIRTY |
| ----------- | :--: | :--: | :-----: | :--: | :---: |
| **WAN**     |  X   |  X   |         |      |       |
| **DMZ**     |      |  X   |    X    |  X   |       |
| **PROXY**   |      |  X   |         |      |       |
| **INTERNE** |      |      |    X    |      |       |
| **CTF**     |      |  X   |         |  X   |       |
| **DIRTY**   |      |      |         |      |   X   |
| **ADMIN**   |      |      |         |      |       |

Ces communications restreintes à quelques IP et quelques port que nous allons détaillé par la suite.

## Règles OPNSense

Voici un résumé des règles principales, les règles plus détaillées seront présente dans les hosts_vars ansible.

Nomenclature générale d'une règle type 1 :

```
Interface : ZONE
Protocole : TCP
Source : Hôte unique ou Réseau - <IP du conteneur source>/32
Destination :  Hôte unique ou Réseau - <IP du conteneur destination>/32
Plage de ports de destination : Port nécessaire (Pas de plage)
Description : Celle donnée dans le descriptif
```

Nomenclature générale d'une règle type 2 :

```
Interface : ZONE
Protocole : TCP ou TCP/UDP pour le DNS ou ICMP
Source : Hôte unique ou Réseau - <IP du conteneur source>/32
Destination :  Hôte unique ou Réseau - 10.0.0.0/8
Plage de ports de destination : any
Description : Celle donnée dans le descriptif
```

### Règles DMZ

HAProxy désigne les deux conteneurs HAProxy.

- Accès à OPN depuis HAProxy (type 1) - Port : 443
- Accès à PVE depuis HAProxy (type 1) - Port : 443
- Accès à NGINX Alpha depuis HAProxy (type 1) - Port : 80
- Accès à NGINX Bêta depuis HAProxy (type 1) - Port : 80
- Accès à NGINX CTF depuis HAProxy (type 1) - Port : 80
- Accès à l'extérieur depuis le proxy (type 2) - TCP
- Accès à l'extérieur depuis le DNS (type 2) - TCP/UDP

### Règles PROXY

- Accès au serveur web interne depuis PROXY (type 1) - Port 80 - Destination : INTERNE net

### Règles ADMIN

- ICMP depuis la zone ADMIN vers tout (type 2) - Protocole : ICMP - Source : ADMIN net
- TCP/UDP depuis la zone ADMIN vers tout (type 2) - Protocole : TCP/UDP - Source : ADMIN net

### Règles Flottant

Nomenclature générale d'une règle flottant :

```
Interface : ADMIN, DMZ, PROXY, INTERNE, CTF, DIRTY
Protocole : TCP
Source : Hôte unique ou Réseau - 10.0.0.0/8
Destination :  Hôte unique ou Réseau - <IP du conteneur destination>/32
Plage de ports de destination : Port nécessaire (Pas de plage)
Description : Celle donnée dans le descriptif
```

- Accès depuis toutes les zones au Proxy Interne (Squid) - Port : 3128
- Accès depuis toutes les zones au Proxy Interne (Apt-Cacher) - Port : 9999
- Accès depuis toutes les zones au DNS - Port : 53 (TCP/UDP)
