#!/bin/bash
cd "${0%/*}"
rm -f out-of-sync.txt
./refresh-log-alchemy "https://wax.dfuse.eosnation.io/graphql" || touch out-of-sync.txt
./show-log-alchemy || exit 1
./create/do-create > create.html || exit 1
mv create.html ../public_html/alchemy/create || exit 1
mv *.html *.csv ../public_html/alchemy/ || exit 1
