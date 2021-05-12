#!/bin/bash
cd "${0%/*}"
./refresh-inventions "https://wax.dfuse.eosnation.io/graphql" || exit 1
./show-recipes || exit 1
mv *.html *.csv ../../public_html/alchemy/ || exit 1
