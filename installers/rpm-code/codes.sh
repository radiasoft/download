#!/bin/bash

_codes_home_local=$HOME/.local

codes_assert_easy_install() {
    local easy=$(find  $(pyenv prefix)/lib -name easy-install.pth)
    if [[ $easy ]]; then

        install_err "$easy: packages used python setup.py install instead of pip:
$(cat "$easy")"
    fi
}
codes_cmake() {
    mkdir build
    cd build
    cmake -DCMAKE_RULE_MESSAGES:BOOL=OFF "$@" ..
}

codes_curl() {
    curl -s -S -L "$@"
}

codes_dependencies() {
    local i
    for i in "$@"; do
        rpm_code_build_depends+=( "rscode-$i" )
    done
    install_repo_eval code "$@"
    codes_touch_sentinel
}


codes_dir() {
    local d=$_codes_home_local/${1:-}
    if [[ ! -d $d ]]; then
        # POSIT: codes are public
        (umask 022 && install -d "$d")
    fi
    if ! codes_is_common; then
        rpm_code_build_exclude_add "$d"
    fi
    echo "$d"
}

codes_dir_bashrc_d() {
    codes_dir etc/bashrc.d
}

codes_dir_bin() {
    codes_dir bin
}

codes_dir_lib() {
    codes_dir lib
}

codes_dir_include() {
    codes_dir include
}

codes_dir_share() {
    codes_dir share
}

codes_download() {
    # If download is an rpm, also installs
    local repo=$1
    local qualifier=${2:-}
    local package=${3:-}
    local version=${4:-}
    if [[ ! $repo =~ / ]]; then
        repo=radiasoft/$repo
    fi
    if [[ ! $repo =~ ^(ftp|https?): ]]; then
        repo=https://github.com/$repo.git
    fi
    codes_msg "Download: $repo"
    case $repo in
        *.git)
            local d=$(basename "$repo" .git)
            local r=--recursive
            if [[ ${codes_download_nonrecursive:-} ]]; then
               r=
            fi
            if [[ -d "$d" && ${codes_download_reuse_git:-} ]]; then
                cd "$d"
                codes_msg "Cleaning: $PWD"
                git clean -dfx
            elif [[ $qualifier ]]; then
                # Don't pass --depth in this case for a couple of reasons:
                # 1) we don't know where the commit is; 2) It might be a simple http
                # transport (synergia.sh) which doesn't support git
                git clone $r -q "$repo"
                cd "$d"
                git checkout "$qualifier"
            else
                git clone $r --depth 1 "$repo"
                cd "$d"
            fi
            local manifest=('' '')
            repo=
            ;;
        *.tar\.gz)
            local b=$(basename "$repo" .tar.gz)
            local d=${qualifier:-$b}
            local t=tarball-$RANDOM
            codes_curl -o "$t" "$repo"
            tar xzf "$t"
            rm -f "$t"
            cd "$d"
            if [[ ! $b =~ ^(.+)-([[:digit:]].+)$ ]]; then
                codes_err "$repo: basename does not match version regex"
            fi
            local manifest=(
                "${BASH_REMATCH[1]}"
                "${BASH_REMATCH[2]}"
            )
            ;;
        *.rpm)
            local b=$(basename "$repo")
            local n="${b//-*/}"
            if rpm --quiet -q "$n"; then
                echo "$b already installed"
            else
                # not a yum dependency (codes script copies the files)
                install_yum_install "$repo"
            fi
            local manifest=(
                "$(rpm -q --queryformat '%{NAME}' "$n")"
                "$(rpm -q --queryformat '%{VERSION}-%{RELEASE}' "$n")"
            )
            ;;
        *)
            codes_err "$repo: unknown repository format; must end in .git, .rpm, .tar.gz"
            ;;
    esac
    if [[ ! ${codes_download_reuse_git:-} ]]; then
        codes_manifest_add_code "${package:-${manifest[0]}}" "${version:-${manifest[1]}}" "$repo"
    fi
    return 0
}

codes_is_common() {
    [[ $codes_module == common ]]
}

codes_is_function() {
    [[ $(type -t "$1") == function ]]
}

codes_download_foss() {
    local path=$1
    shift
    codes_download https://depot.radiasoft.org/foss/"$path" "$@"
}


codes_download_module_file() {
    local file=$1
    install_download "codes/$codes_module/$file" > "$file"
}

codes_err() {
    codes_msg "$@"
    return 1
}

codes_install() {
    local module=$1
    local prev=$(pwd)
    local build_d=$HOME/src/radiasoft/codes/$module-$(date -u +%Y%m%d.%H%M%S)
    rm -rf "$build_d"
    mkdir -p "$build_d"
    codes_msg "Build: $module"
    codes_msg "Directory: $build_d"
    cd "$build_d"
    rpm_code_build_src_dir=( "$build_d" )
    codes_install_sentinel=$build_d/.codes_install
    codes_touch_sentinel
    local codes_module=$module
    install_script_eval "codes/$module.sh"
    local f=${module}_main
    if codes_is_function "$f"; then
        $f
    fi
    cd "$prev"
    if codes_is_common; then
        # create all these directories and own them
        rpm_code_build_include_add \
            "$(codes_dir_bashrc_d)" \
            "$(codes_dir_bin)" \
            "$(codes_dir_lib)" \
            "$(codes_dir_share)"
        return
    fi
    local p=${module}_python_install
    local codes_python_version=2
    if codes_is_function "$p"; then
        # Needed for pyenv
        install_source_bashrc
        local v
        local codes_download_reuse_git=
        local vs=${module}_python_versions
        # No quotes so splits
        for v in ${!vs}; do
            cd "$build_d"
            codes_python_version=$v
            install_not_strict_cmd pyenv activate py"$v"
            "$p" "$v"
            codes_install_add_python
            codes_download_reuse_git=1
        done
    else
        codes_install_add_python
    fi
    cd "$prev"
}

codes_install_add_python() {
    local pp=$(pyenv prefix)
    # This excludes all the top level directories and python2.7/site-packages
    rpm_code_build_exclude_add "$pp"/* "$(codes_python_lib_dir)"
    codes_assert_easy_install
    # note: --newer doesn't work, because some installers preserve mtime
    find "$pp/" ! -name pip-selfcheck.json ! -name '*.pyc' ! -name '*.pyo' \
         \( -type f -o -type l \) -cnewer "$codes_install_sentinel" \
         | rpm_code_build_include_add
}

codes_main() {
    codes_install "$@"
}

codes_make_install() {
    local cmd=( make -j$(codes_num_cores) )
    if [[ $@ ]]; then
        cmd+=( "$@" )
    else
        cmd+=( install )
    fi
    "${cmd[@]}"
}

codes_manifest_add_code() {
    # must supply all three params unless in a git repo
    local package=${1:-}
    local version=${2:-}
    local repo=${3:-}
    local pwd=$(pwd)
    if [[ ! $package ]]; then
        package=$(basename "$pwd")
    fi
    if [[ ! $version ]]; then
        version=$(git rev-parse HEAD)
    fi
    if [[ ! $repo ]]; then
        repo=$(git config --get remote.origin.url)
    fi
    rpm_code_build_desc+="version: $version
source: $repo
build: $pwd
"
}

codes_msg() {
    echo "$(date -u +%H:%M:%SZ)" "$@" 1>&2
}

codes_num_cores() {
    local res=$(grep -c '^core id[[:space:]]*:' /proc/cpuinfo)
    # Use half the cores (likely hyperthreads) except if on TRAVIS
    if [[ ${TRAVIS:-} != true ]]; then
        res=$(( $res / 2 ))
    fi
    if (( $res < 1 )); then
        res=1
    fi
    echo "$res"
}

codes_python_install() {
    # normal python install
    pip install .
    codes_assert_easy_install
}

codes_python_lib_copy() {
    # simple file copies for packages without setup.py
    install -m 644 "$@" $(codes_python_lib_dir)
}

codes_python_lib_dir() {
    python <<'EOF'
import sys
from distutils.sysconfig import get_python_lib as x
sys.stdout.write(x())
EOF
}

codes_touch_sentinel() {
    # Need a new ctime, see find above
    rm -f "$codes_install_sentinel"
    touch "$codes_install_sentinel"
}

codes_yum_dependencies() {
    rpm_code_build_depends+=( "$@" )
    install_yum_install "$@"
}
