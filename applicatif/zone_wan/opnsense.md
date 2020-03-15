# Pare-Feu OPNSense

Au niveau du pare-feu nous allons utiliser OPNSense (fork de pfSense). Alpha et Sigma auront une VM avec OPNSense pour la Haute Disponibilité, l'IP publique (WAN) se déplacera entre les trois VM grâce à une IP virtuelle CARP et à pfSync. Ca sera la même chose pour la gateway sur chaque interface.

## Configuration des VMs
- Guest OS : Other
- Bus Device : VirtIO Block
- Network device model : VirtIO (paravirtualized)

Avant de lancer la VM ajoutez les interfaces ci-dessous
- vmbr0.10 -> WAN
- vmbr1.10 -> LAN
- vmbr1.20 -> CARP

WAN sera l'interface portant l'ip publique et LAN l'interface gateway pour la zone DMZ.

## Installation du système
Il faut récupérer une image iso "DVD" sur le site d'OpnSense

Lors du démarrage il faut utiliser,
- login : installer
- pass : opnsense

Ne pas configurer de VLANs.

Une fois installation terminée, quitter le programme d'installation et redémarrer la VM.

## Premiers paramétrages d'OPNSense
### Interfaces
Une fois la VM redémarrée pour la première fois, il faut faut assigner les interfaces, choix 1 dans le menu (assign interfaces).
Il faut configurer 2 interfaces pour commencer :
- WAN (vmbr0 / vlan 10)
- LAN (vmbr1 / vlan 10)
- pfSync (vmbr1 / vlan20)

On ajoutera le reste plus tard.

### Adresse IP
Il faut maintenant configurer les adresses IP des interfaces :
- WAN, mettre l'IP (dépend du choix fait) et la gateway donnée. Pas de DHCP ni d'ipv6.
- LAN, dépend de la node
  - Alpha : 10.0.0.4
  - Sigma : 10.0.0.6

- pfSync, dépend de la node
  - Alpha : 10.1.2.1
  - Gamma : 10.1.2.2


### Accès au panel d'administration
A partir de la OPNSense est fonctionnel cependant il bloque tout en entrée, la WebUI est donc accessible uniquement depuis la zone DMZ. Il va donc falloir désactiver le pare-feu d'OPNSense pour pouvoir si connecter directement via son IP publique.

Sur la console d'OPNSense disponible sur la VM
```
pfctl -d
touch /tmp/disable_security_checks
```
Attention le pare-feu est activer à nouveau à chaque ajout de règle.

En cas de perte d'accès faire la commande `pfctl -d` sur la console pour désactiver le pare-feu.

## Interfaces
Le firewall aura une interface sur toute les zones afin de réguler le trafic. Aucune règle spéciale ne sera ajouter pour ces interfaces.

Voici la liste des interfaçes à assigner à la VM ainsi que le nom à leur donner dans OPNSense lors de leur assignation
- vmbr0.10 -> WAN (déjà assignée)
- vmbr0.20 -> pfSync
- vmbr1.10 -> LAN (déjà assignée)
- vmbr1.20 -> PROXY
- vmbr1.30 -> INT
- vmbr1.40 -> CTF
- vmbr1.50 -> DIRTY
- vmbr2.100 -> ADMIN

Il vous faut ensuite leur donner une IP publique en respectant les IP données dans la [partie réseau](reseau/mise_en_place.md)

## Mise en cluster des pares-feu

Appliquer les règles à la fin sinon le pare-feu va se réactiver et vous allez perdre l'accès

### Alpha

Système / Haute disponibilité / Paramètres

- Cocher `Synchroniser les États`
- Interface de Synchronisation `CARP`
- IP de Synchronisation du Pair `10.1.2.2`
- Synchroniser la Config vers l'IP `10.1.2.2`
- Identifiant du Système Distant `root` (pour l'instant)
- Tout cocher et sauvegarder

### Sigma

Système / Haute disponibilité / Paramètres

- Cocher `Synchroniser les États`
- Interface de Synchronisation `CARP`
- IP de Synchronisation du Pair `10.1.2.1`
- Sauvegarder

La configuration du serveur est maintenant partagé entre les deux VM.

On passe maintenant à la configuration des IPs Virtuelles

Pare-feu / IPs virtuelles / Paramètres

Pour chaque interface portant une IP virtuelle

- Ajouter
- Mode `CARP`
- Interface `CARP`
- Adresse `<adresse_selon_interface>/24`
- Mot de passe IP virtuelle : différent d'une interface à l'autre
- Groupe VHID : Ajouter 1 à chaque interface
- Description : Nom de l'interface

Les interfaces :
- WAN : IP Publique
- LAN : 10.0.0.254
- PROXY : 10.0.1.254
- INT : 10.0.2.254
- CTF : 10.0.3.254
- DIRTY : 10.0.4.254
- ADMIN : 10.1.0.254

### Règle firewall (CARP)

#### Pare-feu / Règles / CARP

- Interface : `CARP`
- Protocole : `CARP`
- Source : `CARP net`
- Destination : `CARP net`

Pour pouvoir accéder à l'interface web via HAProxy il vous faut mettre en place du DNAT vers l'IP virtuelle de HAProxy.

#### Pare-feu / NAT / Redirection de port
Ajouter deux nouvelle règle

```
Interface : WAN
Protocole : TCP
Destination :  WAN adresse
Plage de ports de destination : HTTP / HTTP
Rediriger Vers : 10.0.0.8
Rediriger port cible : HTTP / HTTP
Description : DNAT port 80 pour HAProxy
```
```
Interface : WAN
Protocole : TCP
Destination :  WAN adresse
Plage de ports de destination : HTTPS / HTTPS
Rediriger Vers : 10.0.0.9
Rediriger port cible : HTTPS / HTTPS
Description : DNAT port 80 pour HAProxy
```

On donne l'accès à l'interface web via HAProxy.

Maintenant que des règles de DNAT, `opn.krhacken.org` doit vous rediriger sur l'interface Web.

Avant de continuer il faut dire à OPNSense depuis quelle adresse on y accède.

#### Système / Paramètres / Administration
Dans *Noms d'hôte alternatifs* mettre `opn.krhacken.org`
On peu maintenant redémarrer la VM.

La configuration de départ d'OPNSense est terminé,

## Règle de DNAT complète
Une fois les interfaces assignée et ajouter sur le panel d'OPNSense on peu mettre en place les règles NAT définitive

Pour les ports 25, 465, 587, 143, 993 et 4190 DNAT vers la mail gateway (10.0.1.10).
```
Interface : WAN
Protocole : TCP
Destination :  WAN adresse
Plage de ports de destination : XXXX / XXXX
Rediriger Vers : 10.0.1.10
Rediriger port cible : XXXX / XXXX
Description : DNAT port XXXX pour la Mail Gateway
```

Pour le port 2222 DNAT vers la VM de l'environnement CTF système (10.0.3.12)
```
Interface : WAN
Protocole : TCP
Destination :  WAN adresse
Plage de ports de destination : XXXX / XXXX
Rediriger Vers : 10.0.3.12
Rediriger port cible : XXXX / XXXX
Description : DNAT port XXXX pour l'environnement Système (CTF)
```

Pour la plage de ports 8081 à 8091 DNAT vers l'environnement CTF Web (10.0.3.13).
```
Interface : WAN
Protocole : TCP
Destination :  WAN adresse
Plage de ports de destination : XXXX / XXXX
Rediriger Vers : 10.0.3.13
Rediriger port cible : XXXX / XXXX
Description : DNAT port XXXX pour l'environnement Web (CTF)
```

C'est tout pour la configuration du pare-feu.
