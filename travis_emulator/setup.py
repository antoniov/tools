# -*- coding: utf-8 -*-
from setuptools import setup
from setuptools import find_packages

setup(name='travis_emulator',
<<<<<<< HEAD
      version='1.0.2.99',
=======
      version='1.0.2.1',
>>>>>>> stash
      description='Travis CI emulator for local develop environment',
      long_description="""
Travis emulator can emulate TravisCi parsing the **.travis.yml** file in local Linux machine and it is osx/darwin compatible.
You can test your application before pushing code to github.com web site.

Travis emulator can creates all the build declared in **.travis.yml**; all the builds are executed in sequential way.
The directory ~/travis_log (see -l switch) keeps the logs of all builds created.
Please note that log file is a binary file with escape ANSI screen code.
If you want to see the log use one of following command:

    `travis show`

    `less -R ~/travis_log/<build_name>.log`

A travis build executes the following steps:

* Initialize from local .travis.conf (not in travis-ci.org)
* Optional install packages `apt addons` (emulatore makes just the check)
* Optional install packages `cache`
* Set global values `env global`
* Execute code `before_install`
* Execute matrix initialization, included python version
* Execute build code `install`
* Execute build code `before_script`
* Execute build code `script`
* Execute build `before_cache` (only if cache is effective, not emulated)
* Execute build code `after_success` (emulated) or `after_failure` (not emulated)
* Optional code `before_deploy` (only if deployment is effective, not emulated)
* Optional code `deploy` (not emulated)
* Optional code `after_deploy` (only if deployment is effective, not emulated)
* Execute code `after_script` (not emulated)
* Wep from local .travis.conf (not in travis-ci.org)

Read furthermore info read `travis-ci phase <https://docs.travis-ci.com/user/job-lifecycle/>`__
""",
      classifiers=[
<<<<<<< HEAD
          'Development Status :: 3 - Alpha',
=======
          'Development Status :: 4 - Beta',
>>>>>>> stash
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
      keywords='linux travis development',
<<<<<<< HEAD
=======
      url='https://zeroincombenze-tools.readthedocs.io',
>>>>>>> stash
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
<<<<<<< HEAD
          '': ['scripts/setup.conf', './travis.sh', './travisrc',
               './travis.man']
=======
          '': ['scripts/setup.info',
               './travis', './travisrc', './travis.man']
>>>>>>> stash
      },
      entry_points={
          'console_scripts': [
              'travis_emulator-info = travis_emulator.scripts.main:main',
<<<<<<< HEAD
              'travis = travis_emulator.scripts.travis:main',
=======
              # 'travis = travis_emulator.scripts.travis:main',
>>>>>>> stash
          ],
      },
      zip_safe=False)
