# LDAP
Nous allons ici mettre en place le serveur LDAP qui sera répliqué sur les deux nodes. Tout les services utiliseront LDAP pour l'authentification des utilisateurs.
A noté que pour des questions pratique nous n'allons pas utilisé Fusion Directory, il faudra donc créer un schéma pour chaque service et modifier les utilisateur avec ldapadd et ldapmodify.
Pour la sécurisation de LDAP nous allons utiliser LDAP avec STARTTLS.
## Installation slapd
On commence par installer le serveur ldap.
```
apt-get update
apt-get install slapd ldap-utils
```

## Configuration de sladp
On commence par reconfigurer le packet
```
dpkg-reconfigure slapd
```
Il faut répondre de la manière suivante
```
Omit OpenLDAP server configuration? No
DNS domain name: krhacken.org
Organization name? Kr[HACK]en
Administrator password: PASSWORD
Confirm password: PASSWORD
Database backend to use: MDB
Do you want the database to be removed when slapd is purged? YES
Allow LDAPv2 protocol? No
```
### /etc/ldap/ldap.conf
```
BASE dc=krhacken,dc=org
URI ldap://IP.LDAP/
```

## Centralisation des fichiers de configuration
Nous allons créer un répertoire /root/ldap/conf qui va centraliser tous nos fichiers de configuration
```
mkdir -p /root/ldap/conf/
```

## Mise en place SSL
```
apt-get install gnutls-bin ssl-cert
mkdir /etc/ssl/templates
```
### /etc/ssl/templates/ca_server.conf
```
cn = LDAP Server CA
ca
cert_signing_key
```
### /etc/ssl/templates/ldap_server.conf
```
organization = "krhacken"
cn = ldap.krhacken.org
tls_www_server
encryption_key
signing_key
expiration_days = 3652
```
### CA clé et certificat
```
certtool -p --outfile /etc/ssl/private/ca_server.key
certtool -s --load-privkey /etc/ssl/private/ca_server.key --template /etc/ssl/templates/ca_server.conf --outfile /etc/ssl/certs/ca_server.pem
```
### LDAP clé et certificat
```
certtool -p --sec-param high --outfile /etc/ssl/private/ldap_server.key
certtool -c --load-privkey /etc/ssl/private/ldap_server.key --load-ca-certificate /etc/ssl/certs/ca_server.pem --load-ca-privkey /etc/ssl/private/ca_server.key --template /etc/ssl/templates/ldap_server.conf --outfile /etc/ssl/certs/ldap_server.pem
```
Nous avons maintenant créer tout les certificats nécessaire pour pouvoir chiffrer LDAP avec STARTTLS.

## Chiffrement par STARTTLS
Nous avons choisi STARTTLS au lieu de LDAPS car il est plus sûr pour notre usage.
### Gestion des permissions
```
usermod -aG ssl-cert openldap
chown :ssl-cert /etc/ssl/private/ldap_server.key
chmod 640 /etc/ssl/private/ldap_server.key
```

## Ajout des certificat à OpenLDAP
### /root/ldap/conf/addcerts.ldif
```
dn: cn=config
changetype: modify
replace: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/ssl/certs/ca_server.pem

dn: cn=config
changetype: modify
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ssl/certs/ldap_server.pem

dn: cn=config
changetype: modify
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/ssl/private/ldap_server.key
```
Application des modification et redémarrage de slapd
```
ldapmodify -H ldapi:// -Y EXTERNAL -f addcerts.ldif
service slapd force-reload
```
## Sur le serveur
```
cp /etc/ssl/certs/ca_server.pem /etc/ldap/ca_certs.pem
```
Il faut ensuite ajuster la configuration en modifiant la ligne suivante
### /etc/ldap/ldap.conf
```
...
TLS_CACERT /etc/ldap/ca_certs.pem
...
```
### Vérification
La commande
```
ldapsearch -xLLL -H ldap://localhost -D cn=viewer,ou=system,dc=krhacken,dc=org -w passview -b "dc=krhacken,dc=org"
```
doit retourner une erreur, si on ajout -ZZ à la fin ça doit fonctionner


## Configuration des futurs client LDAP
Sur tout les futurs client LDAP il faudra activer la connexion SSL.
Il faut commencer par copier le certificat de la CA (ca_server.pem)
```
cat ca_server.pem | tee -a /etc/ldap/ca_certs.pem
```
Il faut ensuite modifier la configuration en modifiant la ligne suivante
### /etc/ldap/ldap.conf
```
...
TLS_CACERT /etc/ldap/ca_certs.pem
...
```

## Droits d'accès pour la configuration
### /root/ldap/conf/acces-conf-admin.ldif
```
dn: olcDatabase={0}config,cn=config
changeType: modify
add: olcAccess
olcAccess: to * by dn.exact=cn=admin,dc=krhacken,dc=org manage by * break
```
Puis on applique le .ldif
```
ldapmodify -Y external -H ldapi:/// -f acces-conf-admin.ldif
```

# Les overlays
Les overlays sont des fonctionnalités supplémentaires. Si dessous l'ensemble des overlays que nous allons utiliser ainsi que leur utilité.

## MemberOf
L’overlay memberof permet de savoir dans quels groupes se trouve un utilisateur en une seule requête au lieu de deux.
### /root/ldap/conf/memberof_act.ldif
```
dn: cn=module,cn=config
cn:module
objectclass: olcModuleList
objectclass: top
olcmoduleload: memberof.la
olcmodulepath: /usr/lib/ldap
```
### /root/ldap/conf/memberof_conf.ldif
```
dn: olcOverlay=memberof,olcDatabase={1}mdb,cn=config
changetype: add
objectClass: olcMemberOf
objectClass: olcOverlayConfig
objectClass: olcConfig
objectClass: top
olcOverlay: memberof
olcMemberOfDangling: ignore
olcMemberOfRefInt: TRUE
olcMemberOfGroupOC: groupOfNames
olcMemberOfMemberAD: member
olcMemberOfMemberOfAD: memberOf
```
On applique les modifications
```
ldapadd -Y EXTERNAL -H ldapi:/// -f memberof_act.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f memberof_conf.ldif
```
Vérification
```
ldapsearch -QLLLY EXTERNAL -H ldapi:/// -b "cn=config" "Objectclass=olcModuleList"
```

## refint
L'overlay permet de s’assurer de la cohérence de l’annuaire lors de suppression d’entrées.
### /root/ldap/conf/refint_act.ldif
```
dn: cn=module,cn=config
cn: module
objectclass: olcModuleList
objectclass: top
olcmoduleload: refint.la
olcmodulepath: /usr/lib/ldap
```
### /root/ldap/conf/refint_conf.ldif
```
dn: olcOverlay=refint,olcDatabase={1}mdb,cn=config
objectClass: olcConfig
objectClass: olcOverlayConfig
objectClass: olcRefintConfig
objectClass: top
olcOverlay: refint
olcRefintAttribute: memberof member manager owner
olcRefintNothing: cn=admin,dc=krhacken,dc=org
```
On applique les modifications
```
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f refint_act.ldif
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f refint_conf.ldif
```
Vérifications
```
ldapsearch -QLLLY EXTERNAL -H ldapi:/// -b "cn=config" "Objectclass=olcModuleList"
ldapsearch -QLLLY EXTERNAL -H ldapi:/// -b "cn=config" "Objectclass=olcRefintConfig"
```

## Audit Log
Cet overlay sert à auditer chaque modification au sein de l’annuaire. Dans notre cas, cela sera inscrit dans le fichier : /var/log/openldap/audit.ldif

### /root/ldap/conf/auditlog_act.ldif
```
dn: cn=module,cn=config
cn: module
objectclass: olcModuleList
objectclass: top
olcModuleLoad: auditlog.la
olcmodulepath: /usr/lib/ldap
```
### /root/ldap/conf/auditlog_conf.ldif
```
dn: olcOverlay=auditlog,olcDatabase={1}mdb,cn=config
objectClass: olcOverlayConfig
objectClass: olcAuditLogConfig
olcOverlay: auditlog
olcAuditlogFile: /var/log/openldap/auditlog.ldif
```
On applique les modifications
```
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f auditlog_act.ldif
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f auditlog_conf.ldif
```
On créer le fichier
```
mkdir /var/log/openldap
chmod 755 /var/log/openldap
chown openldap:openldap /var/log/openldap
touch /var/log/openldap/auditlog.ldif
chmod 755 /var/log/openldap/auditlog.ldif
chown openldap:openldap /var/log/openldap/auditlog.ldif
```
Vérifications
```
ldapsearch -QLLLY EXTERNAL -H ldapi:/// -b "cn=config" "Objectclass=olcModuleList"
ldapsearch -QLLLY EXTERNAL -H ldapi:/// -b "cn=config" "Objectclass=olcAuditLogConfig"
```

## Unique
Cet overlay permet de nous assurer l’unicité des attributs que l’on spécifie.
### /root/ldap/conf/unique_act.ldif
```
dn: cn=module,cn=config
cn: module
objectclass: olcModuleList
objectclass: top
olcModuleLoad: unique.la
olcmodulepath: /usr/lib/ldap
```
### /root/ldap/conf/unique_conf.ldif
```
dn: olcOverlay=unique,olcDatabase={1}mdb,cn=config
objectClass: olcOverlayConfig
objectClass: olcUniqueConfig
olcOverlay: unique
olcUniqueUri: ldap:///ou=people,dc=krhacken,dc=org?uid?sub
olcUniqueUri: ldap:///ou=people,dc=krhacken,dc=org?mail?sub
olcUniqueUri: ldap:///ou=people,dc=krhacken,dc=org?uidNumber?sub
olcUniqueUri: ldap:///ou=groups,dc=krhacken,dc=org?cn?sub
```
Nous demandons ici à ce que les attributs UI, mail et uidNumber dans l’ou people soient uniques. Et que l’attribut cn dans l’ou groups soit lui aussi unique.
On applique les modifications,
```
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f unique_act.ldif
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f unique_conf.ldif
```
Vérifications,
```
ldapsearch -QLLLY EXTERNAL -H ldapi:/// -b "cn=config" "Objectclass=olcModuleList"
ldapsearch -QLLLY EXTERNAL -H ldapi:/// -b "cn=config" "Objectclass=olcUniqueConfig"
```

## Ppolicy
Cet overlay va nous permettre de spécifier une politique de mot de passe.

On va ajouter son schéma dans l’annuaire
```
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/ppolicy.ldif
```
Dans la branche cn=schema, on doit voir le schéma ppolicy,
```
ldapsearch -QLLLY EXTERNAL -H ldapi:/// -b "cn=schema,cn=config" cn
```
### /root/ldap/conf/ppolicy_act.ldif
```
dn: cn=module,cn=config
cn: module
objectclass: olcModuleList
objectclass: top
olcModuleLoad: ppolicy.la
olcmodulepath: /usr/lib/ldap
```
### /root/ldap/conf/ppolicy_conf.ldif
```
dn: olcOverlay=ppolicy,olcDatabase={1}mdb,cn=config
objectClass: olcOverlayConfig
objectClass: olcPpolicyConfig
olcOverlay: ppolicy
olcPPolicyDefault: cn=ppolicy,dc=krhacken,dc=org
olcPPolicyHashCleartext: TRUE
olcPPolicyUseLockout: FALSE
```
Explication,
- olcPPolicyDefault : Indique le DN de configuration utilisé
- olcPPolicyHashCleartext : Indique si les mots de passe doivent être cryptés.
On applique les modifications,
```
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f ppolicy_act.ldif
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f ppolicy_conf.ldif
```
On va maintenant créer la politique par défaut.

### /root/ldap/conf/ppolicy_def.ldif
```
dn: cn=ppolicy,dc=krhacken,dc=org
objectClass: top
objectClass: device
objectClass: pwdPolicy
cn: ppolicy
pwdAllowUserChange: TRUE
pwdAttribute: userPassword
pwdCheckQuality: 1
pwdExpireWarning: 0
pwdFailureCountInterval: 30
pwdGraceAuthNLimit: 5
pwdInHistory: 5
pwdLockout: TRUE
pwdLockoutDuration: 60
pwdMaxAge: 0
pwdMaxFailure: 5
pwdMinAge: 0
pwdMinLength: 5
pwdMustChange: FALSE
pwdSafeModify: FALSE
```
La signification des attributs est :
- pwdAllowUserChange : indique si l’utilisateur peut changer son mot de passe.
- pwdCheckQuality : indique si OpenLDAP renvoie une erreur si le mot de passe n’est pas conforme
- pwdExpireWarning : avertissement d’expiration.
- pwdFailureCountInterval : Intervalle de temps entre deux tentatives infructueuses pour qu’elles soient considérées comme « à la suite ».
- pwdGraceAuthNLimit : période de grâce suite à l’expiration du mot de passe.
- pwdInHistory : nombre de mots de passe dans l’historique.
- pwdLockout : indique si on bloque le compte au bout de X échecs.
- pwdLockoutDuration : durée du blocage du compte (en secondes).
- pwdMaxAge : age maximal du mot de passe (en secondes).
- pwdMaxFailure : nombre d’échecs de saisie du mot de passe maximal (avant blocage).
- pwdMinAge : age minimal du mot de passe (en secondes).
- pwdMinLength : longueur minimale du mot de passe.
- pwdMustChange : indique si l’utilisateur doit changer son mot de passe.
- pwdSafeModify : indique si il faut envoyer l’ancien mot de passe avec le nouveau pour modification.

On applique les modifications,
```
ldapadd -H ldap://localhost -D cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f ppolicy_def.ldif
```
Vérifications
```
ldapsearch -QLLLY EXTERNAL -H ldapi:/// -b "cn=schema,cn=config" cn
ldapsearch -QLLLY EXTERNAL -H ldapi:/// -b "cn=config" "Objectclass=olcPpolicyConfig" -LLL
ldapsearch -QLLLY EXTERNAL -H ldapi:/// -b "dc=krhacken,dc=org" "Objectclass=pwdPolicy"
```

## Mise en place des OU
Les OUs sont des conteneurs qui permettent de ranger les données dans l’annuaire, de les hiérarchiser.

### /root/ldap/conf/OU.ldif
```
dn: ou=people,dc=krhacken,dc=org
ou: people
objectClass: organizationalUnit

dn: ou=group,dc=krhacken,dc=org
ou: group
objectClass: organizationalUnit

dn: ou=system,dc=krhacken,dc=org
ou: system
objectClass: organizationalUnit

dn: ou=krhacken,ou=people,dc=krhacken,dc=org
ou: krhacken
objectClass: organizationalUnit

dn: ou=client,ou=people,dc=krhacken,dc=org
ou: client
objectClass: organizationalUnit

dn: ou=sysgroup,ou=group,dc=krhacken,dc=org
ou: sysgroup
objectClass: organizationalUnit

dn: ou=workgroup,ou=group,dc=krhacken,dc=org
ou: workgroup
objectClass: organizationalUnit
```
On rajoute les OU au ldap
```
ldapadd -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f OU.ldif
```

Explication rapide
- krhacken contenant tout les utilisateurs krhacken
- people contient tout les utilisateurs (krhacken ou non)


## Utilisateurs
### /root/ldap/conf/User_PSEUDO.ldif
```
dn: uid=PSEUDO,ou=krhacken,ou=people,dc=krhacken,dc=org
objectclass: person
objectclass: organizationalPerson
objectclass: inetOrgPerson
uid: niko
sn: niko
givenName: Nicolas
cn: Nicolas
displayName: Nicolas
userPassword: password
mail: mail@spam.com
title: Admin
initials: N
```
On ajoute l'utilisateur
```
ldapadd -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f User_PSEUDO.ldif
```
Commande pour la connexion à un utilisateur
```
ldapsearch -xLLLH ldap://localhost -D uid=PSEUDO,ou=krhacken,ou=people,dc=krhacken,dc=org -W -b "dc=krhacken,dc=org" "uid=PSEUDO"
```

## Groupes

Il existe deux types de groupes : les posixgroup et les groupofnames.
Les posixgroup sont similaires au groupes Unix, et les groupofnames ressemblent plus à des groupes AD.
Pour faire simple, l’avantage des groupofnames est qu’avec un filtre sur un utilisateur, on peut connaitre ses groupes (avec l’overlay memberof). Chose impossible avec les posixgroups.


### /root/ldap/conf/Group.ldif
```
dn: cn=cloud,ou=sysgroup,ou=group,dc=krhacken,dc=org
cn: cloud
description: Cloud
objectClass: groupOfNames
member: cn=admin,dc=krhacken,dc=org

dn: cn=krhacken,ou=workgroup,ou=group,dc=krhacken,dc=org
cn: krhacken
description: krhacken
objectClass: groupOfNames
member: cn=admin,dc=krhacken,dc=org
```
On ajoute les
```
ldapadd -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f Group.ldif
```
On peu tester memberof pour voir si admin est bien dans les bon groupes
```
ldapsearch -xLLLH ldap://localhost -D cn=admin,dc=krhacken,dc=org -y /root/pwdldap -b "dc=krhacken,dc=org" "cn=admin" memberof
```

Pour rajouter un utilisateur dans un groupe avec un fichier ldif (addusertogroup.ldif)
```
dn: cn=cloud,ou=sysgroup,ou=group,dc=krhacken,dc=org
changetype: modify
add: member
member: uid=niko,ou=krhacken,ou=people,dc=krhacken,dc=org
```
On ajoute l'utilisateur avec
```
ldapmodify -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f addusertogroup.ldif
```

# Sécurisation de l'annuaire

## Comptes avec permissions réduite
Nous allons créer deux compte systèmes.
- Un viewer qui aura uniquement les droits en lecture de l'arbre
- Un Writer qui lui aura les droits en écriture

### /root/ldap/conf/viewer.ldif
```
dn: cn=viewer,ou=system,dc=krhacken,dc=org
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: viewer
description: LDAP viewer
userPassword: passview
```

### /root/ldap/conf/writer.ldif
```
dn: cn=writer,ou=system,dc=krhacken,dc=org
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: writer
description: LDAP Writer
userPassword: passwrite
```
Ajout des utilisateurs,
```
ldapadd -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f viewer.ldif
ldapadd -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f writer.ldif
```

On autorise la lecture de l'arbre uniquement au utilisateur authentifié en modifiant une ACL
### /root/ldap/conf/acl.ldif
```
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcAccess
olcAccess: to attrs=userPassword by self write by anonymous auth by dn="cn=writer,ou=system,dc=krhacken,dc=org" write by dn="cn=viewer,ou=system,dc=krhacken,dc=org" read by dn="cn=admin,dc=krhacken,dc=org" write by * none
olcAccess: to dn.base="dc=krhacken,dc=org" by users read
olcAccess: to * by self write by dn="cn=admin,dc=krhacken,dc=org" write by * read by anonymous none
```
On modife l'ACL
```
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f acl.ldif
```

## Forcer SSL
Si c'est le cas on peut maintenant forcer la connexion SSL
### /root/ldap/conf/forcetls.ldif
```
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcSecurity
olcSecurity: tls=1
```
Ajout des modifications et application
```
ldapmodify -H ldapi:// -Y EXTERNAL -f forcetls.ldif
systemctl restart slapd
```
Vérifions si TLS est obligatoire,
Cette commande doit retourner une erreur
```
ldapsearch -H ldap:// -x -b "dc=krhacken,dc=org" -LLL dn
```
et celle la doit aboutir
```
ldapsearch -H ldap:// -x -b "dc=example,dc=com" -LLL -Z dn
```

Voilà pour la mise en place de base du LDAP cependant il faut configuré chaque client pour se connecter au serveur avec STARTTLS.

NB : Il manque la réplication que nous mettrons en place plus tard.
