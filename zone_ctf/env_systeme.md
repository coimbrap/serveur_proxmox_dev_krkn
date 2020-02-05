# Environnement Système CTF

Il faut impérativement une VM pour que Docker soit fluide

## Installation de Docker et Docker-Compose
```
apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt-get update
apt-get install docker-ce
```

## Mise en place de l'environement système

La restauration des challenges actuel est expliqué à la fin. 

### Procédure pour la création d'un nouveau challenge

Placer les Dockerfile est source du challenge dans /home/systeme/SystemeChall/<challenge>
Le Dockerfile doit idéalement être fait à partir de debmod, créer un utilisateur systemeXX et contenir
```
USER systemeXX
WORKDIR /home/systemeXX
```

### Installation et création de l'utilisateur administrateur non root
```
apt-get install python3-pip
pip3 install --upgrade docker
pip3 install --upgrade argcomplete
adduser systeme
adduser systeme sudo
adduser systeme docker
su systeme
```
#### /usr/local/bin/dockersh
```
#!/usr/bin/env python3
# PYTHON_ARGCOMPLETE_OK
import os
os.environ['TERM'] = 'xterm'
import argparse
from configparser import ConfigParser, ExtendedInterpolation
import docker
import random
import string
import sys
from pwd import getpwnam

prog = 'dockersh'
config_file = "/etc/dockertempsh.ini"

import os
user = os.getlogin()

host = os.uname()[1]

cli = docker.APIClient()

def containers(image_filter='', container_filter='', sort_by='Created', all=True):
    cs = cli.containers(all=all, filters={'label': "user="+user})
    cs.sort(key=lambda c: c[sort_by])
    cs = [c for c in cs if str(c['Image']+':latest').startswith(image_filter)]
    cs = [c for c in cs if c['Names'][0][1:].startswith(container_filter)]
    return cs

def random_string(length):
        def random_char():
            return random.choice(string.ascii_uppercase + string.digits)
        return ''.join(random_char() for _ in range(length))

def strip(s, suffix=''):
    for c in ['/', ':', '.', ' ']:
        s = s.replace(c, '')
    if s.endswith(suffix):
        s = s[:len(s)-len(suffix)]
    return s

def image_split(s):
    sp = s.split(':')
    if len(sp) == 1:
        return sp[0], 'latest'
    else:
        return sp[0], sp[1]

#Chargement du fichier de configuration
config_envir = {
    "USER": user,
    "HOME": os.environ['HOME']
}
cfg = ConfigParser(config_envir, interpolation=ExtendedInterpolation())
cfg.read(config_file)

ini = cfg[user] if cfg.has_section(user) else cfg['DEFAULT']

#Spécification particulière
post_cmd = ""
name = ""
image = ""
home = ini['homedir']
suffix = ini['suffix']

#Vérification des spécifications
name_passed  = (name  != "")
image_passed = (image != "")

#Génération du container temporaire

#Création du nom random
if not image_passed:
    image = ini['image']
image_base, image_tag = image_split(image)
image = image_base + ':' + image_tag
name = strip(image) + '_tmp' + random_string(4)

full_name = name + suffix

#Création
if len(containers(container_filter=name)) == 0:
    volumes = []
    if "volumes" in ini:
        volumes = volumes + ini["volumes"].split(",")
    volumes = [v.split(":") for v in volumes]
    binds = {v[0].strip():{"bind":v[1].strip(),"mode":v[2].strip()} for v in volumes}
    volumes = [v[1] for v in volumes]

    host_config = cli.create_host_config(
        binds=binds,
        restart_policy={'Name' : 'unless-stopped'},
        cap_add='SYS_PTRACE', #GDB
        security_opt=['seccomp:unconfined']) #GDB

    userpwd = getpwnam(user)
    cli.create_container(image,
                         stdin_open=True,
                         tty=True,
                         name=full_name,
                         hostname='systemekrkn',
                         labels={'group': prog, 'user': user},
                         volumes=volumes,
                         working_dir=home,
                         environment={
                            "HOST_USER_ID": userpwd.pw_uid,
                            "HOST_USER_GID": userpwd.pw_gid,
                            "HOST_USER_NAME": user
                         },
                         host_config=host_config
                         )

#Lancement et attach
cli.start(full_name)
os.popen('docker exec '+full_name + ' echo Initialization finished.').read().split(":")[-1]

user_bash = "/bin/bash" #Path par défaut
cmd = post_cmd if post_cmd else user_bash #Donne la posibilité de spécifié le path dans le .ini
os.system('docker exec -u '+user+" " + "-it" +' '+ full_name + ' ' + cmd)

#Arrêt à la fin
cli.remove_container(full_name, v=True, force=True)
cli.close()
```

```
chmod +x /usr/local/bin/dockersh
```
### Création d'une image docker de base

#### Dockerfile
```
FROM debian:latest
RUN dpkg --add-architecture i386
RUN apt update && apt install -y gdb elfutils binutils python-minimal perl zip pwgen nano gcc
```
Création de l'image de base debmod
```
docker built -t debmod .
```
### Script pour la création des images Docker à partir des Dockerfile

Usage : ./createImg <systemeXX> <dockerfile>

```
#!/bin/bash
if [ "$#" -lt "2" ]
	then
		echo "Usage : ./createImg <systemeXX> <dockerfile>"
	else
		if [ -f "$2" ];then
			docker build -t $1 $2
		else
			echo "Usage : ./createImg <systemeXX> <dockerfile>"
			exit 0
		fi
fi
```

### Script pour la création d'un utilisateurs et son ajout à DockerTemp

Usage ./deployEnv <systemeXX>

```
#!/bin/bash
if [ "$#" -eq  "0" ]
	then
		echo "Usage : ./deployEnv <systemeXX>"
	else
		if grep -q "$1" /etc/dockertempsh.ini
		then
			echo "Utilisateur déjà crée dans /etc/dockertempsh.ini ECHEC"
			exit 1
		else
			useradd -m -p $1 -s /usr/local/bin/dockersh $1
			echo "$1:$1" | chpasswd
			adduser $1 docker
			echo -e "[$1]
			image = $1
			suffix = _$1
			homedir = /home/$1
			volumes = /globalinfo:/globalinfo:ro" >> /etc/dockertempsh.ini
		fi
fi
```

Une fois le programme mis au bon endroit et les deux scripts executés avec succès tout est prêt. Pour personnaliser le message d'acceuil il faut modifié le /etc/motd de la VM et non celui des containers Docker.

## Restauration des challenges déjà existant
Voilà la correspondance utilisateur / challenge
```
systeme1 -> easyshell
systeme2 -> pwn_my_home
systeme3 -> overflow
systeme4 -> shellcode1
systeme5 -> shellcode3
systeme6 -> shellcode3
systeme7 -> history
```

Extraire l'archive des challenge dans /home/systeme/SystemeChall/

### Script qui utilisera les deux autres pour tout déployer
```
#!/bin/bash
declare -a path=(easyshell pwn_my_home overflow shellcode1 shellcode2 shellcode3 history)
for i in `seq 0 6`;
do
	./createImg.sh systeme$(($i+1)) "/home/systeme/SystemeChall/${path[${i}]}"
	./deployEnv.sh systeme$(($i+1))
done
```

