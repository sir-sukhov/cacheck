#/bin/bash
# Crontab string example
# 0 7 * * 1 bash -c '/root/CA/cacheck.bash -p "/root/CA" -m "http://192.168.192.168:8080/hooks/g1p2123ybssfqcsdf7fsfffbc"' >> /var/log/cacheck.bash.log 2>&1 
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'
mattermost() {
	TEXT=$1
	[[ $verbose -eq 1 ]] && echo "Sending to mattermost"
	[[ $verbose -eq 1 ]] && echo -e "$TEXT"
	curl -i -X POST -d "payload={\"text\":\"$TEXT\"}" $MTRMT_HOOK
}
cert_check() {
	CERT_PATH=$1
	EDHR=`openssl x509 -in $CERT_PATH -noout -dates 2>/dev/null | grep notAfter | cut -d'=' -f2` # Expiration date Human Readable
	ED=$(date --date "$EDHR" +%s) # Expiration date
	DIFF=`bc <<< "scale=0; ($ED -$TD) / 86400"`
	if [ $DIFF -lt 0 ]
	then
		[[ $verbose -eq 1 ]] && echo -e "${RED}ERROR:${NC} Cert $CERT_PATH has expired (${RED}Expiration date: $EDHR${NC})"
	elif [ $DIFF -lt 90 ]
	then
		echo -e "${YELLOW}WARN:${NC} Cert $CERT_PATH expires in less than 90 days! (${YELLOW}Expiration date: $EDHR${NC})"
		add_to_message "WARN" "`basename $CERT_PATH` expires in less than 90 days! (Expiration date: $EDHR)"
	else
		[[ $verbose -eq 1 ]] && echo "OK: Cert $CERT_PATH isn't going to expire soon. (Expiration date: $EDHR)"
	fi
}
add_to_message() {
	status=$1
	content=$2
	if [ -z "$ERROR_MESSAGE" ]
	then
			ERROR_MESSAGE="$status - $content"
	else
			ERROR_MESSAGE="$ERROR_MESSAGE\n$status - $content"
	fi
}
##########################
#   SCRIPT STARTS HERE   #
##########################
while getopts ":vp:m:" Option
do
	case $Option in
		v       ) echo "Verbose mode";verbose=1;;
		p	) CHECK_PATH=$OPTARG;echo "Checking all files under $CHECK_PATH";;
		m       ) MTRMT_HOOK=$OPTARG;echo "Mattermost option is active, will send WARN to $MTRMT_HOOK";;
		*       ) echo "Something wrong with opions. Usage: `basename $0` -p /path/to/certificates [-v] [-m http://mattermost/hooks/exmple] " ; exit $E_OPTERROR;;
	esac
done
#checking if mandatory option -p are in place
if [ -z $CHECK_PATH ]
then
	echo "Missing mandatory option -p. Usage: `basename $0` -p /path/to/certificates -[vm]"; exit 1
fi
TD=$(date --date "$DTS_SSL" +%s) # Today's date
for CERT in `find $CHECK_PATH -type f -name "*.cert.pem"`
do
	cert_check $CERT
done
[[ -n "$ERROR_MESSAGE" ]] && [[ $verbose -eq 1 ]] && echo '##################### ERROR_MESSAGE ###################' && echo -e $ERROR_MESSAGE
[[ -n "$MTRMT_HOOK" ]] && [[ -n "$ERROR_MESSAGE" ]] && mattermost "$ERROR_MESSAGE"
