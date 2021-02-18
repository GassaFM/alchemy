#!/bin/bash
cd "${0%/*}"
./refresh-log-alchemy "https://wax.dfuse.eosnation.io/graphql"
./show-log-alchemy || exit 1
mv *.html *.csv ../public_html/alchemy/ || exit 1
