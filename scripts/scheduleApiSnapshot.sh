#!/usr/bin/env bash
# Schedules hourly API usage snapshots
# Usage: ./scripts/scheduleApiSnapshot.sh Sentinel
alias_name="${1:-Sentinel}"
# Schedule (top of hour, hourly)
sf apex run -u "$alias_name" -f /dev/stdin <<'APEX'
System.schedule('Sentinel_API_Snapshot', '0 0 * * * ?', new ApiUsageSnapshot());
APEX
