#!/bin/bash

readthedocs_main() {
    if [[ ! ${READTHEDOCS_PROJECT:-} ]]; then
        install_err '$READTHEDOCS_PROJECT not set'
    fi
    # use `-e` so can be tested in dev
    pip install -e .
    pykern sphinx prepare "$READTHEDOCS_PROJECT"
}
