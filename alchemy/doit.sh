#!/bin/bash
cd "${0%/*}"
./refresh-log-alchemy "https://wax.dfuse.eosnation.io/graphql" || exit 1
./show-log-alchemy || exit 1
./create/do-create > create.html || exit 1
mv create.html ../public_html/alchemy/create || exit 1
mv *.html *.csv ../public_html/alchemy/ || exit 1
