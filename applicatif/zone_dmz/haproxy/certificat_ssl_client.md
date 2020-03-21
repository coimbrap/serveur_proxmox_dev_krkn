# Génération du certificat SSL client pour HAProxy

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
Common Name (e.g. server FQDN or YOUR name) []:haproxy.krhacken.org
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
Common Name (e.g. server FQDN or YOUR name) []:haproxy.krhacken.org
Email Address []:contact@krhacken.org

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
```

```
openssl x509 -req -days 365 -in client.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out client.crt
openssl req -newkey rsa:2048 -nodes -keyout haproxy.key -out haproxy.csr
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
openssl x509 -req -days 365 -in haproxy.csr -CA ca.crt -CAkey ca.key -set_serial 02 -out haproxy.crt
```

### Création du certificat pour le navigateur
```
openssl pkcs12 -export -out haproxy_user.pfx -inkey haproxy.key -in haproxy.crt -certfile ca.crt
```


## Génération d'un second certificat
```
openssl req -newkey rsa:2048 -nodes -keyout haproxy2.key -out haproxy2.csr
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
openssl x509 -req -days 365 -in haproxy2.csr -CA ca.crt -CAkey ca.key -set_serial 03 -out haproxy2.crt
openssl pkcs12 -export -out haproxy_user2.pfx -inkey haproxy2.key -in haproxy2.crt -certfile ca.crt
```

Il faut maintenant que vous ajoutiez ce certificat à vos certificats Firefox

### Copie des certificats
On copie le certificat pour HAProxy
```
cp ca.crt /home/hasync/pve.crt
scp ca.crt root@10.0.0.7:/home/hasync/pve.crt
```

On met sur l'hyperviseur le certificat client, il faudra ensuite le récupérer via SCP et l'installer dans votre navigateur.
