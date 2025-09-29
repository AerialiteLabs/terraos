#!/bin/bash

echo "Downloading file from https://dl.cros.download/files/${board}/${board}.zip..."
wget -q "https://dl.cros.download/files/${board}/${board}.zip" -O "./${board}.zip" || exit 1
unzip "./${board}.zip"
shim=$(unzip -Z1 "./${board}.zip")
rm ./${board}.zip

boards_url="https://chromiumdash.appspot.com/cros/fetch_serving_builds?deviceCategory=ChromeOS"

reco_url="$(wget -qO- --show-progress $boards_url | python3 -c '
import json, sys

all_builds = json.load(sys.stdin)
board_name = sys.argv[1]
if not board_name in all_builds["builds"]:
    print("Invalid board name: " + board_name, file=sys.stderr)
    sys.exit(1)
    
board = all_builds["builds"][board_name]
if "models" in board:
    for device in board["models"].values():
    if device["pushRecoveries"]:
        board = device
        break

reco_url = list(board["pushRecoveries"].values())[-1]
print(reco_url)
' $board)"

reven_url="$(wget -qO- --show-progress $boards_url | python3 -c '
import json, sys

all_builds = json.load(sys.stdin)
board_name = sys.argv[1]
if not board_name in all_builds["builds"]:
    print("Invalid board name: " + board_name, file=sys.stderr)
    sys.exit(1)
    
board = all_builds["builds"][board_name]
if "models" in board:
    for device in board["models"].values():
    if device["pushRecoveries"]:
        board = device
        break

reco_url = list(board["pushRecoveries"].values())[-1]
print(reco_url)
' reven)"


reco="../reco_$board.bin"
reco_zip="../reco_$board.zip"
reven="../reven_$board.bin"
reven_zip="../reven_$board.zip"

extract_zip() {
  local zip_path="$1"
  local bin_path="$2"
  cleanup_path="$bin_path"
  print_info "extracting $zip_path"
  local total_bytes="$(unzip -lq "$zip_path" | tail -1 | xargs | cut -d' ' -f1)"
  if [ ! "$quiet" ]; then
    unzip -p "$zip_path" | pv -s "$total_bytes" > "$bin_path"
  else
    unzip -p "$zip_path" > "$bin_path"
  fi
  rm -rf "$zip_path"
  cleanup_path=""
}

download_and_unzip() {
  local url="$1"
  local zip_path="$2"
  local bin_path="$3"
  if [ ! -f "$bin_path" ]; then
    if [ ! "$quiet" ]; then
      wget -q --show-progress $url -O "$zip_path" -c
    else
      wget -q "$url" -O "$zip_path" -c
    fi
  fi

  if [ ! -f "$bin_path" ]; then
    extract_zip "$zip_path" "$bin_path"
  fi
}

download_and_unzip "$reco_url" "$reco_zip" "$reco"
download_and_unzip "$reven_url" "$reven_zip" "$reven"

export $reco $reven