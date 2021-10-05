#! /bin/bash
# -*- coding: utf-8 -*-
# Regression tests on clodoo
#
# READLINK=$(which greadlink 2>/dev/null) || READLINK=$(which readlink 2>/dev/null)
# export READLINK
THIS=$(basename "$0")
TDIR=$(readlink -f $(dirname $0))
<<<<<<< HEAD
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
>>>>>>> stash
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
Z0TLIBDIR=$(findpkg z0testrc "$PYPATH" "zerobug")
if [[ -z "$Z0TLIBDIR" ]]; then
  echo "Library file z0testrc not found!"
  exit 72
fi
. $Z0TLIBDIR
Z0TLIBDIR=$(dirname $Z0TLIBDIR)
[[ $TRAVIS_DEBUG_MODE -ge 8 ]] && echo "Z0TLIBDIR=$Z0TLIBDIR"

<<<<<<< HEAD
__version__=0.3.34.99
=======
__version__=0.3.36
>>>>>>> stash


test_01() {
    RES=$($RUNDIR/list_requirements -V 2>&1)
    test_result "list_requirements" "$__version__" "$RES"
    #
    TRES="python=six,astroid,Click,codecov,configparser,coverage,coveralls,docopt,flake8,isort,lazy_object_proxy,lxml,MarkupSafe,mock,pbr,polib,pycodestyle,pycparser,pyflakes,Pygments,pylint,pylint-mccabe,pylint-plugin-utils,pylint_odoo,pyopenssl,pyserial,pytest,python_plus,PyWebDAV,PyYAML,QUnitSuite,restructuredtext_lint,rfc3986,setuptools,simplejson,unittest2,urllib3[secure],websocket-client,whichcraft,wrapt,z0bug_odoo,docutils,zerobug"
    RES=$($RUNDIR/list_requirements -b10.0 -tpython -T)
    test_result "list_requirements -b10.0 -tpython -T" "$TRES" "$RES"
    #
    TRES="python=Babel==2.3.4,chardet,configparser,decorator==3.4.0,feedparser==5.1.3,future,gdata==2.0.18,gevent==1.0.2,html2text,Jinja2==2.7.3,'lxml>=3.4.1',Mako==1.0.4,num2words,numpy,passlib==1.6.2,psutil==4.3.1,psycogreen==1.0,'psycopg2-binary>=2.5.4',pydot==1.2.3,pyparsing==2.0.3,pyPdf==1.13,pyserial==2.7,Python-Chart==1.39,python-dateutil==2.5.3,python-ldap==2.4.19,python-openid==2.2.5,'python-stdnum>=1.8.1',pytz==2014.10,reportlab==3.1.44,simplejson==3.5.3,urllib3[secure],vatnumber==1.2,Werkzeug==0.9.6,docutils==0.14,six==1.9.0,Pillow==3.4.1"
    RES=$($RUNDIR/list_requirements -b8.0 -tpython -BP)
    test_result "list_requirements -b8.0 -tpython -BP" "$TRES" "$RES"
    #
    TRES="python=Babel==2.3.4,chardet,configparser,decorator==4.0.10,feedparser==5.2.1,future,gdata==2.0.18,gevent==1.1.2,html2text,Jinja2==2.10.1,'lxml>=3.4.1',Mako==1.0.4,num2words,numpy,passlib==1.6.5,psutil==4.3.1,psycogreen==1.0,'psycopg2-binary>=2.7.4',pydot==1.2.3,pyparsing==2.1.10,pyPdf==1.13,'pyserial>=3.1.1',Python-Chart==1.39,python-dateutil==2.5.3,python-ldap==2.4.25,python-openid==2.2.5,'python-stdnum>=1.8.1',pytz==2016.7,reportlab==3.3.0,simplejson==3.5.3,'six>=1.10.0',urllib3[secure],vatnumber==1.2,Werkzeug==0.11.11,docutils==0.14,Pillow==3.4.1"
    RES=$($RUNDIR/list_requirements -b10.0 -tpython -BP)
    test_result "list_requirements -b10.0 -tpython -BP" "$TRES" "$RES"
    #
    TRES="python=Babel==2.3.4,chardet,configparser,decorator==4.0.10,feedparser==5.2.1,future,gdata==2.0.18,gevent==1.3.4,html2text,Jinja2==2.10.1,'lxml>=3.4.1',Mako==1.0.4,num2words,numpy,passlib==1.6.5,docutils==0.14,Pillow==6.1.0,psutil==4.3.1,psycogreen==1.0,'psycopg2-binary>=2.8.3',pydot==1.2.3,pyparsing==2.1.10,pyPDF2,'pyserial>=3.1.1',Python-Chart==1.39,python-dateutil==2.5.3,python-openid==2.2.5,'python-stdnum>=1.8.1',python3-ldap,pytz==2016.7,reportlab==3.3.0,simplejson==3.5.3,'six>=1.10.0',urllib3[secure],vatnumber==1.2,Werkzeug==0.14.1"
    RES=$($RUNDIR/list_requirements -b12.0 -tpython -BP)
    test_result "list_requirements -b12.0 -tpython -BP" "$TRES" "$RES"
}

Z0BUG_setup() {
    :
}

Z0BUG_teardown() {
    :
}


Z0BUG_init
parseoptest -l$TESTDIR/test_clodoo.log "$@"
sts=$?
[[ $sts -ne 127 ]] && exit $sts



UT1_LIST=
UT_LIST=""
[[ "$(type -t Z0BUG_setup)" == "function" ]] && Z0BUG_setup
Z0BUG_main_file "$UT1_LIST" "$UT_LIST"
sts=$?
[[ "$(type -t Z0BUG_teardown)" == "function" ]] && Z0BUG_teardown
exit $sts
