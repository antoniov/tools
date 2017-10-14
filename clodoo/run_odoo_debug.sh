#! /bin/bash
# -*- coding: utf-8 -*-

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
ODOOLIBDIR=$(findpkg odoorc "$TDIR $TDIR/.. $TDIR/../clodoo $TDIR/../../clodoo . .. $HOME/dev")
if [ -z "$ODOOLIBDIR" ]; then
  echo "Library file odoorc not found!"
  exit 2
fi
. $ODOOLIBDIR

__version__=0.2.1


OPTOPTS=(h        d        e       k        i       l        m           M         n           o         s         t         U         u       V           v           w       x)
OPTDEST=(opt_help opt_db   opt_exp opt_keep opt_imp opt_lang opt_modules opt_multi opt_dry_run opt_ofile opt_stop  opt_touch opt_user  opt_upd opt_version opt_verbose opt_web opt_xport)
OPTACTI=(1        "="      1       1        1       1        "="         1         "1"         "="       1         1         "="       1       "*>"        1           1       "=")
OPTDEFL=(1        ""       0       0        0       0        ""          -1        0           ""        0         0         ""        0       ""          0           0       "")
OPTMETA=("help"   "dbname" ""      ""       ""      ""       "modules"   ""        "no op"     "file"    ""        "touch"   "user"    ""      "version"   "verbose"   0       "port")
OPTHELP=("this help"\
 "db name to test,translate o upgrade (require -m switch)"\
 "export it translation (conflict with -i -u)"\
 "do not create new DB and keep it after run"\
 "import it translation (conflict with -e -u)"\
 "load it language"
 "modules to test, translate or upgrade"\
 "multi-version odoo environment"\
 "do nothing (dry-run)"\
 "output file (if export multiple modules)"\
 "stop after init"\
 "touch config file, do not run odoo"\
 "db username"\
 "upgrade module (conflict with -e -i)"\
 "show version"\
 "verbose mode"\
 "run as web server"\
 "set odoo xmlrpc port")
OPTARGS=(odoo_vid)

parseoptargs "$@"
if [ "$opt_version" ]; then
  echo "$__version__"
  exit 0
fi
if [ $opt_help -gt 0 ]; then
  print_help "Run odoo in debug mode"\
  "(C) 2015-2017 by zeroincombenze(R)\nhttp://www.zeroincombenze.it\nAuthor: antoniomaria.vigliotti@gmail.com"
  exit 0
fi

odoo_fver=$(build_odoo_param FULLVER $odoo_vid)
odoo_ver=$(build_odoo_param FULLVER $odoo_fver)
if [ $opt_multi -lt 0 ]; then
  c=0
  for v in 6.1 v7 7.0 8.0 9.0 10.0 11.0; do
    odoo_bin=$(build_odoo_param BIN $v search)
    if [ -n "$odoo_bin" ] && [ -f "$odoo_bin" ]; then
      ((c++))
    fi
  done
  if [ $c -gt 2 ]; then
    opt_multi=1
  else
    opt_multi=0
  fi
fi
confn=$(build_odoo_param CONFN $odoo_vid search)
script=$(build_odoo_param BIN $odoo_vid search)
odoo_root=$(build_odoo_param ROOT $odoo_vid search)
manifest=$(build_odoo_param MANIFEST $odoo_vid search)

if [ $opt_web -ne 0 ]; then
  rpcport=$(build_odoo_param RPCPORT $odoo_vid)
  odoo_user=$(build_odoo_param USER $odoo_vid)
else
  rpcport=$(build_odoo_param RPCPORT $odoo_vid debug)
  odoo_user=$(build_odoo_param USER $odoo_vid debug)
fi

create_db=0
drop_db=0
if [ $opt_lang -ne 0 ]; then
  opt_keep=1
  opt_stop=1
  if [ -n "$opt_modules" ]; then
    opt_modules=
  fi
elif [ $opt_exp -ne 0 -o $opt_imp -ne 0 ]; then
  opt_keep=1
  opt_stop=1
  if [ -z "$opt_modules" ]; then
    echo "Missing -m switch"
    exit 1
  fi
elif [ $opt_upd -ne 0 ]; then
  opt_keep=1
  if [ -z "$opt_modules" ]; then
    echo "Missing -m switch"
    exit 1
  fi
  if [ -z "$opt_db" ]; then
    echo "Missing -d switch"
    exit 1
  fi
fi
if [ -n "$opt_modules" ]; then
  if [ $opt_keep -eq 0 ]; then
    mods=${opt_modules//,/ }
    for m in $mods; do
      p=$(find $odoo_root -type d -name $m|head -n1)
      if [ -f $p/$manifest ]; then
        f=$p/$manifest
        x=$(cat $f|grep -A10 depends|tr -d '\n'|awk -F"[" '{print $2}'|awk -F"]" '{print $1}'|tr -d '" '|tr -d "'")
        if [ -n "$x" ]; then
          opt_modules="$opt_modules,$x"
        fi
      fi
    done
    opts="-i $opt_modules --test-enable"
    create_db=1
  elif [ $opt_exp -ne 0 -a -n "$opt_ofile" ]; then
    src=$(readlink -f $opt_ofile)
    opts="--modules=$opt_modules --i18n-export=$src -lit_IT"
  elif [ $opt_exp -ne 0 -o $opt_imp -ne 0 ]; then
    src=$(find $odoo_root -type d -name "$opt_modules"|head -n1)
    if [ -n "$src" ]; then
      if [ -f $src/i18n/it.po ]; then
        src=$src/i18n/it.po
        if [ $opt_exp -ne 0 ]; then
          run_traced "cp $src $src.bak"
        fi
      else
        src=
      fi
    fi
    if [ -z "$src" ]; then
      echo "Translation file not found!"
      exit 1
    fi
    if [ $opt_imp -ne 0 ]; then
      opts="--modules=$opt_modules --i18n-import=$src -lit_IT --i18n-overwrite"
    else
      opts="--modules=$opt_modules --i18n-export=$src -lit_IT"
    fi
  elif [ $opt_upd -ne 0 ]; then
    opts="-u $opt_modules"
  else
    opts="-u $opt_modules --test-enable"
  fi
else
  if [ $opt_lang -ne 0 ]; then
    opts=--load-language=it_IT
  else
    opts=""
  fi
fi
if [ -z "$opt_xport" ]; then
  opt_xport=$rpcport
fi
if [ -z "$opt_user" ]; then
  opt_user=$odoo_user
fi
if [ -n "$opt_modules" -o $opt_upd -ne 0 -o $opt_exp -ne 0 -o $opt_imp -ne 0 -o $opt_lang -ne 0 ]; then
  if [ -z "$opt_db" ]; then
    opt_db="test_openerp"
    if [ $opt_stop -gt 0 -a $opt_keep -eq 0 ]; then
      drop_db=1
    fi
  fi
fi
if [ $opt_stop -gt 0 ]; then
  opts="$opts --stop-after-init"
  if [ $opt_exp -eq 0 -a $opt_imp -eq 0 -a  $opt_lang -eq 0 ]; then
     opts="$opts --test-commit"
  fi
fi
if [ -n "$opt_db" ]; then
   opts="$opts -d $opt_db"
fi
if [ $opt_verbose -gt 0 -o $opt_dry_run -gt 0 -o $opt_touch -gt 0 ]; then
  echo "cp $confn ~/.openerp_serverrc"
fi

if [ $opt_dry_run -eq 0 ]; then
  cp $confn ~/.openerp_serverrc
  sed -ie 's:^logfile *=.*:logfile = False:' ~/.openerp_serverrc
  if [ -n "$opt_xport" ]; then
    sed -ie "s:^xmlrpc_port *=.*:xmlrpc_port = $opt_xport:" ~/.openerp_serverrc
  fi
  if [ -n "$opt_user" ]; then
    sed -ie "s:^db_user *=.*:db_user = $opt_user:" ~/.openerp_serverrc
  fi
  if [ $opt_verbose -gt 0 ]; then
    vim ~/.openerp_serverrc
  fi
fi
if [ $opt_touch -eq 0 ]; then
  if [ $drop_db -gt 0 ]; then
    if [ $opt_verbose -gt 0 ]; then
      echo "pg_db_active -a $opt_db; dropdb -U$opt_user --if-exists $opt_db"
    fi
    pg_db_active -a $opt_db; dropdb -U$opt_user --if-exists $opt_db
  fi
  if [ $create_db -gt 0 ]; then
    if [ $opt_verbose -gt 0 ]; then
      echo "createdb -U$opt_user $opt_db"
    fi
    createdb -U$opt_user $opt_db
  fi
  if [ "$odoo_ver" != "10.0" -a $opt_dry_run -eq 0 -a $opt_exp -eq 0 -a $opt_imp -eq 0 -a $opt_lang -eq 0 ]; then
    opts="--debug $opts"
  fi
  if [ $opt_verbose -gt 0 -o $opt_dry_run -gt 0 ]; then
    echo "$script $opts"
  fi
  if [ $opt_dry_run -eq 0 ]; then
    eval $script $opts
  fi
  if [ $drop_db -gt 0 ]; then
    if [ -z "$opt_modules" -o $opt_stop -eq 0 ]; then
      if [ $opt_verbose -gt 0 ]; then
        echo "dropdb -U$opt_user --if-exists $opt_db"
      fi
      dropdb -U$opt_user --if-exists $opt_db
    fi
  fi
  if [ $opt_exp -ne 0 ]; then
    echo "Translation exported to '$src' file"
  elif [ $opt_imp -ne 0 ]; then
    echo "Translation imported from '$src' file"
  fi
fi
