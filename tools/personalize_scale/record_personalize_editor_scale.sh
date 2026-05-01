#!/usr/bin/env bash
# Record editor + F6 run current scene for char_gallery across editor UI scales.
# Usage: ./record_personalize_editor_scale.sh <project_dir> <output.mp4>
# Deps: godot, xdotool, ffmpeg, python3; set DISPLAY and XAUTHORITY for X11 grab.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:?project dir}"
OUT_MP4="${2:?output mp4}"
EDITOR_SETTINGS="${EDITOR_SETTINGS:-${HOME}/.config/godot/editor_settings-4.6.tres}"
PATCH_PY="${PATCH_PY:-${SCRIPT_DIR}/set_editor_display_scale.py}"

export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-${HOME}/.Xauthority}"

declare -a RUNS=(
  "100|2|"
  "125|3|"
  "135|7|1.35"
  "140|7|1.4"
  "150|4|"
  "175|5|"
  "200|6|"
)

kill_godot() {
  pkill -f "godot --path ${PROJECT_DIR}" 2>/dev/null || true
  sleep 1
}

activate_editor() {
  local w
  w="$(xdotool search --name 'char_gallery.tscn' 2>/dev/null | head -1 || true)"
  if [[ -z "${w}" ]]; then
    return 1
  fi
  xdotool windowactivate --sync "${w}"
  return 0
}

one_scale() {
  local mode="$1"
  local custom="${2:-}"
  kill_godot
  if [[ -n "${custom}" ]]; then
    python3 "${PATCH_PY}" "${EDITOR_SETTINGS}" --mode "${mode}" --custom "${custom}"
  else
    python3 "${PATCH_PY}" "${EDITOR_SETTINGS}" --mode "${mode}"
  fi
  godot --path "${PROJECT_DIR}" -e --scene res://scenes/char_gallery.tscn \
    --windowed --resolution 1680x950 --position 80,40 >/tmp/godot_editor_run.log 2>&1 &
  local god_pid=$!
  sleep 14
  if activate_editor; then
    xdotool key F6
  fi
  sleep 12
  kill "${god_pid}" 2>/dev/null || true
  kill_godot
  sleep 2
}

rm -f "${OUT_MP4}"
ffmpeg -y -f x11grab -video_size 1920x1200 -framerate 12 -i "${DISPLAY}.0" \
  -c:v libx264 -preset veryfast -pix_fmt yuv420p "${OUT_MP4}" 2>/dev/null &
FF_PID=$!
sleep 2

for entry in "${RUNS[@]}"; do
  IFS='|' read -r _lbl mode cust <<< "${entry}"
  one_scale "${mode}" "${cust}"
done

kill "${FF_PID}" 2>/dev/null || true
wait "${FF_PID}" 2>/dev/null || true
echo "Wrote ${OUT_MP4}"
