#!/bin/bash

openpmdapi_nvidia_main() {
    declare codes_is_nvidia=1
    # warpx 26.07 requires 0.17.0 or newer
    declare openpmdapi_version=0.17.1
    codes_run_main openpmdapi
}
