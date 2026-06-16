local _, ns = ...
if GetLocale() ~= "itIT" then return end
local L = ns.L

L["Landing Desc Text"] = "La %s è un'impostazione di gioco nascosta che controlla il tempo di buffer per la tua prossima abilità.\n\n%s monitora il tuo ping mondiale in tempo reale e regola automaticamente questa finestra in modo che il tuo gameplay risulti reattivo senza perdere la capacità di mettere in coda efficacemente gli incantesimi. Un'alta latenza richiede una finestra di coda più ampia, mentre una bassa latenza beneficia di una finestra più stretta.\n\nEspandi il menu LatencyGuard a sinistra e apri Generale per configurare tolleranza e feedback."

L["Automate Spell Queue Window"] = "Automatizza la Finestra di Coda delle Magie"
L["Automate Spell Queue Window Tooltip"] = "Se selezionato, l'addon gestirà tutte le regolazioni della coda degli incantesimi.\n\n|cffff0000Nota:|r Disabilitando questo si interrompono immediatamente tutti gli aggiornamenti."
L["Enable Chat Feedback"] = "Abilita il feedback in chat"
L["Enable Chat Feedback Tooltip"] = "Stampa un messaggio nel registro della chat ogni volta che la finestra della coda degli incantesimi viene aggiornata con un nuovo valore di destinazione."
L["Tolerance Buffer"] = "Buffer di tolleranza"
L["Tolerance Buffer Tooltip"] = "Questo valore viene aggiunto al tuo attuale ping mondiale.\n\nValori elevati (200+) sono più sicuri per le connessioni ad alta latenza.\nValori bassi (50-100) sono migliori per il gioco competitivo ad alto livello."

L["Init Message"] = "v%s inizializzato. Usa |cFFFFD700/lg|r per configurare."
L["Update Message"] = "SQW impostato su |cFFFFD700%dms|r (Ping: %d + Buffer: %d)"
