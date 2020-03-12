# Templace Ferm

L'installation et la configuration de ferm est faite par tout les playbook Ansible.

Si vous n'utilisez pas ces playbook voilà la marche à suivre.

Nous présentons ici une template pour la sécurisation des conteneurs avec ferm.

Tout les conteneurs et toutes les VM auront un firewall dédié (ferm) qui filtrera en INPUT / OUTPUT et bloquera tout en FORWARDING

Voici comment le filtrage ce fera en INPUT :
- Tout autoriser sur l'interface admin.
- Autoriser que ce qui est nécessaire sur l'interface principale.
- Autoriser que ce qui est nécessaire sur les interfaces secondaires avec la possibilité de rien ouvrir.
- Option port UDP dans les deux cas.

Voici comment le filtrage ce fera en OUTPUT :
- Tout bloquer, sauf les connexions établies, sur l'interface admin.
- Autoriser que ce qui est nécessaire sur l'interface principale.
- Autoriser que ce qui est nécessaire sur les interfaces secondaires avec la possibilité de rien ouvrir.
- Option port UDP dans les deux cas.

La template utilise des paramètres pour éviter d'avoir à modifier la configuration. Il vous suffit d'adapter les paramètres suivant en fonction de la configuration souhaité.

#### Interfaces
- IF_ADMIN : Nom de l'interface d'administration
- IF_FRONT : Nom du point d'entrée principal sur le conteneur
- IF_BACK : Liste des interfaces secondaire, ne doit inclure ni l'interface administration ni les interfaces qui n'ont pas besoin de règles autre que DROP.
- IF_VRRP : Nom de l'interface ayant besoin d'utiliser le protocole VRRP, mettre NEED_VRRP à 1 si besoin de VRRP.

#### Ports TCP ouverts
- HAVE_BACK_ACCESS : Doit accéder à des conteneurs qui sont sur des interfaces secondaires
- HAVE_BACK_REQUEST : Doit être accessible depuis des conteneurs qui sont sur des interfaces secondaires
- OPEN_PORT_FRONT : Liste des ports TCP à ouvrir en entrée sur l'interface principale
- OPEN_PORT_BACK_REQUEST : Liste des ports TCP à ouvrir en entrée sur les interfaces secondaires
- OPEN_PORT_BACK_ACCESS : Liste des ports TCP à ouvrir en sortie sur les interfaces secondaires

#### Ports UDP ouverts
- NEED_UDP_* : 0 si pas besoin d'ouvrir un port UDP 1 sinon
- UDP_OPEN_PORT_FRONT : Liste des ports UDP à ouvrir en entrée sur l'interface principale
- UDP_OPEN_PORT_BACK_ACCESS : Liste des ports UDP à ouvrir en sortie sur les interfaces secondaires
- UDP_OPEN_PORT_BACK_REQUEST : Liste des ports UDP à ouvrir en entrée sur les interfaces secondaires

Les règles restrictives en sortie permettent d'éviter qu'un attaquant puisse accéder à tout le rester du réseau.

```
@def $IF_ADMIN = ;
@def $IF_FRONT = ;
@def $IF_BACK = ();

# REQUEST : EXT -> INT | ACCESS : INT -> EXT

# Depuis l'extérieur sur l'interface principale
@def $HAVE_FRONT_REQUEST = 1; #0 pour NON 1 pour OUI
@def $OPEN_PORT_FRONT_REQUEST = ();
@def $NEED_UDP_FRONT_REQUEST = 0; #0 pour NON 1 pour OUI
@def $UDP_OPEN_PORT_FRONT_REQUEST = ();

# Depuis l'intérieur sur l'interface principale
@def $HAVE_FRONT_ACCESS = 1; #0 pour NON 1 pour OUI
@def $OPEN_PORT_FRONT_ACCESS = ();
@def $NEED_UDP_FRONT_ACCESS = 0; #0 pour NON 1 pour OUI
@def $UDP_OPEN_PORT_FRONT_ACCESS = ();


# Depuis l'extérieur sur les interfaces secondaires
@def $HAVE_BACK_REQUEST = 0; #0 pour NON 1 pour OUI
@def $OPEN_PORT_BACK_REQUEST = ();
@def $NEED_UDP_BACK_REQUEST = 0; #0 pour NON 1 pour OUI
@def $UDP_OPEN_PORT_BACK_REQUEST = ();

# Depuis l'intérieur sur les interfaces secondaires
@def $HAVE_BACK_ACCESS = 1; #0 pour NON 1 pour OUI
@def $OPEN_PORT_BACK_ACCESS = (53);
@def $NEED_UDP_BACK_ACCESS = 1; #0 pour NON 1 pour OUI
@def $UDP_OPEN_PORT_BACK_ACCESS = (53);

# Besoin de VRRP sur IF_VRRP
@def $NEED_VRRP = 0; #0 pour NON 1 pour OUI
@def $IF_VRRP = eth0;

table filter {
    chain INPUT {
        policy DROP;
        mod state state INVALID DROP;
        mod state state (ESTABLISHED RELATED) ACCEPT;
        interface lo ACCEPT;
        interface $IF_ADMIN ACCEPT;

        @if $HAVE_FRONT_REQUEST {
            interface $IF_FRONT proto tcp dport $OPEN_PORT_FRONT_REQUEST ACCEPT;
        }

        @if $NEED_VRRP {
            interface $IF_VRRP proto vrrp ACCEPT;
        }

        @if $NEED_UDP_FRONT_REQUEST {
            interface $IF_FRONT proto udp dport $UDP_OPEN_PORT_FRONT_REQUEST ACCEPT;
        }


        @if $HAVE_BACK_REQUEST {
            interface $IF_BACK proto tcp dport $OPEN_PORT_BACK_REQUEST ACCEPT;
        }

        @if $NEED_UDP_BACK_REQUEST {
            interface $IF_BACK proto udp dport $UDP_OPEN_PORT_BACK_REQUEST ACCEPT;
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
            outerface $IF_VRRP proto vrrp ACCEPT;
        }

        @if $NEED_UDP_FRONT_ACCESS {
            outerface $IF_BACK proto udp dport $UDP_OPEN_PORT_FRONT_ACCESS ACCEPT;
        }

        @if $HAVE_BACK_ACCESS {
            outerface $IF_BACK proto tcp dport $OPEN_PORT_BACK_ACCESS ACCEPT;
        }

        @if $NEED_UDP_BACK_ACCESS {
            outerface $IF_BACK proto udp dport $UDP_OPEN_PORT_BACK_ACCESS ACCEPT;
        }

        proto icmp ACCEPT;
    }

    chain FORWARD policy DROP;
}
```
