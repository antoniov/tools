#! /bin/bash
# -*- coding: utf-8 -*-
# Regression tests on clodoo
#
THIS=$(basename $0)
TDIR=$(readlink -f $(dirname $0))
for x in $TDIR $TDIR/.. $TDIR/../z0lib $TDIR/../../z0lib . .. /etc; do
  if [ -e $x/z0librc ]; then
    . $x/z0librc
    Z0LIBDIR=$x
    Z0LIBDIR=$(readlink -e $Z0LIBDIR)
    break
  fi
done
if [ -z "$Z0LIBDIR" ]; then
  echo "Library file z0librc not found!"
  exit 2
fi
TESTDIR=$(findpkg "" "$TDIR . .." "tests")
RUNDIR=$(readlink -e $TESTDIR/..)
Z0TLIBDIR=$(findpkg z0testrc "$TDIR $TDIR/.. $TDIR/../zerobug $TDIR/../../zerobug  . .. $HOME/dev")
if [ -z "$Z0TLIBDIR" ]; then
  echo "Library file z0testrc not found!"
  exit 2
fi
. $Z0TLIBDIR
Z0TLIBDIR=$(dirname $Z0TLIBDIR)
__version__=0.1.17.1


test_01() {
    local cmd
    cmd="$RUNDIR/odoo_skin.sh -Tq 7.0 example"
    eval $cmd
    test_result "odoo_skin" "$TESTDIR/themes/base.test" "$TESTDIR/themes/base.sass.tmp"  "diff"
}

Z0BUG_setup() {
    mkdir -p $TESTDIR/themes
    cat << EOF > $TESTDIR/themes/odoo_theme_example.conf
# Example of theme file
CSS_facets-border=#F1E2D3
CSS_sheet-max-width=860px
EOF
    cat << EOF > $TESTDIR/themes/base.sass
// V0.1.3
// Text def color: dev=#805070 qt=#123456 prod=#2a776d
//\$zi-def-text: #805070
\$zi-def-text: #123456
//\$zi-def-text: #2a776d
// Text def color: dev=#805070 prod=#2a776d
//\$zi-def-text-bg: #805070
\$zi-def-text-bg: #2a776d
// Text def color: dev=#805070 prod=#2a776d
\$zi-login-text: #805070
//\$zi-login-text: #2a776d
// Text def color: dev=#805070 prod=#2a776d
\$zi-login-text-bg: #805070
\$zi-login-text-bg: #2a776d
\$facets-border: #afafb6
\$sheet-max-width: auto
\$sheet-padding: 16px
EOF
    cat << EOF > $TESTDIR/themes/base.test
// V0.1.3
// Text def color: dev=#805070 qt=#123456 prod=#2a776d
//\$zi-def-text: #805070
//\$zi-def-text: #123456
\$zi-def-text: #2a776d
// Text def color: dev=#805070 prod=#2a776d
//\$zi-def-text-bg: #805070
\$zi-def-text-bg: #2a776d
// Text def color: dev=#805070 prod=#2a776d
//\$zi-login-text: #805070
\$zi-login-text: #2a776d
// Text def color: dev=#805070 prod=#2a776d
//\$zi-login-text-bg: #805070
\$zi-login-text-bg: #2a776d
\$facets-border: #F1E2D3
\$sheet-max-width: 860px
\$sheet-padding: 16px
EOF
}

Z0BUG_teardown() {
    :
}


Z0BUG_init
parseoptest -l$TESTDIR/test_clodoo.log "$@ -J"
sts=$?
if [ $sts -ne 127 ]; then
  exit $sts
fi
if [ ${opt_tlib:-0} -ne 0 ]; then
  TRAVISLIBDIR=$(findpkg travisrc "$TDIR $TDIR/.. $TDIR/../travis_emulator $TDIR/../../travis_emulator . .. $HOME/dev")
  if [ -z "$TRAVISLIBDIR" ]; then
    echo "Library file travisrc not found!"
    exit 2
  fi
  . $TRAVISLIBDIR
fi
UT1_LIST=
UT_LIST=""
if [ "$(type -t Z0BUG_setup)" == "function" ]; then Z0BUG_setup; fi
Z0BUG_main_file "$UT1_LIST" "$UT_LIST"
sts=$?
if [ "$(type -t Z0BUG_teardown)" == "function" ]; then Z0BUG_teardown; fi
exit $sts
