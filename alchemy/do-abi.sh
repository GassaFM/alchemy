#!/bin/bash
url=https://wax.dfuse.eosnation.io/v0/state/abi
name=a.rplanet
./get-abi $url $name > $name.json
./contract-abi-to-d $name
