# Configuration type d'un reverse proxy NGINX

Ici, nous allons voir comment configurer un reverse proxy NGINX dans deux cas,
- Si le container du service est sur la node principale (Alpha).
- Si le container du service n'est pas sur la node principale mais sur Beta.

## Dans tous les cas

### Zone DNS
Il faut configurer notre zone DNS pour que _address.fr_ pointe vers l'adresse ip publique de Alpha. La mention subdomain représente le sous-domaine, s'il n'y en a pas, laisser un blanc.
```
subdomain          IN A      ip_publique_alpha
```
## Configuration du reverse proxy NGINX pour une connexion sur un container présent sur Alpha.

On commence par configurer un serveur NGINX simple pour l'obtention du certificat.

```
nano /etc/nginx/conf.d/address.fr.conf
```
Voilà la template du serveur web

```
server {
	listen 80;
	server_name address.fr;
	location / {
		proxy_pass http://ip_ct_alpha/;
	}
}
```

### Génération du premier certificat

On génère le premier certificat SSL à l'aide de certbot
```
systemctl restart nginx
certbot --nginx -d address.fr
```
Choisir No redirect.

Maintenant que le certificat est généré, on va remplacer la configuration du serveur web.

```
nano /etc/nginx/conf.d/address.fr.conf
```
Voilà la template du serveur web
```
server {
	listen 80;
	server_name address.fr;
	return 301 https://$server_name$request_uri;
}

server {
	listen 443 ssl;
	server_name address.fr;
	location / {
		proxy_pass http://ip_ct_alpha/;
		proxy_set_header Host $http_host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto $scheme;
	}
	ssl_certificate /etc/letsencrypt/live/address.fr/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/address.fr/privkey.pem;
	include /etc/letsencrypt/options-ssl-nginx.conf;
	ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}
```

## Configuration du reverse proxy NGINX pour une connexion sur un container présent sur Beta.

### Sur Alpha

On commence par configurer un serveur NGINX simple pour l'obtention du certificat. Ce reverse proxy redirigera les requêtes sur _address.fr_ vers le container NGINX de la node Beta via DNAT.

```
nano /etc/nginx/conf.d/address.fr.conf
```
Voilà la template du serveur web

```
server {
  listen 80;
  server_name address.fr;
  location / {
      proxy_pass http://10.40.0.2:80/; #Ip de Beta sur le bridge Alpha/Beta
      proxy_set_header Host address.fr;
  }
}
```

### Sur Beta
On configure un serveur web qui va rediriger les requêtes entrantes sur Beta avec comme host _address.fr_ vers le container du service associé à l'host.

```
nano /etc/nginx/conf.d/address.fr.confsubdomain          IN A      ip_publique

```
Voilà la template du serveur web
```
server {
	listen 80;
	server_name address.fr;
	location / {
		proxy_pass http://ip_ct_beta/;
	}
}
```

### Obtention des deux premiers certificats SSL

### Sur Alpha

```
systemctl restart nginx
certbot --nginx -d address.fr
```
Choisir No redirect.

Maintenant que le certificat est généré, on va remplacer la configuration du serveur web.

On transmet la requête au container NGINX de beta qui s'occupera de nous mettre en communication avec le container correspondant au site sur la node Beta.

```
nano /etc/nginx/conf.d/address.fr.conf
```
Voilà la template du serveur web
```
server {
	listen 80;
	server_name address.fr;
	return 301 https://$server_name$request_uri;
}

server {
	listen 443 ssl;
	server_name address.fr;
	location / {
		proxy_pass http://10.40.0.2/; #Ip de Beta sur le bridge Alpha/Beta
		proxy_set_header Host $http_host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto $scheme;
	}
	ssl_certificate /etc/letsencrypt/live/address.fr/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/address.fr/privkey.pem;
	include /etc/letsencrypt/options-ssl-nginx.conf;
	ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}
```

### Sur Beta

```
systemctl restart nginx
certbot --nginx -d address.fr
```
Choisir No redirect.

Maintenant que le certificat est généré, on va remplacer la configuration du serveur web.

On configure un serveur web qui va rediriger les requêtes entrantes sur Beta avec comme host _address.fr_ vers le container du service associé à l'host en https.

```
nano /etc/nginx/conf.d/address.fr.conf
```
Voilà la template du serveur web
```
server {
	listen 80;
	server_name address.fr;
	return 301 https://$server_name$request_uri;
}

server {
	listen 443 ssl;
	server_name address.fr;
	location / {
		proxy_pass http://ip_ct_beta/;
		proxy_set_header Host $http_host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto $scheme;
	}
	ssl_certificate /etc/letsencrypt/live/address.fr/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/address.fr/privkey.pem;
	include /etc/letsencrypt/options-ssl-nginx.conf;
	ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}
```
