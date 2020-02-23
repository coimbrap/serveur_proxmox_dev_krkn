# Environnement Web CTF

Il faut impérativement une VM pour que Docker soit fluide

## Installation de Docker et Docker-Compose
```
apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt-get update
apt-get install docker-ce
curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

## Mise en place de l'environnement Web

L'archive contient les sources docker des 11 environnements ainsi qu'un fichier docker-compose qui mettra en place tous les environnements. 

```
Easy HTML : Port 8081
Fais moi un cookie : Port 8082
Header manquant : Port 8083
Easy admin : Port 8084
Easy LFI & Harder LFI : Port 8085
SQL Injection : Port 8086
strcmp : Port 8087
Easy NoSQL & Standard & Harder NoSQL : Port 8088
Blind SQL : Port 8089
XML : Port 8090
Vole mon cookie si tu peux : Port 8091
```

Un reverse proxy en local redirigera vers le bon port en fonction du numéro du challenge.

### Création d'un utilisateur non-root
```
adduser WebChalls --force-badname
adduser WebChalls sudo
su WebChalls
```

Pour la mise en place il suffit de placer le contenu de l'archive dans /home/WebChalls/WebChalls

### Création d'un service pour le démarrage automatique
#### /etc/systemd/system/webchall.service
```
[Unit]
Description=WebChall
Requires=webchall.service
After=webchall.service
[Service]
Restart=always
ExecStart=/usr/local/bin/docker-compose -f /home/WebChalls/WebChalls/docker-compose.yml up
ExecStop=/usr/local/bin/docker-compose -f /home/WebChalls/WebChalls/docker-compose.yml down
[Install]
WantedBy=multi-user.target
```
Il suffit maintenant de l'activer
```
systemctl enable webchall
systemctl start webchall
```