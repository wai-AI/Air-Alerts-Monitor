#!/bin/bash
# <xbar.title>Київ — індикатор тривоги</xbar.title>
# <xbar.version>3.0.0</xbar.version>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.refreshOnOpen>false</swiftbar.refreshOnOpen>

set -u
headers="$HOME/Library/Application Support/KyivAlert/authorization.headers"
url='https://api.alerts.in.ua/v2/iot/active_air_raid_alerts/31.json'

color='#98989D'
status='Статус невідомий'
checked='Немає успішного оновлення'

apply_status() {
    color='#98989D'
    case "$1" in
        '"R"') color='#FF453A'; status='Червоний рівень' ;;
        '"Y"') color='#FFD60A'; status='Жовтий рівень' ;;
        '"N"') color='#30D158'; status='Тривогу не оголошено' ;;
        '"P"') status='Часткова тривога · рівень не уточнено' ;;
        *) status='Невідома відповідь API'; return 1 ;;
    esac
}

if [[ "${1:-}" == '--self-test' ]]; then
    for expected in \
        'R:#FF453A:Червоний рівень' \
        'Y:#FFD60A:Жовтий рівень' \
        'N:#30D158:Тривогу не оголошено' \
        'R:#FF453A:Червоний рівень'
    do
        rest="${expected#*:}"
        apply_status "\"${expected%%:*}\""
        [[ "$color" == "${rest%%:*}" ]] || exit 1
        [[ "$status" == "${rest#*:}" ]] || exit 1
    done
    if apply_status 'invalid'; then exit 1; fi
    [[ "$color" == '#98989D' ]] || exit 1
    printf 'Перевірка кольорів і підписів пройшла успішно.\n'
    exit 0
fi

if [[ ! -s "$headers" ]]; then
    status='Потрібен API-токен'
elif response=$(/usr/bin/curl --silent --show-error \
    --proto '=https' --connect-timeout 4 --max-time 9 \
    --max-filesize 4096 \
    --header "@$headers" \
    --header 'Accept: application/json' \
    --header 'Cache-Control: no-cache' \
    --write-out $'\n%{http_code}' "$url" 2>/dev/null)
then
    http="${response##*$'\n'}"
    body="${response%$'\n'*}"

    if [[ "$http" == '200' ]]; then
        code=$(printf '%s' "$body" | /usr/bin/tr -d '[:space:]')
        if apply_status "$code"; then
            checked="Перевірено: $(/bin/date '+%H:%M:%S')"
        fi
    elif [[ "$http" == '401' ]]; then
        status='Токен недійсний або прострочений'
    elif [[ "$http" == '429' ]]; then
        status='Перевищено ліміт запитів API'
    else
        status="Джерело недоступне · HTTP $http"
    fi
else
    status='Немає зв’язку з джерелом даних'
fi

printf '● | color=%s size=16 dropdown=false tooltip="Київ: %s"\n' \
    "$color" "$status"
printf '%s\n' '---' 'Київ · місто | size=14'
printf '%s | color=%s\n' "$status" "$color"
printf '%s | size=11\n' "$checked"
printf '%s\n' '---' 'Оновити | refresh=true'
printf '%s\n' 'Джерело: alerts.in.ua | href=https://alerts.in.ua/'
