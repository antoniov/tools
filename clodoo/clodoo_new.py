#!/usr/bin/env python
# -*- coding: utf-8 -*-
##############################################################################
#
#    Copyright (C) SHS-AV s.r.l. (<http://ww.zeroincombenze.it>)
#    All Rights Reserved
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
##############################################################################
"""
    Massive operations on Zeroincombenze(R) / Odoo databases

"""

# import pdb
import os.path
import sys
import argparse
import ConfigParser
from os0 import os0
from datetime import date
import time
import oerplib
import re
import csv


__version__ = "0.3.1"
# Apply for configuration file (True/False)
APPLY_CONF = True
# Default configuration file (i.e. myfile.conf or False for default)
CONF_FN = False
# Read Odoo configuration file (False or /etc/odoo-server.conf)
ODOO_CONF = ["/etc/odoo/odoo-server.conf",
             "/etc/odoo-server.conf",
             "/etc/openerp/openerp-server.conf",
             "/etc/openerp-server.conf",
             "/etc/odoo/openerp-server.conf",
             "/etc/openerp/odoo-server.conf"]
# Read Odoo configuration file (False or /etc/openerp-server.conf)
ODOO_CONF = "/etc/openerp-server.conf"


msg_time = time.time()


def init():
    """Setup log file"""
    tlog_fn = "./" + nakedname(os.path.basename(__file__)) + ".log"
    os0.set_tlog_file(tlog_fn)


#############################################################################
# Message and output
#
def msg_burst(level, text, i, n):
    """Show a message per second from burst sequence as a gauge"""
    global msg_time
    t = time.time() - msg_time
    if (t > 1):
        ident = ' ' * level
        print(u"\x1b[A{0}[{1:>6}/{2:>6}] {3}".format(ident,
                                                     i,
                                                     n,
                                                     tounicode(text)))
        msg_time = time.time()


def msg(level, text):
    """Show and log a message"""
    ident = ' ' * level
    txt = u"{0}{1}".format(ident, tounicode(text))
    print txt


def msg_log(ctx, level, text):
    """Log a message and show if needed"""
    ident = ' ' * level
    if ctx:
        if 'test_unit_mode' in ctx:
            return
        elif ctx['simulate'] and level > 0:
            txt = u"{0}({1})".format(ident, tounicode(text))
        else:
            txt = u"{0}{1}".format(ident, tounicode(text))
        if not ctx['quiet_mode']:
            print txt
    else:
        txt = u"{0}{1}".format(ident, tounicode(text))
        print txt
    os0.wlog(txt)


def debug_msg_log(ctx, level, text):
    """Log a debug message and show if needed"""
    ident = ' ' * level
    if ctx.get('dbg_mode', False):
        if 'test_unit_mode' in ctx:
            return
        elif ctx['simulate'] and level > 0:
            txt = u">{0}({1})".format(ident, tounicode(text))
        else:
            txt = u">{0}{1}".format(ident, tounicode(text))
        print txt
        os0.wlog(txt)


def print_hdr_msg(ctx):
    msg = u"Do massive operations V" + __version__
    msg_log(ctx, 0, msg)
    msg = u"Configuration from " + ctx.get('conf_fn', '')
    msg_log(ctx, 1, msg)


def ismbcs(t):
    """"Return true id string contains mbcs"""
    if isinstance(t, str):
        try:
            t = unicode(t)
            return False
        except:
            return True
    return False


def strtype(t):
    """Return string type: ascii, mbcs or unicode"""
    if isinstance(t, unicode):
        return 'unicode'
    elif isinstance(t, str):
        try:
            t = unicode(t)
            return 'ascii'
        except:
            return 'mbcs'
    else:
        return None


def tounicode(s):
    """Return unicode string from basestring"""
    if strtype(s) == 'unicode':
        return s
    elif strtype(s) == 'mbcs':
        return s.decode('utf-8')
    elif strtype(s) == 'ascii':
        return unicode(s)
    else:
        return s


#############################################################################
# Connection and database
#
def open_connection(ctx):
    """Open connection to Odoo service"""
    try:
        oerp = oerplib.OERP(server=ctx['host'],
                            protocol=ctx['svc_protocol'],
                            port=ctx['svc_port'])
    except:
        msg = u"!Odoo server is not running!"
        msg_log(ctx, 0, msg)
        raise ValueError(msg)
    return oerp


def do_login(oerp, ctx):
    """Do a login into DB; try using more usernames and passwords"""
    msg = "do_login()"
    debug_msg_log(ctx, 2, msg)
    userlist = ctx['login2_user'].split(',')
    userlist.insert(0, ctx['login_user'])
    pwdlist = ctx['login2_pwd'].split(',')
    pwdlist.insert(0, ctx['login_pwd'])
    user_obj = False
    for username in userlist:
        for pwd in pwdlist:
            try:
                user_obj = oerp.login(user=username,
                                      passwd=pwd,
                                      database=ctx['db_name'])
                break
            except:
                user_obj = False
        if user_obj:
            break

    if not user_obj:
        os0.wlog(u"!DB={0}: invalid user/pwd"
                 .format(tounicode(ctx['db_name'])))
        return

    if ctx['set_passepartout']:
        wrong = False
        if username != ctx['login_user']:
            user_obj.login = ctx['login_user']
            wrong = True
        if pwd != ctx['login_pwd']:
            user_obj.password = ctx['login_pwd']
            wrong = True
        if wrong:
            try:
                oerp.write_record(user_obj)
                os0.wlog(u"!DB={0}: updated wrong user/pwd {1} to {2}"
                         .format(tounicode(ctx['db_name']),
                                 tounicode(username),
                                 tounicode(ctx['login_user'])))
            except:
                os0.wlog(u"!!write error!")
        if user_obj.email != ctx['zeroadm_mail']:
            user_obj.email = ctx['zeroadm_mail']
            try:
                oerp.write_record(user_obj)
                os0.wlog(u"!DB={0}: updated wrong user {1} to {2}"
                         .format(tounicode(ctx['db_name']),
                                 tounicode(ctx['login2_user']),
                                 tounicode(ctx['login_user'])))
            except:
                os0.wlog(u"!!write error!")
    return user_obj


def init_ctx(ctx, db):
    """"Clear company parameters"""
    for n in ('def_company_id',
              'def_company_name',
              'def_partner_id',
              'def_user_id',
              'def_country_id',
              'company_id',
              'module_udpated'):
        if n in ctx:
            del ctx[n]
    ctx['db_name'] = db
    if re.match(ctx['dbfilterz'], ctx['db_name']):
        ctx['db_type'] = "Z"  # Zeroincombenze
    elif re.match(ctx['dbfiltert'], ctx['db_name']):
        ctx['db_type'] = "T"  # Test
    else:
        ctx['db_type'] = "C"  # Customer
    return ctx


def get_dblist(oerp):
    return oerp.db.list()


def get_userlist(oerp, ctx):
    """Set parameter values for current company"""
    msg = "get_userlist()"
    debug_msg_log(ctx, 2, msg)
    user_ids = oerp.search('res.users')
    msg = "user_ids: %s" % str(user_ids)
    debug_msg_log(ctx, 2, msg)
    for u_id in sorted(user_ids):
        msg = "res.users.browse()"
        debug_msg_log(ctx, 3, msg)
        user_obj = oerp.browse('res.users', u_id)
        msg = u"User {0:>2} {1}\t'{2}'\t{3}\t[{4}]".format(
              u_id,
              tounicode(user_obj.login),
              tounicode(user_obj.partner_id.name),
              tounicode(user_obj.partner_id.email),
              tounicode(user_obj.company_id.name))
        msg_log(ctx, 2, msg)
        if user_obj.login == "admin":
            ctx['def_company_id'] = user_obj.company_id.id
            ctx['def_company_name'] = user_obj.company_id.name
            ctx['def_partner_id'] = user_obj.partner_id.id
            ctx['def_user_id'] = u_id
            if user_obj.company_id.country_id:
                ctx['def_country_id'] = user_obj.company_id.country_id.id
            else:
                ctx['def_country_id'] = user_obj.partner_id.country_id.id
    return ctx


#############################################################################
# Action interface
#

def _get_name_n_params(name, deflt=None):
    """Extract name and params from string like 'name(params)'"""
    deflt = '' if deflt is None else deflt
    i = name.find('(')
    j = name.rfind(')')
    if i >= 0 and j >= i:
        n = name[:i]
        p = name[i + 1:j]
    else:
        n = name
        p = deflt
    return n, p


def _get_name_n_ix(name, deflt=None):
    """Extract name and subscription from string like 'name[ix]'"""
    deflt = '' if deflt is None else deflt
    i = name.find('[')
    j = name.rfind(']')
    if i >= 0 and j >= i:
        n = name[:i]
        x = name[i + 1:j]
    else:
        n = name
        x = deflt
    return n, x


def isaction(oerp, ctx, action):
    """Return if valid action"""
    lx_act = ctx['_lx_act']
    if action == '' or action is False or action is None:
        return True
    elif action in lx_act:
        return True
    else:
        return False


def lexec_name(action):
    """Return local executable function name from action"""
    act = "act_" + action
    return act


def add_on_account(acc_balance, level, code, credit, debit):
    if level not in acc_balance:
        acc_balance[level] = {}
    if code:
        if code in acc_balance[level]:
            acc_balance[level][code] += credit
            acc_balance[level][code] -= debit
        else:
            acc_balance[level][code] = credit
            acc_balance[level][code] -= debit


def action_id(lexec):
    """Return action name from local executable function name"""
    if lexec[0:4] == 'act_':
        action_name = lexec[4:]
    else:
        action_name = None
    return action_name


def do_single_action(oerp, ctx, action):
    """Do single action (recursive)"""
    if isaction(oerp, ctx, action):
        if action == '' or action is False or action is None:
            return 0
        act = lexec_name(action)
        if act in list(globals()):
            if action == 'install_modules' and\
                    not ctx.get('module_udpated', False):
                globals()[lexec_name('update_modules')](oerp, ctx)
                ctx['module_udpated'] = True
            return globals()[act](oerp, ctx)
        else:
            return do_group_action(oerp, ctx, action)
    else:
        return 1


def do_group_action(oerp, ctx, action):
    """Do group actions (recursive)"""
    if 'test_unit_mode' not in ctx:
        msg = u"Do group actions"
        msg_log(ctx, 3, msg)
    conf_obj = ctx['_conf_obj']
    sts = 0
    if conf_obj.has_option(action, 'actions'):
        # Local environment for group actions
        lctx = create_local_parms(ctx, action)
        if not lctx['actions']:
            return 1
        actions = lctx['actions'].split(',')
        for act in actions:
            if isaction(oerp, lctx, act):
                if act == '' or act is False or act is None:
                    break
                elif act == action:
                    msg = u"Recursive actions " + act
                    msg_log(ctx, 3, msg)
                    sts = 1
                    break
                sts = do_single_action(oerp, lctx, act)
            else:
                msg = u"Invalid action " + act
                msg_log(ctx, 3, msg)
                sts = 1
                break
    else:
        msg = u"Undefined action"
        msg_log(ctx, 3, msg)
        sts = 1
    return sts


def do_actions(oerp, ctx):
    """Do root actions (recursive)"""
    actions = ctx.get('actions', None)
    if not actions and 'actions_db' in ctx:
        actions = 'per_db'
    elif not actions and 'actions_mc' in ctx:
        actions = 'per_company'
    elif not actions and 'actions_uu' in ctx:
        actions = 'per_users'
    if not actions:
        return 1
    actions = actions.split(',')
    sts = 0
    for act in actions:
        if isaction(oerp, ctx, act):
            sts = do_single_action(oerp, ctx, act)
        else:
            sts = 1
        if sts > 0:
            break
    return sts
    # debug_explore(oerp, ctx)
    # o_model = {}
    # csv_fn = "user-config.csv"
    # import_config_file(oerp, ctx, o_model, csv_fn)


def create_local_parms(ctx, action):
    """Create local params dictionary"""
    conf_obj = ctx['_conf_obj']
    lctx = {}
    for n in ctx:
        lctx[n] = ctx[n]
    for p in ('actions',
              'install_modules',
              'uninstall_modules',
              'upgrade_modules'):
        if conf_obj.has_option(action, p):
            lctx[p] = conf_obj.get(action, p)
        else:
            lctx[p] = False
    for p in ('model',
              'model_code',
              'model_name',
              'code',
              'name',
              'filename',
              'cid_type'):
        if conf_obj.has_option(action, p):
            lctx[p] = conf_obj.get(action, p)
        elif p in lctx:
            del lctx[p]
    # lctx['actions_db'] = ''
    # lctx['actions_mc'] = ''
    for p in ('install_modules',
              'uninstall_modules',
              'actions',
              'cid_type'):
        if p in lctx:
            lctx[p] = os0.str2bool(lctx[p], lctx[p])
    return lctx


def log_company(oerp, ctx, c_id):
    company_obj = oerp.browse('res.company', c_id)
    msg = u"Company {0:>3})\t'{1}'".format(c_id,
                                           tounicode(company_obj.name))
    msg_log(False, 2, msg)


#############################################################################
# Public actions
#
def act_unit_test(oerp, ctx):
    """This function acts just for unit test"""
    return 0


def act_run_unit_tests(oerp, ctx):
    """"Run module unit test"""
    # import pdb
    # pdb.set_trace()
    sts = oerp.execute('ir.actions.server',
                       'Run Unit test',
                       'banking_export_pain')
    return sts


def act_per_db(oerp, ctx):
    """Iter action on DBs"""
    dblist = get_dblist(oerp)
    sts = 0
    for db in sorted(dblist):
        if re.match(ctx['dbfilter'], db):
            ctx = init_ctx(ctx, db)
            msg = u"DB=" + db + " (" + ctx.get('db_type', '') + ")"
            msg_log(ctx, 1, msg)
            if ctx['dbtypefilter']:
                if ctx['db_type'] != ctx['dbtypefilter']:
                    msg = u"DB skipped by invalid db_type"
                    debug_msg_log(ctx, 5, msg)
                    continue
            if 'actions_db' not in ctx:
                ctx['actions_db'] = ctx['actions']
            lgiuser = do_login(oerp, ctx)
            if lgiuser:
                sts = do_actions(oerp, ctx)
                if sts:
                    break
    return sts


def act_per_company(oerp, ctx):
    """iter on companies"""
    company_ids = oerp.search('res.company')
    sts = 0
    for c_id in sorted(company_ids):
        ctx['company_id'] = c_id
        company_obj = oerp.browse('res.company', c_id)
        if re.match(ctx['companyfilter'], company_obj.name):
            log_company(oerp, ctx, c_id)
            sts = do_actions(oerp, ctx)
            if sts:
                break
    return sts


def act_per_user(oerp, ctx):
    """iter on users"""
    user_ids = oerp.search('res.users')
    sts = 0
    for u_id in sorted(user_ids):
        user_obj = oerp.browse('res.users', u_id)
        if re.match(ctx['userfilter'], user_obj.login):
            msg = u"User {0:>2} {1}\t'{2}'\t{3}\t[{4}]".format(
                u_id,
                tounicode(user_obj.login),
                tounicode(user_obj.partner_id.name),
                tounicode(user_obj.partner_id.email),
                tounicode(user_obj.company_id.name))
            msg_log(ctx, 2, msg)
            if user_obj.login == "admin":
                ctx['def_company_id'] = user_obj.company_id.id
                ctx['def_company_name'] = user_obj.company_id.name
                ctx['def_partner_id'] = user_obj.partner_id.id
                ctx['def_user_id'] = u_id
                if user_obj.company_id.country_id:
                    ctx['def_country_id'] = user_obj.company_id.country_id.id
                else:
                    ctx['def_country_id'] = user_obj.partner_id.country_id.id
            sts = do_actions(oerp, ctx)
            if sts:
                break
    return sts


def act_update_modules(oerp, ctx):
    """Update module list on DB"""
    msg = u"Update module list"
    msg_log(ctx, 3, msg)
    if not ctx['simulate']:
        oerp.execute('base.module.update',
                     "update_module",
                     [])
    return 0


def act_upgrade_modules(oerp, ctx):
    """Upgrade module from list"""
    msg = u"Upgrade modules"
    msg_log(ctx, 3, msg)
    module_list = ctx['upgrade_modules'].split(',')
    done = 0
    for m in module_list:
        if m == "":
            continue
        ids = oerp.search('ir.module.module',
                          [('name', '=', m),
                           ('state', '=', 'installed')])
        if not ctx['simulate']:
            if len(ids):
                try:
                    oerp.execute('ir.module.module',
                                 "button_immediate_upgrade",
                                 ids)
                    msg = "name={0}".format(m)
                    msg_log(ctx, 4, msg)
                    done += 1
                except:
                    msg = "!Module {0} not upgradable!".format(m)
                    msg_log(ctx, 4, msg)
            else:
                msg = "Module {0} not installed!".format(m)
                msg_log(ctx, 4, msg)
        else:
            msg = "name({0})".format(m)
            msg_log(False, 4, msg)

    if done > 0:
        time.sleep(done)
    return 0


def act_uninstall_modules(oerp, ctx):
    """Uninstall module from list"""
    msg = u"Uninstall unuseful modules"
    msg_log(ctx, 3, msg)
    module_list = ctx['uninstall_modules'].split(',')
    done = 0
    for m in module_list:
        if m == "":
            continue
        ids = oerp.search('ir.module.module',
                          [('name', '=', m),
                           ('state', '=', 'installed')])
        if not ctx['simulate']:
            if len(ids):
                if m != 'l10n_it_base':  # debug
                    try:
                        oerp.execute('ir.module.module',
                                     "button_immediate_uninstall",
                                     ids)
                        msg = "name={0}".format(m)
                        msg_log(ctx, 4, msg)
                        done += 1
                    except:
                        msg = "!Module {0} not uninstallable!".format(m)
                        msg_log(ctx, 4, msg)
            else:
                msg = "Module {0} already uninstalled!".format(m)
                msg_log(ctx, 4, msg)

            ids = oerp.search('ir.module.module',
                              [('name', '=', m),
                               ('state', '=', 'uninstalled')])
            if len(ids):
                module_obj = oerp.browse('ir.module.module', ids[0])
                oerp.unlink_record(module_obj)

        else:
            msg = "name({0})".format(m)
            msg_log(False, 4, msg)

    if done > 0:
        time.sleep(done)
    return 0


def act_install_modules(oerp, ctx):
    """Install modules from list"""
    msg = u"Install modules"
    msg_log(ctx, 3, msg)
    module_list = ctx['install_modules'].split(',')
    done = 0
    for m in module_list:
        if m == "":
            continue
        ids = oerp.search('ir.module.module',
                          [('name', '=', m),
                           ('state', '=', 'uninstalled')])
        if not ctx['simulate']:
            if len(ids):
                try:
                    oerp.execute('ir.module.module',
                                 "button_immediate_install",
                                 ids)
                    msg = "name={0}".format(m)
                    msg_log(ctx, 4, msg)
                    done += 1
                except:
                    msg = "!Module {0} not installable!".format(m)
                    msg_log(ctx, 4, msg)
            else:
                ids = oerp.search('ir.module.module',
                                  [('name', '=', m)])
                if len(ids):
                    msg = "Module {0} already installed!".format(m)
                else:
                    msg = "!Module {0} does not exist!".format(m)
                msg_log(ctx, 4, msg)
        else:
            msg = "name({0})".format(m)
            msg_log(False, 4, msg)

    if done > 0:
        time.sleep(done)
    return 0


def act_import_file(oerp, ctx):
    o_model = {}
    for p in ('model',
              'model_code',
              'model_name',
              'cid_type'):
        if p in ctx:
            o_model[p] = ctx[p]
    if 'filename' in ctx:
        csv_fn = ctx['filename']
    elif 'model' not in o_model:
        msg = u"!Wrong import file!"
        msg_log(ctx, 3, msg)
        return 1
    else:
        csv_fn = o_model['model'].replace('.', '_') + ".csv"
    msg = u"Import file " + csv_fn
    msg_log(ctx, 3, msg)
    return import_file(oerp, ctx, o_model, csv_fn)


def act_setup_banks(oerp, ctx):
    msg = u"Setup bank"
    msg_log(ctx, 3, msg)
    o_model = {}
    o_model['cid_type'] = True
    csv_fn = "res-bank.csv"
    return import_file(oerp, ctx, o_model, csv_fn)


def act_setup_sequence(oerp, ctx):
    msg = u"Setup sequence"
    msg_log(ctx, 3, msg)
    o_model = {}
    o_model['name'] = 'name'
    o_model['code'] = 'name'
    csv_fn = "ir-sequence.csv"
    return import_file(oerp, ctx, o_model, csv_fn)


def act_setup_account_journal(oerp, ctx):
    msg = u"Setup account journal"
    msg_log(ctx, 3, msg)
    o_model = {}
    o_model['name'] = 'name'
    o_model['code'] = 'name'
    csv_fn = "account-journal.csv"
    return import_file(oerp, ctx, o_model, csv_fn)


def setup_partner_banks(oerp, ctx):
    msg = u"Setup partner bank"
    msg_log(ctx, 3, msg)
    o_model = {}
    o_model['name'] = 'bank_name'
    csv_fn = "res-partner-bank.csv"
    return import_file(oerp, ctx, o_model, csv_fn)


def act_setup_partners(oerp, ctx):
    msg = u"Setup partner"
    msg_log(ctx, 3, msg)
    o_model = {}
    o_model['code'] = 'vat'
    csv_fn = "res-partner.csv"
    return import_file(oerp, ctx, o_model, csv_fn)


def act_check_config(oerp, ctx):
    if not ctx['simulate'] and 'def_company_id' in ctx:
        if ctx['def_company_id'] is not None:
            msg = u"Check config"
            msg_log(ctx, 3, msg)

            o_model = {}
            csv_fn = "sale-shop.csv"
            import_file(oerp, ctx, o_model, csv_fn)


def act_check_balance(oerp, ctx):
    msg = u"Check for balance; period: " \
        + ctx['date_start'] + ".." + ctx['date_stop']
    msg_log(ctx, 3, msg)
    company_id = ctx['company_id']
    period_ids = oerp.search('account.period',
                             [('company_id', '=', company_id),
                              ('date_start', '>=', ctx['date_start']),
                              ('date_stop', '<=', ctx['date_stop'])])
    account_ctr = 0
    credit_amt = 0.0
    debit_amt = 0.0
    acc_amt_s = {}
    move_line_ids = oerp.search('account.move.line',
                                [('company_id', '=', company_id),
                                 ('period_id', 'in', period_ids),
                                 ('state', '=', 'valid')])
    adm_uids = ctx['adm_uids'].split(',')
    n = len(move_line_ids)
    i = 0
    for move_line_id in move_line_ids:
        move_line_obj = oerp.browse('account.move.line', move_line_id)
        i += 1
        msg_burst(4, "Move ", i, n)
        account_obj = move_line_obj.account_id
        if (account_obj.company_id.id != company_id):
            raise ValueError(u"Invalid company for account {0}".
                             format(tounicode(account_obj.name)))
        acctype_id = account_obj.user_type.id
        if acctype_id in acc_amt_s:
            acc_amt_s[acctype_id] += move_line_obj.credit
            acc_amt_s[acctype_id] -= move_line_obj.debit
        else:
            acc_amt_s[acctype_id] = move_line_obj.credit
            acc_amt_s[acctype_id] -= move_line_obj.debit
        credit_amt += move_line_obj.credit
        debit_amt += move_line_obj.debit

        acctype_obj = oerp.browse('account.account.type', acctype_id)
        clf = acctype_obj.report_type
        if clf == "asset":
            pass
        elif clf == "liability":
            pass
        elif clf == "income":
            pass
        elif clf == "expense":
            pass
        else:
            print("Look carefully at ", move_line_id, " account record")

    msg = "Total balance {0:11.2f} {1:11.2f}".format(credit_amt, debit_amt)
    msg_log(ctx, 3, msg)
    bal_ep_s = {}
    bal_ep_s['_'] = 0.0
    for acctype_id in acc_amt_s:
        acctype_obj = oerp.browse('account.account.type', acctype_id)
        clf = acctype_obj.report_type
        if clf == "asset":
            cf = "1_attivo"
            ep = "3_patr"
        elif clf == "liability":
            cf = "2_passivo"
            ep = "3_patr"
        elif clf == "income":
            cf = "6_ricavi"
            ep = "8_ce"
        elif clf == "expense":
            cf = "7_costi"
            ep = "8_ce"
        else:
            cf = "x_????"
            ep = "z"
        msg = "{0:>2}({1:<6}):{2:<16}={3:11.2f}".format(
              acctype_id,
              ep,
              acctype_obj.name,
              acc_amt_s[acctype_id])
        msg_log(ctx, 3, msg)
        if ep in bal_ep_s:
            bal_ep_s[ep] += acc_amt_s[acctype_id]
        else:
            bal_ep_s[ep] = acc_amt_s[acctype_id]
        if cf in bal_ep_s:
            bal_ep_s[cf] += acc_amt_s[acctype_id]
        else:
            bal_ep_s[cf] = acc_amt_s[acctype_id]
        bal_ep_s['_'] += acc_amt_s[acctype_id]

    for ep in sorted(bal_ep_s):
        msg = "({0:<12})={1:>11.2f}".format(ep,
                                            bal_ep_s[ep])
        if ep != "_" or bal_ep_s[ep] != 0.0:
            msg_log(ctx, 3, msg)

    if len(adm_uids):
        msg = "Account move ctr={0:>5}".format(account_ctr)

    return 0


#############################################################################
# Models
#
def _get_model_bone(ctx, o_model):
    """Inherit model structure from a parent model"""
    model = None
    cid_type = False
    if ctx is not None:
        if 'model' in ctx:
            model = ctx['model']
            if model == '':
                model = None
            else:
                if 'cid_type' in ctx:
                    cid_type = ctx['cid_type']
    if model is None:
        if 'model' in o_model:
            model = o_model['model']
            if model == '':
                model = None
        if 'cid_type' in o_model:
            cid_type = o_model['cid_type']
    return model, cid_type


def _get_model_code(ctx, o_model):
    """Get key field(s) name of  model"""
    if 'model_code' in o_model:
        code = o_model['model_code']
    elif 'code' in o_model:
        code = o_model['code']
    elif 'name' in o_model:
        code = o_model['name']
    elif 'code' in ctx:
        code = 'code'
    elif 'name' in ctx:
        code = 'name'
    elif 'id' in ctx:
        code = 'id'
    else:
        code = 'name'
    return code


def _get_model_name(ctx, o_model):
    """Get description field(s) name of  model"""
    if 'name' in ctx:
        name = 'name'
    elif 'code' in ctx:
        name = 'code'
    elif 'model_name' in o_model:
        name = o_model['model_name']
    elif 'name' in o_model:
        name = o_model['name']
    elif 'code' in o_model:
        name = o_model['code']
    else:
        name = 'name'
    return name


def _get_model_parms(oerp, ctx, o_model, value):
    """Extract model parameters and pure value from value and structure"""
    model, cid_type = _get_model_bone(ctx, o_model)
    value, prefix, suffix = cleanvalue(value)
    sep = '::'
    name = 'name'
    fname = 'id'
    i = value.find(sep)
    if i >= 0:
        cid_type = False
    else:
        sep = ':'
        i = value.find(sep)
        if i >= 0:
            cid_type = True
    if i < 0:
        i = value.find('.') + 1
        if value[0:i] == "base.":
            i -= 1
            model = "ir.model.data"
            name = ['module', 'name']
            value = [value[0:i], value[i + 1:]]
            cid_type = True
        else:
            model = None
            try:
                value = eval(value, None, ctx)
            except:
                pass
        if prefix or suffix:
            if isinstance(value, basestring):
                value = prefix + value + suffix
            elif isinstance(value, (bool, int, long, float)):
                value = prefix + str(value) + suffix
    else:
        model = value[:i]
        value = prefix + value[i + len(sep):] + suffix
        model, fname = _get_name_n_ix(model, fname)
        model, x = _get_name_n_params(model, name)
        if x.find(',') >= 0:
            name = x.split(',')
            value = value.split(',')
    return model, name, value, cid_type, fname


def _import_file_model(o_model, csv_fn):
    """Get model name of import file"""
    model, cid_type = _get_model_bone(None, o_model)
    if model is None:
        model = nakedname(csv_fn).replace('-', '.').replace('_', '.')
    return model, cid_type


def _import_file_dbtype(o_model, fields, csv_fn):
    """Get db selector name of import file"""
    if 'db_type' in o_model:
        db_type = o_model['db_type']
    elif 'db_type' in fields:
        db_type = 'db_type'
    else:
        db_type = False
    return db_type


def _import_file_get_hdr(oerp, ctx, o_model, csv_obj, csv_fn, row):
    """Analyze csv file header and get header names
    Header will be used to load value in table
    @ return:
    @ [model]      model name
    @ [name]       field name which is the record description
    @ [code]       field name which is the record key
    @ [db_type]    field name which is db type selection
    @ [repl_by_id] true if no record key name found (search for id)
    @ [hide_id]    if true, no id will be returned
    """
    o_skull = {}
    for n in o_model:
        o_skull[n] = o_model[n]
    csv_obj.fieldnames = row['undef_name']
    o_skull['model'], o_skull['cid_type'] = _import_file_model(o_model,
                                                               csv_fn)
    o_skull['name'] = _get_model_name(csv_obj.fieldnames,
                                      o_model)
    o_skull['code'] = _get_model_code(csv_obj.fieldnames,
                                      o_model)
    o_skull['db_type'] = _import_file_dbtype(o_model,
                                             csv_obj.fieldnames,
                                             csv_fn)
    if o_skull['code'] != 'id' and 'id' in csv_obj.fieldnames:
        o_skull['repl_by_id'] = True
    else:
        o_skull['repl_by_id'] = False
    o_skull['hide_id'] = True
    return o_skull


#############################################################################
# Field management and Queries
#
def _get_query_id(oerp, ctx, o_model, row):
    """Execute a query to get id of selection field read form csv
    Value may be expanded
    @ oerp:        oerplib object
    @ o_model:     special names
    @ ctx:         global parameters
    @ row:         record fields
    """
    code = o_model['code']
    model, cid_type = _get_model_bone(ctx, o_model)
    value = row.get(code, '')
    value = _eval_value(oerp,
                        ctx,
                        o_model,
                        code,
                        value)
    if model is None:
        ids = []
    else:
        ids = _get_raw_query_id(oerp,
                                ctx,
                                model,
                                code,
                                value,
                                cid_type)
        if len(ids) == 0 and o_model['repl_by_id'] and row['id']:
            o_skull = {}
            for n in o_model:
                o_skull[n] = o_model[n]
            o_skull['code'] = 'id'
            o_skull['hide_id'] = False
            value = _eval_value(oerp,
                                ctx,
                                o_skull,
                                'id',
                                row['id'])
            ids = oerp.search(model,
                              [('id', '=', value)])
    return ids


def _eval_value(oerp, ctx, o_model, name, value):
    """Evaluate value read form csv file: may be a function or macro
    @ oerp:        oerplib object
    @ o_model:     special names
    @ ctx:         global parameters
    @ name:        field name
    @ value:       field value (constant, macro or expression)
    """
    if name == 'id' and o_model.get('hide_id', False):
        value = None
    elif name == o_model.get('db_type', 'db_type'):
        value = None
    elif isinstance(value, basestring):
        if value[0:1] == "=":
            return _eval_subvalue(oerp, ctx, o_model, value)
        else:
            i = value.find('.') + 1
            if value[0:i] == "base.":
                return _eval_subvalue(oerp, ctx, o_model, value)
    return value


def _eval_subvalue(oerp, ctx, o_model, value):
    model, name, value, cid_type, fname = _get_model_parms(oerp,
                                                           ctx,
                                                           o_model,
                                                           value)
    if model is None:
        value = expr(oerp, ctx, model, name, value)
    else:
        value = _get_raw_query_id(oerp,
                                  ctx,
                                  model,
                                  name,
                                  value,
                                  cid_type)
    if isinstance(value, list):
        if len(value):
            value = value[0]
            if fname != 'id':
                o = oerp.browse(model, value)
                value = getattr(o, fname)
        else:
            value = None
    return value


def _get_raw_query_id(oerp, ctx, model, name, value, cid_type):
    """Execute a query to get id of selection field read form csv
    Do not expand value
    @ oerp:        oerplib object
    @ ctx:         global parameters
    @ model:       model name
    @ name:        field name
    @ value:       field value (just constant)
    @ cid_type:    hide company_id
    """

    if model is None:
        return value
    else:
        ids = _get_simple_query_id(oerp,
                                   ctx,
                                   model,
                                   name,
                                   value,
                                   cid_type)
    return ids


def _get_simple_query_id(oerp, ctx, model, code, value, cid_type):
    """Execute a simple query to get id of selection field read form csv
    Do not expand value
    @ oerp:        oerplib object
    @ ctx:         global parameters
    @ model:       model name
    @ code:        field name
    @ value:       field value (just constant)
    @ cid_type:    hide company_id
    """
    if not cid_type and 'company_id' in ctx:
        company_id = ctx['company_id']
    else:
        company_id = None
    where = []
    if isinstance(code, list) and isinstance(value, list):
        for i, c in enumerate(code):
            if i < len(value):
                where = append_2_where(oerp,
                                       ctx,
                                       model,
                                       c,
                                       value[i],
                                       where,
                                       '=')
            else:
                where = append_2_where(oerp,
                                       ctx,
                                       model,
                                       c,
                                       '',
                                       where,
                                       '=')
    else:
        where = append_2_where(oerp,
                               ctx,
                               model,
                               code,
                               value,
                               where,
                               '=')
    if company_id is not None:
        where.append(('company_id', '=', company_id))
    ids = oerp.search(model, where)
    if model == 'ir.model.data' and len(ids) == 1:
        o = oerp.browse('ir.model.data', ids[0])
        ids = [o.res_id]
    if ids is None:
        return []
    if len(ids) == 0:
        where = []
        if isinstance(code, list) and isinstance(value, list):
            for i, c in enumerate(code):
                if i < len(value):
                    where = append_2_where(oerp,
                                           ctx,
                                           model,
                                           c,
                                           value[i],
                                           where,
                                           'ilike')
                else:
                    where = append_2_where(oerp,
                                           ctx,
                                           model,
                                           c,
                                           '',
                                           where,
                                           'ilike')
        else:
            where = append_2_where(oerp,
                                   ctx,
                                   model,
                                   code,
                                   value,
                                   where,
                                   'ilike')
        if company_id is not None:
            where.append(('company_id', '=', company_id))
        ids = oerp.search(model, where)
    return ids


def append_2_where(oerp, ctx, model, code, value, where, op):
    if value is not None and value != "":
        if isinstance(value, basestring) and value[0] == '~':
            where.append('|')
            where.append((code, op, value))
            where.append((code, op, value[1:]))
        else:
            value = expr(oerp, ctx, model, code, value)
            if not isinstance(value, basestring) and op == 'ilike':
                where.append((code, '=', value))
            else:
                where.append((code, op, value))
    elif code == "country_id":
        where.append((code, '=', ctx['def_country_id']))
    elif code != "id" and code[-3:] == "_id":
        where.append((code, '=', ""))
    return where


def expr(oerp, ctx, model, code, value):
    """Evaluate python expression value"""
    if isinstance(value, basestring):
        i = value.find("${")
        j = value.rfind("}")
        if i >= 0 and j >= 0:
            o_model = {}
            o_model['model'] = model
            v = _eval_subvalue(oerp,
                               ctx,
                               o_model,
                               value[i + 2:j])
            if isinstance(v, (bool, int, long, float)):
                v = str(v)
            if isinstance(v, basestring):
                value = value[:i] + v + value[j + 1:]
            else:
                value = value[:i] + value[j + 1:]
            if value[0:1] == "=":
                value = value[1:]
            try:
                value = eval(v, None, ctx)
            except:
                pass
    return value


def cleanvalue(value):
    """Return real value for evaluation"""
    i = value.find("${")
    j = value.rfind("}")
    if i >= 0 and j >= i:
        if value[0] == '=':
            return value[i + 2:j], value[1:i], value[j + 1:]
        else:
            return value[i + 2:j], value[0:i], value[j + 1:]
    else:
        return value, '', ''


#############################################################################
# Private actions
#
def import_file(oerp, ctx, o_model, csv_fn):
    """Import data form file: it is like standard import
    Every field can be an expression enclose between '=${' and '}' tokens
    Any expression may be a standard macro (like def company id) or
    a query selection in format
     'model::value' -> get value id of model of current company
    or
     'model:value' -> get value id of model w/o company
    value may be an exact value or a like value
    """
    msg = u"Import file " + csv_fn
    msg_log(ctx, 4, msg)
    if 'company_id' in ctx:
        company_id = ctx['company_id']
    csv.register_dialect('odoo',
                         delimiter=',',
                         quotechar='\"',
                         quoting=csv.QUOTE_MINIMAL)
    csv_ffn = ctx['data_path'] + "/" + csv_fn
    if os.path.isfile(csv_ffn):
        csv_fd = open(csv_ffn, 'rb')
        hdr_read = False
        csv_obj = csv.DictReader(csv_fd,
                                 fieldnames=[],
                                 restkey='undef_name',
                                 dialect='odoo')
        for row in csv_obj:
            if not hdr_read:
                hdr_read = True
                o_model = _import_file_get_hdr(oerp,
                                               ctx,
                                               o_model,
                                               csv_obj,
                                               csv_fn,
                                               row)
                msg = u"Model={0}, Code={1} Name={2} NoCompany={3}"\
                    .format(o_model['model'],
                            tounicode(o_model['code']),
                            tounicode(o_model['name']),
                            o_model.get('cid_type', False))
                debug_msg_log(ctx, 5, msg)
                if o_model['name'] and o_model['code']:
                    continue
                else:
                    msg = u"!File " + csv_fn + " without key!"
                    msg_log(ctx, 4, msg)
                    break
            # Data for specific db type (i.e. just for test)
            if o_model.get('db_type', ''):
                if row[o_model['db_type']]:
                    if row[o_model['db_type']] != ctx['db_type']:
                        msg = u"Record not imported by invalid db_type"
                        debug_msg_log(ctx, 5, msg)
                        continue
            # Does record exist ?
            ids = _get_query_id(oerp,
                                ctx,
                                o_model,
                                row)
            vals = {}
            for n in row:
                val = _eval_value(oerp,
                                  ctx,
                                  o_model,
                                  n,
                                  row[n])
                if val is not None:
                    vals[n.split('/')[0]] = val
                msg = u"{0}={1}".format(n, tounicode(val))
                debug_msg_log(ctx, 6, msg)
                if n == o_model['name']:
                    name_new = val
            if 'company_id' in ctx and 'company_id' in vals:
                if int(vals['company_id']) != company_id:
                    continue
            if len(ids):
                id = ids[0]
                cur_obj = oerp.browse(o_model['model'], id)
                name_old = cur_obj[o_model['name']]
                msg = u"Update " + str(id) + " " + name_old
                debug_msg_log(ctx, 5, msg)
                if not ctx['simulate']:
                    oerp.write(o_model['model'], ids, vals)
                    msg = u"id={0}, {1}={2}->{3}"\
                          .format(cur_obj.id,
                                  tounicode(o_model['name']),
                                  tounicode(name_old),
                                  tounicode(name_new))
                    msg_log(ctx, 5, msg)
            else:
                msg = u"insert " + name_new.decode('utf-8')
                debug_msg_log(ctx, 5, msg)
                if not ctx['simulate']:
                    if not o_model.get('cid_type', False):
                        vals['company_id'] = ctx['company_id']
                    if 'id' in vals:
                        del vals['id']
                    id = oerp.create(o_model['model'], vals)
                    msg = u"creat id={0}, {1}={2}"\
                          .format(id,
                                  tounicode(o_model['name']),
                                  tounicode(name_new))
                    msg_log(ctx, 5, msg)
        csv_fd.close()
        return 0
    else:
        msg = u"!File " + csv_fn + " not found!"
        msg_log(ctx, 4, msg)
        return 1


def _import_config_file_value(o_model, ctx, value):
    if value[0:3] == "=${" and value[-1] == "}":
        defval, prefix, suffix = cleanvalue(value)
        if defval in ctx:
            value = prefix + ctx[defval] + suffix
        else:
            value = None
    return value


def debug_explore(oerp, ctx):
    ids = oerp.search('res.users')
    for id in ids:
        user = oerp.browse('res.users', id)
        print "User=", id, "(", user.name, ")"
        for n in user.groups_id:
            print u"{0:>3} {1:<20}"\
                .format(n.id,
                        tounicode(n.name))


def import_config_file(oerp, ctx, o_model, csv_fn):
    msg = u"Import config file " + csv_fn
    msg_log(ctx, 4, msg)
    csv.register_dialect('odoo',
                         delimiter=',',
                         quotechar='\"',
                         quoting=csv.QUOTE_MINIMAL)
    csv_ffn = ctx['data_path'] + "/" + csv_fn
    if os.path.isfile(csv_ffn):
        csv_fd = open(csv_ffn, 'rb')
        hdr_read = False
        csv_obj = csv.DictReader(csv_fd,
                                 fieldnames=[],
                                 restkey='undef_name',
                                 dialect='odoo')
        for row in csv_obj:
            if not hdr_read:
                csv_obj.fieldnames = row['undef_name']
                hdr_read = True
                file_valid = True
                if 'user' not in csv_obj.fieldnames:
                    file_valid = False
                if 'category' not in csv_obj.fieldnames:
                    file_valid = False
                if 'name' not in csv_obj.fieldnames:
                    file_valid = False
                if 'value' not in csv_obj.fieldnames:
                    file_valid = False
                if file_valid:
                    continue
                else:
                    msg = u"!Invalid header of " + csv_fn
                    msg = msg + u" Should be: user,category,name,value"
                    msg_log(ctx, 4, msg)
                    break
            user = _import_config_file_value(o_model,
                                             ctx,
                                             row['user'])
            category = _import_config_file_value(o_model,
                                                 ctx,
                                                 row['category'])
            name = _import_config_file_value(o_model,
                                             ctx,
                                             row['name'])
            if name == "" or name == "False":
                name = None
            value = _import_config_file_value(o_model,
                                              ctx,
                                              row['value'])
            setup_config_param(oerp, ctx, user, category, name, value)
        csv_fd.close()
    else:
        msg = u"!File " + csv_fn + " not found!"
        msg_log(ctx, 4, msg)


def setup_config_param(oerp, ctx, user, category, ctx_name, value):
    if not ctx['simulate']:
        ids = oerp.search('ir.module.category',
                          [('name', '=', category)])
        if len(ids):
            mod_cat_id = ids[0]
            if ctx_name is not None:
                ctx_sel_ids = oerp.search('res.groups',
                                          [('category_id', '=', mod_cat_id),
                                           ('name', '=', ctx_name)])
                ctx_label = "." + ctx_name
            else:
                ctx_sel_ids = oerp.search('res.groups',
                                          [('category_id', '=', mod_cat_id)])
                ctx_label = ""
            ctx_sel_name = {}
            for id in sorted(ctx_sel_ids):
                cur_obj = oerp.browse('res.groups', id)
                ctx_sel_name[cur_obj.name] = id
            if len(ctx_sel_ids) > 1:
                if value in ctx_sel_name:
                    msg = u"Param (" + category + ctx_label + \
                        ") = " + value + "(" + str(ctx_sel_name[value]) + ")"
                else:
                    msg = u"!Param (" + category + ctx_label + \
                        ") value " + value + " not valid!"
                    w = "("
                    for x in ctx_sel_name.keys():
                        msg = msg + w + x
                        w = ","
                    msg = msg + ")"
                msg_log(ctx, 5, msg)
            elif len(ctx_sel_ids) == 1:
                if os0.str2bool(value, False):
                    msg = u"!Param " + category + ctx_label + " = True"
                else:
                    msg = u"!Param " + category + ctx_label + " = False"
                msg_log(ctx, 5, msg)
            else:
                msg = u"!Param " + category + ctx_label + " not found!"
                msg_log(ctx, 5, msg)
        else:
            msg = u"!Category " + category + ctx_label + " not found!"
            msg_log(ctx, 5, msg)


#############################################################################
# Public action list
#
def create_simple_act_list():
    """Return action list of local executable functions
    This function is project to be smart for future version
    """
    lx_act = []
    for a in list(globals()):
        if action_id(a):
            lx_act.append(action_id(a))
    return lx_act


def create_act_list(ctx):
    lx_act = create_simple_act_list()
    sts = check_actions_list(ctx, lx_act)
    if sts:
        lx_act = extend_actions_list(ctx, lx_act)
    ctx['_lx_act'] = lx_act
    return ctx


def check_actions_list(ctx, lx_act):
    """Merge local action list with user defined action list"""
    if lx_act is None:
        lx_act = create_simple_act_list()
    conf_obj = ctx['_conf_obj']
    list = ctx.get('actions', None)
    return check_actions_1_list(ctx,
                                lx_act,
                                conf_obj,
                                list)


def check_actions_1_list(ctx, lx_act, conf_obj, list):
    if not list:
        return False
    valid = True
    acts = list.split(',')
    for act in acts:
        if act == '' or act is False or act is None:
            continue
        elif act == 'per_db':
            actions = ctx.get('actions_db', None)
            if actions:
                valid = check_actions_1_list(ctx,
                                             actions,
                                             conf_obj,
                                             actions)
            else:
                valid = False
        elif act == 'per_company':
            actions = ctx.get('actions_mc', None)
            if actions:
                valid = check_actions_1_list(ctx,
                                             actions,
                                             conf_obj,
                                             actions)
            else:
                valid = False
        elif act == 'per_user':
            actions = ctx.get('actions_uu', None)
            if actions:
                valid = check_actions_1_list(ctx,
                                             actions,
                                             conf_obj,
                                             actions)
            else:
                valid = False
        elif act in lx_act:
            continue
        elif conf_obj.has_section(act):
            if conf_obj.has_option(act, 'actions'):
                actions = conf_obj.get(act, 'actions')
                valid = check_actions_1_list(ctx,
                                             lx_act,
                                             conf_obj,
                                             actions)
            else:
                valid = False
        else:
            valid = False
        if not valid:
            break
    return valid


def extend_actions_list(ctx, lx_act):
    conf_obj = ctx['_conf_obj']
    lx_act = extend_actions_1_list(ctx['actions'],
                                   lx_act,
                                   conf_obj)
    return lx_act


def extend_actions_1_list(list, lx_act, conf_obj):
    if not list:
        return lx_act
    acts = list.split(',')
    for act in acts:
        if act == '' or act is False or act is None:
            continue
        elif act == 'per_db':
            if conf_obj.has_option(act, 'actions_db'):
                actions = conf_obj.get(act, 'actions_db')
                lx_act = extend_actions_1_list(actions,
                                               lx_act,
                                               conf_obj)
            else:
                break
        elif act == 'per_company':
            if conf_obj.has_option(act, 'actions_mc'):
                actions = conf_obj.get(act, 'actions_mc')
                lx_act = extend_actions_1_list(actions,
                                               lx_act,
                                               conf_obj)
            else:
                break
        elif act == 'per_user':
            if conf_obj.has_option(act, 'actions_uu'):
                actions = conf_obj.get(act, 'actions_uu')
                lx_act = extend_actions_1_list(actions,
                                               lx_act,
                                               conf_obj)
            else:
                break
        elif act in lx_act:
            continue
        elif conf_obj.has_section(act):
            lx_act.append(act)
            if conf_obj.has_option(act, 'actions'):
                actions = conf_obj.get(act, 'actions')
                lx_act = extend_actions_1_list(actions,
                                               lx_act,
                                               conf_obj)
            else:
                break
    return lx_act


def check_4_actions(ctx):
    if 'test_unit_mode' in ctx:
        log = False
    else:
        log = True
    if '_lx_act' in ctx:
        lx_act = ctx['_lx_act']
    else:
        lx_act = create_simple_act_list()
    valid_actions = check_actions_list(ctx, lx_act)
    if not valid_actions and log:
        msg = u"Invalid action declarative "
        msg_log(ctx, 0, msg)
        msg = u"Use one or more in following parameters:"
        msg_log(ctx, 0, msg)
        msg = u"action_%%=" + ",".join(str(e) for e in lx_act)
        msg_log(ctx, 0, msg)
    return valid_actions


#############################################################################
# Custom parser functions
#
def default_conf():
    """Default configuration values"""
    y = date.today().year
    dfmt = "%Y-%m-%d"
    dts_start = date(y, 1, 1).strftime(dfmt)
    dts_stop = date(y, 12, 31).strftime(dfmt)
    d = {"login_user": "admin",
         "login_password": "admin",
         "login2_user": "admin",
         "login2_password": "admin",
         "svc_protocol": "xmlrpc",
         "xmlrpc_port": "8069",
         "dbfilter": ".*",
         "dbfilterz": "",
         "dbfiltert": "",
         "dbtypefilter": "",
         "companyfilter": ".*",
         "date_start": dts_start,
         "date_stop": dts_stop,
         "adm_uids": "1",
         "set_passepartout": "0",
         "check_balance": "0",
         "setup_banks": "0",
         "setup_account_journal": "0",
         "setup_partners": "0",
         "setup_partner_banks": "0",
         "check_config": "0",
         "install_modules": False,
         "uninstall_modules": False,
         "upgrade_modules": False,
         "zeroadm_mail": "cc@shs-av.com",
         "data_path": "./data",
         "actions": "per_db",
         "actions_db": "per_company",
         "actions_mc": "per_users",
         "actions_uu": "unit_test"}
    return d


def create_parser():
    """Return command-line parser.
    Some options are standard:
    -c --config     set configuration file (conf_fn)
    -h --help       show help
    -q --quiet      quiet mode
    -t --dry-run    simulation mode for test (simulate)
    -U --user       set username (user)
    -v --verbose    verbose mode (dbg_mode)
    -V --version    show version
    -y --yes        confirmation w/out ask
    """
    parser = argparse.ArgumentParser(
        description=docstring_summary(__doc__),
        epilog="© 2015 by SHS-AV s.r.l."
               " - http://www.zeroincombenze.org")
    parser.add_argument("-c", "--config",
                        help="configuration file",
                        dest="conf_fn",
                        metavar="file",
                        default=CONF_FN)
    parser.add_argument("-d", "--dbfilter",
                        help="DB filter",
                        dest="dbfilter",
                        metavar="regex",
                        default="")
    parser.add_argument("-p", "--data_path",
                        help="Import file path",
                        dest="data_path",
                        metavar="dir",
                        default="")
    parser.add_argument("-q", "--quiet",
                        help="run silently",
                        action="store_true",
                        dest="quiet_mode",
                        default=False)
    parser.add_argument("-t", "--dry_run",
                        help="test execution mode",
                        action="store_true",
                        dest="simulate",
                        default=False)
    parser.add_argument("-v", "--verbose",
                        help="run with debugging output",
                        action="store_true",
                        dest="dbg_mode",
                        default=False)
    parser.add_argument("-V", "--version",
                        action="version",
                        version="%(prog)s " + __version__)
    # parser.add_argument("filesrc",
    #                     help="Files to convert")
    return parser


def create_params_dict(opt_obj, conf_obj):
    """Create all params dictionary"""
    ctx = {}
    s = "options"
    if not conf_obj.has_section(s):
        conf_obj.add_section(s)
    ctx['host'] = conf_obj.get(s, "db_host")
    ctx['db_pwd'] = conf_obj.get(s, "db_password")
    ctx['login_pwd'] = conf_obj.get(s, "login_password")
    ctx['login2_pwd'] = conf_obj.get(s, "login2_password")
    for p in ('db_name',
              'db_user',
              'login_user',
              'login2_user',
              'zeroadm_mail',
              'svc_protocol',
              'dbfilter',
              'dbfilterz',
              'dbfiltert',
              'dbtypefilter',
              'companyfilter',
              'adm_uids',
              'data_path',
              'date_start',
              'date_stop',
              'actions',
              'actions_db',
              'actions_mc',
              'actions_uu',
              'install_modules',
              'uninstall_modules',
              'upgrade_modules'):
        ctx[p] = conf_obj.get(s, p)
    for p in ('install_modules',
              'uninstall_modules',
              'actions',
              'actions_db',
              'actions_mc',
              'actions_uu'):
        ctx[p] = os0.str2bool(ctx[p], ctx[p])
    for p in ('set_passepartout',
              'check_balance',
              'setup_banks',
              'setup_account_journal',
              'setup_partners',
              'setup_partner_banks',
              'check_config'):
        ctx[p] = conf_obj.getboolean(s, p)
    for p in ():
        ctx[p] = conf_obj.getint(s, p)
    ctx['svc_port'] = conf_obj.getint(s, "xmlrpc_port")

    ctx['simulate'] = opt_obj.simulate
    ctx['dbg_mode'] = opt_obj.dbg_mode
    ctx['quiet_mode'] = opt_obj.quiet_mode
    if opt_obj.dbfilter != "":
        ctx['dbfilter'] = opt_obj.dbfilter
    if opt_obj.data_path != "":
        ctx['data_path'] = opt_obj.data_path
    ctx['_conf_obj'] = conf_obj
    ctx['_opt_obj'] = opt_obj

    return ctx


#############################################################################
# Common parser functions
#
def nakedname(fn):
    """Return nakedename (without extension)"""
    i = fn.rfind('.')
    if i >= 0:
        j = len(fn) - i
        if j <= 4:
            fn = fn[:i]
    return fn


def docstring_summary(docstring):
    """Return summary of docstring."""
    for text in docstring.split('\n'):
        if text.strip():
            break
    return text.strip()


def parse_args(arguments, apply_conf=False):
    """Parse command-line options."""
    parser = create_parser()
    opt_obj = parser.parse_args(arguments)
    if apply_conf:
        if hasattr(opt_obj, 'conf_fn'):
            conf_fn = opt_obj.conf_fn
            conf_obj, conf_fn = read_config(opt_obj, parser, conf_fn=conf_fn)
        else:
            conf_obj, conf_fn = read_config(opt_obj, parser)
        opt_obj = parser.parse_args(arguments)
    ctx = create_params_dict(opt_obj, conf_obj)
    if 'conf_fn' in globals():
        ctx['conf_fn'] = conf_fn
    return ctx


def read_config(opt_obj, parser, conf_fn=None):
    """Read both user configuration and local configuration."""
    if conf_fn is None or not conf_fn:
        if CONF_FN:
            conf_fn = CONF_FN
        else:
            conf_fn = nakedname(os.path.basename(__file__)) + ".conf"
    d = default_conf()
    conf_obj = ConfigParser.SafeConfigParser(d)
    if ODOO_CONF:
        conf_fns = (ODOO_CONF, conf_fn)
    else:
        conf_fns = conf_fn
    conf_obj.read(conf_fns)
    return conf_obj, conf_fn


def main():
    """Tool main"""
    sts = 0
    init()
    ctx = parse_args(sys.argv[1:], apply_conf=APPLY_CONF)
    print_hdr_msg(ctx)
    # import pdb
    # pdb.set_trace()
    if not check_4_actions(ctx):
        return 1
    ctx = create_act_list(ctx)
    oerp = open_connection(ctx)
    sts = do_actions(oerp, ctx)
    msg = u"Operations ended"
    msg_log(ctx, 0, msg)
    return sts

if __name__ == "__main__":
    sts = main()
    sys.exit(sts)

# vim:expandtab:smartindent:tabstop=4:softtabstop=4:shiftwidth=4:
