# -*- coding: utf-8 -*-
# Copyright (C) 2018-2019 SHS-AV s.r.l. (<http://www.zeroincombenze.org>)
# License AGPL-3.0 or later (http://www.gnu.org/licenses/agpl).

from __future__ import print_function,unicode_literals
from past.builtins import basestring

import os
import sys
import csv
from zerobug import Z0BUG


__version__ = "0.1.0.1.2"


class Z0bugOdoo(object):

    def get_data_file(self, model, csv_fn):
        full_fn = os.path.join(os.path.dirname(__file__), 'data', csv_fn)
        pymodel = model.replace('.', '_')
        with open(full_fn, 'rb') as fd:
            hdr = False
            csv_obj = csv.DictReader(fd,
                                     fieldnames=[],
                                     restkey='undef_name',)
            for row in csv_obj:
                if not hdr:
                    hdr = True
                    csv_obj.fieldnames = row['undef_name']
                    setattr(self, pymodel, {})
                    continue
                if 'id' not in row:
                    continue
                getattr(self, pymodel)[row['id']] = row

    def get_test_values(self, model, xref):
        '''Return model values for test'''
        xids = xref.split('.')
        if len(xids) == 1:
            xids[0], xids[1] = 'z0bug', xids[0]
        if xids[0] == 'z0bug':
            pymodel = model.replace('.', '_')
            if not hasattr(self, pymodel):
                self.get_data_file(model, '%s.csv' % pymodel)
            if xref not in getattr(self, pymodel):
                raise KeyError('Invalid xref %s for model %s!' % (xref, model))
            return getattr(self, pymodel)[xref]
        return {}

    def initialize_model(self, model):
        '''Write all record of model with test values'''
        pymodel = model.replace('.', '_')
        if not hasattr(self, pymodel):
            self.get_data_file(model, '%s.csv' % pymodel)
        for xref in getattr(self, pymodel):
            pass
