# -*- coding: utf-8 -*-
from setuptools import setup
from setuptools import find_packages

with open('./README.rst', 'r') as fd:
    readme = fd.read()

setup(name='os0',
      version='1.0.2.1',
      description='OS indipendent interface',
      long_description_content_type='text/x-rst',
      long_description=readme,
      classifiers=[
          'Development Status :: 4 - Beta',
          'License :: OSI Approved :: GNU Affero General Public License v3',
          'Operating System :: POSIX',
          'Programming Language :: Python :: 2.7',
          'Programming Language :: Python :: 3.6',
          'Programming Language :: Python :: 3.7',
          'Intended Audience :: Developers',
          'Topic :: Software Development',
          'Topic :: Software Development :: Build Tools',
          'Operating System :: OS Independent',
      ],
      keywords='os path linux windows openvms',
      url='https://zeroincombenze-tools.readthedocs.io',
      project_urls={
          'Documentation': 'https://zeroincombenze-tools.readthedocs.io',
          'Source': 'https://github.com/zeroincombenze/tools',
      },
      author='Antonio Maria Vigliotti',
      author_email='antoniomaria.vigliotti@gmail.com',
      license='Affero GPL',
      install_requires=['z0lib', 'future'],
      packages=find_packages(
          exclude=['docs', 'examples', 'tests', 'egg-info', 'junk']),
      package_data={
          '': ['./README.rst', 'scripts/setup.info'],
      },
      entry_points={
          'console_scripts': [
              'os0-info = os0.scripts.main:main'
          ],
      },
      zip_safe=False)
