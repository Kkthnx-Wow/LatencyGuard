local ADDON_NAME, NS = ...
if GetLocale() ~= "frFR" then return end
local L = NS.L

L["Config_Author"] = "Créé par %s%s|r"
L["Config_DescTitle"] = "Pourquoi cet addon existe-t-il ?"
L["Config_DescText"] = "La %sFenêtre de file d'attente des sorts|r est un paramètre caché du jeu qui contrôle le 'temps de tampon' pour votre prochaine capacité.\n\n%sLatencyGuard|r surveille votre ping mondial en temps réel et ajuste automatiquement cette fenêtre pour que votre gameplay soit réactif sans perdre la possibilité de mettre des sorts en file d'attente. Une latence élevée nécessite une fenêtre de file d'attente plus large, tandis qu'une latence faible bénéficie d'une fenêtre plus étroite.\n\nPour configurer le comportement et la tolérance, veuillez développer le menu " .. ADDON_NAME .. " à gauche et sélectionner le panneau Options."

L["Config_OptionsCategory"] = "Options"
L["Config_Enable"] = "Automatiser la fenêtre de file d'attente des sorts"
L["Config_EnableTooltip"] = "Si coché, l'addon gérera tous les ajustements de la file d'attente des sorts.\n\n%sRemarque :|r La désactivation arrête immédiatement toutes les mises à jour."
L["Config_Verbose"] = "Activer les retours dans le chat"
L["Config_VerboseTooltip"] = "Affiche un message dans votre journal de discussion chaque fois que la fenêtre de file d'attente des sorts est mise à jour avec une nouvelle valeur cible."
L["Config_Tolerance"] = "Tampon de tolérance"
L["Config_ToleranceTooltip"] = "Cette valeur est ajoutée à votre ping mondial actuel.\n\nDes valeurs élevées (200+) sont plus sûres pour les connexions à forte latence.\nDes valeurs faibles (50-100) sont meilleures pour le jeu compétitif de haut niveau."

L["Core_InitMessage"] = "v%s Initialisé. Utilisez |cFFFFD700/lg|r pour configurer."
L["Logic_UpdateMessage"] = "SQW défini sur |cFFFFD700%dms|r (Ping : %d + Tampon : %d)"
