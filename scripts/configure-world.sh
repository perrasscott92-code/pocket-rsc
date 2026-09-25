#!/usr/bin/env bash
# configure-world.sh
# Builds server/local.conf from the RSC Preservation preset and applies the
# Pocket RSC world settings. Run from the Core-Framework/server directory.
#
#   cd ~/Core-Framework/server && bash /path/to/configure-world.sh
#
# local.conf overrides default.conf, so default.conf is never touched.

set -e

if [ ! -f preservation.conf ]; then
  echo "Run this from Core-Framework/server (preservation.conf not found)." >&2
  exit 1
fi

if [ ! -f local.conf ]; then
  cp preservation.conf local.conf
  echo "Created local.conf from preservation.conf"
fi

# set_key KEY VALUE: replace the value of an existing key, keeping indentation.
set_key() {
  if grep -q "^[[:space:]]*$1:" local.conf; then
    sed -i "s/^\([[:space:]]*$1:\).*/\1 $2/" local.conf
  else
    echo "  (skipped: $1 not present in local.conf)"
  fi
}

echo "Networking"
set_key server_port 43602                      # matches the Android client's Preservation slot
set_key enforce_custom_client_version false    # the Android client reports a different version
set_key is_localhost_restricted false          # everything on-device comes from 127.0.0.1
set_key network_flood_ip_ban_minutes 0         # one shared IP, so flood bans only hurt the owner
set_key suspicious_player_ip_ban_minutes 0

echo "Experience"
set_key combat_exp_rate 50
set_key skilling_exp_rate 50
set_key want_fatigue false

echo "Quality of life"
set_key batch_progression true
set_key experience_drops_toggle true
set_key experience_counter_toggle true
set_key want_bank_notes true
set_key want_cert_deposit true
set_key want_equipment_tab true
set_key want_bank_presets false   # true breaks logout saves (NullPointerException)
set_key want_decanting true
set_key want_improved_pathfinding true
set_key want_skill_menus true
set_key want_quest_menus true
set_key ground_item_toggle true
set_key show_roof_toggle true

echo "Movement"
set_key want_custom_walking_speed true
set_key walking_tick 400

echo "Phone-friendly"
set_key idle_timer 0
set_key want_pcap_logging false
sed -i 's/^\([[:space:]]*want_discord_[a-z_]*:\).*/\1 false/' local.conf

# Optional OpenRSC custom content. Uncomment to enable.
# set_key want_runecraft true
# set_key want_harvesting true
# set_key want_pets true

echo
echo "Done. Key values:"
grep -n "server_port\|exp_rate\|want_fatigue\|batch_progression\|localhost_restricted\|flood_ip_ban" local.conf
echo
echo "Restart the server for changes to take effect."
