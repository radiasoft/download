#!/bin/bash
#
# For testing installer
#
unit_test_main() {
    local arg=${1:-** call with arg1 **}
    if [[ $arg != arg1 ]]; then
        install_err "$arg: install_extra_args failed"
    fi
    if ! install_download data1 | grep -s -q value1; then
        install_err 'data1: install_download failed'
    fi
    local sentinel=value$RANDOM
    install_exec echo "$sentinel"
    if ! grep -s -q "$sentinel" "$install_log_file"; then
        install_err "$sentinel: install_exec failed"
    fi
    if [[ ! ${install_verbose:-} ]]; then
        # if install_debug/info is on, this test fails
        sentinel=value$RANDOM
        install_info "$sentinel"
        if grep -s -q "$sentinel" "$install_log_file"; then
            install_err "$sentinel: install_info failed"
        fi
    fi
    sentinel=value$RANDOM
    install_verbose=1 install_info "$sentinel"
    if ! grep -s -q "$sentinel" "$install_log_file"; then
        install_err "$sentinel: install_verbose=1 install_info failed"
    fi
    echo PASSED
    install_url radiasoft/download installers
    install_tmp_dir
    install_script_eval rpm-code/codes.sh
    codes_download container-test
}
