#!/bin/bash

elegant_docs_d=/usr/share/doc/elegant

elegant_docs() {
    sudo install -d 755 "$elegant_docs_d"
    local f d
    for f in defns.rpn LICENSE; do
        codes_download_module_file "$f"
        d=$elegant_docs_d/$f
        sudo install -m 444 "$f" "$d"
        rpm_code_build_install_files+=( "$d" )
    done
}

elegant_rpn_defns() {
    #TODO(robnagler) this isn't right, because elegant isn't python. Just needs to
    # be in bashrc. We need a "post_bashrc_d" or something like that to so we don't
    # collide with beamsim. Needs to be added to home-env first.
    local f=~/.pyenv/pyenv.d/exec/rs-beamsim-elegant.bash
    cat > "$f" <<EOF
#!/bin/bash
export RPN_DEFNS=$elegant_docs_d/defns.rpn
EOF
    rpm_code_build_install_files+=( "$f" )
    rpm_code_build_exclude_add $(dirname "$f")
}

codes_dependencies sdds
codes_download_foss elegant-34.0.1-1.fedora.27.openmpi.x86_64.rpm
rpm_code_build_install_files+=( $(rpm -ql elegant) )
elegant_docs
elegant_rpn_defns
