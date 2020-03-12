# LDAP

Nous allons ici mettre en place le serveur LDAP qui sera répliqué sur les deux nodes. Tout les services utiliseront LDAP pour l'authentification des utilisateurs.
A noté que pour des questions pratique nous n'allons pas utilisé Fusion Directory, il faudra donc créer un schéma pour chaque service et modifier les utilisateur avec ldapadd et ldapmodify.
Pour la sécurisation de LDAP nous allons utiliser LDAP avec STARTTLS.

## Installation slapd
On commence par installer le serveur ldap.
```
apt-get update
apt-get install -y slapd ldap-utils
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
Do you want the database to be removed when slapd is purged? Yes
Move old database? Yes
```

## Centralisation des fichiers de configuration
Nous allons créer un répertoire /root/ldap/conf qui va centraliser tous nos fichiers de configuration
```
mkdir -p /root/ldap/conf/
```

## Stockage du mot de passe administrateur
Mettez le mot de passe d'administration de l'annuaire LDAP.
```
echo -n "mdpadmin" > /root/pwdldap
chmod 600 /root/pwdldap
```

## Mise en place SSL
```
apt-get install -y gnutls-bin ssl-cert
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
### /root/ldap/conf/addCAcerts.ldif
```
dn: cn=config
changetype: modify
replace: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/ssl/certs/ca_server.pem
```
Application des modification et redémarrage de slapd
```
ldapmodify -H ldapi:// -Y EXTERNAL -f /root/ldap/conf/addCAcerts.ldif
service slapd force-reload
```

### /root/ldap/conf/addcerts.ldif
```
dn: cn=config
changetype: modify
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/ssl/private/ldap_server.key
-
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ssl/certs/ldap_server.pem
```
Application des modification et redémarrage de slapd
```
ldapmodify -H ldapi:// -Y EXTERNAL -f /root/ldap/conf/addcerts.ldif
service slapd force-reload
```

Le retour de la commande
```
ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config | grep olcTLS
```
doit contenir les informations ci-dessous, cela confirme l'installation des certificats.
```
olcTLSCACertificateFile: /etc/ssl/certs/ca_server.pem
olcTLSCertificateFile: /etc/ssl/certs/ldap_server.pem
olcTLSCertificateKeyFile: /etc/ssl/private/ldap_server.key
```

## Sur le serveur
```
cp /etc/ssl/certs/ca_server.pem /etc/ldap/ca_certs.pem
```

Il faut ensuite ajuster la configuration en modifiant les paramètres de connexions
### /etc/ldap/ldap.conf
```
BASE dc=krhacken,dc=org
URI ldap://alpha.ldap.krhacken.org/
TLS_CACERT /etc/ldap/ca_certs.pem
```
On redémarre le serveur slapd.
```
service slapd force-reload
```

### Vérification
La commande `ldapsearch -xLLL -H ldap://alpha.ldap.krhacken.org -ZZ` doit retourner des informations sur l'arbre.


## Droits d'accès pour la configuration
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
Les overlays sont des fonctionnalités supplémentaires.

Voici l'ensemble des overlays que nous allons utiliser

## MemberOf
L’overlay memberof permet de savoir dans quels groupes se trouve un utilisateur.
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

## refint
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
Cet overlay audite chaque modification faites sur l’annuaire, les logs seront dans `/var/log/openldap/audit.ldif`

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


## Structuration de l'annuaire LDAP.

Maintenant que la base de l'annuaire est en place nous allons structurer l'intérieur de l'annuaire.

Avant ça nous allons décrire la structure comme un arbre.

### Le tronc (le DC)
- Le tronc de cet arbre : `dc=krhacken,dc=org`, c'est ce que l'on appelle le DN de base.

### Les grosses branches (les OU)
- Une grosse branche pour les utilisateurs : `ou=people,dc=krhacken,dc=org`.
- Une sous branche des utilisateurs pour les membres krhacken : `ou=krhacken,ou=people,dc=krhacken,dc=org`.
- Une grosse branche pour les groupes : `ou=group,dc=krhacken,dc=org`.
- Une sous branche des groupes pour les groupes krhacken : `ou=krhacken,ou=group,dc=krhacken,dc=org`.

### Les petites branches (les CN)
- Une petite branche pour le groupe des adminsys : `cn=adminsys,ou=krhacken,ou=group,dc=krhacken,dc=org`
- Une petite branche pour le groupe des webmestres : `cn=webmestre,ou=krhacken,ou=group,dc=krhacken,dc=org`
- Une petite branche pour le groupe des membres krhacken : `cn=krhacken,ou=krhacken,ou=group,dc=krhacken,dc=org`
- Une petite branche pour le groupe des membres extérieur :
`cn=ext,ou=krhacken,ou=group,dc=krhacken,dc=org`

## Mise en place des grosses branches

Les OUs sont des conteneurs qui permettent de ranger les données dans l’annuaire et de les hiérarchiser.

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

dn: ou=krhacken,ou=group,dc=krhacken,dc=org
ou: krhacken
objectClass: organizationalUnit
```
On rajoute les OU au ldap
```
ldapadd -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f OU.ldif
```

## Mise en place des petites branches

Il existe deux types de groupes : les posixgroup et les groupofnames.

Les posixgroup sont similaires au groupes Unix.

Pour faire simple, l’avantage des groupofnames est qu’avec un filtre sur un utilisateur, on peut connaitre ses groupes (avec l’overlay memberof). Chose impossible avec les posixgroups. On va donc utiliser des groupofnames.

### /root/ldap/conf/group.ldif
```
dn: cn=adminsys,ou=krhacken,ou=group,dc=krhacken,dc=org
cn: adminsys
description: AdminSys Kr[HACK]en
objectClass: groupOfNames
member: cn=admin,dc=krhacken,dc=org

dn: cn=webmestre,ou=krhacken,ou=group,dc=krhacken,dc=org
cn: webmestre
description: Webmestre Kr[HACK]en
objectClass: groupOfNames
member: cn=admin,dc=krhacken,dc=org

dn: cn=krhacken,ou=krhacken,ou=group,dc=krhacken,dc=org
cn: krhacken
description: Membres du Kr[HACK]en
objectClass: groupOfNames
member: cn=admin,dc=krhacken,dc=org

dn: cn=ext,ou=krhacken,ou=group,dc=krhacken,dc=org
cn: ext
description: Personnes extérieure au Kr[HACK]en
objectClass: groupOfNames
member: cn=admin,dc=krhacken,dc=org
```
On ajoute les groupes
```
ldapadd -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f group.ldif
```
On peu utiliser **memberof** pour voir dans quels groupes est l'utilisateur admin
```
ldapsearch -xLLLH ldap://localhost -D cn=admin,dc=krhacken,dc=org -y /root/pwdldap -b "dc=krhacken,dc=org" "cn=admin" memberof
```

## Création d'un compte root

Cet utilisateur aura tout les droits sur l'annuaire, on ne lui donnera pas accès aux services son rôle est seulement d'administrer l'annuaire LDAP.

### /root/ldap/conf/root.ldif
```
dn: uid=root,ou=krhacken,ou=people,dc=krhacken,dc=org
objectclass: person
objectclass: organizationalPerson
objectclass: inetOrgPerson
uid: root
cn: root
sn: root
displayName: root
userPassword: PASSWORD
mail: root@krhacken.org
```
On ajoute l'utilisateur
```
ldapadd -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f root.ldif
```

Ajout de compte root au groupe adminsys pour qu'il est accès à l'interface d'administration

### /root/ldap/conf/adminsysaddroot.ldif
```
dn: cn=adminsys,ou=krhacken,ou=group,dc=krhacken,dc=org
changetype: modify
add: member
member: uid=root,ou=krhacken,ou=people,dc=krhacken,dc=org
```
```
ldapadd -cxWD cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f adminsysaddroot.ldif
```

Commande pour afficher les informations de l'utilisateur root
```
ldapsearch -xLLLH ldap://localhost -D uid=root,ou=krhacken,ou=people,dc=krhacken,dc=org -W -b "dc=krhacken,dc=org" "uid=root"
```

# Sécurisation de l'annuaire

## Comptes avec permissions réduite
Nous allons créer deux compte systèmes.
- Un viewer qui aura uniquement les droits en lecture de l'arbre
- Un Writer qui lui aura les droits en écriture

### /root/ldap/conf/viewer.ldif
```
dn: cn=viewer,ou=system,dc=krhacken,dc=org
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: viewer
description: LDAP Viewer
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
### /root/ldap/conf/acl.ldif
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

### Vérification
La commande
```
ldapsearch -xLLL -H ldap://localhost -D cn=viewer,ou=system,dc=krhacken,dc=org -w passview -b "dc=krhacken,dc=org"
```
doit retourner une erreur, si on ajout -ZZ à la fin ça doit fonctionner

Voilà pour la mise en place de base du LDAP cependant il faut configuré chaque client pour se connecter au serveur avec STARTTLS.

## Réplication de l'annuaire LDAP

Nous allons mettre en place une réplication Master/Master. L’idée est de faire en sorte que n’importe lequel de nos serveurs LDAP soit capable à la fois de lire les données, mais également de les modifier. De plus, nous allons mettre en place une réplication, à la fois sur l’arbre de données dc=krhacken,dc=org mais également sur l’arbre de configuration cn=config.

Vous avez déjà fait toute la configuration du premier conteneur LDAP (CT107). Pour gagner du temps clonez ce conteneur vers le conteneur 108 sur l'autre node.

Avant le démarrage il vous faudra reconfigurer les interfaces comme suis :
- eth0 : vmbr1 / VLAN: 30 / IP: 10.0.2.2/24 / GW: 10.0.2.254
- eth1 : vmbr2 / VLAN: 100 / IP: 10.1.0.108/24 / GW: 10.1.0.254

Nous avons désormais deux conteneurs LDAP identique, ce qui ne fonctionnera pas dans l'état.

Il faut donc ajuster la configuration en modifiant les paramètres de connexions


### /etc/ldap/ldap.conf
Sur Alpha :
```
BASE dc=krhacken,dc=org
URI ldap://alpha.ldap.krhacken.org/
URI ldap://vip.ldap.krhacken.org/
TLS_CACERT /etc/ldap/ca_certs.pem
```
Sur Beta :
```
BASE dc=krhacken,dc=org
URI ldap://beta.ldap.krhacken.org/
URI ldap://vip.ldap.krhacken.org/
TLS_CACERT /etc/ldap/ca_certs.pem
```

On redémarre les serveurs slapd.
```
service slapd force-reload
```

## Réplication de l'arbre de configuration

### 01-syncprov_act.ldif
```
dn: cn=module,cn=config
cn: module
objectclass: olcModuleList
objectclass: top
olcmoduleload: syncprov.la
olcmodulepath: /usr/lib/ldap
```
```
ldapadd -Y EXTERNAL -H ldapi:/// -f 01-syncprov_act.ldif
```

Vérifications :
```
ldapsearch -LLLY external -H ldapi:/// -b "cn=config" "objectClass=olcModuleList"
ldapsearch -LLLY external -H ldapi:/// -b "cn=module{6},cn=config"
```

### 02-serverid.ldif
X vaut 1 sur Alpha 2 sur Beta.
```
dn: cn=config
changetype: modify
add: olcServerID
olcServerID: X
```
```
ldapmodify -Y EXTERNAL -H ldapi:/// -f 02-serverid.ldif
```
Vérification :
```
ldapsearch -LLLY external -H ldapi:/// -b "cn=config" "objectClass=olcGlobal" olcServerID
```

### 03-replica_account.ldif
```
dn: cn=replica,ou=system,dc=krhacken,dc=org
userPassword: PASS
cn: replica
objectclass: top
objectclass: person
sn: replica
```
```
ldapadd -x -H ldap://localhost -D cn=admin,dc=krhacken,dc=org -y /root/pwdldap -f 03-replica_account.ldif
```

### 04-droit_conf.ldif
Gestion des droits du CN *replica*
```
dn: olcDatabase={0}config,cn=config
changeType: modify
add: olcAccess
olcAccess: to * by dn.exact=cn=replica,ou=system,dc=krhacken,dc=org manage by * break
```
```
ldapmodify -Y EXTERNAL -H ldapi:/// -f 04-droit_conf.ldif
```

### 05-syncprov_conf_conf.ldif
```
dn: olcOverlay=syncprov,olcDatabase={0}config,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcSyncProvConfig
olcOverlay: syncprov
```
```
ldapmodify -Y EXTERNAL -H ldapi:/// -f 05-syncprov_conf_conf.ldif
```

### 06-repl_conf_conf.ldif
```
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcSyncRepl
olcSyncRepl: rid=01 provider=ldap://alpha.ldap.krhacken.org
  binddn="cn=replica,ou=system,dc=krhacken,dc=org" bindmethod=simple
  credentials=password searchbase="cn=config"
  type=refreshAndPersist retry="5 5 300 5" timeout=1
olcSyncRepl: rid=02 provider=ldap://beta.ldap.krhacken.org
  binddn="cn=replica,ou=system,dc=krhacken,dc=org" bindmethod=simple
  credentials=password searchbase="cn=config"
  type=refreshAndPersist retry="5 5 300 5" timeout=1
-
add: olcMirrorMode
olcMirrorMode: TRUE
```
```
ldapmodify -Y EXTERNAL -H ldapi:/// -f 06-repl_conf_conf.ldif
```
Vérification :
```
ldapsearch -QLLLY external -H ldapi:/// -b "cn=config" "olcDatabase={0}config" olcSyncRepl
```

A partir d'ici l'arbre de configuration cn=config est synchronisé entre les deux conteneurs LDAP. Pour le reste de la configuration il faut faire les manipulations que sur un des deux conteneurs LDAP

## Réplication de l'arbre de données
Nous allons ici mettre en place la synchronisation automatique de l'arbre de données entre les deux conteneurs LDAP.

### 07-acl_replica.ldif
```
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcAccess
olcAccess: to attrs=userPassword by self write by anonymous auth by dn="cn=writer,ou=system,dc=krhacken,dc=org" write by dn="cn=viewer,ou=system,dc=krhacken,dc=org" read by dn="cn=admin,dc=krhacken,dc=org" write by dn.exact="cn=replica,ou=system,dc=krhacken,dc=org" read by * none
olcAccess: to dn.subtree="dc=krhacken,dc=org" by users read by * none
olcAccess: to * by self write by dn="cn=admin,dc=krhacken,dc=org" write by * read by anonymous none
```
```
ldapmodify -Y EXTERNAL -H ldapi:/// -f 07-acl_replica.ldif
```
Vérification :
```
ldapsearch -QLLLY external -H ldapi:/// -b "cn=config" "olcDatabase={1}mdb" olcAccess
```

### 08-limit.ldif
```
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcLimits
olcLimits: dn.exact="cn=replica,ou=system,dc=krhacken,dc=org" time.soft=unlimited time.hard=unlimited size.soft=unlimited size.hard=unlimited
```
```
ldapmodify -Y EXTERNAL -H ldapi:/// -f 08-limit.ldif
```

### 09-index.ldif
```
dn:olcDatabase={1}mdb,cn=config
changetype: modify
add: olcDbIndex
olcDbIndex: entryCSN,entryUUID eq
```
```
ldapmodify -Y EXTERNAL -H ldapi:/// -f 09-index.ldif
```

### 10-syncprov_conf_data.ldif
```
dn: olcOverlay=syncprov,olcDatabase={1}mdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcSyncProvConfig
olcOverlay: syncprov
```
```
ldapmodify -Y EXTERNAL -H ldapi:/// -f 10-syncprov_conf_data.ldif
```

### 11-repl_conf_data.ldif
```
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcSyncRepl
olcSyncRepl: rid=01 provider=ldap://alpha.ldap.krhacken.org
  binddn="cn=replica,ou=system,dc=krhacken,dc=org"
  bindmethod=simple credentials=password
  searchbase="dc=krhacken,dc=org"
  type=refreshAndPersist retry="5 5 300 5" timeout=1
olcSyncRepl: rid=02 provider=ldap://beta.ldap.krhacken.org
  binddn="cn=replica,ou=system,dc=krhacken,dc=org"
  bindmethod=simple credentials=password
  searchbase="dc=krhacken,dc=org"
  type=refreshAndPersist retry="5 5 300 5" timeout=1
-
add: olcMirrorMode
olcMirrorMode: TRUE
```
```
ldapmodify -Y EXTERNAL -H ldapi:/// -f 11-repl_conf_data.ldif
```

## Configuration des ServerID
A cause de la synchronisation de l'arbre de configuration les ServerID sont les mêmes.

Il faut stoper **slapd** sur les deux conteneurs avec `systemctl stop slapd`

Puis éditer `/etc/ldap/slapd.d/cn\=config.ldif` de la manière suivante
- Alpha -> `olcServerID: 1`
- Beta -> `olcServerID: 2`

On peut maintenant relancer slapd sur les deux conterneurs avec `systemctl start slapd`

Maintenant la commande ci-dessous donne un ID différent selon le conteneur.
```
ldapsearch -x -LLL -H ldap://localhost -D cn=admin,dc=krhacken,dc=org -w passadmin -b cn=config "objectClass=olcGlobal"
```

## Accès via une IP virtuelle
Comme pour HAProxy nous allons utiliser keepalived pour avoir une IP virtuelle que se déplace entre les deux conteneurs en fonction de la disponibilité de l'annuaire LDAP.

```
apt-get install -y keepalived
```

### Script pour vérifier l'état des conteneurs LDAP

Créer, sur les deux serveurs, le script `/etc/keepalived/test_ldap.sh`

Il faut spécifier le mot de passe du compte viewer.
```
#!/bin/bash

ldapsearch -x -H ldap://$1 -D cn=viewer,ou=system,dc=krhacken,dc=org -w passview -b dc=krhacken,dc=org -l 3 > /dev/null 2>&1
ldapresponse=$?

if [ "$ldapresponse" -gt 0 ]; then
    echo "down"
    exit 1
else
    echo "up"
fi

exit 0
```
```
chmod /etc/keepalived/test_ldap.sh +x
```

## Configuration de keepalived

### Configuration sur Alpha
#### /etc/keepalived/keepalived.conf
```
vrrp_script check_server_health {
    script "/etc/keepalived/test_ldap.sh 10.0.2.1" (mettre l'ip réel de votre serveur)
    interval 2
    fall 2
    rise 2
}
vrrp_instance VI_LDAP {
    interface eth0
    state MASTER
    virtual_router_id 50
    priority 101 # 101 on master, 100 on backup
    virtual_ipaddress {
        10.0.2.3
    }
    track_script {
        check_server_health
    }
}
```
```
systemctl restart keepalived
```
    authentication {
        auth_type PASS
        auth_pass MON_MOT_DE_PASSE_SECRET
    }

### Configuration sur Beta
#### /etc/keepalived/keepalived.conf
```
vrrp_script check_server_health {
    script "/etc/keepalived/test_ldap.sh 10.0.2.2" (mettre l'ip réel de votre serveur)
    interval 2
    fall 2
    rise 2
}
vrrp_instance VI_LDAP {
    interface eth0
    state MASTER
    virtual_router_id 50
    priority 101 # 101 on master, 100 on backup
    virtual_ipaddress {
        10.0.2.3
    }
    track_script {
        check_server_health
    }
}
```
```
systemctl restart keepalived
```
Un des deux conteneur est maintenant accessible à l'adresse 10.0.2.3. Les requêtes se feront sur cette adresse.


## Configuration des futurs client LDAP
Sur tout les futurs client LDAP il faudra activer la connexion SSL.
Il faut commencer par copier le certificat de la CA (ca_server.pem qu'il faudra copier via scp)
```
cat ca_server.pem | tee -a /etc/ldap/ca_certs.pem
```
Il faut ensuite modifier la configuration en modifiant la ligne suivante
### /etc/ldap/ldap.conf
```
TLS_CACERT /etc/ldap/ca_certs.pem
```

La commande,
```
ldapsearch -xLLL -H ldap://vip.ldap.krhacken.org -D cn=viewer,ou=system,dc=krhacken,dc=org -w passview -b "dc=krhacken,dc=org" -ZZ
```
doit retourner des informations sur l'arbre.
