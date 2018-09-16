#!/bin/bash

# Where to install binaries (needed by genesis.sh)
codes_bin_dir=$(dirname "$(pyenv which python)")

# Where to install binaries (needed by genesis.sh)
codes_pylib_dir=$(python -c 'from distutils.sysconfig import get_python_lib as x; print x()')

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
    cmake "$@" ..
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
            if [[ $qualifier ]]; then
                # Don't pass --depth in this case for a couple of reasons:
                # 1) we don't know where the commit is; 2) It might be a simple http
                # transport (synergia.sh) which doesn't support git
                git clone --recursive -q "$repo"
                cd "$d"
                git checkout "$qualifier"
            else
                git clone --recursive --depth 1 "$repo"
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
    codes_manifest_add_code "${package:-${manifest[0]}}" "${version:-${manifest[1]}}" "$repo"
    return 0
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
    local dir=$HOME/src/radiasoft/codes/$module-$(date -u +%Y%m%d.%H%M%S)
    rm -rf "$dir"
    mkdir -p "$dir"
    codes_msg "Build: $module"
    codes_msg "Directory: $dir"
    cd "$dir"
    rpm_code_build_src_dir=( "$dir" )
    codes_install_sentinel=$dir/.codes_install
    codes_touch_sentinel
    local codes_module=$module
    install_script_eval "codes/$module.sh"
    cd "$prev"
    local pp=$(pyenv prefix)
    # This excludes all the top level directories and python2.7/site-packages
    rpm_code_build_exclude_add "$pp"/* "$codes_pylib_dir"
    rpm_code_build_include_add
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
    if [[ ! $(type -t pykern) ]]; then
        return
    fi
    local venv=
    if [[ -n $(find . -name \*.py) ]]; then
        venv=( $(pyenv version) )
        venv=${venv[0]}
    fi
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
    pykern rsmanifest add_code --pyenv="$venv" "$package" "$version" "$repo" "$pwd"
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

codes_patch_requirements_txt() {
    # numpy==1.9.3 is the only version that works with all the codes
    local t=tmp.$$
    grep -v numpy requirements.txt > "$t"
    mv -f "$t" requirements.txt
}

codes_python_install() {
    pip install .
    codes_assert_easy_install
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
