#!/bin/bash
bnlcrl_main() {
    codes_dependencies common
}

bnlcrl_python_install() {
    codes_download mrakitin/bnlcrl
    perl -pi -e 's{http://henke.lbl.gov}{https://henke.lbl.gov}' bnlcrl/package_data/json/defaults_delta.json
    codes_python_install
}
