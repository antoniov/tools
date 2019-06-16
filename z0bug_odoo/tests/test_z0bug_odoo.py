#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Copyright (C) 2018-2019 SHS-AV s.r.l. (<http://www.zeroincombenze.org>)
# License AGPL-3.0 or later (http://www.gnu.org/licenses/agpl).
"""
    Zeroincombenze® unit test library for python programs Regression Test Suite
"""

# import pdb
import os
import os.path
import sys
from zerobug import Z0test


__version__ = "0.1.0.1.1"

MODULE_ID = 'z0bug_odoo'


def version():
    return __version__


#
# Run main if executed as a script
if __name__ == "__main__":
    ctx = Z0test.parseoptest(sys.argv[1:],
                             version=version())
    sts = Z0test.main_file(ctx)
    exit(sts)

# vim:expandtab:smartindent:tabstop=4:softtabstop=4:shiftwidth=4: