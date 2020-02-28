# Templace Ferm

L'installation et la configuration de ferm est faite par tout les playbook Ansible.

Si vous n'utilisez pas ces playbook voilà la marche à suivre.

Nous allons ici faire une template pour la sécurisation des conteneurs avec ferm.

Tout les conteneurs et toutes les VM auront un firewall dédié (ferm) qui filtrera en INPUT autorisera tout en OUTPUT et bloquera tout en FORWARDING

Voici comment le filtrage ce fera en INPUT :
- Tout autoriser sur l'interface admin.
- Autoriser que ce qui est nécessaire sur les autres interfaces (la même chose sur toute).

La template utilise des paramètres pour éviter d'avoir à modifier la configuration. Il vous suffit d'adapter les paramètres suivant en fonction de la configuration souhaité.

- IF_FRONT : Point d'entrée principal sur le conteneur
- IF_BACK : Point de sortie sur le conteneur
- PROTO_FRONT : Les protocoles à autorisé sur les ports frontaux ouvert (utile pour le udp du DNS).
- PROTO_BACK : Même chose sur les interfaces de sortie
- HAVE_BACK : Mettre à un si il y a une ou plusieurs interfaces de sortie, à zéro sinon.

Dans le cas du DNS IF_FRONT est son interface sur la zone DMZ et IF_BACK est son interface sur la zone PROXY et son interface sur la zone INT.

```
@def $IF_ADMIN = ;
@def $IF_FRONT = ;
@def $IF_BACK = ();
@def $OPEN_PORT_FRONT = (22);
@def $PROTO_FRONT = (tcp);
@def $OPEN_PORT_BACK = (22);
@def $PROTO_BACK = (tcp);
@def $HAVE_BACK = 0; #0 pour NON 1 pour OUI

table filter {
    chain INPUT {
        policy DROP;
        mod state state INVALID DROP;
        mod state state (ESTABLISHED RELATED) ACCEPT;
        interface lo ACCEPT;
        interface $IF_ADMIN ACCEPT;
        interface $IF_FRONT proto $PROTO_FRONT dport $OPEN_PORT_FRONT ACCEPT;

        @if $HAVE_BACK {
            interface $IF_BACK proto $PROTO_BACK dport $OPEN_PORT_BACK ACCEPT;
        }

        proto icmp icmp-type echo-request ACCEPT;
    }

    chain OUTPUT policy ACCEPT;

    chain FORWARD policy DROP;
}
```
