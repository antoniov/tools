#! /bin/bash
# -*- coding: utf-8 -*-
#
# please
# Developer shell
#
# This free software is released under GNU Affero GPL3
# author: Antonio M. Vigliotti - antoniomaria.vigliotti@gmail.com
# (C) 2015-2022 by SHS-AV s.r.l. - http://www.shs-av.com - info@shs-av.com
#
READLINK=$(which greadlink 2>/dev/null) || READLINK=$(which readlink 2>/dev/null)
export READLINK
# Based on template 2.0.0
THIS=$(basename "$0")
TDIR=$(readlink -f $(dirname $0))
[ $BASH_VERSINFO -lt 4 ] && echo "This script $0 requires bash 4.0+!" && exit 4
if [[ -z $HOME_DEVEL || ! -d $HOME_DEVEL ]]; then
  [[ -d $HOME/odoo/devel ]] && HOME_DEVEL="$HOME/odoo/devel" || HOME_DEVEL="$HOME/devel"
fi
[[ -x $TDIR/../bin/python3 ]] && PYTHON=$(readlink -f $TDIR/../bin/python3) || [[ -x $TDIR/python3 ]] && PYTHON="$TDIR/python3" || PYTHON=$(which python3 2>/dev/null) || PYTHON="python"
[[ -z $PYPATH ]] && PYPATH=$(echo -e "import os,sys\no=os.path\na=o.abspath\nj=o.join\nd=o.dirname\nb=o.basename\nf=o.isfile\np=o.isdir\nC=a('"$TDIR"')\nD='"$HOME_DEVEL"'\nif not p(D) and '/devel/' in C:\n D=C\n while b(D)!='devel':  D=d(D)\nN='venv_tools'\nU='setup.py'\nO='tools'\nH=o.expanduser('~')\nT=j(d(D),O)\nR=j(d(D),'pypi') if b(D)==N else j(D,'pypi')\nW=D if b(D)==N else j(D,'venv')\nS='site-packages'\nX='scripts'\ndef pt(P):\n P=a(P)\n if b(P) in (X,'tests','travis','_travis'):\n  P=d(P)\n if b(P)==b(d(P)) and f(j(P,'..',U)):\n  P=d(d(P))\n elif b(d(C))==O and f(j(P,U)):\n  P=d(P)\n return P\ndef ik(P):\n return P.startswith((H,D,K,W)) and p(P) and p(j(P,X)) and f(j(P,'__init__.py')) and f(j(P,'__main__.py'))\ndef ak(L,P):\n if P not in L:\n  L.append(P)\nL=[C]\nK=pt(C)\nfor B in ('z0lib','zerobug','odoo_score','clodoo','travis_emulator'):\n for P in [C]+sys.path+os.environ['PATH'].split(':')+[W,R,T]:\n  P=pt(P)\n  if B==b(P) and ik(P):\n   ak(L,P)\n   break\n  elif ik(j(P,B,B)):\n   ak(L,j(P,B,B))\n   break\n  elif ik(j(P,B)):\n   ak(L,j(P,B))\n   break\n  elif ik(j(P,S,B)):\n   ak(L,j(P,S,B))\n   break\nak(L,os.getcwd())\nprint(' '.join(L))\n"|$PYTHON)
[[ $TRAVIS_DEBUG_MODE -ge 8 ]] && echo "PYPATH=$PYPATH"
for d in $PYPATH /etc; do
  if [[ -e $d/z0librc ]]; then
    . $d/z0librc
    Z0LIBDIR=$(readlink -e $d)
    break
  fi
done
[[ -z "$Z0LIBDIR" ]] && echo "Library file z0librc not found in <$PYPATH>!" && exit 72
[[ $TRAVIS_DEBUG_MODE -ge 8 ]] && echo "Z0LIBDIR=$Z0LIBDIR"
ODOOLIBDIR=$(findpkg odoorc "$PYPATH" "clodoo")
[[ -z "$ODOOLIBDIR" ]] && echo "Library file odoorc not found!" && exit 72
. $ODOOLIBDIR
[[ $TRAVIS_DEBUG_MODE -ge 8 ]] && echo "ODOOLIBDIR=$ODOOLIBDIR"
TRAVISLIBDIR=$(findpkg travisrc "$PYPATH" "travis_emulator")
[[ -z "$TRAVISLIBDIR" ]] && echo "Library file travisrc not found!" && exit 72
. $TRAVISLIBDIR
[[ $TRAVIS_DEBUG_MODE -ge 8 ]] && echo "TRAVISLIBDIR=$TRAVISLIBDIR"
TESTDIR=$(findpkg "" "$TDIR . .." "tests")
[[ $TRAVIS_DEBUG_MODE -ge 8 ]] && echo "TESTDIR=$TESTDIR"
RUNDIR=$(readlink -e $TESTDIR/..)
[[ $TRAVIS_DEBUG_MODE -ge 8 ]] && echo "RUNDIR=$RUNDIR"

# DIST_CONF=$(findpkg ".z0tools.conf" "$PYPATH")
# TCONF="$HOME/.z0tools.conf"
CFG_init "ALL"
link_cfg_def
link_cfg $DIST_CONF $TCONF
[[ $TRAVIS_DEBUG_MODE -ge 8 ]] && echo "DIST_CONF=$DIST_CONF" && echo "TCONF=$TCONF"
get_pypi_param ALL
RED="\e[1;31m"
GREEN="\e[1;32m"
CLR="\e[0m"

__version__=2.0.2

#
# General Purpose options:
# -A dont exec odoo test
# -B exec bash test
# -b branch: must be 6.1 7.0, 8.0, 9.0 10.0 11.0 12.0 13.0 or 14.0
# -C commit & push | dont exc clodoo test
# -c configuration file
# -D duplicate odoo to another version
# -d diff
# -F fetch
# -f force
# -H use virtualenv
# -k keep files
# -K exec bash, flake8 and pylint tests | run cron environ
# -j exec tests in project dir rather in test dir
# -m show missing line in report
# -n do nothing (dry-run)
# -o limit push to ids
# -O run odoo burst
# -O replace odoo distribution
# -o OCA directives
# -P push
# -p local path
# -q silent mode
# -R replace | replica
# -r rescricted mode (w/o parsing travis.yml file)
# -S status
# -T exec regression test
# -t do nothing (test-mode)
# -u dont update newer files
# -V show version
# -v verbose mode
# -W whatis
# -w wep

FIND_EXCL="-not -path '*/build/*' -not -path '*/_build/*' -not -path '*/dist/*' -not -path '*/docs/*' -not -path '*/__to_remove/*' -not -path '*/filestore/*' -not -path '*/.git/*' -not -path '*/html/*' -not -path '*/.idea/*' -not -path '*/latex/*' -not -path '*/__pycache__/*' -not -path '*/.local/*' -not -path '*/.npm/*' -not -path '*/.gem/*' -not -path '*/Trash/*' -not -path '*/VME/*'"

get_dbuser() {
  # get_dbuser odoo_majver
  local u
  for u in $USER odoo openerp postgres; do
    if [[ -n "$1" ]]; then
      psql -U$u$1 -l &>/dev/null
      if [[ $? -eq 0 ]]; then
        echo "$u$1"
        break
      fi
    fi
    psql -U$u -l &>/dev/null
    if [[ $? -eq 0 ]]; then
      echo "$u"
      break
    fi
  done
}

move() {
  # move(src dst)
  if [ -f "$2" ]; then rm -f $2; fi
  run_traced "cp -p $1 $2"
  run_traced "rm -f $1"
}

move_n_bak() {
  # move_n_bak(src dst)
  if [ -f "$2.bak" ]; then rm -f $2.bak; fi
  run_traced "cp -p $2 $2.bak"
  run_traced "mv -f $1 $2"
}

search_pofile() {
  srcs=$(find -L $odoo_root -not -path '*/build/*' -not -path '*/_build/*' -not -path '*/dist/*' -not -path '*/docs/*' -not -path '*/__to_remove/*' -not -path '*/filestore/*' -not -path '*/.git/*' -not -path '*/html/*' -not -path '*/.idea/*' -not -path '*/latex/*' -not -path '*/__pycache__/*' -not -path '*/.local/*' -not -path '*/.npm/*' -not -path '*/.gem/*' -not -path '*/Trash/*' -not -path '*/VME/*' -type d -name "$opt_modules")
  f=0
  for src in $srcs; do
    if [ -n "$src" ]; then
      if [ -f $src/i18n/it.po ]; then
        src=$src/i18n/it.po
        if [ $opt_exp -ne 0 ]; then
          run_traced "cp $src $src.bak"
        fi
        f=1
        break
      else
        alt=$(find -L $src/i18n -name '*.po' | head -n1)
        src=
        if [ -n "$alt" ]; then fi=1 break; fi
      fi
    fi
  done
}

add_copyright() {
  #add_copyright(file rst zero|oca|powerp)
  if [[ "$PRJNAME" == "Odoo" ]]; then
    if [[ $2 -eq 1 ]]; then
      echo ".. [//]: # (copyright)" >>$1
    else
      echo "[//]: # (copyright)" >>$1
    fi
    echo "" >>$1
    echo "----" >>$1
    echo "" >>$1
    if [[ $2 -eq 1 ]]; then
      echo "**Odoo** is a trademark of  \`Odoo S.A." >>$1
      echo "<https://www.odoo.com/>\`_." >>$1
      echo "(formerly OpenERP, formerly TinyERP)" >>$1
    else
      echo "**Odoo** is a trademark of [Odoo S.A.](https://www.odoo.com/) (formerly OpenERP, formerly TinyERP)" >>$1
    fi
    echo "" >>$1
    if [[ $2 -eq 1 ]]; then
      echo "**OCA**, or the  \`Odoo Community Association" >>$1
      echo "<http://odoo-community.org/>\`_." >>$1
      echo "is a nonprofit organization whose" >>$1
    else
      echo "**OCA**, or the [Odoo Community Association](http://odoo-community.org/), is a nonprofit organization whose" >>$1
    fi
    echo "mission is to support the collaborative development of Odoo features and" >>$1
    echo "promote its widespread use." >>$1
    echo "" >>$1
    if [[ "$3" == "powerp" ]]; then
      echo "**powERP**, or the [powERP enterprise network](https://www.powerp.it/)" >>$1
      echo "is an Italian enterprise network whose mission is to develop high-level" >>$1
      echo "addons designed for Italian enterprise companies." >>$1
      echo "The powER software, released under Odoo Proprietary License," >>$1
      echo "adds new enhanced features to Italian localization." >>$1
      echo "La rete di imprese [powERP](https://www.powerp.it/)" >>$1
      echo "fornisce, sotto licenza OPL, estensioni evolute della localizzazine italiana." >>$1
      echo "Il software è progettato per medie e grandi imprese italiane" >>$1
      echo "che richiedono caratteristiche non disponibili nella versione Odoo CE" >>$1
      echo "" >>$1
    else
      if [ $2 -eq 1 ]; then
        echo "**zeroincombenze®** is a trademark of \`SHS-AV s.r.l." >>$1
        echo "<http://www.shs-av.com/>\`_." >>$1
      else
        echo "**zeroincombenze®** is a trademark of [SHS-AV s.r.l.](http://www.shs-av.com/)" >>$1
      fi
      echo "which distributes and promotes **Odoo** ready-to-use on own cloud infrastructure." >>$1
      echo "[Zeroincombenze® distribution of Odoo](http://wiki.zeroincombenze.org/en/Odoo)" >>$1
      echo "is mainly designed for Italian law and markeplace." >>$1
      echo "Users can download from [Zeroincombenze® distribution](https://github.com/zeroincombenze/OCB) and deploy on local server." >>$1
      echo "" >>$1
    fi
    if [ $2 -eq 1 ]; then
      echo "" >>$1
      echo ".. [//]: # (end copyright)" >>$1
    else
      echo "[//]: # (end copyright)" >>$1
    fi
  else
    if [ $2 -eq 1 ]; then
      echo ".. [//]: # (copyright)" >>$1
    else
      echo "[//]: # (copyright)" >>$1
    fi
    echo "" >>$1
    echo "----" >>$1
    echo "" >>$1
    if [ $2 -eq 1 ]; then
      echo "**zeroincombenze®** is a trademark of \`SHS-AV s.r.l." >>$1
      echo "<http://www.shs-av.com/>\`_." >>$1
    else
      echo "**zeroincombenze®** is a trademark of [SHS-AV s.r.l.](http://www.shs-av.com/)" >>$1
    fi
    echo "which distributes and promotes **Odoo** ready-to-use on its own cloud infrastructure." >>$1
    echo "" >>$1
    echo "Odoo is a trademark of Odoo S.A." >>$1
    if [ $2 -eq 1 ]; then
      echo "" >>$1
      echo ".. [//]: # (end copyright)" >>$1
    else
      echo "[//]: # (end copyright)" >>$1
    fi
  fi
}

add_addons() {
  #add_addons(file rst zero|oca|oia ORIG)
  if [ "$PRJNAME" == "Odoo" ]; then
    if [ $2 -eq 1 ]; then
      echo ".. [//]: # (addons)" >>$1
    else
      echo "[//]: # (addons)" >>$1
    fi
    $TDIR/gen_addons_table.py addons $4 >>$1
    if [ $2 -eq 1 ]; then
      echo "" >>$1
      echo ".. [//]: # (end addons)" >>$1
    else
      echo "[//]: # (end addons)" >>$1
    fi
  fi
}

add_install() {
  #add_install(file rst zero|oca|oia ORIG)
  if [ "$PRJNAME" == "Odoo" ]; then
    local pkgs
    local gitorg=$3
    [ "$3" == "zero" -o "$3" == "oia" ] && gitorg=${3}-http
    if [ -z "$REPOSNAME" ]; then
      local REPOS=$PKGNAME
      local url=$(build_odoo_param GIT_URL '.' "" "$gitorg")
      local root=$(build_odoo_param HOME '.')
    else
      pushd .. >/dev/null
      local REPOS=$REPOSNAME
      local url=$(build_odoo_param GIT_URL '.' "" "$gitorg")
      local root=$(build_odoo_param HOME '.')
      popd >/dev/null
    fi
    if [ $2 -eq 1 ]; then
      echo ".. [//]: # (install)" >>$1
    else
      echo "[//]: # (install)" >>$1
    fi
    echo "    ODOO_DIR=$root  # here your Odoo dir" >>$1
    echo "    BACKUP_DIR=$HOME/backup  # here your backup dir" >>$1
    pkgs=$(list_requirements.py -p $PWD -s' ' -P -t python)
    pkgs="${pkgs:7}"
    if [ -n "$pkgs" ]; then
      echo "    for pkg in $pkgs; do" >>$1
      echo "        pip install \$pkg" >>$1
      echo "    done" >>$1
    fi
    pkgs=$(list_requirements.py -p $PWD -s' ' -P -t modules)
    pkgs="${pkgs:8}"
    if [ -n "$pkgs" ]; then
      echo "    # Check for <$pkgs> modules" >>$1
    fi
    echo "    cd /tmp" >>$1
    echo "    git clone $url $REPOS" >>$1
    echo "    mv \$ODOO_DIR/$REPOS/$PKGNAME/ \$BACKUP_DIR/" >>$1
    echo "    mv /tmp/$REPOS/$PKGNAME/ \$ODOO_DIR/" >>$1
    if [ $2 -eq 1 ]; then
      echo "" >>$1
      echo ".. [//]: # (end install)" >>$1
    else
      echo "[//]: # (end install)" >>$1
    fi
  fi
}

restore_owner() {
  if [ "$USER" != "odoo" ]; then
    local fown="odoo:odoo"
    # [ "$USER" == "travis" ] && fown="travis:odoo"
    if sudo -v &>/dev/null; then
      run_traced "sudo chown -R $fown .git"
    elif [ "$USER" != "travis" ]; then
      run_traced "chown -R $fown .git"
    fi
  fi
}

expand_macro() {
  local t p v lne lne1
  lne="$1"
  for t in {1..9} LNK_DOCS BTN_DOCS LNK_HELP BTN_HELP; do
    p=\${$t}
    v=${M[$t]}
    lne1="${lne//$p/$v}"
    lne="$lne1"
  done
  echo -n "$lne"
}

# set_executable() {
#   run_traced "find $PKGPATH -type f -executable -exec chmod -x '{}' \;"
#   run_traced "find $PKGPATH -type f -name \"*.sh\" -exec chmod +x '{}' \;"
#   run_traced "find $PKGPATH -type f -exec grep -El \"#. *(/bin/bash|/usr/bin/env )\" '{}' \;|xargs -I{} chmod +x {}"
# }

get_ver() {
  local ver=
  if [ -n "$BRANCH" ]; then
    if [ "$BRANCH" == "master" ]; then
      ver=$BRANCH
    else
      ver=$(echo $BRANCH | grep --color=never -Eo '[0-9]+' | head -n1)
    fi
  else
    ver=master
  fi
  [ -n "$1" -a "$ver" == "master" ] && ver=0
  echo $ver
}

build_line() {
  # build_line(flag replmnt act)
  local v w x line
  v=${1^^}
  w="LNK_${v:1}"
  v="BTN_${v:1}"
  line="$2"
  if [[ "$3" =~ md_BTN ]]; then
    if [ -n "${M[$v]}" ]; then
      x="${M[$v]}"
      line="$line($x)]"
    fi
    if [ -n "${M[$w]}" ]; then
      x="${M[$w]}"
      line="$line($x)"
    fi
  elif [[ "$3" =~ rstBTN_.*/1 ]]; then
    if [ -z "$2" ]; then
      line=".. image::"
    else
      line=".. ${line:0:-1} image::"
    fi
    if [ -n "${M[$v]}" ]; then
      x="${M[$v]}"
      line="$line $x"
    fi
  elif [[ "$3" =~ rstBTN_.*/2 ]]; then
    if [ -z "$2" ]; then
      line="   :target:"
    else
      line=".. _${line:1:-2}:"
    fi
    if [ -n "${M[$w]}" ]; then
      x="${M[$w]}"
      line="$line $x"
    fi
  elif [ "$3" == "CHPT_lang_en" ]; then
    line="[![en](https://github.com/zeroincombenze/grymb/blob/master/flags/en_US.png)](https://www.facebook.com/groups/openerp.italia/)"
  elif [ "$3" == "CHPT_lang_it" ]; then
    line="[![it](https://github.com/zeroincombenze/grymb/blob/master/flags/it_IT.png)](https://www.facebook.com/groups/openerp.italia/)"
  elif [[ $3 =~ CHPT_ ]]; then
    :
  fi
  echo "$line"
}

cvt_doxygenconf() {
  local fn=$1
  if [ -f $fn ]; then
    local fntmp=$fn.tmp
    rm -f $fntmp
    local line lne submod url p v
    while IFS= read -r line r || [ -n "$line" ]; do
      if [[ $line =~ ^PROJECT_NAME ]]; then
        line="PROJECT_NAME           = \"$PRJNAME\""
      elif [[ $line =~ ^PROJECT_BRIEF ]]; then
        line="PROJECT_BRIEF          = \"$prjdesc\""
      elif [[ $line =~ ^HTML_COLORSTYLE_HUE ]]; then
        line="HTML_COLORSTYLE_HUE    = 93"
      elif [[ $line =~ ^HTML_COLORSTYLE_SAT ]]; then
        line="HTML_COLORSTYLE_SAT    = 87"
      elif [[ $line =~ ^HTML_COLORSTYLE_GAMMA ]]; then
        line="HTML_COLORSTYLE_GAMMA  = 120"
      elif [[ $line =~ ^HTML_COLORSTYLE_GAMMA ]]; then
        line="HTML_COLORSTYLE_GAMMA  = 120"
      elif [[ $line =~ ^JAVADOC_AUTOBRIEF ]]; then
        line="JAVADOC_AUTOBRIEF      = YES"
      elif [[ $line =~ ^OPTIMIZE_OUTPUT_JAVA ]]; then
        line="OPTIMIZE_OUTPUT_JAVA   = YES"
      elif [[ $line =~ ^EXTRACT_STATIC ]]; then
        line="EXTRACT_STATIC         = YES"
      elif [[ $line =~ ^FILTER_SOURCE_FILES ]]; then
        line="FILTER_SOURCE_FILES    = YES"
      elif [[ $line =~ ^INPUT_FILTER ]]; then
        line="INPUT_FILTER           = /usr/bin/doxypy.py"
      elif [[ $line =~ ^HTML_TIMESTAMP ]]; then
        line="HTML_TIMESTAMP         = YES"
      elif [[ $line =~ ^GENERATE_LATEX ]]; then
        line="GENERATE_LATEX         = NO"
      elif [[ $line =~ ^EXCLUDE_PATTERNS ]]; then
        line="EXCLUDE_PATTERNS       = */tests/* "
      fi
      echo "$line" >>$fntmp
    done <"$fn"
    if [ -n "$(diff -q $fn $fntmp)" ]; then
      # run_traced "cp -p $fn $fn.bak"
      # run_traced "mv $fntmp $fn"
      move_n_bak $fntmp $fn
    else
      rm -f $fntmp
    fi
  fi
}

cvt_gitmodule() {
  #cvt_gitmodule(oca|zero)
  if [ -f .gitmodules ]; then
    local fn=.gitmodules
    local fntmp=$fn.tmp
    local urlty=zero-http
    rm -f $fntmp
    local line lne submod url p v
    while IFS= read -r line r || [ -n "$line" ]; do
      if [ "${line:0:1}" == "[" -a "${line: -1}" == "]" ]; then
        lne="${line:1:-1}"
        read p v <<<"$lne"
        submod=${v//\"/}
      else
        lne=$(echo $line)
        IFS== read p v <<<$lne
        lne=$(echo $p)
        if [ "$lne" == "url" ]; then
          url=$(build_odoo_param URL '' $submod $urlty)
          lne=$(echo $v)
          if [ "$lne" != "$url" ]; then
            v="${line//$lne/$url}"
            line="$v"
          fi
        fi
      fi
      echo "$line" >>$fntmp
    done <"$fn"
    if [ -n "$(diff -q $fn $fntmp)" ]; then
      move_n_bak $fntmp $fn
    else
      rm -f $fntmp
    fi
  fi
}

cvt_travis() {
  # cvt_travis(file_travis oca|zero|oia currpt ORIG)
  local fn=$1
  local fntmp=$fn.tmp
  ORGNM=$(build_odoo_param GIT_ORGNM '' '' $2)
  run_traced "tope8 -B -b $odoo_fver $fn"
  run_traced "sed -e \"s|ODOO_REPO=.[^/]*|ODOO_REPO=\\\"$ORGNM|\" -i $fn"
}

cvt_file() {
  # cvt_file(file oca|zero|powerp travis|readme|manifest currpt ORIG)
  local f1=$1
  local sts=$STS_SUCCESS
  if [ -n "$f1" ]; then
    if [ -f "$1" ]; then
      local b=$(basename $f1)
      local d=$(dirname $f1)
      if [[ $f1 =~ $PWD ]]; then
        local l=${#PWD}
        ((l++))
        local ft=${f1:l}
      elif [ "${f1:0:2}" == "./" ]; then
        local ft=${f1:2}
      else
        local ft=$f1
      fi
      local f1_oca=$(dirname $f1)/${b}.oca
      local f1_z0i=$(dirname $f1)/${b}.z0i
      local f1_oia=$(dirname $f1)/${b}.oia
      if [ "$2" == "zero" -o -z "$2" ]; then
        local f1_new=$f1_z0i
      else
        local f1_new=$(dirname $f1)/${b}.$2
      fi
      if [ "$4" == "zero" -o -z "$4" ]; then
        local f1_cur=$f1_z0i
      else
        local f1_cur=$(dirname $f1)/${b}.$4
      fi
      if [ "$2" == "$4" -a $opt_force -eq 0 ]; then
        local do_proc=0
      else
        local do_proc=1
      fi
      local fntmp=$f1.tmp
      if [ -f $f1_new ]; then
        if [ -f "$f1_oca" -a -f "$f1_oia" -a -f "$f1_zoi" ]; then
          :
        else
          move $f1 $f1_cur
        fi
        move $f1_new $f1
        do_proc=1
      elif [ $opt_force -ne 0 -a ! -f $f1_cur -a "$3" != "graph" -a "$3" != "xml" -a "$3" != "css" -a "$3" != "sass" ]; then
        if [ -f "$f1_cur" ]; then rm -f $f1_cur; fi
        run_traced "cp -p $f1 $f1_cur"
        do_proc=1
      fi
#      if [ $opt_orig -gt 0 -a -f ./tmp/$ft ]; then
#        run_traced "mv -f $f1 ${f1}.bak"
#        run_traced "cp -p ./tmp/$ft $f1"
#      fi
      if [ "$3" == "travis" ]; then
        cvt_travis $f1 "$2" "$4" "$5"
      elif [ "$3" == "readme" ] && [ ${test_mode:-0} -ne 0 -o $do_proc -gt 0 ]; then
        # cvt_readme $f1 "$2" "$4" "$5"
        :
      fi
      if [ -f $f1_cur ] && [ $opt_force -eq 0 -o "$3" == "manifest" ]; then
        diff -q $f1 $f1_cur &>/dev/null
        if [ $? -eq 0 ]; then
          run_traced "rm -f $f1_cur"
        fi
      fi
    else
      echo "File $f1 not found!"
    fi
  else
    local f1=
    echo "Missed parameter! use:"
    echo "\$ please distribution oca|zero|oia"
    sts=$STS_FAILED
  fi
  return $sts
}

set_remote_info() {
  #set_remote_info (REPOSNAME odoo_vid odoo_org)
  local REPOSNAME=$1
  if [ "$(build_odoo_param VCS $2)" == "git" ]; then
    local odoo_fver=$(build_odoo_param FULLVER "$2")
    local DUPSTREAM=$(build_odoo_param RUPSTREAM "$2" "default" $3)
    local RUPSTREAM=$(build_odoo_param RUPSTREAM "$2" "" $3)
    local DORIGIN=$(build_odoo_param RORIGIN "$2" "default" $3)
    local RORIGIN=$(build_odoo_param RORIGIN "$2" "" $3)
    if [[ ! "$DUPSTREAM" == "$RUPSTREAM" ]]; then
      [[ -n "$RUPSTREAM" ]] && run_traced "git remote remove upstream"
      [[ -n "$DUPSTREAM" ]] && run_traced "git remote add upstream $DUPSTREAM"
    fi
    if [[ ! "$DORIGIN" == "$RORIGIN" ]]; then
      [[ -n "$RORIGIN" ]] && run_traced "git remote remove origin"
      [[ -n "$DORIGIN" ]] && run_traced "git remote add origin $DORIGIN"
    fi
  elif [ ${test_mode:-0} -eq 0 ]; then
    echo "No git repositoy $REPOSNAME!"
  fi
}

mvfiles() {
  # mvfiles(srcpath, tgtpath, files, owner)
  if [ -z "$3" ]; then
    local l="*"
  else
    local l="$3"
  fi
  local CWD=$PWD
  local sts=$STS_SUCCESS
  local f
  if [ -d $1 -a -n "$2" ]; then
    if [ -d $2 ]; then
      cd $1
      for f in $l; do
        if [ -e $1/$f ]; then
          run_traced "mv -f $1/$f $2/$f"
          if [ $4 ]; then
            run_traced "chown $4 $2/$f"
          fi
        else
          elog "! File $1/$f not found!!"
          sts=$STS_FAILED
        fi
      done
    else
      elog "! Directory $2 not found!!"
      sts=$STS_FAILED
    fi
  else
    elog "! Directory $1 not found!!"
    sts=$STS_FAILED
  fi
  cd $CWD
  return $sts
}

create_pubblished_index() {
  # create_pubblished_index(index_dir) {
  local f
  run_traced "cd $1"
  cat <<EOF >index.html
<!DOCTYPE HTML>
<html>
    <head>
        <title>Speed Test</title>
    </head>
    <body>
    <table>
EOF
  for f in *; do
    if [ "$f" != "index.html" ]; then
      echo "        <tr><td>$f</td></tr>" >>index.html
    fi
  done
  echo "    </body>" >>index.html
  echo "</html>" >>index.html
}

merge_cfg() {
  #merge_cfg(cfgfn)
  local cfgfn=$1 fbak ftmp f line ln
  local tmpl
  [[ -d $HOME_DEVEL ]] && tmpl=$HOME_DEVEL/pypi/tools/install_tools.sh
  ftmp=$cfgfn.tmp
  [[ -f $ftmp ]] && rm -f $ftmp
  f=0
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ $line =~ ^RFLIST__ ]]; then
      if [ $f -eq 0 ] && [[ -f $tmpl ]]; then
        while IFS= read -r ln || [ -n "$ln" ]; do
          [[ $ln =~ ^RFLIST__ ]] && echo "$ln" >>$ftmp
        done <$tmpl
      fi
      f=1
    else
      echo "$line" >>$ftmp
    fi
  done <$1
  fbak=$cfgfn.bak
  [[ -f $fbak ]] && rm -f $fbak
  [[ -f $cfgfn ]] && mv $cfgfn $fbak
  [[ -f $ftmp ]] && mv $ftmp $cfgfn
}

do_publish() {
  #do_publish (docs|download|pypi|svg|testpypi)
  wlog "do_publish $1 $2"
  local cmd="do_publish_$1"
  sts=$STS_SUCCESS
  if [ "$(type -t $cmd)" == "function" ]; then
    eval $cmd "$@"
  else
    echo "Missing object! Use:"
    echo "> please publish (docs|download|pypi|svg|testpypi)"
    echo "publish docs     -> publish generate docs to website (require system privileges)"
    echo "   type 'please docs' to generate docs files"
    echo "publish download -> publish tarball to download (require system privileges)"
    echo "   type 'please build' to generate tarball file"
    echo "publish pypi     -> publish package to pypi website (from odoo user)"
    echo "publish svg      -> publish test result svg file (require system privileges)"
    echo "publish tar      -> write a tarball with package files"
    echo "publish testpypi -> publish package to testpypi website (from odoo user)"
    sts=$STS_FAILED
  fi
  return $sts
}

do_publish_svg() {
  #do_publish_svg svg (prd|dev)
  local sts=$STS_FAILED
  local HTML_SVG_DIR=$(get_cfg_value 0 "HTML_SVG_DIR")
  local DEV_SVG=$(get_cfg_value 0 "DEV_SVG")
  if [ $EUID -ne 0 ]; then
    echo "!!Error: no privilege to publish svg!!"
    return $sts
  fi
  if [ "$HOSTNAME" == "$PRD_HOST" ]; then
    local tgt="prd"
  elif [ "$HOSTNAME" == "$DEV_HOST" ]; then
    local tgt="dev"
  else
    local tgt=""
  fi
  if [ ! -d $HTML_SVG_DIR ]; then
    run_traced "mkdir -p $HTML_SVG_DIR"
    run_traced "chown apache:apache $HTML_SVG_DIR"
    if [ ! -d $HTML_SVG_DIR/$tgt ]; then
      run_traced "mkdir -p $HTML_SVG_DIR/$tgt"
      run_traced "chown apache:apache $HTML_SVG_DIR/$tgt"
    fi
  fi
  mvfiles "$DEV_SVG" "$HTML_SVG_DIR/$tgt" "*.svg" "apache:apache"
  local sts=$?
  if [ "$HOSTNAME" == "$DEV_HOST" ]; then
    scpfiles "$HTML_SVG_DIR/$tgt" "$PRD_HOST:$HTML_SVG_DIR/$tgt" "*.svg"
    local s=$?
    [ $sts -eq $STS_SUCCESS ] && sts=$s
  fi
  return $sts
}

do_publish_docs() {
  #do_publish_svg docs
  local sts=$STS_FAILED
  if [ $EUID -ne 0 ]; then
    echo "!!Error: no privilege to publish documentation!!"
    return $sts
  fi
  local HTML_DOCS_DIR=$(get_cfg_value "" "HTML_DOCS_DIR")
  if [ -d $HTML_DOCS_DIR/$1 ]; then
    run_traced "rm -fR $HTML_DOCS_DIR/$1"
  fi
  if [ ! -d $HTML_DOCS_DIR/$1 ]; then
    run_traced "mkdir -p $HTML_DOCS_DIR/$1"
    run_traced "chown apache:apache $HTML_DOCS_DIR/$1"
  fi
  mvfiles "$PRJPATH/html" "$HTML_DOCS_DIR/$1" "" "apache:apache"
  local sts=$?
  rmdir $PRJPATH/html
  if [ -d $PRJPATH/latex ]; then
    rm -fR $PRJPATH/latex
  fi
  if [ $opt_verbose -gt 0 ]; then
    echo ""
    echo -e "see \e[1mdocs.zeroincombenze.org/$1\e[0m webpage"
  fi
  return $sts
}

do_publish_download() {
  #do_publish_download
  local f n s v
  local sts=$STS_FAILED
  if [ $EUID -ne 0 ]; then
    echo "!!Error: no privilege to publish download!!"
    return $sts
  fi
  local HTML_DOWNLOAD_DIR=$(get_cfg_value "" "HTML_DOWNLOAD_DIR")
  if [ "$PRJNAME" != "Odoo" ]; then
    if [ ! -d $HTML_DOWNLOAD_DIR ]; then
      run_traced "mkdir -p $HTML_DOWNLOAD_DIR"
      run_traced "chown apache:apache $HTML_DOWNLOAD_DIR"
    fi
    run_traced "cd $PKGPATH"
    s=$?; [ ${s-0} -ne 0 ] && sts=$s
    n=$(cat setup.py | grep "name *=" | awk -F= '{print $2}' | grep --color=never -Eo '[a-zA-Z0-9_-]+' | head -n1)
    v=$(cat setup.py | grep version | grep --color=never -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
    f=$(ls -1 $n*$v*tar.gz)
    # f=$n*$v*tar.gz
    if [ -n "$f" -a -f "$f" ]; then
      mvfiles "$PKGPATH" "$HTML_DOWNLOAD_DIR" "$f" "apache:apache"
      sts=$?
      if [ $sts -eq $STS_SUCCESS ]; then
        run_traced "cp $HTML_DOWNLOAD_DIR/$f $HTML_DOWNLOAD_DIR/$n.tar.gz"
        run_traced "chown apache:apache $HTML_DOWNLOAD_DIR/$n.tar.gz"
        create_pubblished_index "$HTML_DOWNLOAD_DIR"
        if [ $opt_verbose -gt 0 ]; then
          echo ""
          echo -e "You can download this package typing"
          echo -e "\$ wget http://download.zeroincombenze.org/$n.tar.gz"
        fi
      fi
    else
      echo "Source $n*$v*tar.gz file non found!"
    fi
  fi
  return $sts
}

do_publish_testpypi() {
  do_publish_pypi testpypi
}

do_publish_pypi() {
  #do_publish_pypi repos
  local sts=$STS_SUCCESS
  local rpt=$1
  local n p s v
  [[ -z $rpt || ! $rpt =~ (pypi|testpypi) ]] && rpt=pypi
  if [[ "$PRJNAME" != "Odoo" ]]; then
    if twine --version &>/dev/null; then
      run_traced "cd $PKGPATH"
      s=$?; [ ${s-0} -ne 0 ] && sts=$s
      [[ -f $PRJPATH/README.rst ]] && run_traced "cp $PRJPATH/README.rst ./"
      v=$(python setup.py --version)
      n=$(python setup.py --name)
      p=$(find dist -name "${n}-${v}.tar.gz")
      if [[ -z "$p" || $opt_force -gt 0 ]]; then
        run_traced "python setup.py build sdist"
        s=$?; [ ${s-0} -ne 0 ] && sts=$s
      fi
      p=$(find dist -name "${n}-${v}.tar.gz")
      [[ -z $p ]] && echo "Internal error: file tar not found!" && return 127
      run_traced "twine upload $p -r $rpt"
      s=$?; [ ${s-0} -ne 0 ] && sts=$s
    else
      echo "Command twine not found!"
      echo "Do pip install twine"
      sts=1
    fi
  fi
  return $sts
}

do_register_pypi() {
  #do_register_pypi
  local sts=$STS_SUCCESS
  local rpt=testpypi
  local n p s v
  if [ "$PRJNAME" != "Odoo" ]; then
    run_traced "cd $PKGPATH"
    s=$?; [ ${s-0} -ne 0 ] && sts=$s
    n=$(cat setup.py | grep "name *=" | awk -F= '{print $2}' | grep --color=never -Eo '[a-zA-Z0-9_-]+' | head -n1)
    v=$(cat setup.py | grep version | grep --color=never -Eo '[0-9]+[0-9\.]*' | head -n1)
    p=$(find dist -name "$n*$v*.whl")
    if [ -z "$p" -o $opt_force -gt 0 ]; then
      run_traced "python setup.py bdist_wheel --universal"
      s=$?; [ ${s-0} -ne 0 ] && sts=$s
    fi
    p=$(find dist -name "$n*$v*.whl")
    run_traced "twine register $p -r $rpt"
    s=$?; [ ${s-0} -ne 0 ] && sts=$s
  fi
  return $sts
}

do_register_testpypi() {
  #do_register_testpypi
  local sts=$STS_SUCCESS
  local rpt=testpypi
  local n p s v
  if [ "$PRJNAME" != "Odoo" ]; then
    run_traced "cd $PKGPATH"
    s=$?; [ ${s-0} -ne 0 ] && sts=$s
    n=$(cat setup.py | grep "name *=" | awk -F= '{print $2}' | grep --color=never -Eo '[a-zA-Z0-9_-]+' | head -n1)
    v=$(cat setup.py | grep version | grep --color=never -Eo '[0-9]+[0-9\.]*' | head -n1)
    p=$(find dist -name "$n*$v*.whl")
    if [ -z "$p" -o $opt_force -gt 0 ]; then
      run_traced "python setup.py bdist_wheel --universal"
      s=$?; [ ${s-0} -ne 0 ] && sts=$s
    fi
    p=$(find dist -name "$n*$v*.whl")
    run_traced "twine register $p -r $rpt"
    s=$?; [ ${s-0} -ne 0 ] && sts=$s
  fi
  return $sts
}

do_edit() {
  #do_edit (pofile|translation|untranslated)
  local cmd
  wlog "do_edit $1 $2"
  cmd="do_edit_$1"
  sts=$STS_SUCCESS
  if [ "$(type -t $cmd)" == "function" ]; then
    eval $cmd "$@"
  else
    echo "Missing object! Use:"
    echo "> please edit (pofile|translation|translation_from_pofile|untranslated)"
    sts=$STS_FAILED
  fi
  return $sts
}

do_edit_pofile() {
  [[ -f "./i18n/it.po" ]] && run_traced "poedit ./i18n/it.po" || echo "No file it.po found!"
  return $STS_STS_SUCCESS
}

do_edit_translation() {
  local xfile
  [[ -f "$HOME_DEVEL/pypi/tools/odoo_default_tnl.xlsx" ]] && xfile="$HOME_DEVEL/pypi/tools/odoo_default_tnl.xlsx"
  [[ -n "$xfile" ]] && run_traced "libreoffice $xfile" || echo "No file odoo_default_tnl.xlsx found!"
  return $STS_STS_SUCCESS
}

do_edit_translation_from_pofile() {
  local xfile
  local confn db module odoo_fver sts=$STS_FAILED opts pyv pofile
  if [[ ! "$PRJNAME" == "Odoo" ]]; then
    echo "No Odoo module"
    return $STS_FAILED
  fi
  module="."
  odoo_fver=$(build_odoo_param FULLVER '.')
  pofile="$(build_odoo_param PKGPATH '.')/i18n/it.po"
  module=$(build_odoo_param PKGNAME '.')
  if [[ -z "$odoo_fver" || -z "$module" ]]; then
    echo "Invalid Odoo environment!"
    return $STS_FAILED
  fi
  odoo_ver=$(echo $odoo_fver | grep --color=never -Eo '[0-9]+' | head -n1)
  if [[ ! -f "$pofile" ]]; then
    echo "File $pofile not found!"
    return $STS_FAILED
  fi
  pyv=$(python3 --version 2>&1 | grep --color=never -Eo "[0-9]+\.[0-9]+")
  [[ -n "$pyv" ]] && pyver="-p $pyv"
  pyver="-p 2.7" #debug
  [[ ! -d $HOME/clodoo/venv ]] && \
    run_traced "vem $pyver create $HOME/clodoo/venv" && \
    run_traced "vem $HOME/clodoo/venv install xlrd" && \
    run_traced "vem $HOME/clodoo/venv install Babel" && \
    run_traced "vem $HOME/clodoo/venv install clodoo"
  run_traced "pushd $HOME/clodoo >/dev/null"
  [ $opt_verbose -ne 0 ] && opts="-v" || opts="-q"
  [ $opt_dbg -ne 0 ] && opts="${opts}B"
  run_traced "vem $HOME/clodoo/venv exec \"odoo_translation.py $opts -b$odoo_fver -m $module -R $pofile\""
  sts=$?
  run_traced "popd >/dev/null"
  return $sts

  [[ -f "$HOME_DEVEL/pypi/tools/odoo_default_tnl.xlsx" ]] && xfile="$HOME_DEVEL/pypi/tools/odoo_default_tnl.xlsx"
  [[ -n "$xfile" ]] && run_traced "libreoffice $xfile" || echo "No file odoo_default_tnl.xlsx found!"
  return $STS_STS_SUCCESS
}

do_edit_untranslated() {
  local xfile
  [[ -f "$HOME/odoo_default_tnl.csv" ]] && run_traced "libreoffice $HOME/odoo_default_tnl.csv" || echo "No file odoo_default_tnl.csv found!"
  return $STS_STS_SUCCESS
}

create_pkglist() {
  # create_pkglist(pkgname type)
  local PKGLIST Z0LIB OELIB x
  local xx="$(get_cfg_value 0 filedel)"
  local yy="$(get_cfg_value 0 fileignore)"
  if [ $opt_keep -ne 0 ]; then
    xx="$xx $yy"
  else
    xx="$xx $yy tests/"
  fi
  if [ "$2" == "PkgList" -o "$2" == "binPkgList" -o "$2" == "etcPkgList" ]; then
    PKGLIST=$(cat setup.py | grep "# PKGLIST=" | awk -F= '{print $2}')
    if [ -n "$PKGLIST" ]; then
      PKGLIST="${PKGLIST//,/ }"
    fi
    if [ "$2" == "etcPkgList" ]; then
      x=$(cat setup.py | grep "# BUILD_WITH_Z0LIBR=" | awk -F= '{print $2}')
      if [ "$x" == "1" ]; then
        Z0LIB=$(findpkg z0librc "/etc . ..")
        [ -z "$Z0LIB" ] && Z0LIB=z0librc
      fi
      x=$(cat setup.py | grep "# BUILD_WITH_ODOORC=" | awk -F= '{print $2}')
      if [ "$x" == "1" ]; then
        OELIB=$(findpkg odoorc "/etc $HOME_DEVEL . ..")
        [ -z "$OELIB" ] && OELIB=odoorc
      fi
    fi
    if [ -z "$PKGLIST" -a "$2" == "PkgList" ]; then
      x="find . -type f"
      for f in $xx "setup.*"; do
        if [ "${f: -1}" == "/" ]; then
          x="$x -not -path '*/$f*'"
        else
          x="$x -not -name '*$f'"
        fi
      done
      eval $x >./tmp.log
      PKGLIST="$(cat ./tmp.log | tr '\n' ' ')"
      rm -f ./tmp.log
    fi
  fi
  echo "$PKGLIST $Z0LIB $OELIB"
}

add_file_2_pkg() {
  #add_file_2_pkg(pkgname type)
  local f s
  local PKGLIST=$(create_pkglist "$1" "$2")
  s=0
  for f in $PKGLIST; do
    if [ -f $f ]; then
      :
    elif [ "$2" == "etcPkgList" -a -f /etc/$f ]; then
      :
    elif [ ! -f $PKGPATH/$f ]; then
      s=1
      echo "File $f not found"
      break
    fi
  done
  return $s
}

do_build() {
  #do_build pgkname tar
  local sts=$STS_SUCCESS
  local rpt=pypi
  local f i l n p s v x y PKGLIST invalid PASSED
  local SETUP=./setup.sh
  local xx="$(get_cfg_value 0 filedel)"
  local yy="$(get_cfg_value 0 fileignore)"
  if [ $opt_keep -ne 0 ]; then
    xx="$xx $yy"
  else
    xx="$xx $yy tests/"
  fi
  if [ "$PRJNAME" != "Odoo" ]; then
    run_traced "cd $PKGPATH"
    # run_traced "mkdir -p tmp"
    s=$?; [ ${s-0} -ne 0 ] && sts=$s
    n=$(cat setup.py | grep "name *=" | awk -F= '{print $2}' | grep --color=never -Eo '[a-zA-Z0-9_-]+' | head -n1)
    v=$(cat setup.py | grep version | grep --color=never -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
    if [ ! -f "$n*$v*tar.gz" -o $opt_force -gt 0 ]; then
      PKGLIST=$(cat setup.py | grep "# PKGLIST=" | awk -F= '{print $2}')
      if [ -n "$PKGLIST" ]; then
        PKGLIST=${PKGLIST//,/ }
      else
        if [ "$PRJNAME" == "lisa" ]; then
          cp ../../clodoo/clodoo/odoorc ./
          cp ../../z0lib/z0lib/z0librc ./
        fi
        x="find . -type f"
        for f in $xx "setup.*"; do
          if [ "${f: -1}" == "/" ]; then
            x="$x -not -path '*/$f*'"
          else
            x="$x -not -name '*$f'"
          fi
        done
        eval $x >./tmp.log
        PKGLIST="$(cat ./tmp.log)"
        rm -f ./tmp.log
      fi
      invalid=
      for f in $PKGLIST; do
        if [ -f $f ]; then
          :
          #cp $f $PKGPATH/tmp
        else
          invalid=$f
        fi
      done
      if [ -n "$invalid" ]; then
        echo "File $f not found"
        return 1
      fi
      p="$n-$v.tar.gz"
      if [ -f $p ]; then
        run_traced "rm -f $p"
      fi
      echo "# $p" >$SETUP
      f=
      for i in {2..9}; do
        x=$(echo $PRJPATH | awk -F/ '{print $'$i'}')
        if [ -n "$x" ]; then
          f=$f/$x
          if [ $i -gt 3 ]; then
            echo "mkdir -p $f" >>$SETUP
          fi
        fi
      done
      l=${#PKGPATH}
      f=".${PRJPATH:l}" # subroot
      l=${#f}
      ((l++))
      PASSED=
      x="-cf"
      for f in $PKGLIST; do
        y=$(dirname ./${f:l})
        if [ "$y" != "." ]; then
          y=$(dirname ${f:l})
          if [[ " $PASSED " =~ [[:space:]]$y[[:space:]] ]]; then
            :
          else
            echo "mkdir -p $PRJPATH/$y" >>$SETUP
            PASSED="$PASSED $y"
          fi
          y=$y/
        else
          y=
        fi
        run_traced "tar $x $p $f"
        x=${x/c/r}
        # if [ -f "$f" ]; then rm -f $f; fi
        echo "cp -p $f $PKGPATH/$y" >>$SETUP
      done
      chmod +x $SETUP
      if [ -x $PRJPATH/setup.sh ]; then
        run_traced "cp $PRJPATH/setup.sh $SETUP"
      fi
      run_traced "tar $x $p $SETUP"
      run_traced "rm -f $SETUP"
    fi
  fi
  return $sts
}

do_distribution_pypi() {
  echo "Deprecated action!"
  local sts=$STS_SUCCESS
  diff -q ~/agpl.txt ./LICENSE &>/dev/null || run_traced "cp ~/agpl.txt  ./LICENSE"
  if [ -d docs ]; then
    OPTS=-lmodule
    [ -f README.md.bak ] && run_traced "rm -fR README.md.bak"
    [ -f README.md ] && run_traced "mv README.md README.md.bak"
    run_traced "gen_readme.py -qGzero $OPTS"
    do_docs
  fi
  return $sts
}

do_distribution_odoo() {
  echo "Deprecated action!"
  local sts=$STS_SUCCESS
  local currpt=zero
  local ORIG= GIT_ORG=$2 UPSTREAM= OPTS
  local b f f1 f2 tmod x
  local odoo_ver=$(get_ver)
  [ -z "$GIT_ORG" ] && GIT_ORG=zero
  [ ${test_mode:-0} -eq 0 ] && tmod="" || tmod="default"
  if [ -n "$3" ]; then
    local travis_passed=1
    if [ -d $3/tmp ]; then
      ORIG=$3/tmp
    elif [ -d ~/original/$1 ]; then
      ORIG=~/original/$1
    fi
  else
    local travis_passed=0
    set_remote_info "$REPOSNAME" "." "$GIT_ORG"
  fi
  if [ -f .gitrepname ]; then
    currpt=$(grep "^repository" .gitrepname | awk -F= '{print $2}' | tr -d " ")
  fi
  local GITPRJ=$(build_odoo_param RUPSTREAM '.' "$tmod" $GIT_ORG)
  if [ -z "$GITPRJ" ]; then
    local GITPRJ=$(build_odoo_param RORIGIN '.' "$tmod" $GIT_ORG)
  fi
  if [ $travis_passed -eq 0 ]; then
#    if [ $opt_orig -gt 0 ]; then
#      if [ -z "$GITPRJ" ]; then
#        echo "git project not found!"
#        sts=$STS_FAILED
#      else
#        run_traced "git clone $GITPRJ tmp -b $BRANCH --depth 1 --single-branch"
#        ORIG=$(readlink -e tmp)
#      fi
#    else
      if [ -d ~/original ]; then rm -fR -d ~/original; fi
      if [ -n "$GITPRJ" ]; then
        run_traced "git clone $GITPRJ ~/original/$1 -b $BRANCH --depth 1 --single-branch"
        ORIG=$(readlink -e ~/original/$1)
      fi
#    fi
  fi
  if [ $travis_passed -eq 0 ]; then
    cvt_gitmodule "$GIT_ORG" "$currpt"
    if [ $sts -eq $STS_SUCCESS ]; then
      f1=oca_dependencies.txt
      if [ -f "$f1" ]; then
        cvt_file $f1 $GIT_ORG "" "$currpt" "$ORIG"
        sts=$?
      fi
    fi
  fi
  local PKGS= FL= PIGN=
  for f in $(find . -type f \( -name __openerp__.py -o -name __manifest__.py -o -name ".travis.yml" -o -name "README*" -a -not -name "*.bak" -a -not -name "*~" -a -not -name "*.z0i" -a -not -name "*.oca" -a -not -name "*.tmp" \)); do
    x=$(readlink -e $f)
    f1=$(dirname $x)
    f2=$(build_odoo_param REPOS $f1)
    b=$(basename $f)
    if [ -f .gitmodules ] && grep -q "submodule[[:space:]].$f2" .gitmodules 2>/dev/null; then
      if [[ ! " $PKGS " =~ [[:space:]]$f2[[:space:]] ]]; then
        [ $opt_verbose -gt 0 ] && echo "Found submodule $f2 ..."
        PKGS="$PKGS $f2"
      fi
    elif [ "$f2" != "OCB" -a -f .gitignore ] && grep -q "^$f2/$" .gitignore 2>/dev/null; then
      if [[ ! " $PIGN " =~ [[:space:]]$f2[[:space:]] ]]; then
        [ $opt_verbose -gt 0 ] && echo "Submodule $f2 ignored ..."
        PIGN="$PIGN $f2"
      fi
    fi
  done
  for f in $PKGS; do
    if [ $sts -ne $STS_SUCCESS ]; then
      break
    fi
    f2=$(basename $f)
    if [ ${test_mode:-0} -eq 0 -a ! -f $f2/LICENSE ]; then
      if [ $odoo_ver -ge 10 -a "$PRJNAME" == "Odoo" ]; then
        diff -q ~/lgpl.txt $f2/LICENSE &>/dev/null || run_traced "cp ~/lgpl.txt  $f2/LICENSE"
      else
        diff -q ~/agpl.txt $f2/LICENSE &>/dev/null || run_traced "cp ~/agpl.txt  $f2/LICENSE"
      fi
    fi
  done
  f2=$(readlink -e .)
  for f in $(find . -type d -name 'egg-info'); do
    d=$(dirname $f)
    run_traced "pushd $d >/dev/null"
    if [[ "$PWD" == "$f2" ]]; then
      OPTS=-lrepository
    else
      OPTS=-lmodule
    fi
    [[ -f README.md ]] && run_traced "rm -fR README.md"
    run_traced "gen_readme.py -qG$GIT_ORG $OPTS"
    if [ $odoo_ver -ge 8 ]; then
      if [ -f __openerp__.py -o -f __manifest__.py ]; then
        [ ! -d ./static ] && mkdir -p ./static
        [ ! -d ./static/description ] && mkdir -p ./static/description
        [ -d ./static/src/img/icon.png -a ! -d ./static/description/icong.png ] && run_traced "mv ./static/src/img/* ./static/description/"
        run_traced "gen_readme.py -qH -G$GIT_ORG $OPTS"
      fi
    else
      if [ -f __openerp__.py ]; then
        [ ! -d ./static ] && mkdir -p ./static
        [ ! -d ./static/src ] && mkdir -p ./static/src
        [ ! -d ./static/src/img ] && mkdir -p ./static/src/img
        [ -d ./static/description/icong.png -a ! -d ./static/src/img/icon.png ] && run_traced "mv ./static/description/* ./static/src/img/"
        run_traced "gen_readme.py -qR -G$GIT_ORG $OPTS"
      fi
    fi
    run_traced "popd >/dev/null"
  done
  if [ $opt_r -gt 0 ]; then
    for f in $PKGS; do
      if [ $sts -ne $STS_SUCCESS ]; then
        break
      fi
      local PKG=$(basename $f)
      cd $f
      pushd $f >/dev/null
      revaluate_travis
      do_distribution $PKG $2 "$CCWD"
      sts=$?
      popd >/dev/null
    done
  fi
  revaluate_travis
  if [ $sts -eq $STS_SUCCESS -a -z "$3" ]; then
    if [ -f .gitignore ]; then
      if ! grep -q "\.gitrepname" .gitignore 2>/dev/null; then
        echo ".gitrepname" >>.gitignore
      fi
    fi
  fi
  if [ $sts -eq $STS_SUCCESS ]; then
    if [ -d tmp -a $opt_keep -eq 0 ]; then
      rm -fR tmp
    fi
    if [ -f .gitrepname ]; then
      if [ "$2" != "$currpt" ]; then
        run_traced "sed -i -e 's:^repository *=.*:repository=$2:' .gitrepname"
      fi
    else
      echo "repository=$2" >>.gitrepname
    fi
    restore_owner "$2"
  fi
  return $sts
}

do_distribution() {
  # do_distribution(repos oca|zero parent)
  echo "Deprecated action!"
  local sts
  wlog "do_distribution $1 $2 $3"
  if [ "$PRJNAME" == "Odoo" ]; then
    do_distribution_odoo "$1" "$2" "$3"
    sts=$?
  else
    do_distribution_pypi "$1" "$2" "$3"
    sts=$?
  fi
  return $sts
}

do_docs() {
  wlog "do_docs"
  local docs_dir=./docs
  local author version theme SETUP b f l t x
  local opts src_png odoo_fver REPO
  [[ $opt_dbg -ne 0 || $PWD =~ /devel/pypi/ ]] && opts=-B || opts=
  if [ "$PRJNAME" == "Odoo" ]; then
    [[ -z "$opt_branch" ]] && odoo_fver=$(build_odoo_param FULLVER ".") || odoo_fver=$(build_odoo_param FULLVER "$opt_branch")
    [[ -z "$opt_branch" ]] && orgid=$(build_odoo_param GIT_ORGID ".") || orgid=$(build_odoo_param GIT_ORGID "$opt_branch")
    REPO=$(build_odoo_param REPOS ".")
    # TODO: GIT_ORGid of build_odoo_param does not work
    PARENTDIR=$(build_odoo_param PARENTDIR ".")
    if [[ -z "$opt_branch" && -d ./.git && $(git status -s &>/dev/null) ]]; then
      GIT_URL=$(git remote get-url --push origin 2>/dev/null)
      [[ -n "$GIT_URL" ]] && GIT_ORGNM=$(basename $(dirname $(git remote -v | echo $GIT_URL | awk -F: '{print $2}')))
      [[ $GIT_ORGNM == "OCA" ]] && orgid="oca"
      [[ $GIT_ORGNM == "zeroincombenze" ]] && orgid="zero"
      [[ $GIT_ORGNM =~ (PowERP-cloud|powerp1) ]] && orgid="powerp"
    elif [[ -z "$opt_branch" && -d $PARENTDIR/.git ]]; then
      pushd $PARENTDIR >/dev/null
      GIT_URL=$(git remote get-url --push origin 2>/dev/null)
      [[ -n "$GIT_URL" ]] && GIT_ORGNM=$(basename $(dirname $(git remote -v | echo $GIT_URL | awk -F: '{print $2}')))
      [[ $GIT_ORGNM == "OCA" ]] && orgid="oca"
      [[ $GIT_ORGNM == "zeroincombenze" ]] && orgid="zero"
      [[ $GIT_ORGNM =~ (PowERP-cloud|powerp1) ]] && orgid="powerp"
      popd >/dev/null
    fi
    if [[ -f ./__manifest__,py || -f ./__openerp__.py ]]; then
      l=$(build_odoo_param LICENSE "." "" "" "search")
      [[ $licence == "AGPL" && -f $HOME_DEVEL/license_text/agpl-3.0.txt ]] && run_traced "cp -p $HOME_DEVEL/license_text/agpl-3.0.txt ./LICENSE"
      [[ $licence == "LGPL" && -f $HOME_DEVEL/license_text/lgpl-3.0.txt ]] && run_traced "cp -p $HOME_DEVEL/license_text/lgpl-3.0.txt ./LICENSE"
      [[ $licence == "OPL" && -f $HOME_DEVEL/license_text/opl-1.0.txt ]] && run_traced "cp -p $HOME_DEVEL/license_text/opl-1.0.txt ./LICENSE"
    fi
    if [[ $opt_oca -ne 0 ]]; then
      run_traced "oca-gen-addon-readme --gen-html --branch 12.0 $odoo_fver --repo-name $REPO"
    else
      run_traced "gen_readme.py -b$odoo_fver $opts -G$orgid"
    fi
    version=$(build_odoo_param MAJVER $odoo_fver)
    if [[ ! -d ./static ]]; then
      run_traced "mkdir ./static"
      [[ $version -le 7 ]] && run_traced "mkdir ./static/src" && run_traced "mkdir ./static/src/img"
      [[ $version -gt 7 ]] && run_traced "mkdir ./static/description"
    fi
    if [[ ! -d ./egg-info && ! -d ./readme ]]; then
      mkdir ./egg-info
      opt_force=0
      run_traced "gen_readme.py -b$odoo_fver $opts -RW -G$orgid"
    fi
    [[ $version -gt 7 ]] && run_traced "gen_readme.py -b$odoo_fver $opts -H -G$orgid"
    [[ $version -le 7 && $opt_force -eq 0 ]] && run_traced "gen_readme.py -b$odoo_fver $opts -R -G$orgid"
    [[ $opt_force -ne 0 ]] && run_traced "gen_readme.py -b$odoo_fver $opts -RW -G$orgid"
    return 0
  fi
  if [[ ! -d $docs_dir ]]; then
    if [[ $opt_force -eq 0 ]]; then
      echo "Missing docs directory!"
      return 1
    fi
    run_traced "mkdir $docs_dir"
  fi
  if [[ ! -f $docs_dir/logozero_180x46.png ]]; then
    src_png=
    [[ -z "$src_png" && -f ../tools/docs/logozero_180x46.png ]] && src_png=$(readlink -e ../tools/docs/logozero_180x46.png)
    [[ -z "$src_png" && -f ../../tools/docs/logozero_180x46.png ]] && src_png=$(readlink -e ../../tools/docs/logozero_180x46.png)
    [[ -n "$src_png" ]] && run_traced "cp $src_png $docs_dir/logozero_180x46.png"
  fi
  for f in $(grep -E "^ *(rtd_|pypi_)" docs/index.rst | tr "\n" " "); do
    echo ".. toctree::" >./rtd_template.rst
    echo "   :maxdepth: 2" >>./rtd_template.rst
    echo "" >>./rtd_template.rst
    if [[ "$f" == "rtd_automodule" ]]; then
      echo "Code documentation" >>./rtd_template.rst
      echo "------------------" >>./rtd_template.rst
      echo "" >>./rtd_template.rst
      for b in $(cat __init__.py | grep "^from . import" | awk '{print $4}' | tr "\n" " "); do
        echo -e ".. automodule:: $PKGNAME.$b\n" >>./rtd_template.rst
      done
      run_traced "mv ./rtd_template.rst $docs_dir/rtd_automodule.rst"
    elif [[ $f =~ ^rtd_ ]]; then
      t=${f:4}
      [[ $t == "features" ]] && echo -e "Features\n--------" >>./rtd_template.rst
      [[ $t == "usage" ]] && echo -e "Usage\n-----" >>./rtd_template.rst
      echo "{{$t}}" >>./rtd_template.rst
      echo ".. \$include readme_footer.rst" >>./rtd_template.rst
      run_traced "gen_readme.py $opts -t ./rtd_template.rst -o $docs_dir/$f.rst"
      run_traced "rm ./rtd_template.rst"
    elif [[ $f =~ ^pypi_ ]]; then
      x=$(echo $f | grep --color=never -Eo "^pypi.*/index")
      b=${x:0:-6}
      x=${x:5:-6}
      [[ -d $docs_dir/$b ]] || run_traced "mkdir -p $docs_dir/$b"
      run_traced "rsync -avz --delete $HOME_DEVEL/pypi/$x/$x/docs/ $docs_dir/$b/"
    fi
  done
  # [[ $(basename $PWD) == "tools" && -f egg-info/history.rst ]] && run_traced "rm -f egg-info/history.rst"
  [[ $(basename $PWD) == "tools" ]] && run_traced "gen_readme.py $opts -W" || run_traced "gen_readme.py $opts"
  [[ $(grep "\.\. include:: MAINPAGE.rst" docs/index.rst) ]] && run_traced "gen_readme.py $opts -t mainpage -o $docs_dir/MAINPAGE.rst"
  run_traced "pushd $docs_dir >/dev/null"
  if [[ ! -f index.rst || ! -f conf.py ]]; then
    # SETUP=$(build_pypi_param SETUP)
    version=$(get_value_from_file "$SETUP" "version")
    author=$(get_value_from_file "$SETUP" "author")
    run_traced "sphinx-quickstart -p '$PRJNAME' -a '$author' -v '$version' -r '$version' -l en --no-batchfile --makefile --master index --suffix .rst ./"
    cat <<EOF >conf.py
# -*- coding: utf-8 -*-
#
# Configuration file for the Sphinx documentation on $(date "+%Y-%m-%d %H:%M:%S")
#
# This file does only contain a selection of the most common options. For a
# full list see the documentation:
# http://www.sphinx-doc.org/en/master/config

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
import os
# import sys
# sys.path.insert(0, os.path.abspath('.'))
import sphinx_rtd_theme


# -- Project information -----------------------------------------------------

project = '$PRJNAME'
copyright = '2022, $author'
author = '$author'

# The short X.Y version
version = '$version'
# The full version, including alpha/beta/rc tags
release = '$version'


# -- General configuration ---------------------------------------------------

# If your documentation needs a minimal Sphinx version, state it here.
#
# needs_sphinx = '1.0'

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    'sphinx_rtd_theme',
    'sphinx.ext.todo',
    'sphinx.ext.githubpages',
]


# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# The suffix(es) of source filenames.
# You can specify multiple suffix as a list of string:
#
# source_suffix = ['.rst', '.md']
source_suffix = '.rst'

# The master toctree document.
master_doc = 'index'

# The language for content autogenerated by Sphinx. Refer to documentation
# for a list of supported languages.
#
# This is also used if you do content translation via gettext catalogs.
# Usually you set "language" from the command line for these cases.
language = 'en'

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store',
                    'description*', 'descrizione*', 'features*',
                    'oca_diff*', 'certifications*', 'prerequisites*',
                    'installation*', 'configuration*', 'upgrade*',
                    'support*', 'usage*', 'maintenance*',
                    'troubleshooting*', 'known_issues*',
                    'proposals_for_enhancement*', 'history*', 'faq*',
                    'sponsor*', 'copyright_notes*', 'available_addons*',
                    'contact_us*',
                    '__init__*', 'name*', 'summary*', 'sommario*',
                    'maturity*', 'module_name*', 'repos_name*',
                    'today*',
                    'authors*', 'contributors*', 'translators*',
                    'acknowledges*']

# The name of the Pygments (syntax highlighting) style to use.
# pygments_style = None
pygments_style = 'sphinx'


# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
# on_rtd is whether we are on readthedocs.org,
# this line of code grabbed from docs.readthedocs.org
#     html_theme = 'master'

# Theme options are theme-specific and customize the look and feel of a theme
# further.  For a list of options available for each theme, see the
# documentation.
#
html_theme_options = {
    # 'canonical_url': '',
    # 'analytics_id': 'UA-XXXXXXX-1',
    # 'logo_only': False,
    # 'display_version': True,
    # 'prev_next_buttons_location': 'bottom',
    # 'style_external_links': False,
    # 'vcs_pageview_mode': '',
    # 'style_nav_header_background': 'white',
    # Toc options
    # 'collapse_navigation': True,
    # 'sticky_navigation': True,
    # 'navigation_depth': 4,
    # 'includehidden': True,
    # 'titles_only': False
}

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['_static']

# Custom sidebar templates, must be a dictionary that maps document names
# to template names.
#
# The default sidebars (for documents that don't match any pattern) are
# defined by theme itself.  Builtin themes are using these templates by
# default: ``['localtoc.html', 'relations.html', 'sourcelink.html',
# 'searchbox.html']``.
#
# html_sidebars = {}
html_logo = 'logozero_180x46.png'
EOF
    cat <<EOF >index.rst
.. $PRJNAME documentation master file, created by
   sphinx-quickstart on $(date "+%Y-%m-%d %H:%M:%S")
   You can adapt this file completely to your liking, but it should at least
   contain the root \`toctree\` directive.

===========================================
Welcome to $PRJNAME $version documentation!
===========================================

|Maturity| |Build Status| |Coverage Status| |license gpl|

.. toctree::
   :maxdepth: 2
   :caption: Contents:

.. include:: MAINPAGE.rst


Indices and tables
==================

* :ref:\`genindex\`
* :ref:\`modindex\`
* :ref:\`search\`
EOF
  fi
  if [ ! -f requirements.txt ]; then
    cat <<EOF >requirements.txt
sphinx_rtd_theme
EOF
  fi
  if [ ! -f readthedocs.yml ]; then
    cat <<EOF >readthedocs.yml
# readthedocs.yml
# Read the Docs configuration file
# See https://docs.readthedocs.io/en/stable/config-file/v2.html for details

# Required
version: 2

# Build documentation in the docs/ directory with Sphinx
sphinx:
  configuration: docs/conf.py

# Build documentation with MkDocs
#mkdocs:
#  configuration: mkdocs.yml

# Optionally build your docs in additional formats such as PDF and ePub
formats: all

# Optionally set the version of Python and requirements required to build your docs
python:
  version: 3.7
  install:
    - requirements: docs/requirements.txt

sphinx:
  builder: html
  configuration: conf.py
  fail_on_warning: true
EOF
  fi
  run_traced "make html"
  sts=$?
  run_traced "popd >/dev/null"
  return $sts
}

do_duplicate() {
  set_executable
  if [ "$PRJNAME" == "Odoo" ]; then
    if [[ ! $LGITPATH =~ (14\.0|13\.0|12\.0|11\.0|10\.0|9\.0|8\.0|7\.0|6\.1) ]]; then
      echo "Missing or invalid target Odoo version"
      exit 1
    fi
    cur_ver=""
    for ver in 14.0 13.0 12.0 11.0 10.0 9.0 8.0 7.0 6.1; do
      if [[ $PWD =~ $HOME/$ver ]]; then
        cur_ver="$ver"
        break
      fi
    done
    if [ -z "$cur_ver" ]; then
      echo "Unrecognized Odoo version"
      exit 1
    fi
    LGITPATH="${PWD/$cur_ver/$LGITPATH}"
    opts=$(inherits_travis_opts "D" "D")
    opt_dry_run=0
    run_traced "$TDIR/dist_pkg $opts $1 -p$LGITPATH"
    sts=$?
  fi
  return $sts
}

do_export() {
  wlog "do_export '$1' '$2' '$3'"
  local db dbdt dummy DBs m module odoo_fver path pofile sts=$STS_FAILED u
  if [[ $PRJNAME != "Odoo" ]]; then
    echo "This action can be issued only on Odoo projects"
    return $sts
  fi
  odoo_fver=$(build_odoo_param FULLVER ".")
  m=$(build_odoo_param MAJVER ".")
  module=$(build_odoo_param PKGNAME ".")
  if [[ -z "$module" ]]; then
    echo "Invalid environment!"
    return $sts
  fi
  path=$(build_odoo_param PKGPATH '.')
  if [[ ! -d $PKGPATH/i18n ]]; then
    echo "Directory $PKGPATH/i18n not found!"
    read -p "Create $PKGPATH/i18n (y/n)?" dummy
    [[ $dummy != "y" ]] && return $sts
    mkdir $PKGPATH/i18n
  fi
  pofile="$PKGPATH/i18n/it.po"
  if [[ ! -f $pofile ]]; then
    echo "File $pofile not found!"
    read -p "Create empty file $pofile (y/n)?" dummy
    [[ $dummy != "y" ]] && return $sts
    makepo_it.py -m $module -b $odoo_fver -f $pofile
  fi
  db="$opt_db"
  u=$(get_dbuser $m)
  if [[ -z "$db" ]]; then
    DBs=$(psql -U$u -Atl | awk -F'|' '{print $1}' | tr "\n" '|')
    DBs="^(${DBs:0: -1})\$"
    for x in test_openerp_ tnl test demo; do
      [[ $x =~ $DBs ]] && db="$x" && break
      [[ $x$m =~ $DBs ]] && db="$x$m" && break
    done
  fi
  if [[ -z "$db" ]]; then
    echo "No DB matched! use:"
    echo "$0 export -d DB"
    return $STS_FAILED
  fi
  stat=$(psql -U$u -Atc "select state from ir_module_module where name = '$module'" $db)
  [[ -z "$stat" || $stat == "uninstalled" ]] && echo "Module $module not installed in $db!" && exit $sts
  # dbdt=$(psql -U$u -Atc "select write_date from ir_module_module where name='$module' and state='installed'" $db)
  # [[ -n "$dbdt" ]] && dbdt=$(date -d "$dbdt" +"%s") || dbdt="999999999999999999"
  # podt=$(stat -c "%Y" $pofile)
  # ((dbdt < podt)) && run_traced "run_odoo_debug -b$odoo_fver -usm $module -d $db"
  run_traced "run_odoo_debug -b$odoo_fver -em $module -d $db"
  sts=$?
  return $sts
}

do_import() {
  wlog "do_import '$1' '$2' '$3'"
  local db dbdt dummy DBs m module odoo_fver path pofile sts=$STS_FAILED u
  if [[ $PRJNAME != "Odoo" ]]; then
    echo "This action can be issued only on Odoo projects"
    return $sts
  fi
  odoo_fver=$(build_odoo_param FULLVER ".")
  m=$(build_odoo_param MAJVER ".")
  module=$(build_odoo_param PKGNAME ".")
  [[ $module != $(basename $PWD) ]] && module=$1
  if [[ -z "$module" ]]; then
    echo "Invalid environment!"
    return $sts
  fi
  path=$(build_odoo_param PKGPATH '.')
  if [[ ! -d $PKGPATH/i18n ]]; then
    echo "Directory $PKGPATH/i18n not found!"
    return $sts
  fi
  pofile="$PKGPATH/i18n/it.po"
  if [[ ! -f $pofile ]]; then
    echo "File $pofile not found!"
    return $sts
  fi
  db="$2"
  if [[ -z "$db" ]]; then
    u=$(get_dbuser $m)
    DBs=$(psql -U$u -Atl | awk -F'|' '{print $1}' | tr "\n" '|')
    DBs="^(${DBs:0: -1})\$"
    for x in tnl test demo; do
      [[ $x$m =~ $DBs ]] && db="$x$m" && break
    done
  fi
  if [[ -z "$db" ]]; then
    echo "No DB matched! use:"
    echo "$0 import 'DB'"
    return $STS_FAILED
  fi
  stat=$(psql -U$u -Atc "select state from ir_module_module where name = '$module'" $db)
  [[ -z "$stat" || $stat == "uninstalled" ]] && echo "Module $module not installed in $db!" && exit $sts
  run_traced "run_odoo_debug -b$odoo_fver -im $module -d $db"
  sts=$?
  return $sts
}

do_list() {
  local ii x y tgtpath tgtparm
  for ii in {1..9}; do
    x=tgt${ii}path
    y=tgt${ii}params
    tgtpath="$(get_cfg_value 0 $x)"
    if [ -n "$tgtpath" ]; then
      printf "%2d %s\n" $ii "$tgtpath"
    fi
  done
}

do_translate() {
  wlog "do_translate '$1' '$2' '$3'"
  local db dbdt dummy DBs m module odoo_fver path sts=$STS_FAILED u x
  local confn opts pofile
  if [[ $PRJNAME != "Odoo" ]]; then
    echo "This action can be issued only on Odoo projects"
    return $sts
  fi
  odoo_fver=$(build_odoo_param FULLVER ".")
  m=$(build_odoo_param MAJVER ".")
  module=$(build_odoo_param PKGNAME ".")
  if [[ -z "$module" ]]; then
    echo "Invalid environment!"
    return $sts
  fi
  pofile="$PKGPATH/i18n/it.po"
  if [[ ! -f $pofile ]]; then
    echo "File $pofile not found!"
    return $sts
  fi
  confn=$(readlink -f $HOME_DEVEL/../clodoo/confs)/${odoo_fver/./-}.conf
  [[ ! -f $confn ]] && echo "Configuration file $confn not found!" && return $sts
  db="$opt_db"
  u=$(get_dbuser $m)
  if [[ -z "$db" ]]; then
    DBs=$(psql -U$u -Atl | awk -F'|' '{print $1}' | tr "\n" '|')
    DBs="^(${DBs:0: -1})\$"
    for x in test_openerp_ tnl test demo; do
      [[ $x =~ $DBs ]] && db="$x" && break
      [[ $x$m =~ $DBs ]] && db="$x$m" && break
    done
  fi
  if [[ -z "$db" ]]; then
    echo "No DB matched! use:"
    echo "$0 translate -d DB"
    return $STS_FAILED
  fi
  [[ $opt_verbose -ne 0 ]] && opts="-v" || opts="-q"
  [[ $opt_dbg -ne 0 ]] && opts="${opts}B"
  x=$(find $PKGPATH -type f -not -path "*/egg-info/*" -not -name "*.pyc" -anewer i18n/it.po)
  [[ -n $x ]] && do_export "$1" "$2" "$3"
  run_traced "odoo_translation.py $opts -b$odoo_fver -m $module -d $db -c $confn -p $pofile -AP"
  sts=$?
  return $sts
}

do_lint() {
    wlog "do_lint '$1' '$2' '$3'"
    local sts=$STS_FAILED s x
    [[ -z $FLAKE8_CONFIG && -f $HOME_DEVEL/maintainer-quality-tools/travis/cfg/travis_run_flake8.cfg ]] && run_traced "export FLAKE8_CONFIG_DIR=$($READLINK -f $HOME_DEVEL/maintainer-quality-tools/travis/cfg/travis_run_flake8.cfg)"
    if [[ -z $FLAKE8_CONFIG ]]; then
      x=$(find $HOME_DEVEL/venv/lib -type d -name site-packages)
      [[ -n $x ]] && run_traced "export FLAKE8_CONFIG=$($READLINK -f $x/zerobug/_travis/cfg/travis_run_flake8.cfg)"
    fi
    [[ -z $FLAKE8_CONFIG ]] && echo "Non flake8 configuration file found!" && return 1
    run_traced "flake8 --config=$FLAKE8_CONFIG --extend-ignore=B006 --max-line-length=88 ./"
    sts=$?
    [[ -z $PYLINT_CONFIG_DIR && -f $HOME_DEVEL/maintainer-quality-tools/travis/cfg/travis_run_pylint_beta.cfg ]] && run_traced "export FLAKE8_CONFIG_DIR=$($READLINK -f $HOME_DEVEL/maintainer-quality-tools/travis/cfg)"
    if [[ -z $PYLINT_CONFIG_DIR ]]; then
      x=$(find $HOME_DEVEL/venv/lib -type d -name site-packages)
      [[ -n $x ]] && run_traced "export PYLINT_CONFIG_DIR=$($READLINK -f $x/zerobug/_travis/cfg)"
    fi
    [[ -z $PYLINT_CONFIG_DIR ]] && echo "Non pylint configuration file found!" && return 1
    run_traced "pylint --rcfile=$PYLINT_CONFIG_DIR/travis_run_pylint_beta.cfg ./"
    s=$?; [[ $s -ne 0 ]] && sts=$s
    return $sts
}

do_test() {
    wlog "do_test '$1' '$2' '$3'"
    local db m module odoo_fver opts svcname sts=$STS_FAILED x
    if [[ $PRJNAME != "Odoo" ]]; then
      echo "This action can be issued only on Odoo projects"
      return 1
    fi
    opt_multi=1
    odoo_fver=$(build_odoo_param FULLVER $PWD)
    m=$(build_odoo_param MAJVER $PWD)
    module=$(build_odoo_param PKGNAME $PWD)
    [[ $module != $(basename $PWD) ]] && module=$1
    if [[ -z "$module" ]]; then
      echo "Invalid environment!"
      return $sts
    fi
    [[ $opt_dbg -ne 0 ]] && x="-B"
    [[ $opt_dbg -gt 1 ]] && x="-BB"
    [[ -n $opt_ocfn ]] && svcname=$(basename "$opt_ocfn") || svcname=$(build_odoo_param SVCNAME "$(readlink -f $PWD)")
    opts="-b $odoo_fver"
    [[ -f /etc/odoo/${svcname}.conf ]] && opts="-c /etc/odoo/${svcname}.conf"
    [[ -n $opt_ocfn && -f "$opt_ocfn" ]] && opts="-c $opt_ocfn"
    run_traced "run_odoo_debug $opts -Tm $module $x"
    sts=$?
    return $sts
}

do_lsearch() {
  # search n log ([date] db token)
  wlog "do_lsearch '$1' '$2' '$3'"
  local CM cmd db f LOGDIRS odoo_fver odoo_ver PM sts=$STS_FAILED tok_dt token
  [ -n "$opt_branch" ] && odoo_fver=$opt_branch || odoo_fver=10.0
  odoo_ver=$(echo $odoo_fver | grep --color=never -Eo '[0-9]+' | head -n1)
  tok_dt=$opt_date
  CM=$(date +%Y-%m)
  PM=$(date -d "1 month ago" +%Y-%m)
  db=$1
  token=$2
  if [ "$CM" == "$PM" ]; then
    LOGDIRS="/var/log/odoo/odoo$odoo_ver.log.$CM-* /var/log/odoo/odoo$odoo_ver.log"
  else
    LOGDIRS="/var/log/odoo/odoo$odoo_ver.log.$PM-* /var/log/odoo/odoo$odoo_ver.log.$CM-* /var/log/odoo/odoo$odoo_ver.log"
  fi
  for f in $LOGDIRS; do
    if [ -n "$tok_dt" ]; then
      if [ -n "$token" ]; then
        cmd="grep -a -A 10 --color=never \"^$tok_dt.* $db .*$token\" $f|grep -av --color=never \"/longpolling/poll HTTP/1.1\"|grep -av --color=never \"POST /jsonrpc HTTP/1.1. 200\"|grep -a --color \"$token\""
      else
        cmd="grep -av --color=never \"/longpolling/poll HTTP/1.1\" $f|grep -av --color=never \"POST /jsonrpc HTTP/1.1. 200\"|grep -a \"^$tok_dt.* $db .*\""
      fi
    else
      if [ -n "$token" ]; then
        cmd="grep -a -A 10 --color=never \" $db .*$token\" $f|grep -av --color=never \"/longpolling/poll HTTP/1.1\"|grep -av --color=never \"POST /jsonrpc HTTP/1.1. 200\"|grep -a --color \"$token\""
      else
        cmd="grep -av --color=never \"/longpolling/poll HTTP/1.1\" $f|grep -av --color=never \"POST /jsonrpc HTTP/1.1. 200\"|grep -a \" $db .*\""
      fi
    fi
    if [ $opt_dry_run -eq 0 ]; then
      eval $cmd
    else
      echo $cmd
    fi
  done
}

do_push() {
  opts=$(inherits_travis_opts "oP" "D")
  opt_dry_run=0
  run_traced "$TDIR/dist_pkg $opts $1"
  sts=$?
  return $sts
}

do_pythonhosted() {
  wlog "do_pythonhosted $1 $2 $3"
  sts=$STS_SUCCESS
  if [ -z "$2" ]; then
    echo "Missing URL! use:"
    echo "> please pythonhosted URL"
    return $STS_FAILED
  fi
  local URL=$2
  if [ "${URL: -1}" != "/" ]; then
    local URL=$URL/
  fi
  local TITLE="$3"
  local CWD=$PWD
  run_traced "cd $PKGPATH"
  cat <<EOF >index.html
<!DOCTYPE HTML>
   <head>
       <meta http-equiv="refresh" content="0; $URL">
       <script type="text/javascript">
           top.location.href = "$URL"
       </script>
       <title>Redirect</title>
   </head>
   <body>
       Please wait for a moment .. <a href='$URL' $2</a>
   </body>
</html>
EOF
  run_traced "zip -j pythonhosted-$PKGNAME.zip index.html"
  if [ -f index.html ]; then
    rm -f index.html
  fi
  cd $CWD
  if [ -f $PKGPATH/pythonhosted-$PKGNAME.zip ]; then
    echo "Now you can download $PKGPATH/pythonhosted-$PKGNAME.zip in pypi webpage of project"
  fi
  return $sts
}

do_register() {
  #do_register PKGNAME (pypi|testpypi)
  wlog "do_register $1 $2"
  local cmd="do_register_$1"
  sts=$STS_SUCCESS
  if [ "$(type -t $cmd)" == "function" ]; then
    eval $cmd "$@"
  else
    echo "Missing object! Use:"
    echo "> please register (pypi|testpypi)"
    sts=$STS_FAILED
  fi
  return $sts
}

do_replace() {
    wlog "do_replace '$1' '$2' '$3'"
    local f opts t
    if [[ $PRJNAME == "Odoo" ]]; then
      echo "This action can be issued only on PYPI projects"
      return $sts
    fi
    # do_distribution_pypi "$@"
    for f in $PRJPATH/*; do
      t=$(file -b --mime-type $f)
      [[ $t != "application/x-sharedlib" && ( -x $f || $f =~ .py$ ) && ! -d $f ]] && grep -q "^#\!.*/venv/bin/python3$" $f &>/dev/null && run_traced "sed -i -e \"s|^#\!.*/venv/bin/python3$|^#\!/usr/bin/env python3|\" $f"
      [[ $t != "application/x-sharedlib" && ( -x $f || $f =~ .py$ ) && ! -d $f ]] && grep -q "^#\!.*/venv/bin/python3$" $f &>/dev/null && run_traced "sed -i -e \"s|^#\!.*/venv/bin/python2$|^#\!/usr/bin/env python2|\" $f"
      [[ $t != "application/x-sharedlib" && ( -x $f || $f =~ .py$ ) && ! -d $f ]] && grep -q "^#\!.*/venv/bin/python$" $f &>/dev/null && run_traced "sed -i -e \"s|^#\!.*/venv/bin/python2$|^#\!/usr/bin/env python|\" $f"
    done
    do_docs
    clean_dirs "$PKGPATH"
    opts=$(inherits_travis_opts "R" "D")
    run_traced "$TDIR/dist_pkg.sh $opts $1"
    sts=$?
    [[ $(basename $PRJPATH) != "tools" ]] && clean_dirs "$HOME_DEVEL/tools"
    [[ $opt_force -ne 0 ]] && set_executable
    return $sts
}

do_replica() {
  # do_replica(pkgname file)
  local cur_ver fn srcfn tp ver
  if [[ $PRJNAME == "Odoo" ]]; then
    cur_ver=""
    for ver in 14.0 13.0 12.0 11.0 10.0 9.0 8.0 7.0 6.1; do
      if [[ $PWD =~ $HOME/$ver ]]; then
        cur_ver="$ver"
        break
      fi
    done
    if [[ -z "$cur_ver" ]]; then
      echo "Unrecognized Odoo version"
      exit 1
    fi
    tp="f"
    fn="$2"
    if [[ -d "$fn" ]]; then
      tp="d"
    elif [[ ! -f "$fn" ]]; then
      echo "File $fn not found"
      exit 1
    fi
    srcfn=$(readlink -f $fn)
    for ver in 14.0 13.0 12.0 11.0 10.0 9.0 8.0 7.0 6.1; do
      if [ "$ver" != "$cur_ver" ]; then
        tgtfn="${srcfn/$cur_ver/$ver}"
        if [ "$tp" == "f" ]; then
          tgtdir=$(dirname "$tgtfn")
          if [[ -d "$tgtdir" ]]; then
            echo "cp $srcfn $tgtfn"
            cp $srcfn $tgtfn
            if [ "${tgtfn: -4}" == ".xml" ]; then
              run_traced "$TDIR/topep8 -b$ver $tgtfn"
            fi
          else
            echo "Directory $tgtdir not found"
          fi
        else
          tgtdir=$(dirname "$tgtfn")
          if [[ ! -d "$tgtdir" ]]; then
            if [[ ! -d "$tgtdir/.." ]]; then
              echo "Directory $tgtdir not found!"
            else
              echo "Warning: directory $tgtdir not found!"
              run_traced "cp -R $srcfn $tgtdir/"
            fi
          else
            run_traced "rsync -avzb $srcfn/ $tgtfn/"
          fi
        fi
      fi
    done
    sts=0
  fi
  return $sts
}

do_show() {
  #do_show (docs|license|status)
  wlog "do_show $1"
  local cmd="do_show_$1"
  sts=$STS_SUCCESS
  if [ "$(type -t $cmd)" == "function" ]; then
    eval $cmd "$@"
  else
    echo "Missing object! Use:"
    echo "> please show (docs|licence)"
    echo "show docs        -> show docs using local browser"
    echo "show license     -> show licenses of modules of current Odoo repository"
    echo "show status      -> show component status"
    sts=$STS_FAILED
  fi
  return $sts
}

do_show_docs() {
  if [[ ! "$PRJNAME" == "Odoo" ]]; then
    local b
    b=$(which firefox)
    [[ -z $b ]] && b=$(which google-chrome)
    [[ -z $b ]] && echo "No browser found! Please install firefox or google-chrome" && return 1
    if [[ -f ./docs/_build/html/index.html ]]; then
      eval $b $(readlink -e ./docs/_build/html/index.html) &
    else
      echo "No documentation found in ./docs!"
    fi
  fi
  return 0
}

do_show_license() {
  if [[ "$PRJNAME" == "Odoo" ]]; then
    local module license FILES
    FILES=$(find ./ -maxdepth 2 -type f -not -path '*/build/*' -not -path '*/_build/*' -not -path '*/dist/*' -not -path '*/docs/*' -not -path '*/__to_remove/*' -not -path '*/filestore/*' -not -path '*/.git/*' -not -path '*/html/*' -not -path '*/.idea/*' -not -path '*/latex/*' -not -path '*/__pycache__/*' -not -path '*/.local/*' -not -path '*/.npm/*' -not -path '*/.gem/*' -not -path '*/Trash/*' -not -path '*/VME/*' -not -path "*/i18n/*" -not -path "*/static/*" \( -name "__manifest__.py" -o -name "__openerp__.py" \)|sort)
    for fn in $FILES; do
      path=$(readlink -f $(dirname $fn))
      module=$(basename $path)
      licence=$(grep "[\"']license[\"'] *:" $fn|grep --color=never -Eo "(.GPL-3|OPL-1)")
      printf "Module %-60.60s: $licence\n" $module
    done
  fi
  return 0
}

do_show_status() {
  local s v1 v2 v x y
  local PKGS_LIST=$(get_cfg_value 0 "PKGS_LIST")
  pushd $HOME/tools >/dev/null
  local PKGS=$(git status -s | grep -E "^ M" | awk '{print $2}' | awk -F/ '{print $1}' | grep -v "^[0-9]" | sort -u | tr "\n" "|")
  local PKGS_V=$(git diff -G__version__ --compact-summary | awk '{print $1}' | awk -F/ '{print $1}' | grep -v "^[0-9]" | sort -u | tr "\n" "|")
  [[ -n "$PKGS" ]] && PKGS="(${PKGS:0:-1})" || PKGS="()"
  [[ -n "$PKGS_V" ]] && PKGS_V="(${PKGS_V:0:-1})" || PKGS_V="()"
  popd >/dev/null
  for pkg in $PKGS_LIST tools; do
    x=""
    [[ $opt_force -ne 0 ]] && echo -e "\e[1m[ $pkg ]\e[0m"
    [[ $opt_force -eq 0 ]] && echo -e "[ $pkg ]"
    [[ $pkg =~ (python-plus|z0bug-odoo) ]] && pkg="${pkg//-/_}"
    if [[ $pkg == "tools" ]]; then
      for fn in egg-info licence_text templates .travis.yml install_tools.sh odoo_default_tnl.xlsx setup.py; do
        vfdiff -X diff $HOME/$pkg/$fn $HOME_DEVEL/pypi/$pkg/$fn -q >/dev/null
        if [[ $? -ne 0 ]]; then
          x="R"
          [[ $opt_force -ne 0 ]] && vfdiff -X diff $HOME/$pkg/$fn $HOME_DEVEL/pypi/$pkg/$fn
          break
        fi
      done
    else
      vfdiff -X diff $HOME/tools/$pkg $HOME_DEVEL/pypi/$pkg/$pkg -q >/dev/null
      if [[ $? -ne 0 ]]; then
        x="R"
        [[ $opt_force -ne 0 ]] && vfdiff -X diff $HOME/tools/$pkg $HOME_DEVEL/pypi/$pkg/$pkg
      fi
    fi
    [[ $PKGS != "()" && $pkg =~ $PKGS ]] && x="$x G"
    [[ $PKGS_V != "()" && $pkg =~ $PKGS_V ]] && x="$x V"
    if [[ $pkg == "tools" ]]; then
      v1=$(grep -E "version" $HOME/tools/setup.py|head -n1|awk -F= '{print $2}'|grep --color=never -Eo "[0-9.]+")
      v2=$(grep -E "version" $HOME_DEVEL/pypi/$pkg/setup.py|head -n1|awk -F= '{print $2}'|grep --color=never -Eo "[0-9.]+")
    else
      v1=$(grep -E "version" $HOME/tools/$pkg/setup.py|head -n1|awk -F= '{print $2}'|grep --color=never -Eo "[0-9.]+")
      v2=$(grep -E "version" $HOME_DEVEL/pypi/$pkg/setup.py|head -n1|awk -F= '{print $2}'|grep --color=never -Eo "[0-9.]+")
    fi
    if [[ $x =~ "R" ]]; then
      [[ $pkg == "tools" ]] && s="$HOME_DEVEL/pypi/$pkg" || s="$HOME_DEVEL/pypi/$pkg/$pkg"
      if [[ $v1 == $v2 && ! $x =~ "V" ]]; then
        v=$(echo $v2 | awk -F. '{if ($NF == 3) {OFS="."; print $1,$2,int($3)+1} else {OFS="."; print $1,$2,$3,int($4)+1}}')
        echo -e "\e[1m    Execute: cd $s; please version $v2 $v; travis && please replace\e[0m"
      else
        echo -e "\e[1m    Execute: cd $s; travis && please replace\e[0m"
      fi
    fi
    [[ $x =~ "G" && $x =~ "V" ]] && echo -e "\e[1m    Package $pkg (new version $v1) have to be pushed on github.com\e[0m"
    [[ $x =~ "G" && ! $x =~ "V" ]] && echo -e "\e[1m    Package $pkg differs from github.com but it has the same version $v1!!\e[0m"
  done
  [[ -f $HOME/tools/egg-info/history.rst ]] && head $HOME/tools/egg-info/history.rst
}

do_version() {
  # do_version([cur_ver [new_ver]])
  local re1 re2 new_ver
  re1="^#? *__version__ *="
  [[ -n $1 ]] && re2="${re1} *([\"'])?$1\1?$" || re2=$re1
  [[ -n $2 ]] && new_ver="$2" || new_ver=""
  if [ "$PRJNAME" != "Odoo" ]; then
    if [ -z "$1" ]; then
      if [ $opt_dry_run -eq 0 ]; then
        find . -type f -not -path '*/build/*' -not -path '*/_build/*' -not -path '*/dist/*' -not -path '*/docs/*' -not -path '*/__to_remove/*' -not -path '*/filestore/*' -not -path '*/.git/*' -not -path '*/html/*' -not -path '*/.idea/*' -not -path '*/latex/*' -not -path '*/__pycache__/*' -not -path '*/.local/*' -not -path '*/.npm/*' -not -path '*/.gem/*' -not -path '*/Trash/*' -not -path '*/VME/*' -not -name "*.pyc" -not -name "*.log" -exec grep -EH "$re1" '{}' \;
      else
        echo find . -type f -not -path '*/build/*' -not -path '*/_build/*' -not -path '*/dist/*' -not -path '*/docs/*' -not -path '*/__to_remove/*' -not -path '*/filestore/*' -not -path '*/.git/*' -not -path '*/html/*' -not -path '*/.idea/*' -not -path '*/latex/*' -not -path '*/__pycache__/*' -not -path '*/.local/*' -not -path '*/.npm/*' -not -path '*/.gem/*' -not -path '*/Trash/*' -not -path '*/VME/*' -not -name "*.pyc" -not -name "*.log" -exec grep -EH "$re1" '{}' \;
      fi
    else
      if [ $opt_dry_run -eq 0 ]; then
        find . -type f -not -path '*/build/*' -not -path '*/_build/*' -not -path '*/dist/*' -not -path '*/docs/*' -not -path '*/__to_remove/*' -not -path '*/filestore/*' -not -path '*/.git/*' -not -path '*/html/*' -not -path '*/.idea/*' -not -path '*/latex/*' -not -path '*/__pycache__/*' -not -path '*/.local/*' -not -path '*/.npm/*' -not -path '*/.gem/*' -not -path '*/Trash/*' -not -path '*/VME/*' -not -name "*.pyc" -not -name "*.log" -exec grep -EH "$re2" '{}' \;
      else
        echo find . -type f -not -path '*/build/*' -not -path '*/_build/*' -not -path '*/dist/*' -not -path '*/docs/*' -not -path '*/__to_remove/*' -not -path '*/filestore/*' -not -path '*/.git/*' -not -path '*/html/*' -not -path '*/.idea/*' -not -path '*/latex/*' -not -path '*/__pycache__/*' -not -path '*/.local/*' -not -path '*/.npm/*' -not -path '*/.gem/*' -not -path '*/Trash/*' -not -path '*/VME/*' -not -name "*.pyc" -not -name "*.log" -exec grep -EH "$re2" '{}' \;
      fi
      if [ -n "$new_ver" ]; then
        for fn in $(find . -type f -not -path '*/build/*' -not -path '*/_build/*' -not -path '*/dist/*' -not -path '*/docs/*' -not -path '*/__to_remove/*' -not -path '*/filestore/*' -not -path '*/.git/*' -not -path '*/html/*' -not -path '*/.idea/*' -not -path '*/latex/*' -not -path '*/__pycache__/*' -not -path '*/.local/*' -not -path '*/.npm/*' -not -path '*/.gem/*' -not -path '*/Trash/*' -not -path '*/VME/*' -not -name "*.pyc" -not -name "*.log" -exec grep -El "$re2" '{}' \;); do
          if [ $opt_dry_run -ne 0 ]; then
            echo sed -E "s|^(${re1:1} *[\"']?)$1([\"']?)|\1$new_ver\2|" -i $fn
          else
            sed -E "s|^(${re1:1} *[\"']?)$1([\"']?)|\1$new_ver\2|" -i $fn
          fi
        done
        if [ -f $PKGPATH/setup.py ]; then
          re1="^#? *version *="
          [[ -n $1 ]] && re2="${re1} *([\"'])?$1\1?$" || re2=$re1
          if [ $opt_dry_run -ne 0 ]; then
            echo sed -E "s|^(${re1:1} *[\"']?)$1([\"']?)|\1$new_ver\2|" -i $PKGPATH/setup.py
          else
            sed -E "s|^(${re1:1} *[\"']?)$1([\"']?)|\1$new_ver\2|" -i $PKGPATH/setup.py
          fi
        fi
      fi
    fi
    if [ -f $PKGPATH/setup.py ]; then
      echo -n "Project $PRJNAME $prjversion [$PKGNAME]: "
      python $PKGPATH/setup.py --version
    fi
  else
    echo "Project $PRJNAME $BRANCH [$PKGNAME $prjversion]"
  fi
  return 0
}

do_config() {
  sts=$STS_SUCCESS
  if [ "$sub1" == "global" ]; then
    cfgfn=$TCONF
  elif [ "$sub1" == "repository" ]; then
    cfgfn=$(readlink -m $PKGPATH/../conf/.local_dist_pkg.conf)
  elif [ "$sub1" == "local" ]; then
    cfgfn=$(readlink -m $PKGPATH/conf/.local_dist_pkg.conf)
  elif [ "$sub1" == "current" ]; then
    cfgfn=$DIST_CONF
  elif [ "$sub1" == "zero" -o "$sub1" == "powerp" ]; then
    cfgfn=
  else
    echo "Missed parameter! use:"
    echo "\$ please config global|repository|local|current|zero|powerp [def|del]"
    sts=$STS_FAILED
  fi
  if [ $sts -eq $STS_SUCCESS ]; then
    if [ -n "$cfgfn" ]; then
      cfgdir=$(dirname $cfgfn)
      if [ "$sub2" == "del" ]; then
        [[ -f $cfgfn ]] && run_traced "rm -f $cfgfn"
        [[ ! -d $cfgfn ]] && run_traced "rmdir $cfgdir"
      elif [ $opt_dry_run -ne 0 ]; then
        echo "vim $cfgfn"
      else
        [[ ! -d $cfgfn ]] && run_traced "mkdir -p $cfgdir"
        [[ "$sub2" == "def" ]] && merge_cfg $cfgfn
        run_traced "vim $cfgfn"
      fi
    else
      r="origin_$sub1"
      x=$(git remote | grep $r)
      if [ -z "$x" ]; then
        local ro=$(build_odoo_param RORIGIN '' $PKGNAME $sub1)
        run_traced "git remote add $r $ro"
        run_traced "git remote set-url --add --push $r $ro"
      fi
    fi
  fi
  return $sts
}

do_wep() {
    wlog "do_wep '$1' '$2' '$3'"
    clean_dirs "$PKGPATH"
    [[ $opt_force -ne 0 ]] && set_executable
    return 0
}

OPTOPTS=(h        B       b          C        c         D         d        f         j        k        L         m       n           o        O       p         q           r     s        t         u       V           v)
OPTLONG=(help     debug   branch     config   odoo-conf from-date database force     ""       keep     log       ""      dry-run     ""       ""      ""        quiet       ""    ""       test      ""      version     verbose)
OPTDEST=(opt_help opt_dbg opt_branch opt_conf opt_ocfn  opt_date  opt_db   opt_force opt_dprj opt_keep opt_log   opt_mis opt_dry_run opt_ids  opt_oca opt_dpath opt_verbose opt_r opt_srcs test_mode opt_uop opt_version opt_verbose)
OPTACTI=("+"      "+"     "="        "="      "="       "="       "="      1         1        1        "="       1       1           "=>"     1       "="       0           1     "="      1         1       "*"         "+")
OPTDEFL=(1        0       ""         ""       ""        ""        ""       0         0        0        ""        0       0           ""       0       ""        0           0     ""       0         0       ""          -1)
OPTMETA=("help"   ""      "branch"   "file"   "file"    "diff"    "name"   ""       "dprj"   "keep"   "logfile" ""      "noop"       "prj_id" ""      "path"    "quiet"     "rxt" "files"  "test"    "uop"   "version"   "verbose")
OPTHELP=("this help, type '$THIS help' for furthermore info"
  "debug mode"
  "branch: must be 6.1 7.0 8.0 9.0 10.0 11.0 12.0 13.0 or 14.0"
  "configuration file (def .travis.conf)"
  "odoo configuration file"
  "date to search in log"
  "database name"
  "force copy (push) | build (publish) | set_exec (wep) | full (status)"
  "execute tests in project dir rather in test dir/old style synchro"
  "keep coverage statistics in annotate test/keep original repository | tests/ in publish"
  "log file name"
  "show missing line in report coverage"
  "do nothing (dry-run)"
  "push only external project ids (of push)"
  "prefer OCA version of action, if available"
  "declare local destination path"
  "silent mode"
  "run restricted mode (w/o parsing travis.yml file) | recurse distribution OCB"
  "files to include in annotate test"
  "test mode (implies dry-run)"
  "check for unary operator W503 or no OCA/zero module translation"
  "show version end exit"
  "verbose mode")
OPTARGS=(actions sub1 sub2 sub3 sub4 sub5 sub6 sub7 sub8 sub9)

parseoptargs "$@"
if [[ "$opt_version" ]]; then
  echo "$__version__"
  exit 0
fi
HLPCMDLIST="help|build|chkconfig|config|docs|duplicate|edit|export|import|lint|list|lsearch|publish|push|pythonhosted|replace|replica|show|test|translate|version|wep"
if [[ $opt_help -gt 0 ]]; then
  print_help "Developer shell\nAction may be on of:\n$HLPCMDLIST" \
    "© 2015-2022 by zeroincombenze®\nhttps://zeroincombenze-tools.readthedocs.io/\nAuthor: antoniomaria.vigliotti@gmail.com"
  exit 0
fi

opts_travis
conf_default
[[ $opt_verbose -gt 2 ]] && set -x
init_travis
# prepare_env_travis
prepare_env_travis "$actions" "-r"
sts=$STS_SUCCESS
sts_bash=127
sts_flake8=127
sts_pylint=127
test_sts=127
[[ -n $LGITPATH && $PKGNAME == "tools" && $LGITPATH =~ "tools" ]] && LGITPATH=$(dirname $LGITPATH)

if [[ -z $sub1 ]]; then
  sub1="$sub2"
  sub2="$sub3"
  sub3="$sub4"
  sub4=""
fi
if [[ "$actions" == "help" ]]; then
  man $(dirname $0)/man/man8/$(basename $0).8.gz
else
  [[ "$PRJNAME" == "Odoo" ]] && odoo_fver=$(build_odoo_param FULLVER ".")
  actions=${actions//+/ }
  actions=${actions//,/ }
  for action in $actions; do
    if [[ "${action:0:3}" == "if-" ]]; then
      opt_dry_run=1
      cmd="do_${action:3}"
    else
      cmd="do_${action/-/_}"
    fi
    if [[ "$(type -t $cmd)" == "function" ]]; then
      eval $cmd "'$sub1'" "'$sub2'" "'$sub3'"
      sts=$?
    else
      echo "Invalid action!"
      echo "Use $THIS $HLPCMDLIST"
      sts=$STS_FAILED
    fi
    [[ $sts -ne $STS_SUCCESS ]] && break
  done
fi
exit $sts
