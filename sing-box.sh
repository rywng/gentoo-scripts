#!/usr/bin/env sh

set -e

_output_path="/usr/local/etc/sing-box/config.json"
_prefix="/usr/local/etc/sing-box/configs"
_unbound_dest_file="/etc/unbound/fwd.conf"

inbound=$(ls $_prefix/inbound | fzf --no-multi)
outbound=$(ls $_prefix/outbound | fzf --no-multi)
if test -n "$inbound" -a -n "$outbound" ; then
	jq -s ".[0] * .[1] * .[2]" $_prefix/base.json $_prefix/inbound/$inbound $_prefix/outbound/$outbound > $_output_path
	sing-box check -c /usr/local/etc/sing-box/config.json
	systemctl restart sing-box.service

	if [ `basename $inbound` = "vpn.json" ] ; then
		ln -sf /etc/unbound/fwd-vpn.conf $_unbound_dest_file
	else
		ln -sf /etc/unbound/fwd-cn.conf $_unbound_dest_file
	fi
	systemctl restart unbound.service
fi
