#!/bin/bash
#
# Vagrant specific code to radia-run
#
radia_run_main() {
    radia_run_prompt
    exec ./.bivio_vagrant_ssh $radia_run_cmd
}
