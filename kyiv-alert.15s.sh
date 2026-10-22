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

# KyivAlert: centered full-color PNG icon v4
kyiv_alert_centered_icon() {
    local kyiv_icon_format="$1"
    shift
    local kyiv_icon_png
    kyiv_icon_png="$(/usr/bin/perl -e 'use strict;
use warnings;
use MIME::Base64 qw(encode_base64 decode_base64);

my $color = shift @ARGV;
# Version 1 passed the old SF configuration as its first argument.
if ($color !~ /\A(?:\#[0-9a-f]{3}|\#[0-9a-f]{6}|red|green|yellow|gray|grey|white|black)\z/i) {
    my $old_config = decode_base64($color);
    ($color) = $old_config =~ /"colors"\s*:\s*\[\s*"([^"\\]+)"/;
    die "Invalid Kyiv Alert color\n" unless defined $color;
}
my %named = (red=>'"'"'ff0000'"'"', green=>'"'"'008000'"'"', yellow=>'"'"'ffff00'"'"',
    gray=>'"'"'808080'"'"', grey=>'"'"'808080'"'"', white=>'"'"'ffffff'"'"', black=>'"'"'000000'"'"');
$color = $named{lc $color} if exists $named{lc $color};
$color =~ s/^\#//;
$color =~ s/([0-9a-f])/$1$1/ig if length($color) == 3;
die "Invalid Kyiv Alert color\n" unless $color =~ /\A[0-9a-f]{6}\z/i;
my @rgb = map { hex($_) } ($color =~ /(..)/g);

sub crc32 {
    my $crc = 0xffffffff;
    for my $byte (unpack('"'"'C*'"'"', $_[0])) {
        $crc ^= $byte;
        for (1..8) { $crc = ($crc >> 1) ^ (($crc & 1) ? 0xedb88320 : 0); }
    }
    return $crc ^ 0xffffffff;
}
sub chunk {
    my ($type, $data) = @_;
    return pack('"'"'N'"'"', length($data)) . $type . $data . pack('"'"'N'"'"', crc32($type . $data));
}

# A symmetric 28px circle on a transparent 32px Retina canvas (16pt).
my $raw = '"'"''"'"';
for my $y (0..31) {
    $raw .= "\0";
    for my $x (0..31) {
        my $inside = 0;
        for my $sy (0..3) {
            for my $sx (0..3) {
                my $dx = $x + ($sx + 0.5) / 4 - 16;
                my $dy = $y + ($sy + 0.5) / 4 - 16;
                ++$inside if $dx*$dx + $dy*$dy <= 14*14;
            }
        }
        $raw .= pack('"'"'C4'"'"', @rgb, int(255 * $inside / 16 + 0.5));
    }
}
my ($a, $b) = (1, 0);
for my $byte (unpack('"'"'C*'"'"', $raw)) {
    $a = ($a + $byte) % 65521;
    $b = ($b + $a) % 65521;
}
# A valid uncompressed zlib stream avoids any external image dependencies.
my $zlib = "\x78\x01" . pack('"'"'Cv2'"'"', 1, length($raw), 65535-length($raw))
    . $raw . pack('"'"'N'"'"', ($b << 16) | $a);
my $png = "\x89PNG\r\n\x1a\n"
    . chunk('"'"'IHDR'"'"', pack('"'"'NNCCCCC'"'"', 32, 32, 8, 6, 0, 0, 0))
    . chunk('"'"'pHYs'"'"', pack('"'"'NNC'"'"', 5669, 5669, 1))
    . chunk('"'"'IDAT'"'"', $zlib) . chunk('"'"'IEND'"'"', '"'"''"'"');
print encode_base64($png, '"'"''"'"');
' -- "$1")" || return 1
    shift
    printf "$kyiv_icon_format" "$kyiv_icon_png" "$@"
}
kyiv_alert_centered_icon ' | image=%s width=16 height=16 dropdown=false tooltip="Київ: %s"\n' \
    "$color" "$status"
printf '%s\n' '---' 'Київ · місто | size=14'
printf '%s | color=%s\n' "$status" "$color"
printf '%s | size=11\n' "$checked"
printf '%s\n' '---' 'Оновити | refresh=true'
printf '%s\n' 'Джерело: alerts.in.ua | href=https://alerts.in.ua/'
