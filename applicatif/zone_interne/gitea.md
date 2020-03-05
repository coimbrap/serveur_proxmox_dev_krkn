# Gitea

## Le conteneur
Numéro 121
#### Deux interfaces
- eth0 : vmbr1 / VLAN 30 / IP 10.0.2.21 / GW 10.0.2.254
- eth1 : vmbr2 / VLAN 100 / IP 10.0.2.121 / GW 10.1.0.254

### Le proxy

#### /root/.wgetrc
```
http_proxy = http://10.0.2.252:3128/
https_proxy = http://10.0.2.252:3128/
use_proxy = on
```

#### /etc/apt/apt.conf.d/01proxy
```
Acquire::http {
 Proxy "http://10.0.2.252:9999";
};
```

### Connexion à l'annuaire LDAP

Il faut commencer par copier le certificat de la CA (/etc/ldap/ca_certs.pem qu'il faudra copier via scp)
```
cat ca_certs.pem | tee -a /etc/ldap/ca_certs.pem
```
Il faut ensuite modifier la configuration en modifiant la ligne suivante
#### /etc/ldap/ldap.conf
```
...
TLS_CACERT /etc/ldap/ca_certs.pem
...
```

# Configuration du serveur LDAP
Le serveur LDAP est déjà en place sur le conteneur LDAP il faut cependant faire ce qu'il suit pour ajouter le support de NextCloud.

## Ajout d'un schéma

### schemagit.ldif
```
dn: cn=gitkrhacken,cn=schema,cn=config
objectClass: olcSchemaConfig
cn: gitkrhacken
olcAttributeTypes: ( 1.3.6.1.4.1.99999.2.4.10 NAME 'gitaccountactif' DESC 'Git Actif' EQUALITY caseExactMatch SINGLE-VALUE SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 )
olcObjectClasses: ( 1.3.6.1.4.1.99999.2.4.20 NAME 'gitaccountkrhacken' SUP TOP AUXILIARY MUST (gitaccountactif))
```
```
ldapadd -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f schemagit.ldif -ZZ
```

## Ajout d'un nouvel utilisateur

Ce .ldif permet d'ajouter un nouvel utilisateur dans l'anuaire LDAP et de lui autorisé l'accès au mail et au cloud.

### addusermailcloudgit.ldif
Pour GROUPE :
- ou=krhacken,ou=people -> Membre actif du club
- ou=people -> Le reste

```
dn: uid=new,GROUPE,dc=krhacken,dc=org
objectclass: person
objectclass: organizationalPerson
objectclass: inetOrgPerson
objectclass: mailaccountkrhacken
objectclass: cloudaccountkrhacken
objectclass: gitaccountkrhacken
uid: new
sn: new
givenName: new
cn: new
displayName: new
userPassword: PASSWORD
mail: new@krhacken.org
mailaccountquota: 0
mailaccountactif: YES
cloudaccountquota: 5GB
cloudaccountactif: YES
gitaccountactif: YES
```
```
ldapadd -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f addusermailcloudgit.ldif -ZZ
```

## Autoriser un utilisateur à utiliser le cloud

Permet d'ajouter la classe cloudaccountkrhacken à un utilisateur, il pourra ensuite utiliser NextCloud.

### addtogit.ldif
Pour GROUPE :
- ou=krhacken,ou=people -> Membre actif du club
- ou=people -> Le reste

```
dn: uid=adminsys,GROUPE,dc=krhacken,dc=org
changetype: modify
add: objectclass
objectclass: gitaccountkrhacken
-
add: gitaccountactif
gitaccountactif: YES
```
```
ldapadd -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f addtogit.ldif -ZZ
```

Lister les utilisateurs :
```
ldapsearch -xLLL -H ldap://vip.ldap.krhacken.org -D cn=admin,dc=krhacken,dc=org -y /root/pwdldap -b "ou=people,dc=krhacken,dc=org" "(&(objectClass=cloudaccountkrhacken))" -ZZ
```

## Installation
```
apt-get update
apt-get install -y git postgresql sudo
wget -O gitea https://dl.gitea.io/gitea/1.11.1/gitea-1.11.1-linux-amd64
```
pg_ctlcluster 11 main start


## Configuration de Nginx
### Dans le conteneur Nginx
#### /etc/nginx/sites-available/gitea
```
server {
        listen 80;
        server_name git.krhacken.org;
        location / {
                proxy_pass http://10.0.2.21:3000/;
                proxy_set_header Host $http_host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
        }
}
```
```
sh ~/deploy-webhost.sh gitea
```

### Sur le conteneur HAProxy
Obtention du certificat
```
certbot certonly --webroot -w /home/hasync/letsencrypt-requests/ -d git.krhacken.org
```
```
sh ~/install-certs.sh
```

## Configuration de PostGreSQL
On accède à la console PostGreSQL
```
sudo -u postgres psql
```

Création de l'utilisateur et de la table dans la base de données, n'oubliez pas de spécifié le mot de passe
```
CREATE USER gitea WITH PASSWORD 'PASSWORD';
CREATE DATABASE gitea TEMPLATE template0 ENCODING 'UNICODE';
ALTER DATABASE gitea OWNER TO gitea;
GRANT ALL PRIVILEGES ON DATABASE gitea TO gitea;
\q
```


## Mise en place de Gitea

```
adduser --system --shell /bin/bash --group --disabled-password --home /home/git git
chmod +x gitea
cp gitea /usr/local/bin/gitea
mkdir -p /var/lib/gitea/{custom,data,indexers,public,log}
chown git:git /var/lib/gitea/{data,indexers,log}
chmod 750 /var/lib/gitea/{data,indexers,log}
mkdir /etc/gitea
chown root:git /etc/gitea
chmod 770 /etc/gitea
```
Gitea est installé, on met maintenant en place un service pour que gitea démarre automatiquement.

### /etc/systemd/system/gitea.service
```
[Unit]
Description=Gitea (Git with a cup of tea)
After=syslog.target
After=network.target
Requires=postgresql.service

#Requires=redis.service

[Service]
RestartSec=2s
Type=simple
User=git
Group=git
WorkingDirectory=/var/lib/gitea/
ExecStart=/usr/local/bin/gitea web --config /etc/gitea/app.ini
Restart=always
Environment=USER=git HOME=/home/git GITEA_WORK_DIR=/var/lib/gitea

[Install]
WantedBy=multi-user.target
```
Ce service permet de démarrer automatiquement Gitea et d'attendre que postgresql soit prêt avant le démarrage.

## Premier démarrage et démarrage automatique
```
systemctl enable gitea
systemctl start gitea
```

## Configuration de Gitea via le panel

Via la page **https://git.krhacken.org/install**

### Paramètres de la base de données
- Type de base de données `PostgreSQL`
- Hôte `127.0.0.1:5432`
- Nom d'utilisateur `gitea`
- Nom de base de données `gitea`
- SSL `Require`

### Configuration générale
- Titre du site `Gitea Kr[HACK]en`
- Emplacement racine des dépôts `/home/git/gitea-repositories`
- Répertoire racine Git LFS `/var/lib/gitea/data/lfs`
- Exécuter avec le compte d'un autre utilisateur : `git`
- Domaine du serveur SSH `localhost`
- Port du serveur SSH `None`
- Port d'écoute HTTP de Gitea `3000`
- URL de base de Gitea `https://git.krhacken.org`
- Chemin des fichiers log `/var/lib/gitea/log`

### Paramètres facultatifs
Cocher uniquement
- Activer le mode hors-ligne
- Désactiver Gravatar
- Désactiver le formulaire d'inscription
- Exiger la connexion à un compte pour afficher les pages
- Masquer les adresses e-mail par défaut
- Activer le suivi le temps par défaut
Ensuite
- Domaine pour les e-mails cachés : noreply.krhacken.org

### Paramètres de compte administrateur
- Nom d’utilisateur administrateur `root`
- Adresse e-mail `root@noreply.krhacken.org`

Gitea est maintenant en place on termine par restreindre l'accès au fichiers sensible

```
chmod 750 /etc/gitea
chmod 644 /etc/gitea/app.ini
```

L'accès à Gitea se fait vie le reverse proxy Nginx public

## Ajout de l'annuaire LDAP aux sources d'authentification

Dans **Administration du site / Sources d'authentification**

#### Ajouter une source d'authentification
- Type d'authentification `LDAP (via BindDN)`
- Nom de l'authentification `LDAP Kr[HACK]en`
- Protocole de sécurité `StartTLS`
- Hôte `vip.ldap.krhacken.org`
- Port `389`
- Bind DN `cn=viewer,ou=system,dc=krhacken,dc=org`
- Utilisateur Search Base `ou=people,dc=krhacken,dc=org`
- Filtre utilisateur `(&(objectClass=gitaccountkrhacken)(gitaccountactif=YES)(|(uid=%[1]s)(mail=%[1]s)))`
- Attribut nom d'utilisateur `uid`
- Attribut prénom `cn`
- Attribut nim de famille `sn`
- Attribut e-mail `mail`
- Cocher `Ne pas vérifier TLS`

Après avoir mis à jour la source d'authentification, exécuter `Synchroniser les données de l’utilisateur externe` dans le Tableau de bord, les utilisateurs compatible avec le filtre doivent apparaître dans **Comptes utilisateurs**

Si c'est n'est pas le cas regarder ce qu'il ce passe dans les logs `cat /var/lib/gitea/log/gitea.log | grep LDAP`.

Vous pouvez lister les utilisateurs avec ldapsearch,
```
ldapsearch -xLLL -H ldap://vip.ldap.krhacken.org -D cn=viewer,ou=system,dc=krhacken,dc=org -w PASSVIEWER -b "ou=people,dc=krhacken,dc=org" "(&(objectClass=gitaccountkrhacken)(gitaccountactif=YES))" -ZZ
```

## Customisation
Les templates des pages sont disponible [ici](https://github.com/go-gitea/gitea/tree/master/templates)

### Page d'accueil
Le fichier modifier doit être à l'adresse **/var/lib/gitea/custom/templates/home.tmpl**

Page actuelle :
```
{{template "base/head" .}}
<div class="home">
	<div class="ui stackable middle very relaxed page grid">
		<div class="sixteen wide center aligned centered column">
			<div>
				<img class="logo" src="{{StaticUrlPrefix}}/img/gitea-lg.png" />
			</div>
			<div class="hero">
				<h1 class="ui icon header title">
					{{AppName}}
				</h1>
			</div>
			<a href="https://krhacken.org" target="_blank">Site Web</a> - <a href="https://github.com/go-gitea/gitea/" target="_blank">Code source</a>
		</div>
	</div>
</div>
{{template "base/footer" .}}
```

Pour activer les modifications :
```
chown -R git:git /var/lib/gitea/custom/templates/home.tmpl
systemctl restart gitea
```

### Autres page
La procédure est la même que pour la page d'accueil.
