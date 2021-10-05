#! /bin/bash
# -*- coding: utf-8 -*-
#
# Install packages to run travis tests
#
# This free software is released under GNU Affero GPL3
# author: Antonio M. Vigliotti - antoniomaria.vigliotti@gmail.com
# (C) 2016-2021 by SHS-AV s.r.l. - http://www.shs-av.com - info@shs-av.com
#
# READLINK=$(which greadlink 2>/dev/null) || READLINK=$(which readlink 2>/dev/null)
# export READLINK
THIS=$(basename "$0")
TDIR=$(readlink -f $(dirname $0))
<<<<<<< HEAD:zerobug/_travis/travis_install_env.sh
PYPATH=""
for p in $TDIR $TDIR/.. $TDIR/../.. $HOME/venv_tools/bin $HOME/venv_tools/lib $HOME/tools; do
  [[ -d $p ]] && PYPATH=$(find $(readlink -f $p) -maxdepth 3 -name z0librc)
  [[ -n $PYPATH ]] && PYPATH=$(dirname $PYPATH) && break
done
PYPATH=$(echo -e "import os,sys;p=[os.path.dirname(x) for x in '$PYPATH'.split()];p.extend([x for x in os.environ['PATH'].split(':') if x not in p and x.startswith('$HOME')]);p.extend([x for x in sys.path if x not in p]);print(' '.join(p))"|python)
=======
[ $BASH_VERSINFO -lt 4 ] && echo "This script cvt_script requires bash 4.0+!" && exit 4
[[ -d "$HOME/dev" ]] && HOME_DEV="$HOME/dev" || HOME_DEV="$HOME/devel"
PYPATH=$(echo -e "import os,sys;\nTDIR='"$TDIR"';HOME_DEV='"$HOME_DEV"'\nHOME=os.environ.get('HOME');y=os.path.join(HOME_DEV,'pypi');t=os.path.join(HOME,'tools')\ndef apl(l,p,x):\n  d2=os.path.join(p,x,x)\n  d1=os.path.join(p,x)\n  if os.path.isdir(d2):\n   l.append(d2)\n  elif os.path.isdir(d1):\n   l.append(d1)\nl=[TDIR]\nfor x in ('z0lib','zerobug','odoo_score','clodoo','travis_emulator'):\n if TDIR.startswith(y):\n  apl(l,y,x)\n elif TDIR.startswith(t):\n  apl(l,t,x)\nl=l+os.environ['PATH'].split(':')\np=set()\npa=p.add\np=[x for x in l if x and x.startswith(HOME) and not (x in p or pa(x))]\nprint(' '.join(p))\n"|python)
>>>>>>> stash:zerobug/_travis/travis_install_env
[[ $TRAVIS_DEBUG_MODE -ge 8 ]] && echo "PYPATH=$PYPATH"
for d in $PYPATH /etc; do
  if [[ -e $d/z0lib/z0librc ]]; then
    . $d/z0lib/z0librc
    Z0LIBDIR=$d/z0lib
    Z0LIBDIR=$(readlink -e $Z0LIBDIR)
    break
  elif [[ -e $d/z0librc ]]; then
    . $d/z0librc
    Z0LIBDIR=$d
    Z0LIBDIR=$(readlink -e $Z0LIBDIR)
    break
  fi
done
if [[ -z "$Z0LIBDIR" ]]; then
  echo "Library file z0librc not found!"
  exit 72
fi
TESTDIR=$(findpkg "" "$TDIR . .." "tests")
[[ $TRAVIS_DEBUG_MODE -ge 8 ]] && echo "TESTDIR=$TESTDIR"
RUNDIR=$(readlink -e $TESTDIR/..)
[[ $TRAVIS_DEBUG_MODE -ge 8 ]] && echo "RUNDIR=$RUNDIR"
RED="\e[1;31m"
GREEN="\e[1;32m"
CLR="\e[0m"

__version__=1.0.2.99

conf_default() {
  if [[ -z "$PS_TXT_COLOR" ]]; then
    export PS_TXT_COLOR="0;97;40"
    export PS_RUN_COLOR="1;37;44"
    export PS_NOP_COLOR="34;107"
    export PS_HDR1_COLOR="97;42"
    export PS_HDR2_COLOR="30;43"
    export PS_HDR3_COLOR="30;45"
  fi
}

run_traced() {
  [[ :$SHELLOPTS: =~ :xtrace: ]] && set +x
  [[ -z ${Z0_STACK:+_} ]] && export Z0_STACK=0
  ((Z0_STACK=Z0_STACK+2))
  local xcmd="$1" lm="                    "
  local sts=$STS_SUCCESS
  local pfx=
  if [[ $1 =~ ^# ]]; then
    pfx=
  elif [[ ${opt_dry_run:-0} -eq 0 && ( $2 != "nolocal" || $TRAVIS =~ (true|emulate) ) ]]; then
    pfx="${lm:0:$Z0_STACK}\$ "
  else
    pfx="${lm:0:$Z0_STACK}> "
  fi
  if [[ ${opt_dry_run:-0} -eq 0 ]]; then
    if [[ ${opt_verbose:-0} -gt 0 ]]; then
      [[ ${opt_humdrum:-0} -eq 0 && -n "$PS_RUN_COLOR" ]] && echo -en "\e[${PS_RUN_COLOR}m"
      echo "$pfx$xcmd"
      [[ ${opt_humdrum:-0} -eq 0 && -n $PS_NOP_COLOR ]] && echo -en "\e[${PS_NOP_COLOR}m"
    fi
    if [[ ! $1 =~ ^# && ( $2 != "nolocal" || $TRAVIS =~ (true|emulate) ) ]]; then
      eval $xcmd
      sts=$?
    fi
  elif [[ ! $1 =~ ^sleep[[:space:]] ]]; then
    if [[ ${opt_verbose:-0} -gt 0 ]]; then
      echo "$pfx$xcmd"
    fi
    if [[ $1 =~ ^(cd[[:space:]].*|cd)$ ]]; then
      eval "$xcmd" 2>/dev/null
    fi
  fi
  echo -en "\e[0m"
  ((Z0_STACK=Z0_STACK-2))
  [[ :$SHELLOPTS: =~ :xtrace: ]] && set -x
  return $sts
}

cp_n_upd_odoo_conf() {
  local odoo_ver=$(echo $VERSION | grep -Eo '[0-9]*' | head -n1)
  if [ $odoo_ver -ge 10 ]; then
    local tgt=~/.odoorc
    local atgt=~/.openerp_serverrc
  else
    local tgt=~/.openerp_serverrc
    local atgt=
  fi
  [ -f $atgt ] && rm -f $atgt
  [ -f $tgt ] && rm -f $tgt
  if [ "$TRAVIS" == "true" ]; then
    return
  fi
  local t="$TRAVIS_SAVED_HOME/$(basename $tgt)"
  [ -n "$atgt" ] && local at="$TRAVIS_SAVED_HOME/$(basename $atgt)" || local at=
  [ -f $at ] && rm -f $at
  [ -f $t ] && rm -f $t
  return
  local pfx="odoo$odoo_ver"
  local pfx2=odoo
  local sfx=
  local ODOO_LOGFILE="False"
  local confn=/etc/odoo/${pfx}-server.conf
  if [ ! -f $confn ]; then
    confn=/etc/odoo/${pfx}.conf
  fi
  if [ ! -f $confn ]; then
    confn=/etc/odoo/${pfx2}-server.conf
  fi
  if [ ! -f $confn ]; then
    confn=/etc/odoo/${pfx2}.conf
  fi
  if [ ! -f $confn ]; then
    echo "File $confn not found!"
    exit 1
  fi
  touch $tgt
  while IFS=\| read -r line || [ -n "$line" ]; do
    if [[ $line =~ ^data_dir[[:space:]]*=[[:space:]]*.*Odoo$odoo_ver ]]; then
      line=$(echo "$line" | sed -e "s:Odoo$odoo_ver:Odoo-test:")
    elif [[ $line =~ ^logfile[[:space:]]*=[[:space:]]*[0-9A-Za-z]+ ]]; then
      line=$(echo "logfile = $ODOO_LOGFILE")
    elif [[ $line =~ ^pidfile[[:space:]]*=[[:space:]]*.* ]]; then
      line=$(echo "$line" | sed -e "s:odoo$odoo_ver:odoo-test:")
    elif [[ $line =~ ^xmlrpc_port[[:space:]]*=[[:space:]]*[0-9A-Za-z]+ ]]; then
      line="xmlrpc_port = $((18060 + $odoo_ver))"
    elif [[ $line =~ ^NAME=.*odoo$odoo_ver.* ]]; then
      line=$(echo "$line" | sed -e "s:odoo$odoo_ver:odoo-test:")
    elif [[ $line =~ .*odoo${odoo_ver}-server.conf.* ]]; then
      line=$(echo "$line" | sed -e "s:odoo$odoo_ver:odoo-test:")
    elif [[ $line =~ .*$confn.* ]]; then
      line=$(echo "$line" | sed -e "s:$confn:odoo-test:")
    elif [[ $line =~ .*odoo${odoo_ver}-server.pid.* ]]; then
      line=$(echo "$line" | sed -e "s:odoo$odoo_ver:odoo-test:")
    elif [[ $line =~ .*odoo${odoo_ver}-server.log.* ]]; then
      line=$(echo "$line" | sed -e "s:odoo$odoo_ver:odoo-test:")
    elif [[ $line =~ ^server_wide_modules[[:space:]]*=[[:space:]] ]]; then
      line="server_wide_modules = web"
    fi
    echo "$line" >>$tgt
  done <"$confn"
}

git_clone_ocb() {
  local majver prjhome u
  local SRCREPOPATH=
  local ODOO_URL="https://github.com/$REMOTE/$REPO_NAME.git"
  echo -e "\e[${PS_HDR3_COLOR}m### Installing Odoo from $ODOO_URL\e[${PS_TXT_COLOR}m"
  if [[ ! -L ${ODOO_PATH} && ! "$TRAVIS" == "true" ]]; then
    prjhome=$(echo $TRAVIS_HOME_BRANCH | grep -Eo "$TRAVIS_SAVED_HOME/[^/]+")
    majver=$(echo $BRANCH | grep -Eo [0-9]+ | head -n1)
    if [[ -n "$prjhome" ]]; then
      if [[ $REMOTE == "oca" && -d $prjhome/oca$majver ]]; then
        SRCREPOPATH="$prjhome/oca$majver"
      elif [[ ! $REMOTE == "oca" && -d $prjhome/$BRANCH ]]; then
        SRCREPOPATH="$prjhome/$BRANCH"
      elif [[ ! $REMOTE == "oca" && -d $prjhome/odoo && -f $prjhome/odoo/odoo-bin ]]; then
        SRCREPOPATH="$prjhome/odoo"
      fi
    fi
    if [[ -z "$SRCREPOPATH" ]]; then
      if [[ $REMOTE == "oca" && -d $TRAVIS_SAVED_HOME/oca$majver ]]; then
        SRCREPOPATH="$TRAVIS_SAVED_HOME/oca$majver"
      elif [[ ! $REMOTE == "oca" && -d $TRAVIS_SAVED_HOME/$BRANCH ]]; then
        SRCREPOPATH="$TRAVIS_SAVED_HOME/$BRANCH"
      elif [[ ! $REMOTE == "oca" && -d $TRAVIS_SAVED_HOME/odoo && -f $TRAVIS_SAVED_HOME/odoo/odoo-bin ]]; then
        SRCREPOPATH="$TRAVIS_SAVED_HOME/odoo"
      fi
    fi
  fi
  if [[ -n "$SRCREPOPATH" ]]; then
    run_traced "ln -s $SRCREPOPATH ${ODOO_PATH}"
  else
    if [[ $REMOTE == "oca" ]]; then
      run_traced "git clone --depth=50 https://github.com/${REMOTE^^}/$REPO_NAME.git -b $BRANCH ${ODOO_PATH}"
    else
      run_traced "git clone --depth=50 https://github.com/${REMOTE}/$REPO_NAME.git -b $BRANCH ${ODOO_PATH}"
    fi
    run_traced "git --work-tree=${ODOO_PATH} --git-dir=${ODOO_PATH}/.git remote rename origin $REMOTE"
  fi
  if [[ ${TRAVIS_DEBUG_MODE:-0} -gt 2 ]]; then
    for u in $USER odoo openerp postgresql; do
      if [[ -n "$u" ]]; then
        psql -U$u -l &>/dev/null
        [[ $? -eq 0 ]] && psql -U$u -l
      fi
    done
  fi
}

set_pythonpath() {
  # set_pythonpath(toolspath sitecustomize PIP)
  local TOOLS_PATH="${1//,/ }"
  TOOLS_PATH="${TOOLS_PATH//:/ }"
  local FSITE=$2
  local pth PYLIB
  PYLIB=$(echo -e "import os,sys\nfor x in sys.path:\n if os.path.basename(x)=='site-packages':\n  print(x);break"|python)
  if [[ -n "$PYLIB" ]]; then
    if [[ -n "$TOOLS_PATH" && -w $PYLIB ]]; then
      if [[ -f $PYLIB/sitecustomize.py ]]; then
        if grep -q "import sys" $PYLIB/sitecustomize.py; then
          :
        else
          echo 'import sys' >>$PYLIB/sitecustomize.py
        fi
      else
        echo 'import sys' >$PYLIB/sitecustomize.py
      fi
      for pth in $TOOLS_PATH; do
        if grep -q "if '$pth' not in sys.path" $PYLIB/sitecustomize.py; then
          :
        else
          echo "if '$pth' not in sys.path:    sys.path.insert(0, '$pth')" >>$PYLIB/sitecustomize.py
        fi
        if echo ":$PYTHONPATH": | grep -q ":$pth:"; then
          x=${PYTHONPATH//$pth/}
          export PYTHONPATH=${x//::/:}
        fi
      done
      [ "${PYTHONPATH:0:1}" == ":" ] && export $PYTHONPATH=${PYTHONPATH:1}
    fi
    if [[ -n "$FSITE" && -f $FSITE && -w $PYLIB ]]; then
      if [[ -f $PYLIB/sitecustomize.py ]]; then
        if grep -q "import sys" $PYLIB/sitecustomize.py; then
          run_traced "tail $FSITE -n -1 >> $PYLIB/sitecustomize.py"
        else
          run_traced "cat $FSITE >> $PYLIB/sitecustomize.py"
        fi
      else
        run_traced "cp $FSITE $PYLIB"
      fi
      export PYTHONPATH=
    fi
  fi
}

check_pythonpath() {
  # check_pythonpath(path python)
  local TOOLS_PATH="${1//,/ }"
  TOOLS_PATH="${TOOLS_PATH//:/ }"
  local PYTHON=${2:-python}
  local PYVER=$(python --version 2>&1 | grep -Eo "[0-9]+" | head -n1)
  local pth PYLIB
  for pth in $TOOLS_PATH; do
    if [ "$PYVER" == "2" ]; then
      echo -e "import sys\nfor x in sys.path:\n  print x," | $PYTHON | grep -q " $pth "
    else
      echo -e "import sys\nfor x in sys.path:\n  print (x,end=' ')" | $PYTHON | grep -q " $pth "
    fi
    if [ $? -ne 0 ]; then
      echo "Warning: sitecustomize.py without effect! Use PYTHONPATH method"
      [ -n "$PYTHONPATH" ] && export PYTHONPATH=$PYTHONPATH:$pth
      [ -z "$PYTHONPATH" ] && export PYTHONPATH=$pth
    fi
  done
}

install_n_activate_tools() {
  if [[ -d $HOME/tools && $(which travis_run_tests 2>&1 >/dev/null) ]]; then
    [ $opt_verbose -gt 0 ] && echo -e "\e[${PS_RUN_COLOR}m$pfx$xcmd\$ cd $HOME/tools\e[${PS_TXT_COLOR}m"
    pushd $HOME/tools >/dev/null
    [ ${TRAVIS_DEBUG_MODE:-0} -gt 2 ] && x=-pt
    [ ${TRAVIS_DEBUG_MODE:-0} -le 2 ] && x=-qpt
    run_traced "./install_tools.sh $x"
    [ $opt_verbose -gt 0 ] && echo -e "\e[${PS_RUN_COLOR}m$pfx$xcmd\$ . $HOME/venv_tools/activate_tools\e[${PS_TXT_COLOR}m"
    . $HOME/venv_tools/activate_tools
    popd >/dev/null
    [ ${TRAVIS_DEBUG_MODE:-0} -ge 2 ] && echo "PATH=$PATH"
    [ ${TRAVIS_DEBUG_MODE:-0} -ge 2 ] && echo "PYTHONPATH=$PYTHONPATH"
  fi
}

check_4_needing_pkgs() {
  local p x
  NEEDING_PKGS="future configparser os0 z0lib"
  for p in $NEEDING_PKGS; do
    x=${p^^}
    eval $x=$(pip show $p 2>/dev/null | grep "Version" | grep -Eo "[0-9.]+")
    [ ${TRAVIS_DEBUG_MODE:-0} -ge 2 ] && echo "Inner package $p=${!x}"
  done
}

check_installed_pkgs() {
  local p x
  check_4_needing_pkgs
  for p in $NEEDING_PKGS; do
    x=${p^^}
    [[ -z "${!x}" ]] && run_traced "$PIP install $PIP_OPTS -q $p" "nolocal"
  done
  check_4_needing_pkgs
}

cp_coveragerc() {
  run_traced "cp ${HOME}/tools/z0bug_odoo/travis/cfg/.coveragerc ."
  run_traced "sed -Ee \"s|^#? *..TRAVIS_BUILD_DIR./|    $TRAVIS_BUILD_DIR/|\" -i ./.coveragerc"
  run_traced "sed -e \"s|^ *\*.py\$|#&|\" -i ./.coveragerc"
}

OPTOPTS=(h        b          j        K        H           n            q           T       t          V           v)
OPTDEST=(opt_help opt_branch opt_dprj opt_lint opt_humdrum opt_dry_run  opt_verbose opt_regr test_mode opt_version opt_verbose)
OPTACTI=(1        1          1        1        1           1            0           1        1         "*>"        "+")
OPTDEFL=(0        0          0        0        0           0            -1          0        0         ""          -1)
OPTMETA=("help"   "dprj"     "check"  ""       ""          "do nothing" "qiet"      "test"   "test"    "version"   "verbose")
OPTHELP=("this help"
  "Odoo version"
  "execute tests in project dir rather in test dir"
  "do bash, flake8 and pylint checks"
  "humdrum, display w/o colors"
  "do nothing (dry-run)"
  "silent mode"
  "do regression tests"
  "test mode (implies dry-run)"
  "show version"
  "verbose mode")
OPTARGS=(mode)

parseoptargs "$@"
if [[ "$opt_version" ]]; then
  echo "$__version__"
  exit 0
fi
if [[ $opt_help -gt 0 ]]; then
  print_help "Install packages to run travis tests\n if supplied 'oca' executes travis_install_nightly" \
    "(C) 2016-2021 by zeroincombenze(R)\nhttp://wiki.zeroincombenze.org/en/Linux/dev\nAuthor: antoniomaria.vigliotti@gmail.com"
  exit 0
fi

if [[ -z "$TRAVIS_BUILD_DIR" ]]; then
  echo "Invalid environment!"
  exit 1
fi
export PYTHONWARNINGS="ignore"
sts=$STS_SUCCESS
[[ $MQT_DRY_RUN == "1" ]] && opt_dry_run=1
[[ $MQT_VERBOSE_MODE == "1" ]] && opt_verbose=1
[[ $MQT_VERBOSE_MODE == "0" ]] && opt_verbose=0
[[ $TRAVIS_DEBUG_MODE -ne 0 ]] && opt_verbose=1
if [[ ${opt_regr:-0} -gt 0 ]]; then
  LINT_CHECK="0"
  TESTS="1"
fi
if [[ ${opt_lint:-0} -gt 0 ]]; then
  BASH_CHECK="1"
  LINT_CHECK="1"
fi
[[ $TEST_DEPENDENCIES == "1" || $ODOO_TNLBOT == "1" ]] && export TEST="1"
LINT_OR_TEST_CHECK="0"
[[ ${LINT_CHECK:-0} == "1" ]] && LINT_OR_TEST_CHECK="1"
[[ ${LINT_CHECK:-0} == "0" && ${TESTS:-0} == "1" ]] && LINT_OR_TEST_CHECK="1"
conf_default
[[ -z "$MQT_TEST_MODE" ]] && IFS="/" read MQT_TEST_MODE PKGNAME <<<"${TRAVIS_REPO_SLUG}"
MQT_TEST_MODE=${MQT_TEST_MODE,,}
[[ $MQT_TEST_MODE =~ (oca|zero) ]] || MQT_TEST_MODE=zero
[[ -z "$mode" ]] && mode=$MQT_TEST_MODE
if [[ "$MQT_TEST_MODE" == "oca" ]]; then
  run_traced "$TDIR/travis_install_nightly"
  exit $?
fi

export MQT_TEST_MODE=$mode
[[ -z "$PKGNAME" ]] && PKGNAME=$(basename $TRAVIS_BUILD_DIR)
if [[ $TRAVIS_PYTHON_VERSION =~ ^3 ]]; then
  python3 --version &>/dev/null && PYTHON=python3
  [[ $(pip3 --version|grep -Eo "python [23]\.[0-9]"|grep -Eo "[23]"|head -n1) == 3 ]] && PIP=pip3 || PIP="$PYTHON -m pip"
else
  python2 --version &>/dev/null && PYTHON=python2
  [[ -z "$PYTHON" ]] && PYTHON=python
  [[ $(pip2 --version|grep -Eo "python [23]\.[0-9]"|grep -Eo "[23]"|head -n1) == 2 ]] && PIP=pip2 || PIP="$PYTHON -m pip"
fi
export PYTHON PIP
[[ ! $TRAVIS =~ (true|emulate) && -d $HOME/.local && ! "$SYSTEM_SITE_PACKAGES" == "true" ]] && PIP_OPTS="--user" || PIP_OPTS=""
install_n_activate_tools
if [[ -d $HOME/venv_tools ]]; then
  set_pythonpath "$HOME/tools" "$HOME/venv_tools/sitecustomize.py" $PIP
  [ ${TRAVIS_DEBUG_MODE:-0} -ge 2 ] && echo "PATH=$PATH"
  [ ${TRAVIS_DEBUG_MODE:-0} -ge 2 ] && echo "PYTHONPATH=$PYTHONPATH"
else
  echo "!! Error! Directory $HOME/venv_tools not found!"
fi
check_pythonpath "$HOME/tools" $PYTHON
if [ "${TRAVIS_PYTHON_VERSION:0:1}" == "2" ]; then
  echo -e "import sys\nprint 'sys.path=%s' % sys.path\n" | python
else
  echo -e "import sys\nprint('sys.path=%s' % sys.path)\n" | python3
fi
run_traced "$PIP install -q pip --upgrade" "nolocal"
PIPVER=$($PIP --version | grep -Eo [0-9]+ | head -n1)
[ $PIPVER -gt 18 ] && PIP_OPTS="$PIP_OPTS --no-warn-conflicts"
[ $PIPVER -gt 19 ] && PIP_OPTS="$PIP_OPTS --use-feature=2020-resolver"
check_installed_pkgs
LISTREQ=$(which list_requirements 2>/dev/null)
if [[ -z "$LISTREQ" ]]; then
  if [ -n "$YML_mgrodoo" ]; then
    LISTREQ=$(dirname $YML_mgrodoo)/list_requirements
  else
    [ -f $HOME/tools/clodoo/list_requirements ] && LISTREQ=$HOME/tools/clodoo/list_requirements || LISTREQ=list_requirements
  fi
fi
LISA=$(which lisa 2>/dev/null)
if [[ -z "$LISA" ]]; then
  if [ -n "$YML_lisa" ]; then
    LISA=$YML_lisa
  else
    LISA=$HOME/tools/lisa/lisa
    [ -f $TDIR/../../lisa/lisa ] && LISA=$($READLINK -e $TDIR/../../lisa/lisa)
    [ -f $TDIR/../lisa/lisa ] && LISA=$($READLINK -e $TDIR/../lisa/lisa)
  fi
fi
VEM=$(which vem 2>/dev/null)
if [[ -z "$VEM" ]]; then
  VEM=$HOME/tools/python_plus/vem
  [ -f $TDIR/../../python_plus/python_plus ] && VEM=$($READLINK -e $TDIR/../../python_plus/python_plus)
  [ -f $TDIR/../python_plus/python_plus ] && VEM=$($READLINK -e $TDIR/../python_plus/python_plus)
fi
if [ $opt_verbose -gt 0 ]; then
  echo -e "\e[${PS_HDR3_COLOR}m$0 $__version__\e[${PS_TXT_COLOR}m"
  echo -e "\e[${PS_TXT_COLOR}m\$ alias pip=$(which $PIP).$($PIP --version)\e[${PS_HDR3_COLOR}m"
  echo -e "\e[${PS_TXT_COLOR}m\$ alias lisa=$LISA.$($LISA -V)\e[${PS_HDR3_COLOR}m"
  echo -e "\e[${PS_TXT_COLOR}m\$ alias vem=$VEM.$($VEM -V)\e[${PS_HDR3_COLOR}m"
  # echo -e "\e[${PS_TXT_COLOR}m\$ alias manage_odoo=$MGRODOO.$($MGRODOO -V)\e[${PS_HDR3_COLOR}m"
  echo -e "\e[${PS_TXT_COLOR}m\$ alias list_requirements=$LISTREQ.$($LISTREQ -V 2>&1)\e[${PS_HDR3_COLOR}m"
  echo -e "\e[${PS_TXT_COLOR}m\$ TRAVIS_DEBUG_MODE=$TRAVIS_DEBUG_MODE\e[${PS_HDR3_COLOR}m"
  echo -e "\e[${PS_TXT_COLOR}m\$ MQT_TEST_MODE=$MQT_TEST_MODE\e[${PS_HDR3_COLOR}m"
  [ "$MQT_TEST_MODE" == "tools" ] && echo -e "\e[${PS_TXT_COLOR}m# PATH=$PATH\e[${PS_HDR3_COLOR}m"
  [ "$MQT_TEST_MODE" == "tools" ] && echo -e "\e[${PS_TXT_COLOR}m# OPTS=$OPTS\e[${PS_HDR3_COLOR}m"
  [ -n "$PYPI_CACHED" ] && echo -e "\e[${PS_TXT_COLOR}m# PYPI_CACHED=$PYPI_CACHED\e[${PS_HDR3_COLOR}m"
  echo -e "\e[${PS_TXT_COLOR}m# PYTHONPATH=$PYTHONPATH\e[${PS_HDR3_COLOR}m"
  if [ "${TRAVIS_PYTHON_VERSION:0:1}" == "3" ]; then
    echo -e "import sys\nprint('sys.path=%s' % sys.path)\n" | python3
  else
    echo -e "import sys\nprint 'sys.path=%s' % sys.path\n" | python
  fi
fi
# Build secure environment (python2)
echo -e "\e[${PS_HDR3_COLOR}m### Build Secure Environment\e[${PS_TXT_COLOR}m"
for p in build-essential libssl-dev libffi-dev; do
  [[ "$TRAVIS" == "false" ]] || eval $LISA status -q $p
  [[ $? -ne 0 ]] && run_traced "$LISA install $p" "nolocal"
done
if [[ $TRAVIS != "false" ]]; then
  for p in urllib3[secure] cryptography pyOpenSSL idna certifi; do
    run_traced "$PIP install $PIP_OPTS $p --upgrade --ignore-installed" "nolocal"
  done
fi
[ -z "${VERSION}" ] && VERSION="$opt_branch"
[ -z "${ODOO_BRANCH}" ] && export ODOO_BRANCH=${VERSION}
: ${MQT_TEMPLATE_DB:="openerp_template"}
: ${MQT_TEST_DB:="openerp_test"}
: ${ODOO_REPO:="odoo/odoo"}
IFS="/" read -a REPO <<<"${ODOO_REPO}"
export REMOTE="${REPO[0],,}"
export REPO_NAME="${REPO[1]}"
export BRANCH="${ODOO_BRANCH}"
[[ $BRANCH == *"/"* ]] && export BRANCH=${BRANCH/\//-}
export ODOO_PATH=${HOME}/$REPO_NAME-$ODOO_BRANCH

if [[ "$MQT_TEST_MODE" == "tools" ]]; then
  echo -e "\e[${PS_HDR3_COLOR}m### Build Tools Environment\e[${PS_TXT_COLOR}m"
  [[ -z "$PYPI_CACHED" || $TRAVIS != "false" ]] && run_traced "$VEM amend -D"
  if [ "${ODOO_REPO}" != "odoo/odoo" ]; then
    git_clone_ocb
  fi
  if [ $opt_verbose -gt 0 ]; then
    echo "Content of ${HOME}:"
    ls -l ${HOME}
    echo "Content of ${TRAVIS_BUILD_DIR}:"
    ls -l ${TRAVIS_BUILD_DIR}
    if [[ -d $HOME/venv_tools ]]; then
      echo "Content of ${HOME}/venv_tools:"
      ls -l ${HOME}/venv_tools
    else
      echo "Content of ${HOME}/dev:"
      ls -l ${HOME}/dev
    fi
  fi
  exit $sts
else
  if [[ "${LINT_CHECK:-1}" != "0" ]]; then
    NODE_VER=$(node --version | grep -Eo "[0-9]+" | head -n1)
    if [ $NODE_VER -lt 6 -a -f "${HOME}/.nvm/nvm.sh" ]; then
      [ ${TRAVIS_DEBUG_MODE:-0} -gt 2 ] && echo "1> node version: $NODE_VER"
      CURRENT_NODE=$(which node)
      source ${HOME}/.nvm/nvm.sh
      nvm install 6
      run_traced "ln -sf $(nvm which 6) $CURRENT_NODE"
      [ ${TRAVIS_DEBUG_MODE:-0} -gt 2 ] && echo "2> node version: $(node --version)"
    fi
    echo -e "\e[${PS_HDR3_COLOR}m### Build Test Environment\e[${PS_TXT_COLOR}m"
    run_traced "$PIP install $PIP_OPTS --upgrade --pre --no-deps git+https://github.com/OCA/pylint-odoo.git" "nolocal" # To use last version ever
    if [[ $TRAVIS =~ (true|emulate) ]]; then
      run_traced "npm install -g eslint"
    else
      run_traced "npm install eslint"
    fi
  fi
  if [[ $TESTS == "1" ]]; then
    echo -e "\e[${PS_HDR3_COLOR}m### Install Packages for Base Environment\e[${PS_TXT_COLOR}m"
    if [[ $UNIT_TEST != "0" ]]; then
      NODE_VER=$(node --version | grep -Eo "[0-9]+" | head -n1)
      if [[ $NODE_VER -lt 6 ]]; then
        x=$(which nodejs 2>/dev/null)
        [[ -z "$x" ]] && x=$(which node 2>/dev/null)
        run_traced "ln -s $x $HOME/tools/z0bug_odoo/travis/node"
        [[ $opt_verbose -gt 0 ]] && echo "3> node version: $(node --version)"
      fi
      if [[ $TRAVIS =~ (true|emulate) ]]; then
        run_traced "npm install -g less@3.0.4 less-plugin-clean-css"
        x=$(find $(npm bin -g 2>/dev/null) -name lessc 2>/dev/null)
        [[ -n "$x" ]] && run_traced "ln -s $x $HOME/tools/z0bug_odoo/travis/lessc"
      else
        run_traced "npm install less@3.0.4 less-plugin-clean-css"
        x=$(find $(npm bin) -name lessc 2>/dev/null)
        [[ -n "$x" ]] && run_traced "ln -s $x $HOME/tools/z0bug_odoo/travis/lessc"
      fi
      lessc --version
    fi
    [[ -z "${WKHTMLTOPDF_VERSION}" ]] && export WKHTMLTOPDF_VERSION="0.12.5"
    [[ -n "$(which example.com 2>/dev/null)" ]] && CUR_WKHTMLTOPDF_VERSION=$(wkhtmltopdf --version | grep -Eo [0-9.]+ | head -n1) || CUR_WKHTMLTOPDF_VERSION=
    if [[ "$CUR_WKHTMLTOPDF_VERSION" == "$WKHTMLTOPDF_VERSION" ]]; then
      [ $opt_verbose -gt 0 ] && echo "Installed version of wkhtmltopdf is $WKHTMLTOPDF_VERSION"
    else
      [[ $opt_verbose -gt 0 ]] && echo "Installing wkhtmltopdf version $WKHTMLTOPDF_VERSION (current is $CUR_WKHTMLTOPDF_VERSION)"
      vem install "wkhtmltopdf==$WKHTMLTOPDF_VERSION"
      CUR_WKHTMLTOPDF_VERSION=$(wkhtmltopdf --version | grep -Eo [0-9.]+ | head -n1)
      [[ $opt_verbose -gt 0 ]] && echo "Current version of wkhtmltopdf is $CUR_WKHTMLTOPDF_VERSION"
    fi
    if [[ "${WEBSITE_REPO}" == "1" ]]; then
      if [ -f $HOME/.rvm/scripts/rvm ]; then
        source $HOME/.rvm/scripts/rvm
      elif [ -f /usr/local/rvm/scripts/rvm ]; then
        source /usr/local/rvm/scripts/rvm
      else
        echo "File rvm not found! rvm should be not work!"
      fi
      run_traced "rvm install ruby --latest"
      run_traced "rvm use ruby --latest"
      # Uninstall current versions to be sure that
      # the correct version will be installed
      run_traced "gem uninstall -aIx bootstrap-sass compass sass"
      run_traced "gem install compass bootstrap-sass"
    fi
    if [[ $UNIT_TEST != "0" ]]; then
      # Update PhantomJS (v10 compat)
      if [[ "${PHANTOMJS_VERSION}" != "OS" ]]; then
        run_traced "npm install --prefix ${TRAVIS_BUILD_DIR} \"phantomjs-prebuilt@${PHANTOMJS_VERSION:=latest}\""
        run_traced "ln -s \"${TRAVIS_BUILD_DIR}/node_modules/phantomjs-prebuilt/lib/phantom/bin/phantomjs\" \"${HOME}/tools/z0bug_odoo/travis/phantomjs\""
      fi
      if [ "${CHROME_TEST}" == "1" ]; then
        run_traced "google-chrome --version"
      fi
    fi
    if [[ "$PKGNAME" == "OCB" ]]; then
      echo -e "\e[${PS_HDR3_COLOR}m### Tested repository is OCB\e[${PS_TXT_COLOR}m"
      if [[ $TRAVIS =~ (true|emulate) ]]; then
        run_traced "ln -s ${TRAVIS_BUILD_DIR} ${ODOO_PATH}"
      elif [ ! -L ${ODOO_PATH} ]; then
        run_traced "ln -s ${TRAVIS_BUILD_DIR} ${ODOO_PATH}"
      fi
    else
      git_clone_ocb
    fi
  fi
  if [[ $TESTS != "1" ]]; then
    [[ "$PKGNAME" == "OCB" ]] && ocb_dir='.' || ocb_dir=${ODOO_PATH}
    if [[ -z "$PYPI_CACHED" || $TRAVIS != "false" ]]; then
      reqs=$(find $ocb_dir -name requirements.txt | tr "\n" ",")
      run_traced "$VEM amend -DO $ODOO_BRANCH -r $reqs"
    fi
    cp_coveragerc
    if [[ $TRAVIS =~ (true|emulate) ]]; then
      if [[ $opt_verbose -gt 0 ]]; then
        echo "- reqs=\$($LISTREQ -b$VERSION -p$ocb_dir -t python -s ' ' -qBTR)"
        reqs="$($LISTREQ -b$VERSION -p$ocb_dir -t python -s ' ' -qBTR)"
        reqs=$(echo "$reqs" | tr " " "\n" | sort | tr "\n" " ")
        for pkg in $reqs; do
          v=$($PIP show $pkg | grep "^[Vv]ersion" | awk '{print $2}')
          echo "-- $pkg $v"
        done
      fi
    fi
  else
    mkdir -p ${HOME}/dependencies
    cp_n_upd_odoo_conf
    run_traced "clone_oca_dependencies"
    sts=$?
    if [[ $sts -ne 0 ]]; then
      echo "- Error cloning dependencies"
      exit $sts
    fi
    if [[ "$PKGNAME" == "OCB" ]]; then
      ocb_dir='.'
      dependencies_dir=${HOME}/dependencies
    else
      ocb_dir=${ODOO_PATH}
      dependencies_dir="$TRAVIS_BUILD_DIR ${HOME}/dependencies"
    fi
    if [[ -z "$PYPI_CACHED" || $TRAVIS != "false" ]]; then
      run_traced "$VEM amend -DO $ODOO_BRANCH -d $dependencies_dir"
    fi
    cp_coveragerc
    if [[ $ODOO_TEST_SELECT == "APPLICATIONS" ]]; then
      if [[ -f "${TRAVIS_BUILD_DIR}/addons/website/tests/test_crawl.py" ]]; then
        run_traced "sed -i \"s/self.url_open(url)/self.url_open(url, timeout=100)/g\" ${TRAVIS_BUILD_DIR}/addons/website/tests/test_crawl.py"
      elif [[ -f "${ODOO_PATH}/addons/website/tests/test_crawl.py" ]]; then
        run_traced "sed -i \"s/self.url_open(url)/self.url_open(url, timeout=100)/g\" ${ODOO_PATH}/addons/website/tests/test_crawl.py"
      fi
    elif [[ $ODOO_TEST_SELECT == "LOCALIZATION" ]]; then
      if [[ -f "${TRAVIS_BUILD_DIR}/addons/account/__manifest__.py" ]]; then
        run_traced "sed -i \"/'_auto_install_l10n'/d\" ${TRAVIS_BUILD_DIR}/addons/account/__manifest__.py"
      elif [[ -f "${ODOO_PATH}/addons/account/__manifest__.py" ]]; then
        run_traced "sed -i \"/'_auto_install_l10n'/d\" ${ODOO_PATH}/addons/account/__manifest__.py"
      elif [[ -f "${TRAVIS_BUILD_DIR}/addons/account/__openerp__.py" ]]; then
        run_traced "sed -i \"/'_auto_install_l10n'/d\" ${TRAVIS_BUILD_DIR}/addons/account/__openerp__.py"
      elif [[ -f "${ODOO_PATH}/addons/account/__openerp__.py" ]]; then
        run_traced "sed -i \"/'_auto_install_l10n'/d\" ${ODOO_PATH}/addons/account/__openerp__.py"
      fi
    fi
    if [[ -f "${TRAVIS_BUILD_DIR}/odoo/tests/common.py" ]]; then
      run_traced "sed -i \"s/'phantomjs'/'disable_phantomjs'/g\" ${TRAVIS_BUILD_DIR}/odoo/tests/common.py"
    elif [[ -f "${ODOO_PATH}/odoo/tests/common.py" ]]; then
      run_traced "sed -i \"s/'phantomjs'/'disable_phantomjs'/g\" ${ODOO_PATH}/odoo/tests/common.py"
    fi
    if [[ $opt_verbose -gt 0 ]]; then
      echo "Content of ${HOME}:"
      ls -l ${HOME}
      echo "Content of ${TRAVIS_BUILD_DIR}:"
      ls -l ${TRAVIS_BUILD_DIR}
      if [ ${TRAVIS_DEBUG_MODE:-0} -ge 2 -a -n "${ODOO_PATH}" ]; then
        echo "Content of ${ODOO_PATH}:"
        ls -l ${ODOO_PATH}/
      fi
      echo "Content of ${HOME}/dependencies:"
      ls -l ${HOME}/dependencies
    fi
  fi
fi
echo -e "\e[${PS_TXT_COLOR}m"
exit $sts
