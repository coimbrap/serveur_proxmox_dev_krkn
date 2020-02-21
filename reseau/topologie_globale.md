# Topologie globale de l'infrastructure
Le réseau sera découpé en deux sous réseau matérialisé par des switchs virtuel. Le réseau interne accessible directement depuis l'extérieur et le réseau d'administation accessible uniquement via un VPN.

## Réseau WAN

Le réseau WAN permettra de faire le lien entre l'extérieur, les pare-feu et les hyperviseurs.

## Réseau Interne

Le réseau interne sera séparé en 5 zones privées.

- DMZ qui sera située juste après le firewall et qui contiendra les loadbalancer (HAProxy) et le serveur DNS.

- PROXY qui sera placé juste après la DMZ et qui contiendra les reverses proxy pour les services autres que les environnements CTF ainqi qu'une Mail Gateway pour faire un relai entre l'extérieur et le serveur mail. Ce relai permettra de filtré les mails.

- INT qui contiendra les containers des services permanents. La liaison entre INT et PROXY se fera à travers les reverses proxy NGINX et la Mail Gateway.

- CTF qui sera la zone dédiée au reverse proxy CTF et aux containers/VMs des environnements CTF. Le lien avec l'extérieur se ferra directement au niveau de la DMZ via HAProxy.

- DIRTY qui contiendra les containers des services en test

Les requêtes arriveront sur le pare-feu qui effectura un premier filtrage et transmettra les requêtes sur les ports 80 et 443 à un des loadbalancer, c'est le loadbalancer qui décidera ensuite si la requête sera retransmise à l'un des reverses de la zone INT ou au reverse de la zone CTF.

## Réseau Administation

L'accès au réseau administration se fera grâce à un VPN. Depuis le réseau administration on pourra accéder librement à tout les services hyperviseurs compris. Cela pourra par exemple permettre de mettre en place un système de monitoring.

De son côté l'accès à l'interface d'administration de Proxmox se fera aussi par la voie classique. En cas de connexion à pve.krhacken.org, HAProxy vérifiera le certificat client et son CN avant de rediriger vers un des deux panels.
