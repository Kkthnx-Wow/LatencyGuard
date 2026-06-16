local _, ns = ...
if GetLocale() ~= "koKR" then return end
local L = ns.L

L["Landing Desc Text"] = "%s은(는) 다음 능력에 대한 버퍼 시간을 제어하는 숨겨진 게임 설정입니다.\n\n%s는 실시간 세계 지연 시간을 모니터링하고 이 창을 자동으로 조정하여 주문을 효과적으로 대기열에 넣는 능력을 잃지 않으면서도 게임 플레이가 빠릿빠릿하게 느껴지도록 합니다. 지연 시간이 높을수록 대기열 창이 넓어야 하며, 지연 시간이 낮을수록 창이 좁은 것이 유리합니다.\n\n왼쪽의 LatencyGuard 메뉴를 확장하고 일반을 열어 허용 오차와 피드백을 구성하십시오."

L["Automate Spell Queue Window"] = "주문 대기열 창 자동화"
L["Automate Spell Queue Window Tooltip"] = "체크하면 애드온이 모든 주문 대기열 조정을 처리합니다.\n\n|cffff0000참고:|r 이 기능을 비활성화하면 모든 업데이트가 즉시 중지됩니다."
L["Enable Chat Feedback"] = "채팅 피드백 활성화"
L["Enable Chat Feedback Tooltip"] = "주문 대기열 창이 새로운 목표 값으로 업데이트될 때마다 채팅 로그에 메시지를 출력합니다."
L["Tolerance Buffer"] = "허용 오차 버퍼"
L["Tolerance Buffer Tooltip"] = "이 값은 현재 세계 지연 시간에 추가됩니다.\n\n높은 값(200+)은 지연 시간이 높은 연결에 더 안전합니다.\n낮은 값(50-100)은 고급 경쟁 플레이에 더 좋습니다."

L["Init Message"] = "v%s 초기화됨. 구성하려면 |cFFFFD700/lg|r 를 사용하십시오."
L["Update Message"] = "SQW가 |cFFFFD700%dms|r로 설정됨 (핑: %d + 버퍼: %d)"
