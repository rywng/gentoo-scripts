#!/usr/bin/env sh

choice=$(ls /usr/local/etc/sing-box/configs/ | fzf --no-multi)
if test -n "$choice"; then
	echo $choice | xargs -I {} cp /usr/local/etc/sing-box/configs/{} /usr/local/etc/sing-box/config.json &&
		sing-box check -c /usr/local/etc/sing-box/config.json &&
		systemctl restart sing-box.service &&
		systemctl restart unbound.service
fi
