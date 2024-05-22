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

REL_PROJECT_PATH="$(realpath -s --relative-to="$ONBOARD_BASE_DIR" "$1")"
if [[ "$REL_PROJECT_PATH" == "../"* ]]; then
  echo "Project needs to be inside ONBOARD_BASE_DIR."
  echo "Relative path: $REL_PROJECT_PATH"
  exit 12
fi

cd "$ONBOARD_BASE_DIR"
TARGET_DIR="$ONBOARD_BASE_DIR/$REL_PROJECT_PATH"
SRC_DIR="$OFFBOARD_BASE_DIR/$REL_PROJECT_PATH"

if [ ! -L "$TARGET_DIR" -a -d "$TARGET_DIR" ]; then
  echo "$1 is not a symlink to a directory."
  exit 1
fi

if [ ! -d "$SRC_DIR.offboarded" ]; then
  echo "$SRC_DIR.offboarded does not exist."
  exit 1
fi
if [ -e "$SRC_DIR.onboarding" ]; then
  echo "$SRC_DIR.onboarding already exist, clean up manually."
  exit 2
fi

if [ -e "$TARGET_DIR.onboarding" ]; then
  echo "$TARGET_DIR.onboarding already exists, clean up manually."
  exit 2
fi

echo "Onboarding $SRC_DIR.offboarded -> $TARGET_DIR"
echo -n "Starting in "
LOOP=5
while [ $LOOP -gt 0 ]; do
  echo -n "$LOOP "
  sleep 1
  LOOP=$(( $LOOP - 1 ))
done
echo "START"

###############################################

mkdir -p "$TARGET_DIR.onboarding"
mv "$SRC_DIR.offboarded" "$SRC_DIR.onboarding"
rm "$TARGET_DIR" # delete the symlink while onboarding
rsync -av --numeric-ids --delete "$SRC_DIR.onboarding/" "$TARGET_DIR.onboarding/"
mv "$TARGET_DIR.onboarding" "$TARGET_DIR"
mv "$SRC_DIR.onboarding" "$SRC_DIR.onboarded"

echo "Done."
