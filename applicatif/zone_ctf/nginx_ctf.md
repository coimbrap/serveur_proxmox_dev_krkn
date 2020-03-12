# Reverse proxy NGINX sur le réseau CTF

## Spécification du conteneur
Ce service n'est pas redondé car non vital. Il portera le numéro 145 sur Beta.

#### Deux interfaces
- eth0 : vmbr1 / VLAN 40 / IP 10.0.3.3 / GW 10.0.2.254
- eth1 : vmbr2 / VLAN 100 / IP 10.1.0.145 / GW 10.1.0.254

### Le proxy

#### /root/.wgetrc
```
http_proxy = http://10.0.3.252:3128/
https_proxy = http://10.0.3.252:3128/
use_proxy = on
```

#### /etc/apt/apt.conf.d/01proxy
```
Acquire::http {
 Proxy "http://10.0.3.252:9999";
};
```

## Objectif
Il doit rediriger les requêtes arrivant de HAProxy vers le bon conteneur en fonction de l'hostname. Pour cela nous allons utiliser des serveurs web HTTP Nginx.

## Installation de nginx et persistance,
```
apt-get update
apt-get install -y nginx
systemctl enable nginx.service
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
```

## Mise en place d'un serveur faisant office de reverse proxy

On ajoute un serveur web dans /etc/nginx/sites-available avec un nom décrivant bien le service derrière ce serveur.

Voilà la template du serveur web,
```
server {
	listen 80;
	server_name address.fr;
	location / {
		proxy_pass http://ip_reseau_ctf/;
		proxy_set_header Host $http_host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto $scheme;
	}
}
```

On active ce serveur web,
```
ln -s /etc/nginx/sites-available/<nom_serveur> /etc/nginx/sites-enabled
systemctl restart nginx
```

La procédure est tout le temps la méthode générale pour ajouter un serveur à Nginx. Elle est décrite ici. Cependant, dans certians cas, il peut être nécessaire d'enlever un ou plusieurs proxy\_set\_header dans la configuration du serveur Nginx.
