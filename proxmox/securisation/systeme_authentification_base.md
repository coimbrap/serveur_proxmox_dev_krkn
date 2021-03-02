# Système d'authentification de base

A voir quand le faire car possible de faire sur toutes les nodes du cluster


Avant de continuer avec l'installation des hyperviseurs nous allons les sécuriser. La procédure est la même sur chaque.

A noté que ce système d'authentification sera remplacé une fois que tout sera en place.

## Datacenter / Permissions

### Permissions / Groups
On crée trois groupes d'utilisateur :
- Create **AdminSys**
- Create **Webmestre**
- Create **Visiteur**

Via le shell on ajoute le groupe AdminSys :
```
groupadd adminsys
```

### Permissions / Pools

On crée une pool par zone :
- WAN
- DMZ
- Proxy
- Interne
- CTF
- Dirty
- ADMIN

## Les comptes
Pour les comptes
- Administrateur système : Linux PAM Authentification (pour accès SSH)
- Le reste : Proxmox VE Authentification

Seulement les comptes adminsys auront un accès SSH.

#### Ajout du compte *coimbrap*

Via le shell :
```shell
useradd coimbrap
usermod -a -G adminsys coimbrap
usermod -a -G sudo coimbrap
mkdir /home/coimbrap
chown -R coimbrap:coimbrap /home/coimbrap
usermod -d /home/coimbrap coimbrap
usermod --shell /bin/bash coimbrap
```

#### Permissions / Users
- User name : coimbrap
- Realm : Linux PAM authentification
- Group : AdminSys

### Comptes


#### Ajout d'un compte webmestre
- User name : respotech
- Realm : Proxmox VE authentification
- Group : Webmestre


#### Ajout d'un compte visiteur
- User name : Visiteur
- Realm : Proxmox VE authentification
- Group : Visiteur


## Permissions

### Pour le groupe AdminSys
Add : Group permission
- Path `/`
- Group `AdminSys`
- Role `Administrator`

Pour les webmestres il vaut mieux faire du cas pas cas. Nous avons quand même fait des permissions pour tout le groupe qui peuvent être affiné utilisateur par utilisateur

Un webmeste à besoin d'accéder uniquement au Pools Interne et CTF

Il aura le groupe PVEVMUser, on ajoute les privileges `VM.Snapshot` à ce groupe.

Add : Group permission
- Path `/pool/Interne`
- Group `Webmestre`
- Role `PVEVMUser`

Add : Group permission
- Path `/pool/CTF`
- Group `Webmestre`
- Role `PVEVMUser`


### Ajout d'un accès pour visiteur
Add : Group permission
- Path `/`
- Group `Visiteur`
- Role `NoAccess`


## Neutralisation du compte root

Soyez-sur avant de le faire qu'un compte adminsys soit opérationnel.

### Pour l'authentification sur Proxmox

#### Datacenter / Permissions / Users

Pour root, décocher `Enabled` et valider.

### Pour l'authentification SSH

Nous allons désactiver le compte root et l'authentification par mot de passe. Il vous faut donc générer en local une clé SSH (ou la reutiliser celle déjà générer) et l'envoyer sur le serveur.

```
ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519_krkn
ssh-copy-id -i ~/.ssh/id_ed25519_krkn coimbrap@<ip>
```

Modifiez les lignes suivantes



#### /etc/ssh/sshd_config
```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
StrictModes yes
MaxAuthTries 3
```
```
systemctl restart sshd
```

Voilà il n'est plus possible d'utilisé le compte root sans passé au préalable par un compte non root.

#### /etc/motd
Avec un jolie motd c'est mieux !
```

   _  __     ___ _    _          _____ _  _____            
  | |/ /    |  _| |  | |   /\   / ____| |/ /_  |           
  | ' / _ __| | | |__| |  /  \ | |    | ' /  | | ___ _ __  
  |  < | '__| | |  __  | / /\ \| |    |  <   | |/ _ \ '_ \
  | . \| |  | | | |  | |/ ____ \ |____| . \  | |  __/ | | |
  |_|\_\_|  | |_|_|  |_/_/    \_\_____|_|\_\_| |\___|_| |_|
            |___|                          |___|           

```

Voilà pour la gestion de l'authentification
