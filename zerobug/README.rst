zerobug
=======

This library can run unit test of target package software.
Supported languages are *python* (through z0testlib.py)
and *bash* (through z0testrc)

*zerobug* supports test automation, aggregation of tests into collections
and independence of the tests from the reporting framework.
The *zerobug* module provides all code that make it easy to support testing
both for python programs both for bash scripts.
*zerobug* differs from pytest standard library because show execution test with
a message like "n/tot message" where *n* is current unit test and *tot* is the
total unit test to execute, that is a sort of advancing test progress.
