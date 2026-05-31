local ADDON_NAME, NS = ...
if GetLocale() ~= "itIT" then return end
local L = NS.L

L["Config_Author"] = "Creato da %s%s|r"
L["Config_DescTitle"] = "Perché esiste questo addon?"
L["Config_DescText"] = "La %sFinestra di Coda delle Magie|r è un'impostazione di gioco nascosta che controlla il 'tempo di buffer' per la tua prossima abilità.\n\n%sLatencyGuard|r monitora il tuo ping mondiale in tempo reale e regola automaticamente questa finestra in modo che il tuo gameplay risulti reattivo senza perdere la capacità di mettere in coda efficacemente gli incantesimi. Un'alta latenza richiede una finestra di coda più ampia, mentre una bassa latenza beneficia di una finestra più stretta.\n\nPer configurare il comportamento e la tolleranza, espandi il menu " .. ADDON_NAME .. " a sinistra e seleziona il pannello Opzioni."

L["Config_OptionsCategory"] = "Opzioni"
L["Config_Enable"] = "Automatizza la Finestra di Coda delle Magie"
L["Config_EnableTooltip"] = "Se selezionato, l'addon gestirà tutte le regolazioni della coda degli incantesimi.\n\n%sNota:|r Disabilitando questo si interrompono immediatamente tutti gli aggiornamenti."
L["Config_Verbose"] = "Abilita il feedback in chat"
L["Config_VerboseTooltip"] = "Stampa un messaggio nel registro della chat ogni volta che la finestra della coda degli incantesimi viene aggiornata con un nuovo valore di destinazione."
L["Config_Tolerance"] = "Buffer di tolleranza"
L["Config_ToleranceTooltip"] = "Questo valore viene aggiunto al tuo attuale ping mondiale.\n\nValori elevati (200+) sono più sicuri per le connessioni ad alta latenza.\nValori bassi (50-100) sono migliori per il gioco competitivo ad alto livello."

L["Core_InitMessage"] = "v%s Inizializzato. Usa |cFFFFD700/lg|r per configurare."
L["Logic_UpdateMessage"] = "SQW impostato su |cFFFFD700%dms|r (Ping: %d + Buffer: %d)"
