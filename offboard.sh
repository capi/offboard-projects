#!/bin/bash
set -e

if [ -e "$HOME/.offboard.env" ]; then
  source "$HOME/.offboard.env"
elif [ -e "/etc/offboard.env" ]; then
  source "/etc/offboard.env" ]
fi
if [ -z "$OFFBOARD_BASE_DIR" -o -z "$ONBOARD_BASE_DIR" ]; then
  echo "You need to specify the following environment variables:"
  echo "a) via export"
  echo "b) via $HOME/.offboard.env"
  echo "c) via /etc/offboard.env"
  echo "------------"
  echo "OFFBOARD_BASE_DIR (current value: $OFFBOARD_BASE_DIR): base directory for offboarded projects"
  echo "                  (e.g. /mnt/nfs/server/offboarded)"
  echo "ONBOARD_BASE_DIR  (current value: $ONBOARD_BASE_DIR): base directory for live projects"
  echo "                  (e.g. $HOME)"
  exit 10
fi

if [ $# -ne 1 ]; then
  echo "ONBOARD_BASE_DIR=$ONBOARD_BASE_DIR"
  echo "OFFBOARD_BASE_DIR=$OFFBOARD_BASE_DIR"
  echo
  echo "Syntax: $0 <rel-path-to-project-to-onboard>"
  echo "e.g. $0 project/my-project"
  exit 11
fi

###############################################

if [ -L "$1" ]; then
  echo "$1 is already a symlink."
  exit 1
fi

SRC_DIR="$(readlink -f "$1")"
SRC_BASE="$ONBOARD_BASE_DIR"
TARGET_BASE="$OFFBOARD_BASE_DIR"
GID="$(id -g "$UID")"

if [ ! -d "$SRC_DIR" ]; then
  echo "Is not a directory: $SRC_DIR"
  exit 1
fi
if [[ "$SRC_DIR" != $SRC_BASE/* ]]; then
   echo "Only directories under $SRC_BASE are supported."
   exit 1
fi
REL_DIR="$(realpath -s --relative-to="$SRC_BASE" "$SRC_DIR")"
TARGET_DIR="$TARGET_BASE/$REL_DIR"

echo "Offboarding: $SRC_DIR -> $TARGET_DIR.offboarded"
echo -n "Starting in "
LOOP=5
while [ $LOOP -gt 0 ]; do
  echo -n "$LOOP "
  sleep 1
  LOOP=$(( $LOOP - 1 ))
done
echo "START"

###############################################

echo
echo -n "Check if files not owned by $UID:$GID exist ... "
COUNT="$(find "$SRC_DIR" ! -user $UID -or ! -group $GID | wc -l)"
echo $COUNT
if [ "$COUNT" != 0 ]; then
  echo "Aborting, files owned not by the current user are not supported by this script."
  exit 3
fi

if [ -d "$TARGET_DIR.onboarded" ]; then
  mv "$TARGET_DIR.onboarded" "$TARGET_DIR.offboarding"
fi

mkdir -p "$TARGET_DIR.offboarding"
mv "$SRC_DIR" "$SRC_DIR.offboarding"
rsync -av --numeric-ids --progress --delete "$SRC_DIR.offboarding/" "$TARGET_DIR.offboarding/"
mv "$TARGET_DIR.offboarding" "$TARGET_DIR.offboarded"
ln -s "$TARGET_DIR.offboarded" "$SRC_DIR"
rm -rf "$SRC_DIR.offboarding"

echo "Done."
