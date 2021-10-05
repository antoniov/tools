#! /bin/bash
# -*- coding: utf-8 -*-
#
# pg_db_active
# manage postgres sessions
#
# This free software is released under GNU Affero GPL3
# author: Antonio M. Vigliotti - antoniomaria.vigliotti@gmail.com
# (C) 2016-2021 by SHS-AV s.r.l. - http://www.shs-av.com - info@shs-av.com
#
# READLINK=$(which greadlink 2>/dev/null) || READLINK=$(which readlink 2>/dev/null)
# export READLINK
THIS=$(basename "$0")
TDIR=$(readlink -f $(dirname $0))
<<<<<<< HEAD:zar/pg_db_active.sh
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
>>>>>>> stash:zar/pg_db_active
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

__version__=1.3.36.99


db_act_list() {
# db_act_list(-C|-c|-k|-l|-u|-w|-z [pos])  # count_all, count, return older pid to kill, list sessions, return active sess to wait
    local act=$1
    local fw ord
    local sql sqlc sess_ctr LOG wait4 valid_sess db pid w st older usr user
    local pos=0
    [[ -n "$2" ]] && pos=$2
    [[ $PSQL_VER -ge 96 ]] && fw="wait_event" || fw="waiting"
    [[ "$act" == "-z" ]] && ord="desc" || ord=""
    if [[ -z "$DB" ]]; then
      sql="select datname,pid,state_change,$fw,state,usename from pg_stat_activity where pid<>pg_backend_pid() order by state_change $ord;"
    else
      sql="select datname,pid,state_change,$fw,state,usename from pg_stat_activity where datname='$DB' and pid<>pg_backend_pid() order by state_change $ord;"
    fi
    if [[ $act == "-c" || $act == "-C" ]]; then
      if [[ -z "$DB" || $act == "-C" ]]; then
        sqlc="select count(pid) from pg_stat_activity where pid<>pg_backend_pid();"
      else
        sqlc="select count(pid) from pg_stat_activity where datname='$DB' and pid<>pg_backend_pid();"
      fi
      sess_ctr=$($PSQL -Atc "$sqlc"|head -n1)
      sess_ctr=$(echo $sess_ctr)
    else
      LOG=~/${THIS}_$$.log
      $PSQL -Atc "$sql" -o $LOG
      wait4=0
      sess_ctr=0
      valid_sess=0
      older=0
      user=
      while IFS=\| read db pid dt w st usr; do
        [[ $PSQL_VER -ge 95 && -z "$st" ]] && st="idle"
        if [[ -n "$st" ]]; then
          ((sess_ctr++))
          if [[ $PSQL_VER -ge 95 ]]; then
            [[ -n "$w" && ( $w =~ Lock || ! $w =~ Read ) ]] && w="t" || w="f"
          fi
          if [[ $act == "-l" ]]; then
            printf "(%6.6s) %-16.16s %2.2s %-8.8s %20.20s %8.8s\n" "$pid" "$db" "$w" "$st" "$dt" "$usr"
          fi
          if [[ $older -eq 0 && $w == "f" && $st == "idle" && $db != "postgres" ]]; then
            ((valid_sess++))
            if [[ $pos -gt 0 ]]; then
              if [[ $valid_sess -eq $pos ]]; then
                older=$pid;
                user=$usr
              fi
            else
              older=$pid
              user=$usr
            fi
          fi
          if [[ "$db" == "$DB" ]]; then
            if [[ "$w" != "f" ]]; then
              wait4=1
            fi
            if [[ "${st:0:4}" != "idle" ]]; then
              wait4=1
            fi
          fi
        fi
        [[ $pos -gt 0 && $valid_sess -eq $pos ]] && break
      done < $LOG
      rm -f $LOG
    fi
    if [[ $act == "-w" ]]; then
      return $wait4
    elif [[ $act == "-c" || $act == "-C" || $act == "-l" ]]; then
      echo $sess_ctr
    elif [[ $act == "-k" || $act == "-z" ]]; then
      echo $older
    elif [[ $act == "-u" ]]; then
      echo $user
    fi
    return 0
}

OPTOPTS=(h        a           C        c       G         k        L        n           p        s        U        V           v           w       z)
OPTDEST=(opt_help act_kill4db act_ctra act_ctr opt_grant act_kill opt_lock opt_dry_run pool     opt_show opt_user opt_version opt_verbose wait_db opt_last)
OPTACTI=(1        "1>"        "1>"     "1>"    1         "1>"     1        1           "="      1        "="      "*"          1           1       1)
OPTDEFL=(0        0           0        0       0         0        0        0           -1       0        ""       ""           0           0       0)
OPTMETA=("help"   "kill_all" "count"   "count" ""        "kill"   ""       ""          "number" ""       "dbuser" "version"   "verbose"   "wait"  "")
OPTHELP=("this help"\
 "kill all sessions of DB!"\
 "count all active connections"\
 "count active connections on DB"\
 "grant connection to DB"\
 "kill all sessions out of pool"\
 "lock DB to avoid new connections (may be used with -a)"\
 "do nothing (dry-run)"\
 "declare # of session pool"\
 "show pool size"\
 "show version end exit"\
 "db user"\
 "verbose mode"\
 "wait for DB idle after kill"\
 "search just for last session")
OPTARGS=(DB)

parseoptargs "$@"
if [[ "$opt_version" ]]; then
  echo "$__version__"
  exit 0
fi
if [[ $opt_help -gt 0 ]]; then
  print_help "Check/kill for postgres DB sessions"\
  "(C) 2016-2021 by zeroincombenze(R)\nhttp://wiki.zeroincombenze.org/en/Postgresql\nAuthor: antoniomaria.vigliotti@gmail.com"
  exit 0
fi
PSQL=""
for u in $opt_user $USER odoo openerp postgresql; do
  if [[ -n "$u" ]]; then
    psql -U$u -l &>/dev/null
    if [[ $? -eq 0 ]]; then
      dbuser=$USER
      PSQL="psql -U$u -dtemplate1"
      break
    fi
  fi
done
if [[ -z $PSQL ]]; then
    echo "Denied inquire with psql. Please configure user $USER to access via psql"
    exit 2
fi
PSQL_VER=$(psql --version|grep -Eo "[0-9]+\.[0-9]"|tr -d "."|head -n1)
if [[ $pool -lt 1 ]]; then
  pool=$($PSQL -Atc "select setting from pg_settings where name='max_connections';"|head -n1)
  pool=$(echo $pool)
fi
if [[ $opt_show -ne 0 ]]; then
  echo $pool
  exit 0
fi
if [[ $pool -lt 5 ]]; then
  pool=5
fi
sleep_tm=5
loop_ctr=1
if [[ $act_ctr -ne 0 ]]; then
  if [[ -n "$DB" ]]; then
    act=-c
  else
    echo "Missing DB name!"
    exit 1
  fi
elif [[ $act_ctra -ne 0 ]]; then
  act=-C
elif [[ $act_kill -ne 0 ]]; then
  act=-C
  loop_ctr=8
  sleep_tm=1
elif [[ $act_kill4db -ne 0 ]]; then
  if [[ -n "$DB" ]]; then
    act=-c
    loop_ctr=1
    sleep_tm=0
    if [[ $opt_lock -gt 0 ]]; then
      [[ $opt_verbose -gt 0 ]] && echo "Revoke access to $dbuser from $DB"
      if [[ $opt_dry_run -eq 0 ]]; then
        sqlc="REVOKE CONNECT ON DATABASE $DB FROM PUBLIC, $dbuser;"
        $PSQL -tc "$sqlc" &>/dev/null
      fi
    fi
  else
    echo "Missing DB name!"
    exit 1
  fi
elif [[ $wait_db -ne 0 ]]; then
  if [[ -n "$DB" ]]; then
    act=-c
  else
    act=-C
  fi
else
  act=-l
fi
let threshold="$pool/5"
let pool_max="$pool-$threshold"
let pool_min="$pool_max-$threshold"
bias=0
sts=1
while [[ $sts -ne 0 && $loop_ctr -gt 0 ]]; do
  if [[ $act_kill -ne 0 || $act_kill4db -ne 0 ]]; then
    sess_ctr=$(db_act_list "$act")
    [[ $opt_verbose -gt 0 ]] && echo "Found $sess_ctr currently active sessions"
    if [[ $sess_ctr -gt 0 ]]; then
      if [[ $act_kill4db -ne 0 ]]; then
        killing=1
        if [[ $bias -eq 0 ]]; then
          bias=1
          if [[ $opt_last -eq 0 ]]; then
            loop_ctr=$sess_ctr
            ((loop_ctr++))
          fi
        elif [[ $opt_dry_run -ne 0 ]]; then
          ((bias++))
        fi
      elif [[ $sess_ctr -gt $pool_max ]]; then
        killing=1
        ((bias++))
        loop_ctr=$threshold
      elif [[ $sess_ctr -gt $pool_min && $bias -ne 0 ]]; then
        killing=1
      else
        killing=0
        bias=0
      fi
      if [[ $killing -gt 0 ]]; then
        if [[ $opt_last -ne 0 ]]; then
          if [[ $opt_dry_run -ne 0 ]]; then
            pid=$(db_act_list "-z" "$bias")
            user=$(db_act_list "-u" "$bias")
          else
            pid=$(db_act_list "-z")
            user=$(db_act_list "-u")
          fi
        else
          if [[ $opt_dry_run -ne 0 ]]; then
            pid=$(db_act_list "-k" "$bias")
            user=$(db_act_list "-u" "$bias")
          else
            pid=$(db_act_list "-k")
            user=$(db_act_list "-u")
          fi
        fi
        if [[ ${pid:-0} -ne 0 ]]; then
          if [[ $opt_dry_run -eq 0 ]]; then
            [[ $opt_verbose -gt 0 ]] && echo "Killing process pid=$pid of $user"
            sqlc="select pg_terminate_backend(pid) from pg_stat_activity where pid<>pg_backend_pid() and pid=$pid;"
            [[ $opt_verbose -gt 0 ]] && run_traced "$PSQL -tc \"$sqlc\" -U$user"
            $PSQL -tc "$sqlc" -U $user &>/dev/null
          else
            echo "Process pid=$pid of $user should be killed"
            sts=0
          fi
        elif [[ $opt_dry_run -eq 0 ]]; then
          ((loop_ctr++))
        fi
        sts=1
      else
        sts=0
      fi
    else
      sts=0
    fi
  else
    db_act_list "$act"
    sts=$?
  fi
  ((loop_ctr--))
  if [[ $sts -ne 0 ]]; then
    sleep $sleep_tm
  fi
done
if [[ $wait_db -ne 0 && -n "$DB" ]]; then
  act=-w
  loop_ctr=3
  sleep_tm=1
  while [ $sts -ne 0 -a $loop_ctr -gt 0 ]; do
    db_act_list "$act"
    sts=$?
    ((loop_ctr--))
    if [ $sts -ne 0 ]; then
      if [ $opt_verbose -gt 0 ]; then
        echo "Waiting for DB going idle"
      fi
      sleep $sleep_tm
    fi
  done
  sleep 1
fi
if [ $opt_grant -gt 0 -a -n "$DB" ]; then
  if [ $opt_verbose -gt 0 ]; then
    echo "Grant access to $DB"
  fi
  if [ $opt_dry_run -eq 0 ]; then
    sqlc="GRANT CONNECT ON DATABASE $DB TO PUBLIC, odoo;"
    $PSQL -tc "$sqlc" &>/dev/null
  fi
elif [ $opt_lock -gt 0 -a -n "$DB" ]; then
  if [ $opt_verbose -gt 0 ]; then
    echo "Revoce access from $DB"
  fi
  if [ $opt_dry_run -eq 0 ]; then
    sqlc="REVOKE CONNECT ON DATABASE $DB FROM PUBLIC, odoo;"
    $PSQL -tc "$sqlc" &>/dev/null
  fi
fi
exit $sts
