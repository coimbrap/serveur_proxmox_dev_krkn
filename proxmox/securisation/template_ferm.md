# Templace Ferm

L'installation et la configuration de ferm est faite par tout les playbook Ansible.

Si vous n'utilisez pas ces playbook voilà la marche à suivre.

Nous présentons ici une template pour la sécurisation des conteneurs avec ferm.

Tout les conteneurs et toutes les VM auront un firewall dédié (ferm) qui filtrera en INPUT / OUTPUT et bloquera tout en FORWARDING

Voici comment le filtrage ce fera en INPUT :
- Autoriser que ce qui est nécessaire sur l'interface principale.
- Option pour autorisé le protocole VRRP.
- Option port UDP pour le DNS.

Voici comment le filtrage ce fera en OUTPUT :
- Autoriser que ce qui est nécessaire et les connexions établies sur l'interface principale.
- Option port UDP pour le DNS.

La template utilise des paramètres pour éviter d'avoir à modifier la configuration. Il vous suffit d'adapter les paramètres suivant en fonction de la configuration souhaité.

#### Interfaces
- IF_FRONT : Nom du point d'entrée principal sur le conteneur
- IF_VRRP : Nom de l'interface ayant besoin d'utiliser le protocole VRRP, mettre NEED_VRRP à 1 si besoin de VRRP.

#### Ports TCP ouverts
- HAVE_FRONT_ACCESS : Doit accéder à des conteneurs qui sont sur l'interface principale
- HAVE_FRONT_REQUEST : Doit être accessible depuis des conteneurs qui sont sur l'interface principale
- OPEN_PORT_FRONT_REQUEST : Liste des ports TCP à ouvrir en entrée sur l'interface principale
- OPEN_PORT_FRONT_ACCESS : Liste des ports TCP à ouvrir en sortie sur l'interface principale


#### Ports UDP ouverts
- NEED_UDP_FRONT_ACCESS : 0 si pas besoin d'ouvrir un port UDP en sortie 1 sinon
- NEED_UDP_FRONT_REQUEST : 0 si pas besoin d'ouvrir un port UDP en entrée 1 sinon
- UDP_OPEN_PORT_FRONT_ACCESS : Liste des ports UDP à ouvrir en sortie sur l'interface principale
- UDP_OPEN_PORT_FRONT_REQUEST : Liste des ports UDP à ouvrir en entrée sur l'interface principale

Les règles restrictives en sortie permettent d'éviter qu'un attaquant puisse accéder à tout le reste du réseau.

```
@def $IF_FRONT = eth0;
# REQUEST : EXT -> INT | ACCESS : INT -> EXT

# Depuis l'extérieur sur l'interface principale
@def $HAVE_FRONT_REQUEST = 1; #0 pour NON 1 pour OUI
@def $OPEN_PORT_FRONT_REQUEST = (80 3128 9999); #Par défaut 80/3128/9999
@def $NEED_UDP_FRONT_REQUEST = 0; #0 pour NON 1 pour OUI
@def $UDP_OPEN_PORT_FRONT_REQUEST = ();

# Depuis l'intérieur sur l'interface principale
@def $HAVE_FRONT_ACCESS = 1; #0 pour NON 1 pour OUI
@def $OPEN_PORT_FRONT_ACCESS = (53); #Par défaut 53
@def $NEED_UDP_FRONT_ACCESS = 1; #0 pour NON 1 pour OUI
@def $UDP_OPEN_PORT_FRONT_ACCESS = (53); #Par défaut 53

# Besoin de VRRP
@def $NEED_VRRP = 0; #0 pour NON 1 pour OUI


table filter {
    chain INPUT {
        policy DROP;
        mod state state INVALID DROP;
        mod state state (ESTABLISHED RELATED) ACCEPT;
        interface lo ACCEPT;

        @if $HAVE_FRONT_REQUEST {
            interface $IF_FRONT proto tcp dport $OPEN_PORT_FRONT_REQUEST ACCEPT;
        }

        @if $NEED_VRRP {
            interface $IF_FRONT proto vrrp ACCEPT;
        }
        @if $NEED_UDP_FRONT_REQUEST {
            interface $IF_FRONT proto udp dport $UDP_OPEN_PORT_FRONT_REQUEST ACCEPT;
        }
        proto icmp icmp-type echo-request ACCEPT;
    }
     chain OUTPUT {
        policy DROP;
        mod state state INVALID DROP;
        mod state state (ESTABLISHED RELATED) ACCEPT;
        outerface lo ACCEPT;
        @if $HAVE_FRONT_ACCESS {
            outerface $IF_FRONT proto tcp dport $OPEN_PORT_FRONT_ACCESS ACCEPT;
        }
        @if $NEED_VRRP {
            outerface $IF_FRONT proto vrrp ACCEPT;
        }
        @if $NEED_UDP_FRONT_ACCESS {
            outerface $IF_FRONT proto udp dport $UDP_OPEN_PORT_FRONT_ACCESS ACCEPT;
        }
        proto icmp ACCEPT;
    }
    chain FORWARD policy DROP;
}
```
