# -*- coding: utf-8 -*-
from setuptools import setup
from setuptools import find_packages

setup(name='z0bug_odoo',
<<<<<<< HEAD
      version='1.0.5.104',
=======
      version='1.0.5.2',
>>>>>>> stash
      description='Odoo testing framework',
      long_description="""
Zeroincombenze(R) continuous testing framework for Odoo modules.

Make avaiable test functions indipendent by Odoo version.
""",
      classifiers=[
          'Development Status :: 3 - Alpha',
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
      keywords='unit test debug',
      project_urls={
          'Documentation': 'https://zeroincombenze-tools.readthedocs.io',
          'Source': 'https://github.com/zeroincombenze/tools',
      },
      url='https://zeroincombenze-tools.readthedocs.io',
      author='Antonio Maria Vigliotti',
      author_email='antoniomaria.vigliotti@gmail.com',
      license='Affero GPL',
<<<<<<< HEAD
      # include_package_data=True,
      packages=find_packages(
          exclude=['docs', 'examples', 'tests', 'egg-info', 'junk']),
      package_data={
          '': ['scripts/setup.conf', 'data/*'],
      },
      entry_points={
          'console_scripts': [
              'z0bug-odoo-info = z0bug_odoo.scripts.main:main',
              'travis_run_tests = z0bug_odoo.travis.travis_run_tests:main',
          ],
=======
      packages=find_packages(
          exclude=['docs', 'examples', 'tests', 'egg-info', 'junk']),
      package_data={
          '': ['scripts/setup.info', 'data/*'],
>>>>>>> stash
      },
      zip_safe=False)
