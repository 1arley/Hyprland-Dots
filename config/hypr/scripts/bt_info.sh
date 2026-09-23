#!/usr/bin/env bash
# Outputs JSON: [{"name": "...", "mac": "...", "battery": 80, "connected": true}]

python3 - <<'EOF'
import subprocess
import json
import re

devices = []
info_out = subprocess.run(["bluetoothctl", "devices", "Connected"], capture_output=True, text=True).stdout

for line in info_out.strip().split("\n"):
    if not line:
        continue
    parts = line.split(" ", 2)
    if len(parts) >= 3:
        mac = parts[1]
        name = parts[2]
        dev_info = subprocess.run(["bluetoothctl", "info", mac], capture_output=True, text=True).stdout
        
        battery_match = re.search(r"Battery Percentage:\s*(?:0x[0-9a-fA-F]+\s*)?\((\d+)\)", dev_info)
        battery = int(battery_match.group(1)) if battery_match else -1
        
        devices.append({
            "name": name,
            "mac": mac,
            "battery": battery,
            "connected": True
        })

print(json.dumps(devices))
EOF
