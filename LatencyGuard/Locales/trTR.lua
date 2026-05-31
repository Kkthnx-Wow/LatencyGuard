local ADDON_NAME, NS = ...
if GetLocale() ~= "trTR" then return end
local L = NS.L

L["Config_Author"] = "%s%s|r tarafından oluşturuldu"
L["Config_DescTitle"] = "Bu eklenti neden var?"
L["Config_DescText"] = "%sBüyü Kuyruğu Penceresi|r, bir sonraki yeteneğiniz için 'arabellek süresini' kontrol eden gizli bir oyun ayarıdır.\n\n%sLatencyGuard|r, gerçek zamanlı dünya ping'inizi izler ve büyüleri etkili bir şekilde kuyruğa alma yeteneğinizi kaybetmeden oyununuzun hızlı hissettirmesi için bu pencereyi otomatik olarak ayarlar. Yüksek gecikme, daha geniş bir kuyruk penceresi gerektirirken, düşük gecikme daha dar bir pencereden yararlanır.\n\nDavranışı ve toleransı yapılandırmak için lütfen soldaki " .. ADDON_NAME .. " menüsünü genişletin ve Seçenekler panelini seçin."

L["Config_OptionsCategory"] = "Seçenekler"
L["Config_Enable"] = "Büyü Kuyruğu Penceresini Otomatikleştir"
L["Config_EnableTooltip"] = "İşaretlenirse, eklenti tüm Büyü Kuyruğu ayarlamalarını halleder.\n\n%sNot:|r Bunu devre dışı bırakmak, tüm güncellemeleri anında durdurur."
L["Config_Verbose"] = "Sohbet Geri Bildirimini Etkinleştir"
L["Config_VerboseTooltip"] = "Büyü Kuyruğu Penceresi yeni bir hedef değerle güncellendiğinde sohbet günlüğünüze bir mesaj yazdırır."
L["Config_Tolerance"] = "Tolerans Arabelleği"
L["Config_ToleranceTooltip"] = "Bu değer mevcut dünya ping'inize eklenir.\n\nYüksek değerler (200+), yüksek gecikmeli bağlantılar için daha güvenlidir.\nDüşük değerler (50-100), üst düzey rekabetçi oyunlar için daha iyidir."

L["Core_InitMessage"] = "v%s Başlatıldı. Yapılandırmak için |cFFFFD700/lg|r kullanın."
L["Logic_UpdateMessage"] = "SQW |cFFFFD700%dms|r olarak ayarlandı (Ping: %d + Arabellek: %d)"
