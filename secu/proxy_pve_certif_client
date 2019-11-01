# Accès à l'interface proxmox avec authentification par clé SSL client

Ici nous allons mettre en place un filtrage par clé client pour l'accès à l'interface web de proxmox. Il y aura un loadbalancing entre l'interface de Alpha et celle de Beta.

## Création du premier certificat client
### Création du certificat serveur

```
openssl genrsa -des3 -out ca.key 4096
openssl req -new -x509 -days 365 -key ca.key -out ca.crt
```

#### Spécification du certificat serveur

```
Country Name (2 letter code) [AU]:FR
State or Province Name (full name) [Some-State]:
Locality Name (eg, city) []:Valence
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Kr[HACK]en
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:attract.krhacken.org
Email Address []:contact@krhacken.org
```

### Création de la clé et du CSR du client

```
openssl req -newkey rsa:2048 -nodes -keyout client.key -out client.csr
```

#### Spécification du certificat CSR

```
Country Name (2 letter code) [AU]:FR
State or Province Name (full name) [Some-State]:
Locality Name (eg, city) []:Valence
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Kr[HACK]en
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:attract.krhacken.org  
Email Address []:contact@krhacken.org

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
```

```
openssl x509 -req -days 365 -in client.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out client.crt
openssl req -newkey rsa:2048 -nodes -keyout attract.key -out attract.csr
```

### Spécification du certificat Client

```
Ici le CN est ce qui nous authentifira côté serveur

Country Name (2 letter code) [AU]:FR
State or Province Name (full name) [Some-State]:
Locality Name (eg, city) []:Valence
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Kr[HACK]en
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:CN_autorisé
Email Address []:mail

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
```

```
openssl x509 -req -days 365 -in attract.csr -CA ca.crt -CAkey ca.key -set_serial 02 -out attract.crt
```

### Création du certificat pour le navigateur
```
openssl pkcs12 -export -out attract_user.pfx -inkey attract.key -in attract.crt -certfile ca.crt
```


## Génération d'un second certificat
```
openssl req -newkey rsa:2048 -nodes -keyout attract2.key -out attract2.csr
```
### Spécification du certificat Client
Ici le CN est ce qui nous authentifira côté serveur

```
Country Name (2 letter code) [AU]:FR
State or Province Name (full name) [Some-State]:
Locality Name (eg, city) []:Valence
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Kr[HACK]en
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:CN_autorisé2
Email Address []:mail

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
```

### Certificat pour le navigateur

```
openssl x509 -req -days 365 -in attract2.csr -CA ca.crt -CAkey ca.key -set_serial 03 -out attract2.crt
openssl pkcs12 -export -out attract_user2.pfx -inkey attract2.key -in attract2.crt -certfile ca.crt
```

Il faut maintenant que vous ajoutiez ce certificat à vos certificats Firefox

## Configuration de NGINX

Nous allons maintenant configurer un reverse proxy NGINX, on suppose que les certificat Let's Encrypt pour se sous-domaine ont déjà été généré, se reverse proxy aura pour rôle de vérifier si le client possède le bon certificat client (CA et CN) et de faire du loadbalancing entre Alpha et Beta.

### Copie du certificat client

```
mkdir /etc/nginx/client_certs
cp ca.crt /etc/nginx/client_certs/ca/crt

```

Sur le firewall de Alpha il faut autorisé les connexions de la zone krkn à la zone int

### /etc/shorewall/policy
```
ACCEPT		krkn		int		tcp	8006
```

Nous allons configurer le reverse proxy de façon à ce que seulement les utilisateurs possédant un certificats SSL signé avec ca.crt et avec un CN dans la liste des utilisateurs autorisé accèdent à l'interface proxmox. Les autres seront rejeté. Pour le loadbalancing c'est NGINX qui decidera s'il nous envoi vers Alpha ou vers Beta.

### /etc/nginx/conf.d/pve_web.conf

```
upstream pve {
    server 10.40.0.1:8006;
    server 10.40.0.2:8006;
}

map $ssl_client_s_dn $ssl_access {
    default 0;
    "~CN=user1" 1;
    "~CN=user2" 1;

}

server {
        listen 80;
        server_name attract.sessionkrkn.fr;
        return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name attract.sessionkrkn.fr;
    ssl on;
    ssl_certificate /etc/letsencrypt/live/sessionkrkn.fr/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/sessionkrkn.fr/privkey.pem;
    ssl_client_certificate /etc/nginx/client_certs/ca.crt;
    ssl_verify_client on;
    access_log /var/log/nginx/sessionkrkn.fr;
    ssl_verify_depth 3;

    location / {
    if ( $ssl_client_verify != SUCCESS) {
        return 403;
    }

    if ($ssl_access = 1) {
        proxy_pass https://pve/;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    if ($ssl_access = 0) {
        return 401;
    }

}
}
```

Voilà l'authentification par certificat client SSL ainsi que le loadbalancing entre l'interface de Alpha et celle de beta sont mis en place il ne reste plus qu'a redémarrer nginx.

