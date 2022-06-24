#!/bin/bash

codes_assert_easy_install() {
    if [[ ${rpm_code_debug:-} ]]; then
        # local environment may have easy-install.pth
        return
    fi
    local easy=$(find "${codes_dir[pyenv_prefix]}"/lib -name easy-install.pth)
    if [[ $easy ]]; then
        install_err "$easy: packages used python setup.py install instead of pip:
$(cat "$easy")"
    fi
}

codes_cmake() {
    mkdir build
    cd build
    local t=Release
    if [[ ${CODES_DEBUG_FLAG:-} ]]; then
        t=Debug
    fi
    cmake -D CMAKE_RULE_MESSAGES:BOOL=OFF -D CMAKE_BUILD_TYPE:STRING="$t" "$@" ..
}

codes_cmake_build() {
    local cmd=( cmake --build . -j$(codes_num_cores) )
    if [[ ${CODES_DEBUG_FLAG:-} ]]; then
        cmd+=( --verbose )
    fi
    "${cmd[@]}"
}

codes_cmake_fix_lib_dir() {
    # otherwise uses ~/.local/lib64
    find . -name CMakeLists.txt -print0 | xargs -0 perl -pi -e '/include\(GNUInstallDirs/ && ($_ .= q{
set(CMAKE_INSTALL_LIBDIR "lib" CACHE PATH "Library installation directory." FORCE)
GNUInstallDirs_get_absolute_install_dir(CMAKE_INSTALL_FULL_LIBDIR CMAKE_INSTALL_LIBDIR)
})'
}

codes_curl() {
    curl -s -S -L "$@"
}

codes_dependencies() {
    install_repo_eval code "$@"
    rpm_code_dependencies_done "$@"
}

codes_dir_setup() {
    local todo=()
    local d n p
    for n in prefix \
        etc \
        bashrc_d \
        bin \
        lib \
        include \
        share
    do
        case $n in
            bashrc_d)
                p=/etc/bashrc.d
                ;;
            prefix)
                p=
                ;;
            *)
                p=/$n
                ;;
        esac
        d=$HOME/.local$p
        todo+=( $d )
        codes_dir[$n]=$d
    done
    if codes_is_common; then
        install_msg 'creating directories'
        mkdir -p "${todo[@]}"
    fi
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
                git submodule update --init --recursive
            else
                git clone $r --depth 1 "$repo"
                cd "$d"
            fi
            local manifest=('' '')
            repo=
            ;;
        *.tar.gz|*.tar.xz|*.tar.bz2)
            local z s
            case $repo in
                *bz2)
                    s=bz2
                    z=j
                    ;;
                *gz)
                    s=gz
                    z=z
                    ;;
                *xz)
                    s=xz
                    z=J
                    ;;
                *)
                    install_err "PROGRAM ERROR: repo=$repo must match outer case"
                    ;;
            esac
            local b=$(basename "$repo" .tar."$s")
            if [[ ${version:-} ]]; then
                local manifest=( "$package" "$version" )
            else
                # github tarball
                if [[ $repo =~ ([^/]+)/archive/v([^/]+).tar.$s$ ]]; then
                    if [[ ! $qualifier ]]; then
                        qualifier=${BASH_REMATCH[1]}-${BASH_REMATCH[2]}
                    fi
                # gitlab tarball
                elif [[ $repo =~ /-/archive/v[^/]+/([^/]+)-v([^/]+).tar.$s$ ]]; then
                    : pass
                elif [[ ! $b =~ ^(.+)-([[:digit:]].+)$ ]]; then
                    codes_err "$repo: basename=$b does not match version regex"
                fi
                local manifest=( "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" )
            fi
            local d=${qualifier:-$b}
            local t=tarball-$RANDOM

            codes_curl -o "$t" "$repo"
            tar xf"$z" "$t"
            rm -f "$t"
            cd "$d"
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
            codes_err "$repo: unknown repository format; must end in .git, .rpm, .tar.gz, .tar.xz, .tar.bz2"
            ;;
    esac
    if [[ ! ${codes_download_reuse_git:-} ]]; then
        codes_manifest_add_code "${package:-${manifest[0]}}" "${version:-${manifest[1]}}" "$repo"
    fi
    return 0
}

codes_download_foss() {
    codes_download $(install_foss_server)/"$1" "${@:2}"
}

codes_download_proprietary() {
    codes_download $(install_proprietary_server)/"$1" "${@:2}"
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
    shift
    local args=( "$@" )
    local prev=$(pwd)
    local d=$HOME/src/radiasoft/codes/$module-$(date -u +%Y%m%d.%H%M%S)
    rm -rf "$d"
    mkdir -p "$d"
    codes_msg "Build: $module"
    codes_msg "Directory: $d"
    cd "$d"
    local codes_module=$module
    local -A codes_dir=()
    codes_dir_setup
    # Needed for pyenv
    install_source_bashrc
    install_script_eval "codes/$module.sh"
    local f=${module}_main
    if ! codes_is_function "$f"; then
        install_error "function=$f not defined for code=$module"
    fi
    $f ${args[@]+"${args[@]}"}
    cd "$prev"
    local p=${module}_python_install
    if codes_is_function "$p"; then
        local vs=${module}_python_version
        local v=${!vs:-3}
        local n="py$v"
        codes_msg "Building: $n"
        cd "$d"
        install_not_strict_cmd pyenv activate "$n"
        codes_dir[pyenv_prefix]=$(realpath "$(pyenv prefix)")
        "$p" "$v" "$n"
        codes_install_pyenv_done
    fi
    local d=${codes_dir[prefix]}/lib64
    if [[ -d $d ]]; then
        install_err "$d created, and shouldn't be; see codes_cmake_fix_lib_dir"
    fi
    cd "$prev"
}

codes_install_pyenv_done() {
    local pp=${codes_dir[pyenv_prefix]}
    if [[ ! $pp ]]; then
        install_err 'pyenv prefix not working'
    fi
    rm -rf "$pp"/man
    # Ensure pyenv paths are up to date
    # See https://github.com/biviosoftware/home-env/issues/8
    pyenv rehash
    codes_assert_easy_install
}

codes_is_common() {
    rpm_code_is_common "$codes_module"
}

codes_is_function() {
    [[ $(type -t "$1") == function ]]
}

codes_main() {
    codes_install "$@"
}

codes_make() {
    local cmd=( make -j$(codes_num_cores) )
    if [[ $@ ]]; then
        cmd+=( "$@" )
    fi
    "${cmd[@]}"
}

codes_make_install() {
    codes_make "$@" install
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
    rpm_build_desc+="version: $version
source: $repo
build: $pwd
"
}

codes_msg() {
    echo "$(date -u +%H:%M:%SZ)" "$@" 1>&2
}

codes_num_cores() {
    if [[ $codes_module =~ opal|test|graphtool && $install_virt_virtualbox ]]; then
        # certain codes hang in parallel make inside docker and virtualbox
        # because they run out of memory.
        install_msg 'codes_num_cores: restricting to one core'
        echo 1
        return
    fi
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
    install_pip_install .
    codes_assert_easy_install
}

codes_python_lib_copy() {
    # simple file copies for packages without setup.py
    install -m 644 "$@" $(codes_python_lib_dir)
}

codes_python_lib_dir() {
    python -c 'import sysconfig; print(sysconfig.get_path("purelib"))'
}

codes_yum_dependencies() {
    rpm_code_yum_dependencies "$@"
}
