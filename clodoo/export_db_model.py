#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys
import os
from datetime import datetime, date
import clodoo
import csv
import z0lib
# import pdb


__version__ = "0.1.0"


CACHE = {}


def get_symbolic_value(ctx, model, name, value):
    name_model = 'ir.model.data'
    field_model = 'ir.model.fields'
    if name:
        cache_name = '%s.%s.%s' % (model, name, value)
        if cache_name in CACHE:
            return CACHE[cache_name]
        field_id = clodoo.searchL8(ctx,
                                   field_model,
                                   [('model', '=', model),
                                    ('name', '=', name)])
        if field_id:
            relation = clodoo.browseL8(ctx,
                           field_model,
                           field_id[0]).relation
            name_id = clodoo.searchL8(ctx,
                                      name_model,
                                      [('model', '=', relation),
                                       ('res_id', '=', value)])
            if name_id:
                value = clodoo.browseL8(ctx,
                                        name_model,
                                        name_id[0]).name
                CACHE[cache_name] = value
            elif ctx['enhanced']:
                if name == 'company_id':
                    value = '=${company_id}'
                else:
                    for sel_name in ('code', 'name'):
                        ids = clodoo.searchL8(ctx,
                                              field_model,
                                              [('model', '=', relation),
                                               ('name', '=', sel_name)])
                        if ids:
                            break
                    if ids:
                        value =  clodoo.browseL8(ctx,
                                                 relation,
                                                 value)[sel_name]
                        value = '=${%s(%s)::%s}' % (relation,
                                                    sel_name,
                                                    value)
    else:
        name_id = clodoo.searchL8(ctx,
                                  name_model,
                                  [('model', '=', model),
                                   ('res_id', '=', value)])
        if name_id:
            value = clodoo.browseL8(ctx,
                                    name_model,
                                    name_id[0]).name
    return value


def export_table(ctx):
    import pdb
    pdb.set_trace()
    current_year = date.today().year
    model = ctx['model']
    name_model = 'ir.model.data'
    field_model = 'ir.model.fields'
    out_file = ctx['out_file']
    if not out_file:
        out_file = model.replace('.', '_') + '.csv'
    print "Output file %s" % out_file
    csv_out = open(out_file, 'wb')
    if out_file[-4:] == '.csv':
        hdr_file = out_file[0:-4] + '.hdr' + out_file[-4:]
    else:
        hdr_file = out_file + '.hdr'
    hdr_file = os.path.join('./hdrs', hdr_file)
    try:
        hdr_fd = open(hdr_file, 'rbU')
        line = hdr_fd.read()
        hdr_fd.close()
        out_flds = line.split('\n')[0].split(',')
    except BaseException:
        print 'Header file %s not found!' % hdr_file
    header = dict((n, n) for n in out_flds)
    csv_obj = csv.DictWriter(csv_out, fieldnames=out_flds)
    csv_obj.writerow(header)
    for rec in clodoo.browseL8(ctx,
                               model,
                               clodoo.searchL8(ctx, model, [])):
        print 'Reading id %d' % rec.id
        out_dict = {}
        for nm in out_flds:
            f = nm.split(':')
            if nm == 'id':
                value = rec[f[0]]
                value = get_symbolic_value(ctx, model, False, value)
            elif len(f) == 1:
                value = rec[f[0]]
                if isinstance(rec[f[0]], (date, datetime)):
                    ttype = clodoo.browseL8(
                        ctx, 'ir.model.fields', clodoo.searchL8(
                            ctx,
                            'ir.model.fields',
                            [('model','=',model),
                             ('name','=',f[0])])[0]).ttype
                    if ttype == 'date':
                        if value.year == current_year:
                            value = '${_current_year}-%02d-%02d' % (value.month,
                                                                    value.day)
                        elif value.year == (current_year - 1):
                            value = '${_last_year}-%02d-%02d' % (value.month,
                                                                 value.day)
            elif f[1] == 'id':
                if isinstance(rec[f[0]], bool):
                    value = rec[f[0]]
                    if not value:
                        value = ''
                else:
                    value = rec[f[0]][f[1]]
                    value = get_symbolic_value(ctx, model, f[0], value)
            if isinstance(value, (bool, int, float, long, complex)):
                out_dict[nm] = str(value)
            else:
                out_dict[nm] = value
        csv_obj.writerow(out_dict)
    csv_out.close()


parser = z0lib.parseoptargs("Export table account.tax",
                            "© 2017-2018 by SHS-AV s.r.l.",
                            version=__version__)
parser.add_argument('-h')
parser.add_argument("-b", "--odoo-branch",
                    help="talk server Odoo version",
                    dest="odoo_vid",
                    metavar="version",
                    default="")
parser.add_argument("-c", "--config",
                    help="configuration command file",
                    dest="conf_fn",
                    metavar="file",
                    default='./clodoo.conf')
parser.add_argument("-d", "--dbname",
                    help="DB name to connect",
                    dest="db_name",
                    metavar="file",
                    default='')
parser.add_argument("-e", "--enhanced",
                    help="use enhance convention for many2* fields",
                    action="store_true",
                    dest="enhanced",
                    default=False)
parser.add_argument("-f", "--format",
                    help="file format",
                    dest="format",
                    metavar="csv|xml",
                    default='csv')
parser.add_argument("-m", "--model",
                    help="model name to extract",
                    dest="model",
                    metavar="name",
                    default='')
parser.add_argument("-o", "--out-file",
                    help="output file",
                    dest="out_file",
                    metavar="file",
                    default='')
parser.add_argument('-n')
parser.add_argument('-q')
parser.add_argument('-V')
parser.add_argument('-v')

# Connect to DB
print "Connect to DB"
ctx = parser.parseoptargs(sys.argv[1:], apply_conf=False)
oerp, uid, ctx = clodoo.oerp_set_env(confn=ctx['conf_fn'],
                                     db=ctx['db_name'],
                                     ctx=ctx)
if ctx['model']:
    export_table(ctx)
else:
    print 'Missed model name!'