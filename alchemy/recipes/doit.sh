#!/bin/bash
cd "${0%/*}"
./refresh-inventions "https://wax.dfuse.eosnation.io/graphql" || exit 1
source ./getter-binary.sh nftelements uint64 || exit 1
./show-recipes || exit 1
../create/do-create > create.html || exit 1
mv create.html ../../public_html/alchemy/create/ || exit 1
mv *.html *.csv ../../public_html/alchemy/ || exit 1
