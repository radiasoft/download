#!/bin/bash
codes_dependencies xraylib
codes_download srio/shadow3
#TODO(robnagler) shadow3 doesn't include requirements.txt
# codes_patch_requirements_txt
codes_python_install
