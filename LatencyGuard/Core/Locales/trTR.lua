local _, ns = ...
if GetLocale() ~= "trTR" then return end
local L = ns.L

L["Landing Desc Text"] = "%s, bir sonraki yeteneğiniz için arabellek süresini kontrol eden gizli bir oyun ayarıdır.\n\n%s, gerçek zamanlı dünya ping'inizi izler ve büyüleri etkili bir şekilde kuyruğa alma yeteneğinizi kaybetmeden oyununuzun hızlı hissettirmesi için bu pencereyi otomatik olarak ayarlar. Yüksek gecikme, daha geniş bir kuyruk penceresi gerektirirken, düşük gecikme daha dar bir pencereden yararlanır.\n\nSoldaki LatencyGuard menüsünü genişletin ve tolerans ile geri bildirimi yapılandırmak için Genel'i açın."

L["Automate Spell Queue Window"] = "Büyü Kuyruğu Penceresini Otomatikleştir"
L["Automate Spell Queue Window Tooltip"] = "İşaretlenirse, eklenti tüm Büyü Kuyruğu ayarlamalarını halleder.\n\n|cffff0000Not:|r Bunu devre dışı bırakmak, tüm güncellemeleri anında durdurur."
L["Enable Chat Feedback"] = "Sohbet Geri Bildirimini Etkinleştir"
L["Enable Chat Feedback Tooltip"] = "Büyü Kuyruğu Penceresi yeni bir hedef değerle güncellendiğinde sohbet günlüğünüze bir mesaj yazdırır."
L["Tolerance Buffer"] = "Tolerans Arabelleği"
L["Tolerance Buffer Tooltip"] = "Bu değer mevcut dünya ping'inize eklenir.\n\nYüksek değerler (200+) yüksek gecikmeli bağlantılar için daha güvenlidir.\nDüşük değerler (50-100) üst düzey rekabetçi oyunlar için daha iyidir."

L["Init Message"] = "v%s başlatıldı. Yapılandırmak için %s kullanın."
L["Update Message"] = "SQW |cFFFFD700%dms|r olarak ayarlandı (Ping: %d + Arabellek: %d)"
