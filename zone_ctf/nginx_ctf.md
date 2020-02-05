# Reverse proxy NGINX sur le réseau CTF

## Spécification du container
Ce service n'est pas redondé car non vital, son IP est 10.0.2.5 sur le réseau CTF.

## Objectif
Il doit rediriger les requêtes arrivant de HAProxy vers le bon container en fonction de l'hostname. Pour cela nous allons utilisé des serveurs web HTTP Nginx.

## Installation de nginx et persistance,
```
apt-get update
apt-get install -y nginx
systemctl enable nginx.service
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

La procédure est tout le temps la méthode générale pour ajouter un serveur a Nginx est décrite ici cependant il peu, dans certains cas, être nécessaire d'enlever un ou plusieurs proxy\_set\_header dans la configuration du serveur Nginx.
