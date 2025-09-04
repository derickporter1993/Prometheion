#!/usr/bin/env bash
set -euo pipefail
alias_name="${1:-CCX}"
# Ensure DevHub exists
if ! sfdx force:org:list --json | grep -q '"isDevHub": true'; then
  echo "Please auth a DevHub first: sfdx auth:web:login -d -a DevHub"
fi
sfdx force:org:create -f config/project-scratch-def.json -a "$alias_name" -s -d 7
sfdx force:source:push -u "$alias_name"
sfdx force:user:permset:assign -n Command_Center_Admin -u "$alias_name"
echo "Open org..."
sfdx force:org:open -u "$alias_name" -p /lightning/setup/SetupOneHome/home
