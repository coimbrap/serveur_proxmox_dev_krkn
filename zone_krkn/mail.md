# Service de Mail
Nous allons ici mettre en place tout un service de mail qui va utiliser LDAP, Postfix, Dovecot et Rspamd. Avant de mettre en place le serveur Mail il faut déjà avoir mis en place le serveur LDAP.

# Configuration du serveur LDAP
Le serveur LDAP est déjà en place sur le container LDAP il faut cependant faire ce qu'il suit pour ajouter le support des mails sur LDAP.

## Ajout d'un schéma

### schema.ldif

```
dn: cn=mailkrhacken,cn=schema,cn=config
objectClass: olcSchemaConfig
cn: mailkrhacken
olcAttributeTypes: ( 1.3.6.1.4.1.99999.2.2.20 NAME 'mailaccountquota' DESC 'Quota Mail' EQUALITY caseExactMatch SINGLE-VALUE SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 )
olcAttributeTypes: ( 1.3.6.1.4.1.99999.2.2.21 NAME 'mailaccountactif' DESC 'Mail Actif' EQUALITY caseExactMatch SINGLE-VALUE SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 )
olcAttributeTypes: ( 1.3.6.1.4.1.99999.2.2.40 NAME 'mailaliasfrom' DESC 'Mail From' EQUALITY caseExactMatch SINGLE-VALUE SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 )
olcAttributeTypes: ( 1.3.6.1.4.1.99999.2.2.41 NAME 'mailaliasto' DESC 'Mail To' EQUALITY caseExactMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 )
olcAttributeTypes: ( 1.3.6.1.4.1.99999.2.2.42 NAME 'mailaliasactif' DESC 'Alias Actif' EQUALITY caseExactMatch SINGLE-VALUE SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 )
olcAttributeTypes: ( 1.3.6.1.4.1.99999.2.2.60 NAME 'maildomain' DESC 'Domaine' EQUALITY caseExactMatch SINGLE-VALUE SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 )
olcAttributeTypes: ( 1.3.6.1.4.1.99999.2.2.61 NAME 'maildomainactif' DESC 'Domaine Actif' EQUALITY caseExactMatch SINGLE-VALUE SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 )
olcObjectClasses: ( 1.3.6.1.4.1.99999.2.1.20 NAME 'mailaccountkrhacken' SUP TOP AUXILIARY MUST ( mailaccountquota $ mailaccountactif))
olcObjectClasses: ( 1.3.6.1.4.1.99999.2.1.40 NAME 'mailaliaskrhacken' SUP TOP STRUCTURAL MUST ( cn $ mailaliasfrom $ mailaliasto $ mailaliasactif))
olcObjectClasses: ( 1.3.6.1.4.1.99999.2.1.60 NAME 'maildomainkrhacken' SUP TOP AUXILIARY MUST ( maildomain $ maildomainactif))
```
```
ldapadd -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f schema.ldif
```

### oumail.ldif

Création d'un OU pour les mails ce qui permet de bien organiser l'arbre.
```
dn: ou=mail,dc=krhacken,dc=org
ou: people
objectClass: organizationalUnit

dn: ou=krhacken.org,ou=mail,dc=krhacken,dc=org
ou: krhacken.org
objectClass: organizationalUnit
objectClass: maildomainkrhacken
description: Domaine mail primaire
maildomain: krhacken.org
maildomainactif: YES
```
```
ldapadd -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f oumail.ldif
```

## Ajout d'un nouvel utilisateur

Ce .ldif permet d'ajouter un nouvel utilisateur dans l'anuaire LDAP et de lui autorisé l'envoi des mails.

### adduser.ldif
```
dn: uid=new,ou=people,dc=krhacken,dc=org
objectclass: person
objectclass: organizationalPerson
objectclass: inetOrgPerson
objectclass: mailaccountkrhacken
uid: new
sn: new
givenName: new
cn: new
displayName: new
userPassword: PASSWORD
mail: new@krhacken.org
mailaccountquota: 0
mailaccountactif: YES
```
```
ldapadd -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f adduser.ldif
```

## Autoriser un utilisateur à utilisé le service des mails

Permet d'ajouter la classe mailaccountkrhacken à un utilisateur, il pourra ensuite utilisé le service.

### addtomail.ldif
```
dn: uid=NAME,ou=people,dc=krhacken,dc=org
changetype: modify
add: objectclass
objectclass: mailaccountkrhacken
-
add: mailaccountquota
mailaccountquota: 0
-
add: mailaccountactif
mailaccountactif: YES
```
```
ldapadd -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f addtomail.ldif
```

On crée dès maintenant une adresse adminsys@krhacken.org, c'est impératif pour la suite.

## Ajout d'un alias pour le postmaster

Permet de rediriger tout les mails à destination du postmaster vers le mail de l'adminsys.

### alias.ldif
```
dn: cn=postmaster@krhacken.org,ou=krhacken.org,ou=mail,dc=krhacken,dc=org
objectclass: mailaliaskrhacken
cn: postmaster@krhacken.org
mailaliasfrom: postmaster@krhacken.org
mailaliasto: adminsys@krhacken.org
mailaliasactif: YES
```
```
ldapadd -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f alias.ldif
```

La commande suivante renvoie la liste des mails crée il faut y trouver adminsys@krhacken.org. A noté qu'un mail est considérés comme crée quand il est dans la classe mailaccountkrhacken.
```
ldapsearch -xLLL -H ldap://localhost -D cn=admin,dc=krhacken,dc=org -y /root/pwdldap -b "ou=people,dc=krhacken,dc=org" "(&(objectClass=mailaccountkrhacken))"
```

# Postfix
Postfix et Dovecot seront dans le même container. Nous allons commencer par Postfix qui utilise le protocole SMTP pour envoyer et recevoir des mails. C'est un service très complet mais nécessaire.

## DNS
Voilà les entrées à ajouter, on en rajoutera d'autres à la fin
```
IN MX     10 mail
mail      IN A      PUBLICIP
```
La commande
```
dig krhacken.org MX +short
```
Doit retourner _10 mail.krhacken.org._

## Redirection de ports
Voilà la liste des ports qui vont être utilisé par le container Mail qui contient Postfix et Dovecot.
- 25 -> SMTP
- 465 -> SMTPS
- 587 -> SUBMISSION
- 143 -> IMAP
- 993 -> IMAPS
- 4190 -> Managesieve
Tout c'est ports sont déjà DNAT sur le container Mail grâce à OPNSense

## Installation
### Postfix
```
apt-get install -y postfix postfix-ldap ca-certificates postfix-pcre git socat postfix-policyd-spf-python dovecot-core dovecot-imapd dovecot-ldap dovecot-managesieved dovecot-sieve dovecot-lmtpd
```

Lors de l'instation de Postfix il faut préciser les paramètres suivant, laisser le reste par défaut, on le modifira plus tard. Si ce n'est pas demandé par apt utiliser dpkg-reconfigure

```
Internet Site
mail.krhacken.org
```

## Certificat
Postfix à besoin de certificat SSL pour fonctionner nous allons utiliser un script faisant appel à Let's Encrypt pour obtenir ces certificats.

### Installation
```
mkdir ~/sources
cd ~/sources/
git clone https://github.com/Neilpang/acme.sh.git
cd ./acme.sh
./acme.sh --install
```
### Ajout d'un reverse proxy au niveau des containers nginx
Pour que les requêtes ACME sur le domaine mail.krhacken.org arrive sur le container Postfix il faut rajouter un reverse dans les containers Nginx Public.
```
server {
    listen 80;
    server_name mail.krhacken.org;
    location / {
        proxy_pass http://IPMAIL/;
    }
}
```
On peut maintenant demander un certificat a Let's Encrypt
### Création du certificat
```
acme.sh --issue -k 4096 --standalone -d mail.krhacken.org --log
```
### Installation du certificat et ajout d'une tâche cron
```
mkdir /etc/ssl/private/krhacken.org
acme.sh --installcert -d mail.krhacken.org --cert-file /etc/ssl/private/krhacken.org/cert.pem --key-file /etc/ssl/private/krhacken.org/key.pem --ca-file /etc/ssl/private/krhacken.org/ca.pem --fullchain-file /etc/ssl/private/krhacken.org/fullcert.pem --reloadCmd 'systemctl reload postfix && systemctl reload dovecot'
```
### Génération des clés DH
On génère les clés DH qui seront nécessaire à postfix
```
openssl dhparam -out /etc/ssl/private/krhacken.org/dh512.pem 512
openssl dhparam -out /etc/ssl/private/krhacken.org/dh2048.pem 2048
chmod 644 /etc/ssl/private/krhacken.org/dh{512,2048}.pem
```

## Configuration de Postfix

Postfix utilise deux fichier de configuration, le fichier main.cf définit les options générales de Postfix et le fichier master.cf sert à gérer les sous process de Postfix et permet de modifier certains paramètres du fichier main.cf en les surchargeant (option -o).

### /etc/postfix/main.cf
Cette configuration empêche des utilisateurs déjà connecté au SMTP de modifer leur adresse mail il n'est donc pas possible d'usurper une adresse mail même non attribué.
```
mynetworks = 10.0.0.0/8
inet_interfaces = all
inet_protocols = ipv4
smtpd_banner = $myhostname ESMTP $mail_name (Debian/GNU)
biff = no
append_dot_mydomain = yes
readme_directory = no
compatibility_level = 2

notify_classes = bounce, delay, policy, protocol, resource, software
myhostname = mail.krhacken.org
mydestination = $myhostname, mail, localhost.localdomain, localhost
myorigin = $myhostname
disable_vrfy_command = yes
strict_rfc821_envelopes = yes
show_user_unknown_table_name = no
message_size_limit = 0
mailbox_size_limit = 0
allow_percent_hack = no
swap_bangpath = no
recipient_delimiter = +
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases

broken_sasl_auth_clients=yes

policyd-spf_time_limit = 3600s

smtp_tls_security_level = may
smtp_tls_session_cache_database  = btree:${data_directory}/smtp_tlscache

smtpd_tls_loglevel = 1
smtpd_tls_security_level = may
smtpd_tls_auth_only = yes
smtpd_tls_key_file = /etc/ssl/private/krhacken.org/key.pem
smtpd_tls_cert_file = /etc/ssl/private/krhacken.org/cert.pem
smtpd_tls_CAfile = /etc/ssl/private/krhacken.org/fullcert.pem
smtpd_tls_protocols = !SSLv2 !SSLv3
smtpd_tls_mandatory_protocols = !SSLv2 !SSLv3
smtpd_tls_mandatory_ciphers = high
smtpd_tls_eecdh_grade = strong
smtpd_tls_dh512_param_file  = /etc/ssl/private/krhacken.org/dh512.pem
smtpd_tls_dh1024_param_file = /etc/ssl/private/krhacken.org/dh2048.pem
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_tlscache
smtpd_tls_session_cache_timeout = 3600s
smtpd_tls_received_header = yes

smtpd_sasl_auth_enable = yes
smtpd_sasl_path = private/auth
smtpd_sasl_type = dovecot
smtpd_sasl_security_options = noanonymous, noplaintext
smtpd_sasl_tls_security_options = noanonymous

tls_preempt_cipherlist = yes
tls_high_cipherlist = ALL EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA RC4 !aNULL !eNULL !LOW !MEDIUM !3DES !MD5 !EXP !PSK !SRP !DSS !RC4
tls_ssl_options = no_ticket, no_compression
smtpd_helo_required = yes

smtpd_client_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unknown_reverse_client_hostname,
    reject_unauth_pipelining

smtpd_helo_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    check_helo_access ldap:/etc/postfix/ldap/check_helo_domains_reject.cf,
    reject_invalid_helo_hostname,
    reject_non_fqdn_helo_hostname,
    reject_unauth_pipelining

smtpd_sender_restrictions =
    reject_sender_login_mismatch,
    permit_mynetworks,
    permit_sasl_authenticated,
    check_sender_access ldap://etc/postfix/ldap/check_sender_domains_reject.cf,
    check_policy_service unix:private/policyd-spf,
    reject_non_fqdn_sender,
    reject_unknown_sender_domain,
    reject_unauth_pipelining

smtpd_relay_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    ###
    # VITAL, empêche l'open relay
    reject_unauth_destination
    ###

smtpd_recipient_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_non_fqdn_recipient,
    reject_unknown_recipient_domain,
    reject_unauth_pipelining

smtpd_data_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_multi_recipient_bounce,
    reject_unauth_pipelining

virtual_transport = lmtp:unix:private/dovecot-lmtp
virtual_mailbox_domains = ldap:/etc/postfix/ldap/virtual_domains.cf
virtual_mailbox_maps = ldap:/etc/postfix/ldap/virtual_mailbox.cf
virtual_alias_maps = ldap:/etc/postfix/ldap/virtual_alias.cf
smtpd_sender_login_maps = ldap:/etc/postfix/ldap/virtual_senders.cf
```

### /etc/postfix/master.cf
Modifer les champs suivant, laisser les autres champs par défaut
```
smtp      inet  n       -       y       -       1       postscreen
  -o cleanup_service_name=subcleanin
smtpd     pass  -       -       y       -       -       smtpd
dnsblog   unix  -       -       y       -       0       dnsblog
tlsproxy  unix  -       -       y       -       0       tlsproxy
submission inet n       -       y       -       -       smtpd

submission inet   n   -   y   -   -   smtpd
  -o smtpd_tls_security_level=encrypt
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o cleanup_service_name=subcleanout
smtps      inet   n   -   y   -   -   smtpd
  -o smtpd_tls_security_level=encrypt
  -o smtpd_tls_wrappermode=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o cleanup_service_name=subcleanout

cleanup     unix   n   -   y   -   0   cleanup
subcleanout unix   n   -   -   -   0   cleanup
  -o header_checks=pcre:/etc/postfix/check/header_checks_out
  -o mime_header_checks=pcre:/etc/postfix/check/header_checks_out
subcleanin  unix   n   -   -   -   0   cleanup
  -o header_checks=pcre:/etc/postfix/check/header_checks_in
  -o mime_header_checks=pcre:/etc/postfix/check/header_checks_in

policyd-spf unix - n n - - spawn
  user=nobody argv=/usr/bin/policyd-spf
```
On permet uniquement les utilisateurs connectés et on appelle un service que l'on va créer plus bas qui permet de nettoyer les headers et d'avertir l'utilisateur en cas de pièce jointe suspecte.

## Filtre sur les Header Postfix
Ce filtre permet de nettoyer les headers d'un mail en enlevant les informations sensible et d'avertir l'utilisateur si une pièce jointe est potentiellement dangereuse.

### /etc/postfix/check/header_checks_in
```
/^s*Content­.(Disposition|Type).*names*=s*"?(.+.(bat|exe|com|scr|vbs))"?s*$/ PREPEND X-DEBUGO:WARN
```
### /etc/postfix/check/header_checks_out
Masquage des informations sensibles
```
/^\s*Received: from \S+ \(\S+ \[\S+\]\)(.*)/ REPLACE Received: from [127.0.0.1] (localhost [127.0.0.1])$1
/^X-Originating-IP:/ IGNORE
/^X-Mailer:/ IGNORE
/^Mime-Version:/ IGNORE
/^User-Agent:/ IGNORE
```

## Redirection des mails root de tout les CT et des VMs
On va faire en sorte que tout les mails des CTs et des VMs soit redirigés vers l'adresse adminsys@krhacken.org soit directement soit via l'alias postmaster.

### /etc/aliases
```
postmaster: postmaster@krhacken.org
root: adminsys@krhacken.org
```

## Policyd SPF
SPF est un mécanisme simple qui permet de savoir si le serveur SMTP à l’origine d’un mail est bien légitime.
### /etc/postfix-policyd-spf-python/policyd-spf.conf
```
debugLevel = 1

HELO_reject = Fail
Mail_From_reject = Fail

PermError_reject = False
TempError_Defer = False

skip_addresses = 127.0.0.0/8,10.0.0.0/8
```
Les mails qui ne respectent pas les SPF seront rejetés. Par contre, s’il n’y a pas de SPF définis, on accepte.

## Blocage des clients trop rapide
On va ici bloquer les clients trop rapide et vérifier la légitimité du champs MX de serveur émetteur.

### /etc/postfix/main.cf
```
postscreen_greet_wait = 3s
postscreen_greet_banner = On attend un pneu...
postscreen_greet_action = drop
postscreen_dnsbl_sites =
 zen.spamhaus.org*2,
 bl.spamcop.net,
 b.barracudacentral.org*2
postscreen_dnsbl_threshold = 3
postscreen_dnsbl_action = drop
postscreen_pipelining_enable = yes
postscreen_pipelining_action = enforce
postscreen_non_smtp_command_enable = yes
postscreen_non_smtp_command_action = enforce
postscreen_bare_newline_enable = yes
postscreen_bare_newline_action = enforce
```

## Filtre via LDAP
On place tout les fichiers de configuration dans /etc/postfix/ldap, ces fichiers permettent de faire des requêtes au serveur LDAP pour l'authentification du client au service mail.

### /etc/postfix/ldap/virtual_domains.cf
```
server_host = ldap://10.0.1.6
version = 3
bind = yes
bind_dn = cn=viewer,ou=system,dc=krhacken,dc=org
bind_pw = PASSWRITE
search_base = ou=mail,dc=krhacken,dc=org
scope = sub
query_filter = (&(maildomain=%s)(objectClass=maildomainkrhacken)(maildomainactif=YES))
result_attribute = maildomain
```
### /etc/postfix/ldap/virtual_mailbox.cf
```
server_host = ldap://10.0.1.6
version = 3
bind = yes
bind_dn = cn=viewer,ou=system,dc=krhacken,dc=org
bind_pw = PASSWRITE
search_base = ou=people,dc=krhacken,dc=org
scope = sub
query_filter = (&(mail=%s)(objectClass=mailaccountkrhacken)(mailaccountactif=YES))
result_attribute = mail
```
### /etc/postfix/ldap/virtual_alias.cf
```
server_host = ldap://10.0.1.6
version = 3
bind = yes
bind_dn = cn=viewer,ou=system,dc=krhacken,dc=org
bind_pw = PASSWRITE
search_base = ou=mail,dc=krhacken,dc=org
scope = sub
query_filter = (&(mailaliasfrom=%s)(objectClass=mailaliaskrhacken)(mailaliasactif=YES))
result_attribute = mailaliasto
```
### /etc/postfix/ldap/virtual_senders.cf
```
server_host = ldap://10.0.1.6
version = 3
bind = yes
bind_dn = cn=viewer,ou=system,dc=krhacken,dc=org
bind_pw = PASSWRITE
search_base = dc=krhacken,dc=org
scope = sub
query_filter = (|(&(mailaliasfrom=%s)(objectClass=mailaliaskrhacken)(mailaliasactif=YES))(&(mail=%s)(objectClass=mailaccountkrhacken)(mailaccountactif=YES)))
result_attribute = mail mailaliasto
```
### /etc/postfix/ldap/check_helo_domains_reject.cf
```
server_host = ldap://10.0.1.6
version = 3
bind = yes
bind_dn = cn=viewer,ou=system,dc=krhacken,dc=org
bind_pw = PASSWRITE
search_base = ou=mail,dc=krhacken,dc=org
scope = sub

query_filter = (&(maildomain=%s)(objectClass=maildomainkrhacken)(maildomainactif=YES))
result_attribute = maildomain
result_filter = REJECT Goodbye
```
### /etc/postfix/ldap/check_sender_domains_reject.cf
Bloque les FROM TO vers les mails non attribués
```
server_host = ldap://10.0.1.6
version = 3
bind = yes
bind_dn = cn=viewer,ou=system,dc=krhacken,dc=org
bind_pw = PASSWRITE
search_base = ou=mail,dc=krhacken,dc=org
scope = sub

query_filter = (&(maildomain=%s)(objectClass=maildomaindebugo)(maildomainactif=YES))
result_attribute = maildomain
result_filter = REJECT Tentative d'usurpation
```
On sécurise ces fichiers
```
chmod 640 /etc/postfix/ldap/
chown :postfix /etc/postfix/ldap/*
```
On reload Postfix et on teste la connectivité avec LDAP
```
postfix reload
postmap -q krhacken.org ldap:/etc/postfix/ldap/virtual_domains.cf
```
On transmet à Postfix
```
newaliases
postfix reload
```
A ce stade la connexion TLS fonctionne on peut la vérifier avec https://www.checktls.com/TestReceiver


# Dovecot
Nous allons utiliser Dovecot comme serveur IMAP qui permmtra au client de consulter ces mails sur le serveur.

## Préparation
Création d'un utilisateur pour stocker les mails
```
groupadd -g 11111 vmail
useradd -g vmail -u 11111 vmail -d /home/vmail -m
chown vmail: /home/vmail -R
chmod 770 /home/vmail
```
Tri des fichiers de configuration
```
cd /etc/dovecot/conf.d
rm 10-director 10-tcpwrapper 90-acl auth-* 10-auth.conf 10-logging.conf 10-mail.conf 10-master.conf 10-ssl.conf 15-mailboxes.conf 15-lda.conf 20-imap.conf 20-lmtp.conf /20-managesieve.conf 90-sieve.conf
cd /etc/dovecot
rm dovecot-dict-* dovecot-sql.conf.ext dovecot-ldap.conf.ext dovecot.conf
```

## Configuration
### /etc/dovecot/dovecot.conf
```
protocols = imap lmtp

!include conf.d/*.conf
```
### /etc/dovecot/conf.d/10-auth.conf
```
auth_cache_size = 0
auth_cache_ttl = 1 hour
auth_cache_negative_ttl = 1 hour
auth_mechanisms = plain
passdb {
  driver = ldap
  args = /etc/dovecot/dovecot-ldap-pass.conf.ext
}
userdb {
  driver = prefetch
}
userdb {
  driver = ldap
  args = /etc/dovecot/dovecot-ldap-user.conf.ext
}
```
### /etc/dovecot/conf.d/10-logging.conf
```
#log_path = syslog
#debug_log_path =
#syslog_facility = mail
#auth_verbose = no
#auth_verbose_passwords = no
#auth_debug = no
#auth_debug_passwords = no
#mail_debug = no
#verbose_ssl = no

plugin {
  #mail_log_events = delete undelete expunge copy mailbox_delete mailbox_rename
  # Available fields: uid, box, msgid, from, subject, size, vsize, flags
  # size and vsize are available only for expunge and copy events.
  #mail_log_fields = uid box msgid size
}

#log_timestamp = "%b %d %H:%M:%S "
#login_log_format_elements = user=<%u> method=%m rip=%r lip=%l mpid=%e %c
#login_log_format = %$: %s
#mail_log_prefix = "%s(%u): "

# %$ - Delivery status message (e.g. "saved to INBOX")
# %m - Message-ID
# %s - Subject
# %f - From address
# %p - Physical size
# %w - Virtual size
#deliver_log_format = msgid=%m: %$
```
### /etc/dovecot/conf.d/10-mail.conf
Emplacement des mails
```
mail_home = /home/vmail/%d/%n
mail_location = maildir:~/mailbox

namespace inbox {
  separator = /
  inbox = yes
}

mail_uid = 11111
mail_gid = 11111
mail_privileged_group = vmail
first_valid_uid = 11111
last_valid_uid = 11111
first_valid_gid = 11111
last_valid_gid = 11111

mail_plugins = $mail_plugins quota
```
### /etc/dovecot/conf.d/10-master.conf
On déclare ici les services
```
mail_fsync = never
default_client_limit = 1500

service imap-login {
  inet_listener imap {
    port = 143
  }
}

service imap {
  service_count = 64
  process_min_avail = 1
}

service lmtp {
  unix_listener /var/spool/postfix/private/dovecot-lmtp {
    group = postfix
    mode = 0600
    user = postfix
  }
}

service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}

service auth-worker {
  user = vmail
}
```
### /etc/dovecot/conf.d/10-ssl.conf
Le SSL
```
ssl = required
ssl_ca = </etc/ssl/private/krhacken.org/ca.pem
ssl_cert = </etc/ssl/private/krhacken.org/cert.pem
ssl_key = </etc/ssl/private/krhacken.org/key.pem
ssl_dh_parameters_length = 2048
ssl_protocols = !SSLv3 !TLSv1 !TLSv1.1 TLSv1.2
ssl_cipher_list = ALL:!LOW:!SSLv2:!EXP:!aNULL
ssl_prefer_server_ciphers = yes
```
### /etc/dovecot/conf.d/15-mailboxes.conf
Architecture de base de la BAL
```
namespace inbox {
  separator = /
  mailbox Drafts {
    auto = subscribe
    special_use = \Drafts
  }
  mailbox Junk {
    auto = subscribe
    special_use = \Junk
  }
  mailbox Trash {
    auto = subscribe
    special_use = \Trash
  }
  mailbox Sent {
    auto = subscribe
    special_use = \Sent
  }
  mailbox Archive {
    auto = subscribe
    special_use = \Archive
  }
}
```
### /etc/dovecot/conf.d/15-lda.conf
```
protocol lda {
  info_log_path =
  log_path =
  mail_plugins = sieve quota
  postmaster_address = postmaster@krhacken.org
  quota_full_tempfail = yes
}
```
### /etc/dovecot/conf.d/20-imap.conf
Configuration de IMAP
```
imap_idle_notify_interval = 30 mins

protocol imap {
  mail_max_userip_connections = 50
  mail_plugins = $mail_plugins imap_sieve imap_quota
  postmaster_address = postmaster@krhacken.org
}
```
### /etc/dovecot/conf.d/20-lmtp.conf
Configuration de LMTP
```
protocol lmtp {
  mail_fsync = optimized
  mail_plugins = $mail_plugins sieve quota
  postmaster_address = postmaster@krhacken.org
}
```
### /etc/dovecot/conf.d/20-managesieve.conf
Configuration de ManageSieve
```
protocols = $protocols sieve

service managesieve-login {
  inet_listener sieve {
    port = 4190
  }
  service_count = 1
  #process_min_avail = 0
  #vsz_limit = 64M
}
```
### /etc/dovecot/conf.d/90-sieve.conf
Configuration de Sieve
```
plugin {
  quota = maildir:User quota
  quota_warning = storage=90%% quota-warning 90 %u
}

service quota-warning {
  executable = script /etc/dovecot/quota.sh
  user = vmail
  unix_listener quota-warning {
    user = vmail
  }
}
```

## Link avec LDAP
On met auth_bind à no ainsi le test du mot de passe se fera via le compte viewer ce qui permettra de gagner du temps sur les requêtes LDAP car dovecot pourra en faire plusieurs en même temps.

Cependant cela pose un problème, les requêtes LDAP ne sont pas correcte pour parer à ce problème on fait en sorte que les requêtes à userdb et passdb soient distincts.

### /etc/dovecot/dovecot-ldap-pass.conf.ext
```
uris = ldap://10.0.1.6
dn = cn=viewer,ou=system,dc=krhacken,dc=org
dnpass = PASSWRITE
debug_level = 0
auth_bind = no
ldap_version = 3
base = ou=people,dc=krhacken,dc=org
scope = subtree

pass_attrs = mail=user,userPassword=password,mailaccountquota=userdb_quota_rule=*:bytes=%$
pass_filter = (&(uid=%u)(objectClass=mailaccountkrhacken)(mailaccountactif=YES))
```
### /etc/dovecot/dovecot-ldap-user.conf.ext
```
uris = ldap://10.0.1.6
dn = cn=viewer,ou=system,dc=krhacken,dc=org
dnpass = PASSWRITE
debug_level = 0
auth_bind = no
ldap_version = 3
base = ou=people,dc=krhacken,dc=org
scope = subtree

user_attrs = mailaccountquota=quota_rule=*:bytes=%$
user_filter = (&(mail=%u)(objectClass=mailaccountkrhacken)(mailaccountactif=YES))
```
### Mise en place
```
chmod 600 /etc/dovecot/dovecot-ldap*
systemctl restart dovecot
```
Il ne faut pas voir d'erreur dans le retour de
```
tail /var/log/mail.log -n 100
```

## Sieve
Dovecot permet de filtrer les messages en utilisant le protocole Sieve. Il les range à leur arrivée selon les règles, global et utilisateur.

Pour le global, on aura besoin que d’une seule règle : les messages marqués comme Spam sont dirigés dans le répertoire Spam.

### Préparation
```
mkdir /etc/dovecot/sieve-global
chown vmail /etc/dovecot/sieve-global
```
### /etc/dovecot/sieve-global/global.sieve
Si le header X-spam (rspamd) est à Yes on met le mail dans Junk
```
require ["variables", "envelope", "fileinto", "mailbox", "regex", "subaddress", "body"];

if header :contains "X-Spam" "Yes" {
  fileinto "Junk";
  stop;
}
```
### Mise en place
```
chown vmail: /etc/dovecot/sieve-global/global.sieve
chmod 750 /etc/dovecot/sieve-global/global.sieve
sievec /etc/dovecot/sieve-global/global.sieve
chown vmail /etc/dovecot/sieve-global/global.svbin
```

## Gestion des quota
Le support des quota est déjà mis en place dans Dovecot on va faire en sorte qu'un mail soit envoyé en cas de BAL pleine.

### /etc/dovecot/quota.sh
```
#!/usr/bin/env bash

PERCENT=${1}
USER=${2}

cat << EOF | /usr/lib/dovecot/dovecot-lda -d $USER -o "plugin/quota=maildir:User quota:noenforcing"
From: no-reply@krhacken.org
Subject: Kr[HACK]en - Votre boite aux lettres est pleine a ${PERCENT}
Content-Type: text/plain; charset="utf-8"

Bonjour,
Ce mail automatique est là pour vous avertir que votre BAL est pleine a ${PERCENT}. Pensez à libérer de place pour continuer de recevoir des mails.
EOF
```

### Mise en place
```
chmod +x /etc/dovecot/quota.sh
chown vmail /etc/dovecot/quota.sh
dovecot reload
```
Si on veut modifier le quota d'un utilisateur il faut passer par LDAP voilà le modèle du .ldif
### mod_quota.ldif
Cela correspond à un quota de 2Go
```
dn: uid=NOM,ou=people,dc=krhacken,dc=org
changetype: modify
replace: mailaccountquota
mailaccountquota: 2147483648
```
A partir de là on peut envoyer et recevoir des mails avec par exemple Thunderbird pour augmenter la protection et la fiabilité de notre service des mails on va rajouter un antispam qui utile du machine learning. Pour authentifier notre serveur nous allons rajouter des entrées DNS

# Rspamd
## Préparation
On ajoute la clé et le dépot de rspamd puis on l'installe
```
wget -O- https://rspamd.com/apt-stable/gpg.key | apt-key add -
echo "deb [arch=amd64] http://rspamd.com/apt-stable/ stretch main" > /etc/apt/sources.list.d/rspamd.list
apt-get update
apt-get install -y rspamd redis-server
```
## Configuration
On va utiliser l'assistant
```
rspamadm configwizard
```
Il faut répondre de la manière suivante
```
Do you wish to continue?[Y/n]: -> Yes
Controller password is not set, do you want to set one?[Y/n]: -> Yes
Do you wish to set Redis servers?[Y/n]: -> Yes
Input read only servers separated by `,` [default: localhost] -> localhost
Input write only servers separated by `,` [default: localhost] -> localhost
Do you have any password set for your Redis?[y/N]: -> No
Do you have any specific database for your Redis?[y/N]: -> No
Do you want to setup dkim signing feature?[y/N]: -> No
Expire time for new tokens [100d]:  -> 100d
Reset previous data?[y/N]: -> No
Do you wish to convert them to Redis?[Y/n]: -> Yes
```
On recharge rspamd
```
systemctl reload rspamd
```
### /etc/rspamd/local.d/classifier-bayes.conf
On rajoute
```
autolearn = true;
```
### /etc/rspamd/local.d/worker-controller.inc
Le socket sur le port 11334 sera pour l’interface Web (c’est pour cela qu’on le bind sur l’ip interne de la machine et non sur localhost). Le second socket servira pour l’apprentissage des spams.
```
bind_socket = "10.0.5.51:11334";
bind_socket = "/var/run/rspamd/rspamd.sock mode=0666 owner=nobody";
```
### /etc/rspamd/local.d/metrics.conf
Permet d’indiquer vos valeurs pour les différentes actions
```
actions {
add_header = 5;
greylist = 15;
reject = 30;
}
```
### /etc/rspamd/local.d/milter_headers.conf
Il indique d’ajouter des entêtes dans les mails. Grace à eux, vous pourrez voir directement dans votre logiciel ce qui a provoqué ou non le marquage en spam. 

```
extended_spam_headers = true;
```
### /etc/rspamd/local.d/rspamd_update.conf
Permet à Rspamd de se mettre à jour automatiquement au niveau des règles.

```
enabled = true;
```
## Liaison avec Postfix
On va indiquer à Postfix de passer le mail à Rspamd

### /etc/postfix/main.cf
Il faut rajouter ce qu'il suit dans le fichier

```
milter_protocol = 6
milter_default_action = accept
smtpd_milters = inet:localhost:11332
non_smtpd_milters=inet:localhost:11332
milter_mail_macros = i {mail_addr} {client_addr} {client_name} {auth_authen}
```
Redémarrage de rspamd et de postfix
```
postfix reload
systemctl restart rspamd
```

## Machine Learning en fonction des actions des utilisateurs
Les mails Spam sont considérées comme Spam et les mails lisible sont considérées comme Ham.
Couplé avec Dovecot, Rspamd nous propose de pouvoir apprendre également en fonction des actions des utilisateurs. Si un mail est déplacé vers le répertoire spam, il sera appris comme tel et au contraire,  s’il est sorti du répertoire Spam vers autre chose que la corbeille, il sera appris comme Ham.
### /etc/dovecot/conf.d/90-sieve-extprograms.conf
```
plugin {
sieve_plugins = sieve_imapsieve sieve_extprograms

imapsieve_mailbox1_name = Junk
imapsieve_mailbox1_causes = COPY
imapsieve_mailbox1_before = file:/etc/dovecot/sieve/report-spam.sieve

imapsieve_mailbox2_name = *
imapsieve_mailbox2_from = Junk
imapsieve_mailbox2_causes = COPY
imapsieve_mailbox2_before = file:/etc/dovecot/sieve/report-ham.sieve

sieve_pipe_bin_dir = /etc/dovecot/sieve

sieve_global_extensions = +vnd.dovecot.pipe
}
```
Rechargement de dovecot
```
dovecot reload
```

## Filtres sieves
Création de filtre pour rspamd, un utilisateur considérés comme spam qui sera déplacer par l'utilisateur dans ca Boite de réception augmentera ces chances de ne pas être considérés comme Spam et inversement.

### /etc/dovecot/sieve/report-ham.sieve
```
require ["vnd.dovecot.pipe", "copy", "imapsieve", "environment", "variables"];

if environment :matches "imap.email" "*" {
set "email" "${1}";
}

pipe :copy "train-spam.sh" [ "${email}" ];
```
### /etc/dovecot/sieve/report-spam.sieve
```
require ["vnd.dovecot.pipe", "copy", "imapsieve", "environment", "variables"];

if environment :matches "imap.mailbox" "*" {
set "mailbox" "${1}";
}

if string "${mailbox}" "Trash" {
stop;
}

if environment :matches "imap.email" "*" {
set "email" "${1}";
}

pipe :copy "train-ham.sh" [ "${email}" ];
```
On compile et on met en place
```
sievec /etc/dovecot/sieve/report-ham.sieve
sievec /etc/dovecot/sieve/report-spam.sieve
chown vmail:vmail /etc/dovecot/sieve/report-*
```
### /etc/dovecot/sieve/train-ham.sh
Script pour entrainer rspamd à détecter les bons mails
```
exec /usr/bin/rspamc -h /var/run/rspamd/rspamd.sock learn_ham
```
### /etc/dovecot/sieve/train-spam.sh
Script pour entrainer rspamd à détecter les spams
```
exec /usr/bin/rspamc -h /var/run/rspamd/rspamd.sock learn_spam
```
### Mise en place
```
chown vmail:vmail /etc/dovecot/sieve/train-*
chmod +x /etc/dovecot/sieve/train-*
dovecot reload
```

## Signature DKIM
On remplace Opendkim par Rspamd
```
mkdir /var/lib/rspamd/dkim
```
### /etc/rspamd/local.d/dkim_signing.conf
```
path = "/var/lib/rspamd/dkim/dkim.$domain.key";
allow_username_mismatch = true;
```
### Signature du domaine
```
rspamadm dkim_keygen -b 2048 -s dkim -d krhacken.org -k /var/lib/rspamd/dkim/dkim.krhacken.org.key | tee -a /var/lib/rspamd/dkim/dkim.krhacken.org.pub
```
Il faut garder le retour de la commande dans un fichier pour plus tard
### /etc/rspamd/local.d/dkim_signing.conf
```
path = "/var/lib/rspamd/dkim/$selector.$domain.key";
selector_map = "/etc/rspamd/dkim_selectors.map";
```
### /etc/rspamd/dkim_selectors.map
```
krhacken.org selecteur
```
### Application
```
chmod u=rw,g=r,o= /var/lib/rspamd/dkim/*
chown _rspamd /var/lib/rspamd/dkim/*
systemctl reload rspamd
```
### Interfaçe Web
On rajoute dans la configuration du reverse mail
```
location /rspamd/ {
  proxy_pass http://10.0.1.10:11334/;
  proxy_http_version 1.1;
}
```

## Entrée DNS
### SPF
Permet de valider auprès des récepteurs de nos mails que nous somme vraiment l'expéditeur légitime du mail.
```
IN TXT "v=spf1 ip4:195.154.163.18 mx -all"
```
### DKIM
L’objectif du protocole DKIM est de prouver que le nom de domaine n’a pas été usurpé et que le message n’a pas été altéré durant sa transmission.
Utiliser le retour de la commande que vous avez mis de côté quand vous avez généré la clé DKIM
```
dkim._domainkey IN TXT ( "v=DKIM1; k=rsa; "
        "p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0/4Bq5TCjMqW3ptxnlKW861t7EFPQKuQQOODRwC3FXgzAUzPS52QuXVvHLSVEbIK0wCTQ+Dc0rGgjo69ykyVhb5gPe33MUGosj1rIIfu8X0ST2DguEqdMkfrVq0K8d4nFBTBECm7iC371zaYqmrcfKrThxlb4Ndeq08F5MS3v6CHwXG53n2Y5zt3taXaHe++VyPC7xmsOTJWKQ/Fk"
        "Vvl6BEg78nSrJWGnFxjzHr7jgkhaHt6XxaM/wFZR4crNYaMRJ/6rMHauAO1LbWJKwE6oPZAMawnOfa9BUnRBQJTDOU0FWp6e0cXFBz/sicDR7xzZkseLj3ZIchzd6ECOTNKKQIDAQAB"
) ;
```
## DMARC
DMARC permet à l’expéditeur de recevoir les résultats de l’authentification de ses envois auprès des principaux opérateurs. Il indique ce qu’il faut faire avec des mails qui ne passe pas la politique SPF et/ou DKIM.
```
_dmarc.krhacken.org. IN TXT "v=DMARC1; p=none; rua=mailto:postmaster@krhacken.org;ruf=mailto:postmaster@krhacken.org"
```
On rédemmare le tout
```
systemclt restart postfix
systemclt restart dovecot
systemclt restart rspamd
```
Nous pouvons maintenant tester que le tout marche sur http://www.appmaildev.com