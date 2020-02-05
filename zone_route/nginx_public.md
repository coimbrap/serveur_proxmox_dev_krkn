# Reverse proxy NGINX sur le réseau public

## Spécification des containers
Ce service est redondé car vital, son IP est 10.0.0.6 sur Alpha et 10.0.0.7 sur Beta.

## Objectif
Il doit rediriger les requêtes arrivant de HAProxy vers le bon container en fonction de l'hostname. Pour cela nous allons utilisé des serveurs web HTTP avec des proxy sur Nginx sans s'occuper de l'autre serveur web.

## Création d'un canal d'échange par clé entre les deux containers
Afin de pouvoir faire des scp de manière automatique entre les deux containers il faut mettre en place une connexion ssh par clé en root entre les deux containers.

Le procédé est le même voilà les variantes,
- Sur Alpha le container Nginx aura comme IP 10.0.0.6
- Sur Beta le container HAProxy aura comme IP 10.0.0.7

### /etc/ssh/sshd_config
Remplacer la ligne concerné par
```
PermitRootLogin yes
```

### Génération et échange de la clé
```
ssh-keygen -o -a 100 -t ed25519 -f /root/.ssh/id_ed25519

Alpha : ssh-copy-id -i /root/.ssh/id_ed25519 root@10.0.0.7
Beta : ssh-copy-id -i /root/.ssh/id_ed25519 root@10.0.0.6
```

### /etc/ssh/sshd_config
Remplacer les lignes concerné par
```
PermitRootLogin without-password
PubkeyAuthentication yes
```
Il est maintenant possible de se connecter par clé entre les containers

## Installation de Nginx sur les deux containers
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
		proxy_pass http://ip_reseau_public/;
        proxy_set_header Host $http_host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto $scheme;
	}
}
```

Voilà un script permetant l'installation d'un serveur web présent dans /etc/nginx/sites-available. Il prend en entré le nom du fichier du serveur à activer
```
if [ "$#" -eq  "0" ]
	then
		echo "Bad Usage !"
	else
		if [ -f "/etc/nginx/sites-available/$1" ]
			then
				ln -s /etc/nginx/sites-available/$1 /etc/nginx/sites-enabled
				systemctl restart nginx.service
				scp /etc/nginx/sites-available/$1 root@<ip_autre_ct>:/etc/nginx/sites-available/
				ssh root@<ip_autre_ct> "ln -s /etc/nginx/sites-available/$1 /etc/nginx/sites-enabled"
				ssh root@<ip_autre_ct> 'systemctl restart nginx.service'
			else
				echo "Not exist !"
		fi
fi
```

La procédure est tout le temps la méthode générale pour ajouter un serveur a Nginx est décrite ici cependant il peu, dans certains cas, être nécessaire d'enlever un ou plusieurs proxy\_set\_header dans la configuration du serveur Nginx.