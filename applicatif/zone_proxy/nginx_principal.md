# Reverse proxy NGINX sur le réseau public

## Spécification des conteneurs
Ce service est redondé car vital, son IP est 10.0.1.3 sur Alpha et 10.0.1.4 sur Beta.

## Objectif
Il doit rediriger les requêtes arrivant de HAProxy vers le bon conteneur en fonction de l'hostname. Pour cela nous allons utiliser des serveurs web HTTP avec des proxy sur Nginx sans s'occuper de l'autre serveur web.

## Création d'un canal d'échange par clé entre les deux conteneurs
Afin de pouvoir faire des scp de manière automatique entre les deux conteneurs, il faut mettre en place une connexion ssh par clé en root entre les deux conteneurs.

Le procédé est le même, en voici les variantes,
- Sur Alpha le conteneur Nginx aura comme IP 10.0.1.3
- Sur Beta le conteneur HAProxy aura comme IP 10.0.1.4

### /etc/ssh/sshd_config
Remplacer la ligne concernée par
```
PermitRootLogin yes
```
```
systemctl restart sshd
```

### Génération et échange de la clé
```
ssh-keygen -o -a 100 -t ed25519 -f /root/.ssh/id_ed25519

Alpha : ssh-copy-id -i /root/.ssh/id_ed25519 root@10.0.1.4
Beta : ssh-copy-id -i /root/.ssh/id_ed25519 root@10.0.1.3
```

### /etc/ssh/sshd_config
Remplacer les lignes concernées par
```
PermitRootLogin without-password
PubkeyAuthentication yes
```
```
systemctl restart sshd
```

Il est maintenant possible de se connecter par clé entre les conteneurs

## Installation de Nginx sur les deux conteneurs
Faite par le playbook Ansible

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
		proxy_pass http://ip_reseau_interne/;
		proxy_set_header Host $http_host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto $scheme;
	}
}
```

Voilà un script permetant l'installation d'un serveur web présent dans /etc/nginx/sites-available. Il prend en entrée le nom du fichier du serveur à activer. Disponible dans `/root/deploy-webhost.sh` si déployer avec Ansible.

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

La procédure est tout le temps la méthode générale pour ajouter un serveur à Nginx. Elle est décrite ici. Cependant, dans certains cas, il peut être nécessaire d'enlever un ou plusieurs proxy\_set\_header dans la configuration du serveur Nginx.
