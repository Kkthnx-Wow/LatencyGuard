local _, ns = ...
if GetLocale() ~= "frFR" then return end
local L = ns.L

L["Landing Desc Text"] = "La %s est un paramètre caché du jeu qui contrôle le temps de tampon pour votre prochaine capacité.\n\n%s surveille votre ping mondial en temps réel et ajuste automatiquement cette fenêtre pour que votre gameplay soit réactif sans perdre la possibilité de mettre des sorts en file d'attente. Une latence élevée nécessite une fenêtre de file d'attente plus large, tandis qu'une latence faible bénéficie d'une fenêtre plus étroite.\n\nDéveloppez le menu LatencyGuard à gauche et ouvrez Général pour configurer la tolérance et les retours."

L["Automate Spell Queue Window"] = "Automatiser la fenêtre de file d'attente des sorts"
L["Automate Spell Queue Window Tooltip"] = "Si coché, l'addon gérera tous les ajustements de la file d'attente des sorts.\n\n|cffff0000Remarque :|r La désactivation arrête immédiatement toutes les mises à jour."
L["Enable Chat Feedback"] = "Activer les retours dans le chat"
L["Enable Chat Feedback Tooltip"] = "Affiche un message dans votre journal de discussion chaque fois que la fenêtre de file d'attente des sorts est mise à jour avec une nouvelle valeur cible."
L["Tolerance Buffer"] = "Tampon de tolérance"
L["Tolerance Buffer Tooltip"] = "Cette valeur est ajoutée à votre ping mondial actuel.\n\nDes valeurs élevées (200+) sont plus sûres pour les connexions à forte latence.\nDes valeurs faibles (50-100) sont meilleures pour le jeu compétitif de haut niveau."

L["Init Message"] = "v%s initialisé. Utilisez |cFFFFD700/lg|r pour configurer."
L["Update Message"] = "SQW défini sur |cFFFFD700%dms|r (Ping : %d + Tampon : %d)"
