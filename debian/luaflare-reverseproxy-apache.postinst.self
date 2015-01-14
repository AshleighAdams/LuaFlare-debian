. /usr/share/debconf/confmodule

case "$1" in
configure)
	luaflare --port=8080 --local --trusted-reverse-proxies=localhost,::1 --x-sendfile
	a2enmod proxy proxy_http xsendfile
	a2ensite luaflare
;;
esac

