# NextCloud

Mise en place du conteneur pour NextCloud et intégration à l'annuaire LDAP.

## Le conteneur
Numéro 120
#### Deux interfaces
- eth0 : vmbr1 / VLAN 30 / IP 10.0.2.20 / GW 10.0.2.254
- eth1 : vmbr2 / VLAN 100 / IP 10.1.0.120 / GW 10.1.0.254

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


#### /etc/ferm/ferm.conf

# Configuration du serveur LDAP
Le serveur LDAP est déjà en place sur le conteneur LDAP il faut cependant faire ce qu'il suit pour ajouter le support de NextCloud.

## Ajout d'un schéma

### schemacloud.ldif
```
dn: cn=cloudkrhacken,cn=schema,cn=config
objectClass: olcSchemaConfig
cn: cloudkrhacken
olcAttributeTypes: ( 1.3.6.1.4.1.99999.2.3.10 NAME 'cloudaccountquota' DESC 'Quota Cloud' EQUALITY caseExactMatch SINGLE-VALUE SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 )
olcAttributeTypes: ( 1.3.6.1.4.1.99999.2.3.11 NAME 'cloudaccountactif' DESC 'Cloud Actif' EQUALITY caseExactMatch SINGLE-VALUE SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 )
olcObjectClasses: ( 1.3.6.1.4.1.99999.2.3.20 NAME 'cloudaccountkrhacken' SUP TOP AUXILIARY MUST ( cloudaccountquota $ cloudaccountactif))
```
```
ldapadd -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f schemacloud.ldif -ZZ
```

## Ajout d'un nouvel utilisateur

Ce .ldif permet d'ajouter un nouvel utilisateur dans l'anuaire LDAP et de lui autorisé l'accès au mail et au cloud.

### addusermailcloud.ldif
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
```
```
ldapadd -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f addusermailcloud.ldif -ZZ
```

## Autoriser un utilisateur à utiliser le cloud

Permet d'ajouter la classe cloudaccountkrhacken à un utilisateur, il pourra ensuite utiliser NextCloud.

### addtocloud.ldif
Pour GROUPE :
- ou=krhacken,ou=people -> Membre actif du club
- ou=people -> Le reste

```
dn: uid=NAME,GROUPE,dc=krhacken,dc=org
changetype: modify
add: objectclass
objectclass: cloudaccountkrhacken
-
add: cloudaccountquota
cloudaccountquota: 5GB
-
add: cloudaccountactif
cloudaccountactif: YES
```
```
ldapadd -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f addtocloud.ldif -ZZ
```

Lister les utilisateurs :
```
ldapsearch -xLLL -H ldap://vip.ldap.krhacken.org -D cn=admin,dc=krhacken,dc=org -y /root/pwdldap -b "ou=people,dc=krhacken,dc=org" "(&(objectClass=cloudaccountkrhacken))" -ZZ
```




## Installation des prérequis
```
apt-get install -y postgresql postgresql-contrib nginx php7.3-cli php7.3-common php7.3-mbstring php7.3-gd php-imagick php7.3-intl php7.3-bz2 php7.3-xml php7.3-pgsql php7.3-zip php7.3-dev php7.3-curl php7.3-fpm php-dompdf redis-server php-redis php-smbclient php7.3-ldap wget curl sudo unzip
```

## Configuration de PostGreSQL
On accède à la console PostGreSQL
```
sudo -u postgres psql
```

Création de l'utilisateur et de la table dans la base de données, n'oubliez pas de spécifié le mot de passe
```
CREATE USER nextcloud WITH PASSWORD 'PASSWORD';
CREATE DATABASE nextcloud TEMPLATE template0 ENCODING 'UNICODE';
ALTER DATABASE nextcloud OWNER TO nextcloud;
GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;
\q
```

## Configuration de Nginx
### Dans le conteneur Nginx
#### /etc/nginx/sites-available/nextcloud
```
server {
        listen 80;
        server_name cloud.krhacken.org;
        location / {
                proxy_pass http://10.0.2.20/;
                proxy_set_header Host $http_host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
        }
}
```
```
sh ~/deploy-webhost.sh nextcloud
```

### Dans le conteneur NextCloud
#### /etc/nginx/sites-available/nextcloud
```
server {
    listen 80;
    server_name cloud.krhacken.org;

    # Add headers to serve security related headers
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header X-Download-Options noopen;
    add_header X-Permitted-Cross-Domain-Policies none;

    #This header is already set in PHP, so it is commented out here.
    #add_header X-Frame-Options "SAMEORIGIN";

    # Path to the root of your installation
    root /var/www/nextcloud/;

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # The following 2 rules are only needed for the user_webfinger app.
    # Uncomment it if you're planning to use this app.
    #rewrite ^/.well-known/host-meta /public.php?service=host-meta last;
    #rewrite ^/.well-known/host-meta.json /public.php?service=host-meta-json
    # last;

    location = /.well-known/carddav {
        return 301 $scheme://$host/remote.php/dav;
    }
    location = /.well-known/caldav {
       return 301 $scheme://$host/remote.php/dav;
    }

    location ~ /.well-known/acme-challenge {
      allow all;
    }

    # set max upload size
    client_max_body_size 512M;
    fastcgi_buffers 64 4K;

    # Disable gzip to avoid the removal of the ETag header
    gzip off;

    # Uncomment if your server is build with the ngx_pagespeed module
    # This module is currently not supported.
    #pagespeed off;

    error_page 403 /core/templates/403.php;
    error_page 404 /core/templates/404.php;

    location / {
       rewrite ^ /index.php$uri;
    }

    location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)/ {
       deny all;
    }
    location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console) {
       deny all;
     }

    location ~ ^/(?:index|remote|public|cron|core/ajax/update|status|ocs/v[12]|updater/.+|ocs-provider/.+|core/templates/40[34])\.php(?:$|/) {
       include fastcgi_params;
       fastcgi_split_path_info ^(.+\.php)(/.*)$;
       fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
       fastcgi_param PATH_INFO $fastcgi_path_info;
       #Avoid sending the security headers twice
       fastcgi_param modHeadersAvailable true;
       fastcgi_param front_controller_active true;
       fastcgi_pass unix:/run/php/php7.3-fpm.sock;
       fastcgi_intercept_errors on;
       fastcgi_request_buffering off;
    }

    location ~ ^/(?:updater|ocs-provider)(?:$|/) {
       try_files $uri/ =404;
       index index.php;
    }

    # Adding the cache control header for js and css files
    # Make sure it is BELOW the PHP block
    location ~* \.(?:css|js)$ {
        try_files $uri /index.php$uri$is_args$args;
        add_header Cache-Control "public, max-age=7200";
        # Add headers to serve security related headers (It is intended to
        # have those duplicated to the ones above)
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header X-Robots-Tag none;
        add_header X-Download-Options noopen;
        add_header X-Permitted-Cross-Domain-Policies none;
        # Optional: Don't log access to assets
        access_log off;
   }

   location ~* \.(?:svg|gif|png|html|ttf|woff|ico|jpg|jpeg)$ {
        try_files $uri /index.php$uri$is_args$args;
        # Optional: Don't log access to other assets
        access_log off;
   }
}
```
```
rm /etc/nginx/{sites-enabled,sites-available}/default
ln -s /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled
systemctl restart nginx
```

## Installation de NextCloud
```
cd /var/www
wget https://download.nextcloud.com/server/releases/latest-18.zip
unzip latest-18.zip
chown -R www-data:www-data /var/www/nextcloud/
```

### Sur le conteneur HAProxy
Obtention du certificat
```
certbot certonly --webroot -w /home/hasync/letsencrypt-requests/ -d cloud.krhacken.org
```
```
sh ~/install-certs.sh
```

## Configuration de départ
### /var/www/nextcloud/config/config.php
```
[...]
  'trusted_domains' =>
  array (
    'cloud.krhacken.org',
  ),
[...]
  'overwrite.cli.url' => 'https://cloud.krhacken.org',
[...]
```


Se rendre à l'adresse **https://cloud.krhacken.org**

- Nom d'utilisateur `root`
- Répertoire des données `/var/www/nextcloud/data`
- Utilisateur de la base de données `nextcloud`
- Nom de la base de données `nextcloud`
- Hôte de la base de données `localhost:5432`

## Connexion à l'annuaire LDAP

Il faut commencer par copier le certificat de la CA (/etc/ldap/ca_certs.pem qu'il faudra copier via scp)
```
cat ca_certs.pem | tee -a /etc/ldap/ca_certs.pem
```
Il faut ensuite modifier la configuration en modifiant la ligne suivante
### /etc/ldap/ldap.conf
```
...
TLS_CACERT /etc/ldap/ca_certs.pem
...
```


### Activation du module
On active le module LDAP dans NextCloud

**Applications / LDAP user and group backend** cliquer sur **Activer**

Exécuter la commande suivante pour activer le TLS pour LDAP.
```
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config "s01" "ldapTLS" "1"
```

### Configuration du module
Paramètres / Intégration LDAP/AD

#### Serveur
- Hôte `vip.ldap.krhacken.org`
- Port `389`
- DN Utilisateur `cn=viewer,ou=system,dc=krhacken,dc=org`
- Mot de passe `PASSVIEWER`
- DN de base `ou=people,dc=krhacken,dc=org`
- Cocher Saisir les filtres LDAP

#### Utilisateurs
- Modifier la requête LDAP `(&(objectClass=cloudaccountkrhacken)(cloudaccountactif=YES))`

#### Attributs de login
- Modifier la requête LDAP `(&(objectClass=cloudaccountkrhacken)(cloudaccountactif=YES)(|(uid=%uid)(mail=%uid)))`

#### Groupes
- Modifier la requête LDAP `objectClass=cloudaccountkrhacken`

#### Avancé
- Cocher `Configuration active`
- Champ "nom d'affichage" de l'utilisateur `displayName`
- DN racine de l'arbre utilisateurs `ou=people,dc=krhacken,dc=org`
- Champ "nom d'affichage" du groupe `cn`
- DN racine de l'arbre groupes `cn=cloud,ou=people,dc=krhacken,dc=org`
- Champ du quota `cloudaccountquota`
- Quota par défaut `3GB`
- Champ Email `mail`
- Règle de nommage du répertoire utilisateur `uid`

#### Expert
- Nom d'utilisateur interne `uid`

Une fois que c'est fait tester la configuration normalement les utilisateurs correspondants au filtre apparaisse dans l'onglet Utilisateur.

# Optimisation de NextCloud

## Tâches de fond

Sur le panel administration `Paramètre de base/Tâches de fond` et sélectionner `Cron`

Ensuite on ajoute une tâche cron dans le conteneur NextCloud.
```
crontab -u www-data -e
```
```
*/5  *  *  *  * php -f /var/www/nextcloud/cron.php
```
On lance un premier cron
```
sudo -u www-data php -f /var/www/nextcloud/cron.php
```
