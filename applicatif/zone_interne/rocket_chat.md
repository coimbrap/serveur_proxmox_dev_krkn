# Installation de Rocket Chat

Sur un container dédié (CT113)

## Le proxy

### /root/.wgetrc
```
http_proxy = http://10.0.0.252:3128/
https_proxy = http://10.0.0.252:3128/
use_proxy = on
```

### /etc/apt/apt.conf.d/01proxy
```
Acquire::http {
 Proxy "http://10.0.0.252:9999";
};
```

## Installation des prérequis

```
apt-get update
apt-get install -y curl software-properties-common gnupg2
```

### MongoDB
```
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add -
echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.2 main" | tee /etc/apt/sources.list.d/mongodb-org.list
```

### Node JS
```
export http_proxy=http://10.0.2.252:3128/
export https_proxy=$http_proxy
curl -sL https://deb.nodesource.com/setup_12.x |bash -
```

### Ajout des packets
```
apt-get install -y build-essential mongodb-org nodejs graphicsmagick nginx
npm install -g inherits n && n 12.14.0
```

### Configuration des packets
```
echo -e "replication:\n  replSetName: \"rs01\"" | tee -a /etc/mongod.conf
systemctl enable mongod.service
systemctl start mongod.service

mongo
 > rs.initiate()
 > rs01:SECONDARY> exit
 > rs01:PRIMARY> exit
```

### Mise en place de Rocket Chat
Création d'un utilisateur dédié, installation du programme et création d'un daemon systemd

### Installation du programme

```
useradd -r -m -U -d /srv/rocketchat rocketchat
su - rocketchat
export http_proxy=http://10.0.2.252:3128/
export https_proxy=$http_proxy
npm config set proxy http://10.0.2.252:3128
npm config set https-proxy http://10.0.2.252:3128
curl -L https://releases.rocket.chat/latest/download -o rocket.chat.tgz
tar xvf rocket.chat.tgz
rm rocket.chat.tgz
cd bundle/programs/server && npm install
cd ../../..
mv bundle Rocket.Chat
exit
```

En root

```
chown -R rocketchat:rocketchat /srv/rocketchat/Rocket.Chat/
```

### Daemon Systemd

#### /etc/systemd/system/rocketchat.service

```
[Unit]
Description=The Rocket.Chat server
After=network.target remote-fs.target nss-lookup.target nginx.target mongod.target

[Service]
ExecStart=/usr/local/bin/node /srv/rocketchat/Rocket.Chat/main.js
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=rocketchat
User=rocketchat
Environment=MONGO_URL=mongodb://localhost:27017/rocketchat?replicaSet=rs01 MONGO_OPLOG_URL=mongodb://localhost:27017/local?replicaSet=rs01 ROOT_URL=http://localhost:3000/ PORT=3000

[Install]
WantedBy=multi-user.target
```

# Accès à Rocket Chat depuis l'extérieur

Pour ma configuration j'ai un HAProxy puis un reverse global et ensuite un reverse local au container RocketChat. Pour que l'application mobile puisse fonctionner il faut une configuration spéciale des nginx. Le SSL ce fait au niveau de HAProxy.

## Pour le reverse global

### /etc/nginx/sites-available/rocketchat

```
server {
    listen 80;
    server_name rocket.sessionkrkn.fr;
    location / {
        proxy_pass http://10.0.2.13:80/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection  ^`^|upgrade ^`^};
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forward-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forward-Proto http;
        proxy_set_header X-Nginx-Proxy true;
        proxy_redirect off;
    }
}
```
```
sh ~/deploy-webhost.sh rocketchat
```

## Pour le reverse local
Pour des raisons de sécurité on va mettre en place un proxy NGINX dans le container pour eviter d'exposer le port 3000 aux autres conteneurs.

### /etc/nginx/sites-available/rocketchat
```
upstream backend {
    server 127.0.0.1:3000;
}

server {
    listen 80;
    server_name rocket.sessionkrkn.fr;
    client_max_body_size 200M;
    error_log /var/log/nginx/rocketchat.access.log;

    location / {
        proxy_pass http://backend/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forward-Proto http;
        proxy_set_header X-Nginx-Proxy true;
        proxy_redirect off;
    }
}
```
```
rm /etc/nginx/{sites-available,sites-enabled}/default
ln -s /etc/nginx/sites-available/rocketchat /etc/nginx/sites-enabled
```

# Configuration du LDAP
Nous allons relier Rocket Chat à l'annuaire LDAP en faisant en sorte que tout le monde est accès à ce service.

## Dans l'onglet LDAP du panel d'administration

Cocher / Modifier

- Activer
- Login Fallback
- Rechercher un utilisateur après la connexion
- Hôte `vip.ldap.krhacken.org`
- Port 389
- Rebranchez
- Chiffrement `StartTLS`
- Mettez le Certificat CA
- Décocher `Rejeter les personnes non autorisées`
- DN de base `ou=krhacken,ou=people,dc=krhacken,dc=org`
- Niveau de journal interne `Erreur`

Sauvegarder et tester la connexion

### Authentification
- Permettre
- DN utilisateur `cn=viewer,ou=system,dc=krhacken,dc=org`

### Sync / Import
- Champs du nom d'utilisateur `diplayName`
- Champ de l'identifiant unique `uid`
- Domaine par défaut `sessionkrkn.fr`
- Fusionner les utilisateurs existants
- Synchronisation des données
- Liste des champs utilisateur `{"cn":"name", "mail":"email"}`

Sauvegarder et exécuter la synchronisation

### Chercher un utilisateur
- Filtre `(objectclass=*)`
- Champ de recherche `uid`

Sauvegarder et Exécuter la synchronisation

Normalement les utilisateurs sont disponible dans l'onglet Utilisateurs.

# Configuration de l'interface
On interdit ici la modification des champs LDAP (or nom d'affichage qui sera modifié localement) ainsi que la création de comptes.

Aller dans Comptes et cocher uniquement

- Autoriser la modification de profil
- Autoriser le changement d'avatar
- Permettre le changement de nom
- Autoriser les status personnalisés
- Autoriser les notifications hors-ligne par e-mail

### Enregistrement
- Mettre **Formulaire d'inscription** à `Désactivé`
- Décocher `Réinitialisation du mot de passe`

Sauvegarder les modifications

C'est tout pour l'instant.

TDL
- Solutions de Visio WebRC ou Jitsi
- Link Mail
