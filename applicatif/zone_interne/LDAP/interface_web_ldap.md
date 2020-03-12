# Interface Web de gestion LDAP

Nous avons fait le choix de ne pas utiliser FusionDirectory principalement pour des questions de sureté car avec FusionDirectory il est très simple de tout casser. Le services que nous allons utilisé restreint ce que la personne peux casser.

L'interface que nous allons utilisé et une version légèrement modifié de ce [projet](https://github.com/kakwa/ldapcherry)  sous Licence MIT donc réutilisable / modifiable à souhait.

Cette interface permet aussi aux utilisateurs non admin de changer de mot de passe.

## Le conteneur
Numéro 115 (Beta)
#### Deux interfaces
- eth0 : vmbr1 / VLAN 30 / IP 10.0.2.15 / GW 10.0.2.254
- eth1 : vmbr2 / VLAN 100 / IP 10.1.0.115 / GW 10.1.0.254

### Le proxy

#### /root/.gitconfig
```
[http]
        proxy = http://10.0.2.252:3128
[https]
        proxy = https://10.0.2.252:3128
```

#### /etc/apt/apt.conf.d/01proxy
```
Acquire::http {
 Proxy "http://10.0.2.252:9999";
};
```


## Installation
```
git clone https://github.com/kakwa/ldapcherry
apt-get install python-ldap python-pip
pip install --proxy http://10.0.2.252:3128 cherrypy mako pyyaml
export SYSCONFDIR=/etc
export DATAROOTDIR=/usr/share/
python setup.py install
```

## Configuration
Modification des fichiers de configuration et modification de l'interface web.

### /etc/ldapcherry/attributes.yml
```
cn:
    description: "Prénom"
    display_name: "Prénom"
    type: string
    weight: 10
    backends:
        ldap: cn

sn:
    description: "Nom de famille"
    display_name: "Nom"
    search_displayed: True
    weight: 20
    type: string
    backends:
        ldap: sn

given:
    description: "Prénom & Nom"
    display_name: "Nom d'affichage"
    search_displayed: True
    type: string
    weight: 30
    backends:
        ldap: displayName

email:
    description: "Email"
    display_name: "Email"
    search_displayed: True
    type: email
    weight: 40
    backends:
        ldap: mail

uid:
    description: "UID de l'utilisateur"
    display_name: "UID"
    search_displayed: True
    key: True
    type: string
    weight: 50
    backends:
        ldap: uid

password:
    description: "Mot de passe de l'utilisateur"
    display_name: "Mot de passe"
    weight: 31
    self: True
    type: password
    backends:
        ldap: userPassword

mailaccountactif:
    description: "YES ou NO"
    display_name: "Mail Actif"
    search_displayed: True
    weight: 60
    type: string
    autofill:
        function: lcMailActif
        args:
            - 'YES'
    backends:
        ldap: mailaccountactif

mailaccountquota:
    description: "0 par défaut"
    display_name: "Mail Quota"
    search_displayed: True
    weight: 61
    type: string
    autofill:
        function: lcMailQuota
        args:
            - '2147483648'
    backends:
        ldap: mailaccountquota

cloudaccountactif:
    description: "YES or NO"
    display_name: "Cloud Actif"
    search_displayed: True
    weight: 70
    type: string
    autofill:
        function: lcCloudActif
        args:
            - 'YES'
    backends:
        ldap: cloudaccountactif

cloudaccountquota:
    description: "5GB par défaut"
    display_name: "Cloud Quota"
    search_displayed: True
    weight: 71
    type: string
    autofill:
        function: lcCloudQuota
        args:
            - '5GB'
    backends:
        ldap: cloudaccountquota

gitaccountactif:
    description: "YES or NO"
    display_name: "Git Actif"
    search_displayed: True
    weight: 80
    type: string
    autofill:
        function: lcGitActif
        args:
            - 'YES'
    backends:
        ldap: gitaccountactif
```



### /etc/ldapcherry/ldapcherry.ini
```
[global]
server.socket_host = '0.0.0.0'
server.socket_port = 8080
server.thread_pool = 8

request.show_tracebacks = False
log.error_handler = 'syslog'
log.access_handler = 'none'
log.level = 'info'
tools.sessions.on = True
tools.sessions.timeout = 10

[attributes]
attributes.file = '/etc/ldapcherry/attributes.yml'

[roles]
roles.file = '/etc/ldapcherry/roles.yml'

[backends]
ldap.module = 'ldapcherry.backend.backendLdap'
ldap.display_name = 'My Ldap Directory'
ldap.uri = 'ldap://alpha.ldap.sessionkrkn.fr'
ldap.ca = '/etc/ldap/ca_certs.pem'
ldap.starttls = 'on'
ldap.checkcert = 'off'
ldap.binddn = 'cn=admin,dc=sessionkrkn,dc=fr'
#ldap.binddn = 'cn=writer,ou=system,dc=sessionkrkn,dc=fr'
ldap.password = '8PizMOVqhDwSVChJwNy8Xcb1rPzDEuYbwXdd'
ldap.timeout = 1
ldap.groupdn = 'ou=workgroup,ou=group,dc=sessionkrkn,dc=fr'
ldap.userdn = 'ou=krhacken,ou=people,dc=sessionkrkn,dc=fr'
ldap.user_filter_tmpl = '(uid=%(username)s)'
ldap.group_filter_tmpl = '(member=uid=%(username)s,ou=krhacken,ou=people,dc=sessionkrkn,dc=fr)'
ldap.search_filter_tmpl = '(|(uid=%(searchstring)s*)(sn=%(searchstring)s*))'
ldap.group_attr.member = "%(dn)s"
ldap.dn_user_attr = 'uid'

# Ajouter les classes nécessaire en cas de création de nouveau service
ldap.objectclasses = 'person, organizationalPerson, inetOrgPerson, mailaccountkrhacken, cloudaccountkrhacken gitaccountkrhacken'

[ppolicy]
ppolicy.module = 'ldapcherry.ppolicy.simple'
min_length = 8
min_upper = 1
min_digit = 1

[auth]
auth.mode = 'or'

[resources]
templates.dir = '/usr/share/ldapcherry/templates/'

[/static]
tools.staticdir.on = True
tools.staticdir.dir = '/usr/share/ldapcherry/static/'
```

### /etc/ldapcherry/roles.yml
```
admin:
    display_name: AdminSys
    description: Administrateur total de l'annuaire LDAP
    LC_admins: True
    backends_groups:
        ldap:
            - cn=adminsys,ou=krhacken,ou=group,dc=krhacken,dc=org

webmestre:
    display_name: Webmestre
    description: Webmestre des services
    LC_admins: True
    backends_groups:
        ldap:
            - cn=webmestre,ou=krhacken,ou=group,dc=krhacken,dc=org

club:
    display_name: Membre du Club
    description: Membre du Bureau
    backends_groups:
        ldap:
            - cn=krhacken,ou=krhacken,ou=group,dc=krhacken,dc=org

ext:
    display_name: Personne extérieure
    description: Membre Actif
    backends_groups:
        ldap:
            - cn=ext,ou=krhacken,ou=group,dc=krhacken,dc=org
```

### Interface Web
Placer le contenu du dossier **sources** dans **/usr/share/ldapcherry/**

## Mise en place
Mise en place de HAProxy et de NGINX pour l'accès à l'interface et mise en place d'un daemon systemd pour le démarrage automatique de l'interface Web.

### Dans le conteneur Nginx
#### /etc/nginx/sites-available/nextcloud
```
server {
        listen 80;
        server_name ldapui.krhacken.org;
        location / {
                proxy_pass http://10.0.2.15:8080/;
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

### Dans le conteneur HAProxy
Obtention du certificat
```
certbot certonly --webroot -w /home/hasync/letsencrypt-requests/ -d ldapui.krhacken.org
```
```
sh ~/install-certs.sh
```

## Daemon Systemd
### /etc/systemd/system/ldapui.service
```
Description=LDAP WebUI
Requires=ldapui.service
After=ldapui.service
[Service]
Restart=always
ExecStart=ldapcherryd -c /etc/ldapcherry/ldapcherry.ini -D -p /etc/ldapcherry/proc.pid
ExecStop=kill -9 `cat /etc/ldapcherry/proc.pid`
[Install]
WantedBy=multi-user.target
```
```
systemctl enable ldapui.service
systemctl start ldapui.service
```

L'interface de gestion LDAP est désormais accessible à l'adresse **https://ldapui.sessionkrkn.fr**
