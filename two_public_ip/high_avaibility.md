# Choix technique pour la haute disponibilité.
Chaque service aura un container attitré qui aura lui même une node par défaut. Dans le cas ou se service est critique comme pour le site du club, le serveur mail... si la node par défaut crash le container sera automatiquement migré sur l'autre node et l'accès sera garanti grâce à un reverse proxy avec failover.

Par défaut toute les 

Si un service critique est sur Alpha et que Alpha crash le container du service passera sur beta et les reverse proxy s'adapterons grâce à un système de failover.