#!/bin/bash

codes_assert_easy_install() {
    if [[ ${rpm_code_debug:-} ]]; then
        # local environment may have easy-install.pth
        return
    fi
    declare easy=$(find "${codes_dir[pyenv_prefix]}"/lib -name easy-install.pth)
    if [[ $easy ]]; then
        install_err "$easy: packages used python setup.py install instead of pip:
$(cat "$easy")"
    fi
}

codes_cmake() {
    mkdir build
    cd build
    declare t=Release
    if [[ ${CODES_DEBUG_FLAG:-} ]]; then
        t=Debug
    fi
    CLICOLOR=0 cmake -D CMAKE_RULE_MESSAGES:BOOL=OFF -D CMAKE_BUILD_TYPE:STRING="$t" "$@" ..
}

codes_cmake2() {
    declare t=Release
    if [[ ${CODES_DEBUG_FLAG:-} ]]; then
        t=Debug
    fi
    CLICOLOR=0 cmake -S . -B build -D CMAKE_RULE_MESSAGES:BOOL=OFF -D CMAKE_BUILD_TYPE:STRING="$t" "$@"
}

codes_cmake_build() {
    declare target=${1:-}
    declare cmd=( cmake --build build -j$(codes_num_cores) )
    if [[ ${CODES_DEBUG_FLAG:-} ]]; then
        cmd+=( --verbose )
    fi
    CLICOLOR=0 "${cmd[@]}" ${target:+--target $target}
}

codes_cmake_clean() {
    rm -rf build
}

codes_cmake_fix_lib_dir() {
    # otherwise uses ~/.local/lib64
    find . \( -name CMakeLists.txt -o -name \*.cmake \) -print0 | xargs -0 perl -pi -e '/include\(GNUInstallDirs/ && ($_ .= q{
set(CMAKE_INSTALL_LIBDIR "lib" CACHE PATH "Library installation directory." FORCE)
GNUInstallDirs_get_absolute_install_dir(CMAKE_INSTALL_FULL_LIBDIR CMAKE_INSTALL_LIBDIR)
})'
}

codes_curl() {
    install_download "$@"
}

codes_dependencies() {
    install_repo_eval code "$@"
    rpm_code_dependencies_done "$@"
}

codes_dir_setup() {
    declare todo=()
    declare d n p
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
    else
        # common installs pyenv and sets pyenv_prefix
        codes_dir[pyenv_prefix]=$(realpath "$(pyenv prefix)")
    fi
}

codes_download() {
    # If download is an rpm, also installs
    declare repo=$1
    declare qualifier=${2:-}
    declare package=${3:-}
    declare version=${4:-}
    if [[ ! $repo =~ / ]]; then
        repo=radiasoft/$repo
    fi
    if [[ ! $repo =~ ^(ftp|https?): ]]; then
        repo=https://github.com/$repo.git
    fi
    codes_msg "Download: $repo"
    declare manifest=('' '')
    case $repo in
        *.git)
            declare d=$(basename "$repo" .git)
            declare r=--recursive
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
                # transport which doesn't support git
                git clone $r -q "$repo"
                cd "$d"
                git checkout "$qualifier"
                git submodule update --init --recursive
            else
                git clone $r --depth 1 "$repo"
                cd "$d"
            fi
            repo=
            ;;
        *.sh)
            codes_curl "$repo" | bash
            ;;
        *.tar.gz|*.tar.xz|*.tar.bz2|*.tgz)
            declare z s
            case $repo in
                *.bz2)
                    s=tar.bz2
                    z=j
                    ;;
                *.gz)
                    s=tar.gz
                    z=z
                    ;;
                *.tgz)
                    s=tgz
                    z=z
                ;;
                *.xz)
                    s=tar.xz
                    z=J
                    ;;
                *)
                    install_err "PROGRAM ERROR: repo=$repo must match outer case"
                    ;;
            esac
            declare b=$(basename "$repo" ".$s")
            if [[ ${version:-} ]]; then
                manifest=( "$package" "$version" )
            else
                # github tarball
                if [[ $repo =~ ([^/]+)/archive/v([^/]+).$s$ ]]; then
                    if [[ ! $qualifier ]]; then
                        qualifier=${BASH_REMATCH[1]}-${BASH_REMATCH[2]}
                    fi
                # gitlab tarball
                elif [[ $repo =~ /-/archive/v[^/]+/([^/]+)-v([^/]+).$s$ ]]; then
                    : pass
                elif [[ ! $b =~ ^(.+)-([[:digit:]].+)$ ]]; then
                    codes_err "$repo: basename=$b does not match version regex"
                fi
                manifest=( "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" )
            fi
            declare d=${qualifier:-$b}
            declare t=tarball-$RANDOM
            codes_curl -o "$t" "$repo"
            tar xf"$z" "$t"
            rm -f "$t"
            cd "$d"
            ;;
        *.rpm)
            declare b=$(basename "$repo")
            declare n="${b//-*/}"
            if rpm --quiet -q "$n"; then
                echo "$b already installed"
            else
                # not a yum dependency (codes script copies the files)
                install_yum_install "$repo"
            fi
            manifest=(
                "$(rpm -q --queryformat '%{NAME}' "$n")"
                "$(rpm -q --queryformat '%{VERSION}-%{RELEASE}' "$n")"
            )
            ;;
        *)
            codes_err "$repo: unknown repository format; must end in .git, .rpm, .tar.gz, .tgz, .tar.xz, .tar.bz2"
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
    declare file=$1
    install_download "codes/$codes_module/$file" > "$file"
}

codes_epics_make_install() {
    declare epics="${codes_dir[prefix]}"/epics
    declare os=linux-x86_64
    cat <<EOF > configure/RELEASE.local
EPICS_BASE=$epics
${codes_epics_release_local:-}
EOF
    codes_make
    declare -a f=( $(echo bin/"$os"/*) )
    if [[ $f ]]; then
        install -m 555 "${f[@]}" "$epics/bin/$os"
    fi
    declare f t
    for f in lib/"$os"/*; do
        if [[ -L $f ]]; then
            t=$epics/lib/$os/$(basename "$f")
            rm -f "$t"
            ln -s "$(readlink "$f")" "$t"
        else
            install -m 444 "$f" "$epics/lib/$os"
        fi
    done
    declare i=include${codes_epics_include_dir:+/$codes_epics_include_dir}
    install -m 755 -d "$epics/$i"
    install -m 444 "$i"/* "$epics/$i"
    for f in cfg db dbd; do
        if [[ -d $f ]]; then
            install -m 444 "$f"/* "$epics/$f"
        fi
    done
}

codes_err() {
    codes_msg "$@"
    return 1
}

codes_install() {
    declare module=$1
    shift
    declare args=( "$@" )
    declare prev=$(pwd)
    declare d=$HOME/src/radiasoft/codes/$module-$(date -u +%Y%m%d.%H%M%S)
    rm -rf "$d"
    mkdir -p "$d"
    codes_msg "Build: $module"
    codes_msg "Directory: $d"
    cd "$d"
    declare codes_module=$module
    # Needed to setup pyenv (used in codes_dir_setup)
    install_source_bashrc
    declare -A codes_dir=()
    codes_dir_setup
    install_script_eval "codes/$module.sh"
    cd "$prev"
    declare p=$(codes_module_function python_install)
    if [[ $p ]]; then
        codes_msg "Running: $p"
        cd "$d"
        "$p"
        codes_install_python_done
    fi
    declare t=$(codes_module_function test)
    if [[ $t ]]; then
        codes_msg "Running: $t"
        declare p=$PWD
        # python adds cwd to PYTHONPATH so go to a path where
        # cwd won't contain any python that would be added
        install_tmp_dir
        "$t"
        cd "$p"
    fi
    declare d=${codes_dir[prefix]}/lib64
    if [[ -d $d ]]; then
        install_err "$d created, and shouldn't be; see codes_cmake_fix_lib_dir"
    fi
    cd "$prev"
}

codes_install_python_done() {
    declare pp=${codes_dir[pyenv_prefix]}
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
    declare cmd=( make -j$(codes_num_cores) )
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
    declare package=${1:-}
    declare version=${2:-}
    declare repo=${3:-}
    declare pwd=$(pwd)
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

codes_module_function() {
    declare suffix=$1
    declare f=${module//-/_}_$suffix
    if codes_is_function "$f"; then
        echo "$f"
    fi
}

codes_msg() {
    echo "$(date -u +%H:%M:%SZ)" "$@" 1>&2
}

codes_num_cores() {
    # Cache (mostly) to limit install_msg to once (below)
    if [[ ! ${codes_num_cores:-} ]]; then
        if [[ $codes_module =~ ^(opal)$ && $install_virt_virtualbox ]]; then
            # certain codes hang in parallel make inside docker and virtualbox
            # because they run out of memory.
            install_msg 'codes_num_cores: restricting to one core'
            codes_num_cores=1
        else
            codes_num_cores=$(lscpu | perl -n -e 'BEGIN {$r = 1}; /^(?:Socket|Core).*?(\d+)/ && ($r *= $1); END {print($r)}')
        fi
    fi
    echo "$codes_num_cores"
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

codes_python_include_dir() {
    python -c 'import distutils.sysconfig as s; print(s.get_python_inc())'
}

codes_python_lib_dir() {
    python -c 'import sysconfig; print(sysconfig.get_path("purelib"))'
}

codes_python_version() {
    python -c 'import platform; print(platform.python_version())'
}

codes_yum_dependencies() {
    rpm_code_yum_dependencies "$@"
}
