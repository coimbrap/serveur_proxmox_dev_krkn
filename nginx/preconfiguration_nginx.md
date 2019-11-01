# Préconfiguration du cluster pour l'acceuil de serveurs web

Ici, nous allons mettre en place tout ce qui sera nécessaire au bon fonctionnement des serveur web NGINX.

## Mise en place des DNAT

Nous allons mettre en place deux règles DNAT,
- Une sur Alpha redirigeant toutes les requêtes sur les ports 80 et 443 vers le container NGINX de Alpha.
- Une sur Beta redirigeant toutes requêtes sur les ports 80 et 443 vers le container NGINX de Beta.

### Sur Alpha
On modifie le fichier rules de Shorewall
```
nano /etc/shorewall/rules
```
On rajoute la règle de DNAT
```
DNAT		net			krkn:ip_ct_nginx_alpha		tcp		80,443
```
On redémarre Shorewall
```
systemctl restart shorewall
```

### Sur Beta
On modifie le fichier rules de Shorewall
```
nano /etc/shorewall/rules
```
On rajoute la règle de DNAT
```
DNAT		net			krkn:ip_ct_nginx_beta		tcp		80,443
```
On redémarre Shorewall
```
systemctl restart shorewall
```

## Installation de Certbot 

### Sur les deux containers NGINX

On installe certbot qui est l'outil utilisé par Let's Encrypt pour obtenir des certificats SSL.
```
apt-get install certbot
apt-get install	python-certbot-nginx
```

## Renouvellement automatique des certificats SSL 

### Sur les deux containers NGINX
Tous les certificats SSL sont édités depuis le container NGINX de Alpha. Pour éviter d'avoir à les renouveler manuellement, nous allons créer une tâche de renouvellement automatique avec une tâche cron.

On accède au fichier de configuration des tâches cron
```
crontab -e
```
On ajoute notre tâche de renouvellement en fin de fichier
```
0 12 * * * /usr/bin/certbot renew --quiet
```
Ainsi les futurs certificats se renouvelleront automatiquement.