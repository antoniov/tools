# -*- coding: utf-8 -*-
"""z0lib

bash library for tools
"""

__version__ = '1.0.2.99'

try:
    from . import z0librun as z0lib
except ImportError:
    from z0lib import z0librun as z0lib
