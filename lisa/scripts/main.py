# -*- coding: utf-8 -*-
"""
<<<<<<< HEAD
lis* stands for Linux Install Simplifier App

lisa is an interactive tool to install, update, remove, query and manage software for building a complete LAMP server.
LAMP means Linux Apache Mysql PHP; in recent times, Python and Postgresql were added.

lisa is just a front-end for yum and apt-get commands, it is not a real package installer.
It require yum on CentOS and Red Hat family distros, and apt-get on Ubuntu and debian family distros.
It is very useful to manage all the packages needed to build a complete LAMP server and to check the real server status.
For every main package, may be managed some dependent package; i.e. openssh-server manages openssh-client too.

You can easily write portable script to install packages on every Linux distribution.
=======
Python supplemental features
----------------------------

python_plus adds various features to python 2 and python 3 programs.
It is designed to be used as integration of pypi future to help to port your code from Python 2 to Python 3 and still have it run on Python 2.


vem: virtual environment manager
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This package is released with an nice command:
**vem** that is an interactive tool with some nice features to manage standard virtual environment and it is osx/darwin compatible.
>>>>>>> stash
"""
import os
import sys
import pkg_resources
import shutil


<<<<<<< HEAD
__version__ = '1.0.2.99'
=======
__version__ = '1.0.3.6'
>>>>>>> stash


def fake_setup(**kwargs):
    globals()['setup_args'] = kwargs


def read_setup():
<<<<<<< HEAD
    setup_file = os.path.abspath(
        os.path.join(os.path.dirname(__file__), 'setup.conf'))
    if not os.path.isfile(setup_file):
        setup_file = os.path.abspath(
            os.path.join(os.path.dirname(__file__), '..', 'setup.py'))
    if not os.path.isfile(setup_file):
        setup_file = os.path.abspath(
            os.path.join(os.path.dirname(__file__), '..', '..', 'setup.py'))
    setup_args = {}
    if os.path.isfile(setup_file):
        with open(setup_file, 'r') as fd:
=======
    setup_info = os.path.abspath(
        os.path.join(os.path.dirname(__file__), 'setup.info'))
    setup_file = os.path.abspath(
        os.path.join(os.path.dirname(__file__), '..', '..', 'setup.py'))
    # if os.path.isfile(setup_file):
    #     shutil.copy(setup_file, setup_info)
    if not os.path.isfile(setup_info):
        setup_info = os.path.abspath(
            os.path.join(os.path.dirname(__file__), '..', 'setup.py'))
    setup_args = {}
    if os.path.isfile(setup_info):
        with open(setup_info, 'r') as fd:
>>>>>>> stash
            content = fd.read().replace('setup(', 'fake_setup(')
            exec(content)
            setup_args = globals()['setup_args']
    else:
        print('Not internal configuration file found!')
    pkg = pkg_resources.get_distribution(__package__.split('.')[0])
<<<<<<< HEAD
    setup_args['setup'] = setup_file
=======
    setup_args['setup'] = setup_info
>>>>>>> stash
    setup_args['name'] = pkg.key
    setup_args['version'] = pkg.version
    return setup_args


def get_pypi_paths():
<<<<<<< HEAD
=======
    local_venv = '/devel/venv/'
>>>>>>> stash
    pkgpath = os.path.abspath(
        os.path.join(os.path.dirname(__file__), '..'))
    bin_path = lib_path = ''
    path = pkgpath
<<<<<<< HEAD
    while not bin_path and path != '/':
=======
    while not bin_path and path != '/' and path != os.environ['HOME']:
>>>>>>> stash
        path = os.path.dirname(path)
        if os.path.isdir(path) and os.path.basename(path) == 'lib':
            bin_path = os.path.join(os.path.dirname(path), 'bin')
            lib_path = path
<<<<<<< HEAD
    return pkgpath, bin_path, lib_path


def copy_pkg_data(setup_args):
    if setup_args.get('package_data'):
        pkgpath, bin_path, lib_path = get_pypi_paths()
        if bin_path:
            for pkg in setup_args['package_data'].keys():
                for fn in setup_args['package_data'][pkg]:
                    base = os.path.basename(fn)
                    if base == 'setup.conf':
                        continue
                    full_fn = os.path.abspath(os.path.join(pkgpath, fn))
                    tgt_fn = os.path.abspath(os.path.join(lib_path, base))
                    print('$ cp %s %s' % (full_fn, tgt_fn))
                    shutil.copy(full_fn, tgt_fn)
=======
    if not bin_path and local_venv:
        for path in sys.path:
            if local_venv in path:
                bin_path = os.path.join(
                    path[:path.find(local_venv)],
                    *[x for x in local_venv.split('/') if x][:-1])
                break
    return pkgpath, bin_path, lib_path


def copy_pkg_data(setup_args, verbose):
    if setup_args.get('package_data'):
        pkgpath, bin_path, lib_path = get_pypi_paths()
        if bin_path:
            # TODO> compatibility mode
            bin2_path = os.path.join(os.environ['HOME'], 'devel')
            if not os.path.isdir(bin2_path):
                bin2_path = ''
            for pkg in setup_args['package_data'].keys():
                for fn in setup_args['package_data'][pkg]:
                    base = os.path.basename(fn)
                    if base == 'setup.info':
                        continue
                    full_fn = os.path.abspath(os.path.join(pkgpath, fn))
                    if lib_path:
                        tgt_fn = os.path.join(lib_path, base)
                        if verbose:
                            print('$ cp %s %s' % (full_fn, tgt_fn))
                        shutil.copy(full_fn, tgt_fn)
                    # TODO> compatibility mode
                    tgt_fn = os.path.join(bin_path, base)
                    if os.path.isfile(tgt_fn):
                        os.unlink(tgt_fn)
                    if not os.path.exists(tgt_fn):
                        if verbose:
                            print('$ ln -s %s %s' % (full_fn, tgt_fn))
                        os.symlink(full_fn, tgt_fn)
                    if bin2_path:
                        tgt_fn = os.path.join(bin2_path, base)
                        if os.path.isfile(tgt_fn):
                            os.unlink(tgt_fn)
                        # if not os.path.exists(tgt_fn):
                        #     if verbose:
                        #         print('$ ln -s %s %s' % (full_fn, tgt_fn))
                        #     os.symlink(full_fn, tgt_fn)
>>>>>>> stash


def main(cli_args=None):
    if not cli_args:
        cli_args = sys.argv[1:]
<<<<<<< HEAD
    action = '-H' if not cli_args else cli_args[0]
=======
    action = '-H'
    verbose = False
    for arg in cli_args:
        if arg in ('-h', '-H', '--help', '-V', '--version', '--copy-pkg-data'):
            action = arg
        elif arg == '-v':
            verbose = True
>>>>>>> stash
    setup_args = read_setup()
    if action == '-h':
        print('%s [-h][-H][--help][-V][--version][-C][--copy-pkg-data]' %
              setup_args['name'])
    elif action in ('-V', '--version'):
        if setup_args['version'] == __version__:
            print(setup_args['version'])
        else:
            print('Version mismatch %s/%s' % (setup_args['version'],
                                              __version__))
    elif action in ('-H', '--help'):
        for text in __doc__.split('\n'):
            print(text)
    elif action in ('-C', '--copy-pkg-data'):
<<<<<<< HEAD
        copy_pkg_data(setup_args)
=======
        copy_pkg_data(setup_args, verbose)
>>>>>>> stash
    return 0
