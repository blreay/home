#USERNAME=`whoami`
USERNAME=$(id|tr '()' '  '|awk  '{print $2}')
#ipcs -m|awk '/'$USERNAME'/{system("ipcrm -m "$2"")}'
ipcs -m|awk '/'$USERNAME'/{print $2}'|xargs -I {} ipcrm -m {}
#ipcs -s|awk '/'$USERNAME'/{system("ipcrm -s "$2"")}'
ipcs -s|awk '/'$USERNAME'/{print $2}'|xargs -I {} ipcrm -s {}
#ipcs -q|awk '/'$USERNAME'/{system("ipcrm -q "$2"")}'
ipcs -q|awk '/'$USERNAME'/{print $2}'|xargs -I {} ipcrm -q {}
