#!/bin/bash
#
# Capture a real Raspberry Pi's system outputs into t/data/<board>/ so the
# fixture-replay tests (t/55-board-fixtures.t) can validate RPi::SysInfo against
# genuine hardware data without needing that board present at test time.
#
# Run this ON the Pi you want to capture, naming the board dir, eg:
#
#     ./t/capture-fixtures.sh pi3
#     ./t/capture-fixtures.sh pi4
#
# Serial numbers, MAC addresses and IP addresses are sanitized automatically.
# After capturing, eyeball the files and commit them to replace the
# hand-authored fixtures with ground truth.

set -u

board="${1:-}"

if [ -z "$board" ]; then
    echo "usage: $0 <board-name>   (eg. pi3, pi4, pi5)" >&2
    exit 1
fi

here="$(cd "$(dirname "$0")" && pwd)"
out="$here/data/$board"
mkdir -p "$out"

sanitize() {
    sed -E \
        -e 's/^(Serial[[:space:]]*:).*/\1 10000000deadbeef/' \
        -e 's/([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}/aa:bb:cc:dd:ee:ff/g' \
        -e 's/inet ([0-9]{1,3}\.){3}[0-9]{1,3}/inet 10.0.0.5/g' \
        -e 's#inet ([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]+#inet 10.0.0.5/24#g' \
        -e 's/inet6 [0-9a-fA-F:]+/inet6 fe80::1/g'
}

have() { command -v "$1" >/dev/null 2>&1; }

# --- files (read directly by _slurp) ---------------------------------------

tr -d '\0' < /sys/firmware/devicetree/base/model > "$out/model"; echo >> "$out/model"
sanitize < /proc/cpuinfo > "$out/cpuinfo"
grep -E '^Revision' /proc/cpuinfo | awk '{print $NF}' > "$out/revision"
cat /proc/swaps > "$out/swaps"
cat /sys/class/thermal/thermal_zone0/temp > "$out/thermal" 2>/dev/null

# --- commands (run by _run) -------------------------------------------------

tail -3 /proc/cpuinfo | sanitize > "$out/cpuinfo-tail"
head -4 /etc/os-release > "$out/os-release"
uname -a > "$out/uname"
df > "$out/df-out"

if have vcgencmd; then
    vcgencmd measure_temp           > "$out/measure_temp"
    vcgencmd get_throttled          > "$out/throttled"
    vcgencmd get_config int | head -8 > "$out/config-int"
    vcgencmd get_config str | head -3 > "$out/config-str"
    vcgencmd get_camera             > "$out/get_camera" 2>&1
fi

# config.txt (active path)
for f in /boot/firmware/config.txt /boot/config.txt; do
    if [ -f "$f" ]; then
        grep -E -v '^\s*(#|^$)' "$f" > "$out/config-txt"
        break
    fi
done

# gpio tool (whichever is present), all + single + multi
if have pinctrl; then
    pinctrl get        > "$out/pinctrl-all"
    pinctrl get 2      > "$out/pinctrl-pin2"
    pinctrl get 2,4,6,8 > "$out/pinctrl-multi"
elif have raspi-gpio; then
    raspi-gpio get        > "$out/raspi-gpio-all"
    raspi-gpio get 2      > "$out/raspi-gpio-pin2"
    raspi-gpio get 2,4,6,8 > "$out/raspi-gpio-multi" 2>&1   # capture how it handles a comma list
fi

# camera (libcamera tool, if present)
if have rpicam-hello; then
    rpicam-hello --list-cameras > "$out/list-cameras" 2>/dev/null
elif have libcamera-hello; then
    libcamera-hello --list-cameras > "$out/list-cameras" 2>/dev/null
fi

# network tool (whichever is present)
if have ifconfig; then
    ifconfig | sanitize > "$out/ifconfig"
fi
if have ip; then
    ip addr | sanitize > "$out/ip-addr"
fi

echo "Captured $board fixtures into $out:"
ls -1 "$out"
