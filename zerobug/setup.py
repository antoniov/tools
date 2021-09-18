# -*- coding: utf-8 -*-
from setuptools import setup
from setuptools import find_packages

setup(name='zerobug',
      version='1.0.1.2',
      description='Bash zeroincombenze lib',
      long_description="""
This library can run unit test of target package software.
Supported languages are python (through z0testlib.py) and bash (through z0testrc)

zerobug supports test automation, aggregation of tests into collections
and independence of the tests from the reporting framework.
The zerobug module provides all code that make it easy to support testing
both for python programs both for bash scripts.
zerobug shows execution test with a message like "n/tot message"
where n is current unit test and tot is the total unit test to execute,
that is a sort of advancing test progress.

You can use z0bug_odoo that is the odoo integration to test Odoo modules.

zerobug is built on follow concepts:

* test main - it is a main program to executes all test runners
* test runner - it is a program to executes one or more test suites
* test suite - it is a collection of test cases
* test case - it is a smallest unit test

The main file is the command zerobug of this package; it searches for test runner files
named `[id_]test_` where 'id' is the shor name of testing package.

Test suite is a collection of test case named `test_[0-9]+` inside the runner file,
executed in sorted order.

Every suit can contains one or more test case, the smallest unit test;
every unit test terminates with success or with failure.

Because zerobug can show total number of unit test to execute, it runs tests
in 2 passes. In the first pass it counts the number of test, in second pass executes really
it. This behavior can be overridden by -0 switch.
""",
      classifiers=[
          'Development Status :: 4 - Beta',
          'License :: OSI Approved :: GNU Affero General Public License v3',
          'Operating System :: POSIX',
          'Programming Language :: Python :: 2.7',
          'Programming Language :: Python :: 3.6',
          'Programming Language :: Python :: 3.7',
          'Intended Audience :: Developers',
          'Topic :: Software Development',
          'Topic :: Software Development :: Libraries',
          'Topic :: System :: System Shells',
      ],
      keywords='bash, optargs',
      project_urls={
          'Documentation': 'https://zeroincombenze-tools.readthedocs.io',
          'Source': 'https://github.com/zeroincombenze/tools',
      },
      author='Antonio Maria Vigliotti',
      author_email='antoniomaria.vigliotti@gmail.com',
      license='Affero GPL',
      packages=find_packages(
          exclude=['docs', 'examples', 'tests', 'egg-info', 'junk']),
      package_data={
          '': ['./z0testrc']
      },
      entry_points={
          'console_scripts': [
              'zerobug = zerobug.scripts.main:main'
          ],
      },
      zip_safe=False)
