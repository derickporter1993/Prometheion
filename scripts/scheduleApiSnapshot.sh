#!/usr/bin/env bash
# Schedules hourly API usage snapshots
# Usage: ./scripts/scheduleApiSnapshot.sh OpsGuardian
alias_name="${1:-OpsGuardian}"
# Schedule (top of hour, hourly)
sf apex run -u "$alias_name" -f /dev/stdin <<'APEX'
System.schedule('OpsGuardian_API_Snapshot', '0 0 * * * ?', new ApiUsageSnapshot());
APEX
