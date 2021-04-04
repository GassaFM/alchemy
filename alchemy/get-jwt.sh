#!/bin/bash
curl https://auth.eosnation.io/v1/auth/issue \
       -k --data-binary \
       '{"api_key":"(get your key at https://login.eosnation.io/)"}' \
       > token.json
