#! /bin/bash

[ $# -ne 2 ] && echo "$1 input file, $2 output file" && exit 1

FILE=$1
EXPORT=$2

[ -e ${EXPORT} ] && rm -f ${EXPORT}
touch ${EXPORT}

while read -r line
do
    name=$(echo ${line}|awk '{print $1}')
    echo "insert into suppliers(name, merchant, change_date, entry_date) values('${name}', 15, now(), now());" >> ${EXPORT}
done < ${FILE}

dos2unix ${EXPORT}

exit 0
