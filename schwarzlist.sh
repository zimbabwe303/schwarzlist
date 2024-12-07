#!/bin/sh

vpn_file=vpn-or-datacenter-ipv4-ranges.txt
vpn_list_url=https://raw.githubusercontent.com/josephrocca/is-vpn/main/$vpn_file
ip_addr_file=ip_addresses.txt
schwarzlist_file=ip_schwarzlist.txt

if [ $# -lt 1 ]; then
  echo "Usage: schwarzlist.sh <wg_conf_dir> [vpn-or-datacenter-ipv4-ranges.txt]"
  exit
fi

if [ ! $(which grepcidr) ]; then
  echo "grepcidr is needed, not found, please install."
  exit
fi

echo "Extracting IP addresses from the WireGuard .conf files"
if [ -f "$ip_addr_file" ]; then
  rm "$ip_addr_file"
fi
for f in "$1"/*.conf
do
  ip=$(cat "$f" | sed -n "s/Endpoint = \([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\).*/\1/p")
  if [ "$ip" ]; then
    if [ -f "$ip_addr_file" ] && grep "$ip" "$ip_addr_file" > /dev/null; then
      continue
    fi
    echo "$ip: $f" >> "$ip_addr_file"
  fi
done

if [ $# -lt 2 ]; then
  if [ -f "$vpn_file" ]; then
    rm "$vpn_file"
  fi
  wget -nc $vpn_list_url
  if [ $? -gt 0 ]; then
    echo "Error downloading: $vpn_list_url"
    echo "Try to find it manually and place into the current dir"
    exit
  fi
fi

echo "Servers found in the VPN database:"
grepcidr -f "$vpn_file" "$ip_addr_file" | tee "$schwarzlist_file"

echo "Saved as $schwarzlist_file"

