#! /bin/bash
# -*- coding: utf-8 -*-
#
# Upgrade bash script with z0lib odoorc travisrc libraries
#
# This free software is released under GNU Affero GPL3
# author: Antonio Maria Vigliotti - antoniomaria.vigliotti@gmail.com
# (C) 2016-2021 by SHS-AV s.r.l. - http://www.shs-av.com - info@shs-av.com
#
# READLINK=$(which greadlink 2>/dev/null) || READLINK=$(which readlink 2>/dev/null)
# export READLINK
THIS=$(basename "$0")
TDIR=$(readlink -f $(dirname $0))
<<<<<<< HEAD:wok_code/cvt_script.sh
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
>>>>>>> stash:wok_code/cvt_script
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

<<<<<<< HEAD:wok_code/cvt_script.sh
__version__=1.0.2.2
=======
__version__=1.0.2.5
>>>>>>> stash:wok_code/cvt_script

#//Only human upgradable code/
# blk1 => z0librc
# blk2 => odoorc
# blk3 => travisrc
# blk4 => zarrc
# blk8 => TESTDIR= ...
# blk9 => z0testrc

parse_blk_2() {
  if [ $prc -lt 2 ]; then
    prc=2
    if [ $opt_oeLib -ne 0 -a $opt_UT -eq 0 ]; then
      blk_2 "$fntmp"
      empty=0
    fi
  fi
}

parse_blk_3() {
  if [ $prc -lt 3 ]; then
    prc=3
    if [ $opt_tjLib -ne 0 -a $opt_UT -eq 0 ]; then
      blk_3 "$fntmp"
      empty=0
    fi
  fi
}

parse_blk_4() {
  if [ $prc -lt 4 ]; then
    prc=5
    if [ $opt_zLib -ne 0 -a $opt_UT -eq 0 ]; then
      blk_4 "$fntmp"
      empty=0
    fi
  fi
}

parse_blk_8() {
  if [ $prc -lt 8 ]; then
    prc=8
    if [ $opt_UT -ne 0 -o $opt_Test -ne 0 ]; then
      blk_8 "$fntmp"
      empty=0
    fi
  fi
}

parse_blk_9() {
  if [ $prc -lt 9 ]; then
    prc=9
    if [ $opt_UT -ne 0 ]; then
      blk_9 "$fntmp"
      empty=0
    fi
  fi
}

cvt_file() {
  # cvt_file(file)
  # global empty prc
  local f1=$1
  local fntmp=$f1.tmp
  local bakfn=$f1.bak
  local x y line line_ver
  local state=0
  sts=$STS_SUCCESS
  prc=0
  if [[ -n "$f1" ]]; then
    if [[ -x "$f1" ]]; then
      OPTS_JOZ=
      if [ $opt_tjLib -ne 0 ]; then
        OPTS_J="-J"
        OPTS_JOZ=${OPTS_JOZ}J
      else
        OPTS_J=
      fi
      if [ $opt_oeLib -ne 0 ]; then
        OPTS_O="-O"
        OPTS_JOZ=${OPTS_JOZ}O
      else
        OPTS_O=
      fi
      if [ $opt_zLib -ne 0 ]; then
        OPTS_Z="-Z"
        OPTS_JOZ=${OPTS_JOZ}Z
      else
        OPTS_Z=
      fi
      [[ -n "$OPTS_JOZ" ]] && OPTS_JOZ="-$OPTS_JOZ"
      local incl=0
      empty=0
      susp=0
      break_susp=""
      rm -f $fntmp
      while IFS= read -r line || [[ -n "$line" ]]; do
        while [[ "${line: -1}" == " " ]]; do line="${line:0:-1}"; done
        [[ susp -lt 0 && $line =~ $break_susp ]] && ((susp=-susp)) && break_susp=""
        [[ susp -gt 0 ]] && ((susp--)) && continue
        if [[ $prc -lt 10 && $line =~ ^__version__=.* ]]; then
          if [ $opt_keep -ne 0 ]; then
            line_ver="$line"
          elif [ $opt_lev3 -eq 0 ]; then
            x=$(echo $line | grep -Eo [0-9]+\.[0-9]+\.[0-9]+\(\.[0-9]*\)? | awk -F. '{print $4}')
            ((x++))
            y="$(echo $line | grep -Eo [0-9.]+ | awk -F. '{print $1"."$2"."$3}')"
            line_ver="__version__=$y.$x"
          else
            x=$(echo $line | grep -Eo [0-9]+\.[0-9]+\.[0-9]+ | awk -F. '{print $3}')
            ((x++))
            y="$(echo $line | grep -Eo [0-9.]+ | awk -F. '{print $1"."$2}')"
            line_ver="__version__=$y.$x"
          fi
          if [ $prc -eq 0 ]; then
            [[ $opt_keep -ne 0 ]] && echo "$line_ver" >>$fntmp
            continue
          fi
        fi
        if [[ $line =~ ^if.*\$opt_help.*gt.*then$ ]]; then
          echo "if [[ \$opt_help -gt 0 ]]; then" >>$fntmp
        elif [[ $line =~ ^if.*\$opt_version.*then$ ]]; then
          echo "if [[ \"\$opt_version\" ]]; then" >>$fntmp
        elif [[ $line =~ ^#[^A-Za-z09_]*Enable.auto.upgrade.code.* ]]; then
          echo "$line" >>$fntmp
          incl=0
        elif [[ $line =~ ^#[^A-Za-z09_]*Only.human.upgradable.code.* ]]; then
          echo "$line" >>$fntmp
          incl=1
        elif [ $incl -eq 1 ]; then
          echo "$line" >>$fntmp
        elif [ $prc -eq 0 ]; then
<<<<<<< HEAD:wok_code/cvt_script.sh
          if [[ $line =~ ^THIS=..basename || $line =~ ^#?.*export.READLINK= || $line =~ ^#?.*READLINK= ]]; then
=======
          if [[ $line =~ ^THIS=..basename || $line =~ ^#?.?export.READLINK= || $line =~ ^#?.?READLINK= ]]; then
>>>>>>> stash:wok_code/cvt_script
            prc=1
            blk_1 "$fntmp"
            empty=0
            susp=-3
            break_susp="^if ..? -z ..Z0LIBDIR. ..?; then"
          else
            echo "$line" >>$fntmp
          fi
        elif [[ $prc -ge 1 && $prc -le 9 ]]; then
          if [[ $line =~ ^ODOOLIBDIR.*findpkg.*odoorc ]]; then
            parse_blk_2
            if [ $opt_oeLib -eq 0 -a $opt_nowarn -eq 0 ]; then
              echo "Warning: found Odoo library statements w/o -O switch"
              ToRepeat="$ToRepeat opt_oeLib=1"
            fi
          elif [[ $line =~ ^TRAVISLIBDIR.*findpkg.*travisrc.* ]]; then
            if [ $prc -lt 2 ]; then
              parse_blk_2
            fi
            parse_blk_3
            if [ $opt_tjLib -eq 0 -a $opt_nowarn -eq 0 ]; then
              echo "Warning: found Travis library statements w/o -J switch"
              ToRepeat="$ToRepeat opt_tjLib=1"
            fi
          elif [[ $line =~ ^ZARLIB.*findpkg.*zarrc.* ]]; then
            if [ $prc -lt 2 ]; then
              parse_blk_2
            fi
            if [ $prc -lt 3 ]; then
              parse_blk_3
            fi
            parse_blk_4
            if [ $opt_zLib -eq 0 ]; then
              echo "Warning: found Zar library w/o -Z switch"
              ToRepeat="$ToRepeat opt_zLib=1"
            fi
          elif [[ $line =~ ^TESTDIR.*findpkg.*TDIR.* ]]; then
            if [ $prc -lt 2 ]; then
              parse_blk_2
            fi
            if [ $prc -lt 3 ]; then
              parse_blk_3
            fi
            if [ $prc -lt 4 ]; then
              parse_blk_4
            fi
            if [ $opt_UT -ne 0 -o $opt_Test -ne 0 ]; then
              parse_blk_8
            elif [ $opt_Test -eq 0 -a $opt_nowarn -eq 0 ]; then
              echo "Warning: found statements to remove w/o -T switch"
              ToRepeat="$ToRepeat opt_Test=1"
            fi
          elif [[ $line =~ ^Z0TLIBDIR.*findpkg.*z0testrc.* ]]; then
            if [ $prc -lt 2 ]; then
              parse_blk_2
            fi
            if [ $prc -lt 3 ]; then
              parse_blk_3
            fi
            if [ $prc -lt 4 ]; then
              parse_blk_4
            fi
            if [ $prc -lt 8 ]; then
              parse_blk_8
            fi
            parse_blk_9
            if [[ $opt_UT -eq 0 ]]; then
              echo "Warning: found Zerobug library w/o -U switch"
              ToRepeat="$ToRepeat opt_UT=1"
            fi
          elif [[ $line =~ ^__version__.* || $line =~ ^[a-zA_Z0-9_]+[:space:]*\( ]]; then
            if [ $prc -lt 2 ]; then
              parse_blk_2
            fi
            if [ $prc -lt 3 ]; then
              parse_blk_3
            fi
            if [ $prc -lt 4 ]; then
              parse_blk_4
            fi
            if [ $prc -lt 8 ]; then
              parse_blk_8
            fi
            if [ $prc -lt 9 ]; then
              parse_blk_9
            fi
            if [ $empty -eq 0 ]; then
              echo "" >>$fntmp
            fi
            echo "$line_ver" >>$fntmp
            prc=10
            if ! [[ $line =~ ^__version__.* ]]; then
              echo "$line" >>$fntmp
            fi
          else
            :
          fi
        elif [[ $line =~ ^parseoptargs ]]; then
          echo "parseoptargs \"\$@\"" >>$fntmp
          state=1
        elif [[ $state == "1" && $line =~ ^\ +print_help ]]; then
          echo "$line" >>$fntmp
          state=2
        elif [[ $state == "2" ]]; then
          if [ -n "${COPY[$opt_id]}" ]; then
            echo "  \"${COPY[$opt_id]}\"" >>$fntmp
          else
            echo "$line" >>$fntmp
          fi
          state=0
        elif [ $prc -eq 10 ]; then
          if [[ $line =~ ^Z0BUG_init ]]; then
            prc=11
            blk_11 "$fntmp"
            empty=0
          elif [[ $line =~ ^opts_travis ]]; then
            prc=21
            blk_21 "$fntmp"
          elif [[ $line =~ ^TCONF=.* ]]; then
            :
          else
            echo "$line" >>$fntmp
          fi
        elif [ $prc -eq 11 ]; then
          if [ -z "$line" ]; then
            prc=12
            echo "$line" >>$fntmp
          elif [[ $line =~ ^UT1?_LIST=.* ]]; then
            prc=12
            echo "$line" >>$fntmp
          else
            :
          fi
        elif [ $prc -eq 12 ]; then
          if [[ $line =~ ^.*type.*Z0BUG_setup.*function.* ]]; then
            prc=13
            blk_13 "$fntmp"
            empty=0
          elif [[ $line =~ ^Z0BUG_main_file.* ]]; then
            blk_13 "$fntmp"
            prc=14
            blk_14 "$fntmp"
            empty=0
          else
            echo "$line" >>$fntmp
          fi
        elif [ $prc -eq 13 ]; then
          if [[ $line =~ ^.*type.*Z0BUG_setup.*function.* ]]; then
            :
          elif [[ $line =~ ^Z0BUG_main_file.* ]]; then
            prc=14
            blk_14 "$fntmp"
            empty=0
          elif [[ $line =~ ^#[^A-Za-z09_]End.Include.Block.* ]]; then
            echo "$line" >>$fntmp
            incl=0
          elif [[ $line =~ ^#[^A-Za-z09_]Follow.code.must.be.executed.* ]]; then
            echo "$line" >>$fntmp
            incl=2
          elif [ $incl -eq 2 ]; then
            echo "$line" >>$fntmp
          fi
        elif [ $prc -eq 14 ]; then
          :
        elif [ $prc -eq 21 ]; then
          if [[ $line =~ ^init_travis ]]; then
            echo "$line" >>$fntmp
            prc=22
          elif [[ $line =~ ^#[^A-Za-z09_]End.Include.Block.* ]]; then
            echo "$line" >>$fntmp
            incl=0
          elif [[ $line =~ ^#[^A-Za-z09_]Follow.code.must.be.executed.* ]]; then
            echo "$line" >>$fntmp
            incl=2
          elif [ $incl -eq 2 ]; then
            echo "$line" >>$fntmp
          fi
        elif [ "${line:0:1}" == "#" ]; then
          echo "$line" >>$fntmp
          empty=0
        elif [ -z "$line" ]; then
          [[ $empty -le 2 ]] && echo "$line" >>$fntmp
          ((empty++))
        else
          echo "$line" >>$fntmp
          empty=0
        fi
      done <$f1
    else
      echo "File $f1 not found or not executable!"
      sts=2
    fi
  fi
  if [ -f $fntmp -a -z "$ToRepeat" ]; then
    if [ $opt_verbose -eq 0 -a $opt_yes -ne 0 ]; then
      diff -q $f1 $fntmp &>/dev/null
    else
      diff --suppress-common-line -y $f1 $fntmp
      # diff -y $f1 $fntmp
    fi
    if [ $? -eq 0 ]; then
      dummy='q'
    elif [ $opt_dry_run -ne 0 ]; then
      dummy='n'
    elif [ $opt_yes -ne 0 ]; then
      dummy='y'
    else
      read -p "Confirm (Y/N)? " dummy
    fi
    if [ "$dummy" == "Y" -o "$dummy" == "y" ]; then
      cp -p $f1 $bakfn
      mv $fntmp $f1
      chmod +x $f1
      if [ $opt_verbose -gt 0 ]; then
        echo "File $f1 upgraded"
      fi
    else
      rm -f $fntmp
      if [ $opt_verbose -gt 0 ]; then
        if [ "$dummy" == "q" ]; then
          echo "Script $1 already upgraded"
        else
          echo "Upgrade of $f1 discarded!"
        fi
      fi
    fi
  fi
  return $sts
}

blk_1() {
  cat <<EOF >>$1
# READLINK=\$(which greadlink 2>/dev/null) || READLINK=\$(which readlink 2>/dev/null)
# export READLINK
THIS=\$(basename "\$0")
TDIR=\$(readlink -f \$(dirname \$0))
<<<<<<< HEAD:wok_code/cvt_script.sh
PYPATH=""
for p in \$TDIR \$TDIR/.. \$TDIR/../.. \$HOME/venv_tools/bin \$HOME/venv_tools/lib \$HOME/tools; do
  [[ -d \$p ]] && PYPATH=\$(find \$(readlink -f \$p) -maxdepth 3 -name z0librc)
  [[ -n \$PYPATH ]] && PYPATH=\$(dirname \$PYPATH) && break
done
PYPATH=\$(echo -e "import os,sys;p=[os.path.dirname(x) for x in '\$PYPATH'.split()];p.extend([x for x in os.environ['PATH'].split(':') if x not in p and x.startswith('\$HOME')]);p.extend([x for x in sys.path if x not in p]);print(' '.join(p))"|python)
=======
[ \$BASH_VERSINFO -lt 4 ] && echo "This script cvt_script requires bash 4.0+!" && exit 4
[[ -d "\$HOME/dev" ]] && HOME_DEV="\$HOME/dev" || HOME_DEV="\$HOME/devel"
PYPATH=\$(echo -e "import os,sys;\nTDIR='"\$TDIR"';HOME_DEV='"\$HOME_DEV"'\nHOME=os.environ.get('HOME');y=os.path.join(HOME_DEV,'pypi');t=os.path.join(HOME,'tools')\ndef apl(l,p,x):\n  d2=os.path.join(p,x,x)\n  d1=os.path.join(p,x)\n  if os.path.isdir(d2):\n   l.append(d2)\n  elif os.path.isdir(d1):\n   l.append(d1)\nl=[TDIR]\nfor x in ('z0lib','zerobug','odoo_score','clodoo','travis_emulator'):\n if TDIR.startswith(y):\n  apl(l,y,x)\n elif TDIR.startswith(t):\n  apl(l,t,x)\nl=l+os.environ['PATH'].split(':')\np=set()\npa=p.add\np=[x for x in l if x and x.startswith(HOME) and not (x in p or pa(x))]\nprint(' '.join(p))\n"|python)
>>>>>>> stash:wok_code/cvt_script
[[ \$TRAVIS_DEBUG_MODE -ge 8 ]] && echo "PYPATH=\$PYPATH"
for d in \$PYPATH /etc; do
  if [[ -e \$d/z0lib/z0librc ]]; then
    . \$d/z0lib/z0librc
    Z0LIBDIR=\$d/z0lib
    Z0LIBDIR=\$(readlink -e \$Z0LIBDIR)
    break
  elif [[ -e \$d/z0librc ]]; then
    . \$d/z0librc
    Z0LIBDIR=\$d
    Z0LIBDIR=\$(readlink -e \$Z0LIBDIR)
    break
  fi
done
if [[ -z "\$Z0LIBDIR" ]]; then
  echo "Library file z0librc not found!"
  exit 72
fi
EOF
}

blk_2() {
  cat <<EOF >>$1
ODOOLIBDIR=\$(findpkg odoorc "\$PYPATH" "clodoo")
if [[ -z "\$ODOOLIBDIR" ]]; then
  echo "Library file odoorc not found!"
  exit 72
fi
. \$ODOOLIBDIR
[[ \$TRAVIS_DEBUG_MODE -ge 8 ]] && echo "ODOOLIBDIR=\$ODOOLIBDIR"
EOF
}

blk_2z() {
  if [ $opt_oeLib -ne 0 ]; then
    cat <<EOF >>$1
if [ \${opt_oeLib:-0} -ne 0 ]; then
  ODOOLIBDIR=\$(findpkg odoorc "\$PYPATH" "clodoo")
  if [ -z "\$ODOOLIBDIR" ]; then
    echo "Library file odoorc not found!"
    exit 2
  fi
  . \$ODOOLIBDIR
  [[ \$TRAVIS_DEBUG_MODE -ge 8 ]] && echo "ODOOLIBDIR=\$ODOOLIBDIR"
fi
EOF
  fi
}

blk_3() {
  cat <<EOF >>$1
TRAVISLIBDIR=\$(findpkg travisrc "\$PYPATH" "travis_emulator")
if [[ -z "\$TRAVISLIBDIR" ]]; then
  echo "Library file travisrc not found!"
  exit 72
fi
. \$TRAVISLIBDIR
[[ \$TRAVIS_DEBUG_MODE -ge 8 ]] && echo "TRAVISLIBDIR=\$TRAVISLIBDIR"
EOF
}

blk_3z() {
  if [ $opt_tjLib -ne 0 ]; then
    cat <<EOF >>$1
if [ \${opt_tjLib:-0} -ne 0 ]; then
  TRAVISLIBDIR=\$(findpkg travisrc "\$PYPATH" "travis_emulator")
  if [[ -z "\$TRAVISLIBDIR" ]]; then
    echo "Library file travisrc not found!"
    exit 72
  fi
  . \$TRAVISLIBDIR
  [[ \$TRAVIS_DEBUG_MODE -ge 8 ]] && echo "TRAVISLIBDIR=\$TRAVISLIBDIR"
fi
EOF
  fi
}

blk_4() {
  cat <<EOF >>$1
ZARLIB=\$(findpkg zarrc "\$PYPATH")
if [[ -z "\$ZARLIB" ]]; then
  echo "Library file zarrc not found!"
  exit 72
fi
. \$ZARLIB
[[ \$TRAVIS_DEBUG_MODE -ge 8 ]] && echo "ZARLIB=\$ZARLIB"
EOF
}

blk_4z() {
  if [ $opt_zLib -ne 0 ]; then
    cat <<EOF >>$1
if [ \$opt_zLib -ne 0 ]; then
  ZARLIB=\$(findpkg zarrc "\$PYPATH")
  if [[ -z "\$ZARLIB" ]]; then
    echo "Library file zarrc not found!"
    exit 72
  fi
  . \$ZARLIB
  [[ \$TRAVIS_DEBUG_MODE -ge 8 ]] && echo "ZARLIB=\$ZARLIB"
fi
EOF
  fi
}

blk_8() {
  cat <<EOF >>$1
TESTDIR=\$(findpkg "" "\$TDIR . .." "tests")
[[ \$TRAVIS_DEBUG_MODE -ge 8 ]] && echo "TESTDIR=\$TESTDIR"
RUNDIR=\$(readlink -e \$TESTDIR/..)
[[ \$TRAVIS_DEBUG_MODE -ge 8 ]] && echo "RUNDIR=\$RUNDIR"
RED="\e[1;31m"
GREEN="\e[1;32m"
CLR="\e[0m"
EOF
}

blk_9() {
  cat <<EOF >>$1
Z0TLIBDIR=\$(findpkg z0testrc "\$PYPATH" "zerobug")
if [[ -z "\$Z0TLIBDIR" ]]; then
  echo "Library file z0testrc not found!"
  exit 72
fi
. \$Z0TLIBDIR
Z0TLIBDIR=\$(dirname \$Z0TLIBDIR)
[[ \$TRAVIS_DEBUG_MODE -ge 8 ]] && echo "Z0TLIBDIR=\$Z0TLIBDIR"
EOF
}

blk_11() {
  cat <<EOF >>$1
Z0BUG_init
EOF
  if [ $opt_tjLib -ne 0 -o $opt_oeLib -ne 0 -o $opt_zLib -ne 0 ]; then
    cat <<EOF >>$1
parseoptest -l\$TESTDIR/test_${opt_id}.log "\$@" "$OPTS_JOZ"
EOF
  else
    cat <<EOF >>$1
parseoptest -l\$TESTDIR/test_${opt_id}.log "\$@"
EOF
  fi
  cat <<EOF >>$1
sts=\$?
[[ \$sts -ne 127 ]] && exit \$sts
EOF
  blk_2z "$1"
  blk_3z "$1"
  blk_4z "$1"
  echo "" >>$1
}

blk_13() {
  cat <<EOF >>$1
[[ "\$(type -t Z0BUG_setup)" == "function" ]] && Z0BUG_setup
EOF
}

blk_14() {
  cat <<EOF >>$1
Z0BUG_main_file "\$UT1_LIST" "\$UT_LIST"
sts=\$?
[[ "\$(type -t Z0BUG_teardown)" == "function" ]] && Z0BUG_teardown
exit \$sts
EOF
}

blk_21() {
  cat <<EOF >>$1
opts_travis
CFG_init
conf_default
link_cfg \$DIST_CONF \$TCONF
[[ \$opt_verbose -gt 2 ]] && set -x
EOF
}
#//Enable.auto.upgrade.code/

OPTOPTS=(h        J         K        k        m      n           O         q           T        U      V           v           w          y       Z)
OPTDEST=(opt_help opt_tjLib opt_lev3 opt_keep opt_id opt_dry_run opt_oeLib opt_verbose opt_Test opt_UT opt_version opt_verbose opt_nowarn opt_yes opt_zLib)
OPTACTI=(1        1         1        1        "="    1           1         0           1        1      "*"         "+"         1          1       1)
OPTDEFL=(1        0         0        0        ""     0           0         -1          0        0      ""          -1          0          0       0)
OPTMETA=("help"   ""        ""       ""       "name" "noop"      ""        "quiet"     ""       ""     "version"   "verbose"   ""         ""      "")
OPTHELP=("this help"
  "load travisrc library"
  "set script version format n.n.n"
  "Keep script version"
  "module name"
  "do nothing (dry-run)"
  "load odoorc library"
  "silent mode"
  "script with test_mode switch"
  "unit test script with z0testrc library"
  "show version end exit"
  "verbose mode"
  "suppress warning messages"
  "assume yes"
  "load zar library")
OPTARGS=(bashscript)

parseoptargs "$@"
if [[ "$opt_version" ]]; then
  echo "$__version__"
  exit 0
fi
if [[ $opt_help -gt 0 ]]; then
  print_help "Update bash script" \
    "© 2016-2021 by zeroincombenze®\nhttps://zeroincombenze-tools.readthedocs.io/\nAuthor: antoniomaria.vigliotti@gmail.com"
  exit 0
fi

[[ $opt_verbose -gt 1 ]] && set -x
declare -A COPY
COPY[z0lib]="© 2015-2021 by zeroincombenze®\nhttps://zeroincombenze-tools.readthedocs.io/\nAuthor: antoniomaria.vigliotti@gmail.com"
COPY[travis_em]="© 2015-2021 by zeroincombenze®\nhttps://zeroincombenze-tools.readthedocs.io/\nAuthor: antoniomaria.vigliotti@gmail.com"
[[ -z "$opt_id" ]] && opt_id=$(basename $(dirname $bashscript))
[[ $opt_id == "tests" ]]&& opt_id=$(basename $(dirname $(dirname $bashscript)))
ToRepeat=
cvt_file $bashscript
if [[ -n "$ToRepeat" ]]; then
  eval $ToRepeat
  echo "Found wrong flags, repeating operation ..."
  ToRepeat=
  cvt_file $bashscript
fi
sts=$STS_SUCCESS
exit $sts
