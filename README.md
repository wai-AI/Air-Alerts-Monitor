# Kyiv Alert

A lightweight [SwiftBar](https://swiftbar.app/) plugin that shows Kyiv’s air raid alert status as a colored circle in the macOS menu bar. Updates every **15 seconds** using the [alerts.in.ua API](https://devs.alerts.in.ua/).

<p align="center">
  <img
    src="https://github.com/user-attachments/assets/0aa4ddb9-d25f-47e2-91dc-73ead78bb00a"
    width="225"
    height="303"
    alt="Kyiv Alert status menu"
  />
</p>

## Status colors

| Color | Meaning |
| --- | --- |
| 🟢 Green | No active air raid alert reported |
| 🟡 Yellow | Yellow alert level |
| 🔴 Red | Red alert level |
| ⚪ Gray | Status unavailable, a token error, or an unspecified level |

Colors follow the API’s current level directly. The plugin tracks **Kyiv city**, not Kyiv Oblast. A red level does not necessarily mean a missile attack.

## Setup

1. Install SwiftBar:

   ```bash
   brew install swiftbar
   ```

2. Request a personal [alerts.in.ua API token](https://alerts.in.ua/api-request). Save it locally by running this block in Terminal and pasting the token when prompted. Input is hidden.

   ```bash
   /bin/bash <<'SETUP'
   set -e
   umask 077
   config="$HOME/Library/Application Support/KyivAlert"
   mkdir -p "$config"
   chmod 700 "$config"
   printf 'API token: '
   IFS= read -r -s token </dev/tty
   printf '\n'
   [[ -n "$token" && ! "$token" =~ [[:space:][:cntrl:]] ]] || exit 1
   printf 'Authorization: Bearer %s\n' "$token" > "$config/authorization.headers"
   unset token
   chmod 600 "$config/authorization.headers"
   SETUP
   ```

3. From the repository folder, install the plugin:

   ```bash
   mkdir -p "$HOME/SwiftBarPlugins"
   cp kyiv-alert.15s.sh "$HOME/SwiftBarPlugins/"
   chmod +x "$HOME/SwiftBarPlugins/kyiv-alert.15s.sh"
   open -a SwiftBar
   ```

4. When SwiftBar asks for a plugin folder, select `~/SwiftBarPlugins`. If already configured, copy the script into its existing plugin folder instead.

## Usage

Click the circle to see the current level and last successful check. Select **Оновити (Refresh)** to update manually. Enable **Launch at Login** in SwiftBar for automatic startup; Terminal can stay closed.

The token stays outside the repository. Never commit it. Updates pause while your Mac sleeps or SwiftBar is closed. This indicator supplements official alerts and may reflect source delays.
