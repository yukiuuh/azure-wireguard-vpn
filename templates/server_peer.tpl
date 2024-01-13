[Peer]
# ${friendly_name}
PublicKey = ${wg_client_public_key}
AllowedIPs = ${wg_client_ip}
%{ if wg_nat }
AllowedIPs = ${home_net}
%{ endif }
PersistentKeepalive = ${persistent_keepalive}