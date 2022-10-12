#!/bin/bash

xml=$(wget -O - https://theseus.bbctest01.uk/xml.php 2>/dev/null |grep "receiver name")

missingsites=0
while IFS= read -r rx; do
    #echo "Checking receiver: $rx"
    grep $rx <<< "$xml" > /dev/null && continue
    echo "Missing receiver $rx"
    missingsites=$(expr $missingsites + 1)
done < sites_to_check.txt
echo "$missingsites sites missing"
