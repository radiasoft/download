#!/bin/bash
codes_dependencies xraylib
codes_download srio/shadow3 e745b4957c8931974634856e80ee0006dc5eb754
#TODO(robnagler) shadow3 doesn't include dependencies
# codes_patch_requirements_txt
python setup.py install
