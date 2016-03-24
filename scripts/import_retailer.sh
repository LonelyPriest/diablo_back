#! /bin/bash

[ $# -ne 3 ] && echo "$1 input file, $2 output file, $3 merchant" && exit 1

FILE=$1
EXPORT=$2
MERCHANT=$3

[ -e ${EXPORT} ] && rm -f ${EXPORT}
touch ${EXPORT}

## set -x
while read -r line
do
    echo ${line}
    name=$(echo ${line}|awk -F ',' '{print $1}')
    ## address=$(echo ${line}|awk '{print $2}')
    mobile=$(echo ${line}|awk -F ',' '{print $2}') 
    balance=$(echo ${line}|awk -F ',' '{print $3}')
    if [ x${balance} = x ]; then
	balance=0
    fi 
    echo "insert into w_retailer(name, balance, mobile, merchant, change_date, entry_date) values('${name}', ${balance}, '${mobile}', ${MERCHANT}, now(), curdate());" >> ${EXPORT}
done < ${FILE}
## set +x

dos2unix ${EXPORT}

exit 0
