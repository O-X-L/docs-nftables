# NFTables Documentation - Sphinx Material-Themed

<!-- 
[![Uptime](https://status.oxl.at/api/v1/endpoints/1--oxl_documentation/uptimes/7d/badge.svg)](https://status.oxl.at/endpoints/1--oxl_documentation)
-->

EN 🇬🇧: [nftables.docs.oxl.app](https://gam.docs.oxl.app)

This is a mirror of the [official NFTables documentation](https://wiki.nftables.org/) to make it a bit easier accessible for new users.

## Build

Run:

```
apt install git python3-pip pandoc

# with VENV
apt install python3-virtualenv 
bash venv.sh

# WITHOUT
pip install -r requirements.txt

# USAGE: bash html.sh <BUILD-DIR> <DOMAIN> 
bash html.sh ./build/ nftables.docs.oxl.app
```

## Setup

* Make sure to redirect requests not ending in `.html` to the same path with that extension - else internal redirects will not work.
