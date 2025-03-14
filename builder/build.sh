#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit extglob nullglob globstar lastpipe shift_verbose

source ./tools.sh
source ./source-registry.sh

echo "=== prepare sources"
for i in "${!NGX_SRC_PATH[@]}"; do
	STORAGE_DIR="/data/storage/${NGX_SRC_PATH[$i]}"
	SOURCE_DIR="./src/${NGX_SRC_PATH[$i]}"
	BRANCH="${NGX_SRC_BRANCH[$i]}"

	extract_git_bare_repo "$STORAGE_DIR" "$SOURCE_DIR" "$BRANCH"
done

echo "=== configure nginx"
cd src/nginx

export CC_OPT='-O2 -g -pipe -Wall -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS -fexceptions -fstack-protector-strong -grecord-gcc-switches -m64 -mtune=generic -fasynchronous-unwind-tables -fstack-clash-protection -Wno-error'
export LD_OPT='-lpcre -Wl,-z,defs -Wl,-z,now -Wl,-z,relro -Wl,-E' # -Wl,-rpath,/usr/share/luajit-2.1/jit'

MODULES=()
for REL_FOLDER in ../modules/*/; do
	MODULES+=("--add-module=$REL_FOLDER")
done

OTHER_MODULES=()
OTHER_MODULES+=("--add-module=../special-modules/njs/nginx")

x ./auto/configure \
	'--prefix=/usr/' \
	'--sbin-path=/usr/sbin/nginx' \
	'--modules-path=/usr/nginx/modules' \
	'--conf-path=/etc/nginx/nginx.conf' \
	'--error-log-path=/var/log/ngnix/error.log' \
	'--http-log-path=/var/log/ngnix/access.log' \
	'--http-client-body-temp-path=/run/nginx/client_body' \
	'--http-proxy-temp-path=/run/nginx/proxy' \
	'--http-fastcgi-temp-path=/run/nginx/fastcgi' \
	'--http-uwsgi-temp-path=/run/nginx/uwsgi' \
	'--http-scgi-temp-path=/run/nginx/scgi' \
	'--pid-path=/run/nginx/nginx.pid' \
	'--lock-path=/run/lock/subsys/nginx' \
	'--user=nginx' \
	'--with-compat' \
	'--without-select_module' \
	'--without-poll_module' \
	'--with-threads' \
	'--with-file-aio' \
	'--with-http_ssl_module' \
	'--with-http_v2_module' \
	'--with-http_v3_module' \
	'--with-http_realip_module' \
	'--with-http_addition_module' \
	'--with-http_xslt_module' \
	'--with-http_xslt_module' \
	'--with-http_image_filter_module' \
	'--with-http_geoip_module' \
	'--with-http_sub_module' \
	'--with-http_dav_module' \
	'--with-http_flv_module' \
	'--with-http_mp4_module' \
	'--with-http_gunzip_module' \
	'--with-http_gzip_static_module' \
	'--with-http_auth_request_module' \
	'--with-http_random_index_module' \
	'--with-http_secure_link_module' \
	'--with-http_degradation_module' \
	'--with-http_slice_module' \
	'--with-http_stub_status_module' \
	'--with-stream' \
	'--with-stream_ssl_module' \
	'--with-stream_realip_module' \
	'--with-stream_geoip_module' \
	'--with-stream_ssl_preread_module' \
	'--with-google_perftools_module' \
	'--with-pcre' \
	'--with-pcre-jit' \
	'--with-libatomic' \
	'--with-debug' \
	"--with-cc-opt=$CC_OPT" \
	"--with-ld-opt=$LD_OPT" \
	"${MODULES[@]}" \
	"${OTHER_MODULES[@]}"

echo "=== build nginx"
x make -j

echo "=== copy nginx"
make "DESTDIR=/builder/rpm/root" install
rm -rf /builder/rpm/root/etc
cp -r /builder/filesystem/. /builder/rpm/root

echo "=== make rpm"
cd /builder/rpm

mkdir -p root/var/log/nginx
mkdir -p root/etc/nginx/{stream.d,vhost.d,rtmp.d}

togo file exclude etc run usr/lib/systemd/system usr/sbin var/log

togo build package

cp -v rpms/*.rpm /data/dist
