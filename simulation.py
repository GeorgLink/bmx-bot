#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# imports
from subprocess import call

# base line: python executes
print "Hello World"

# access the bugmark exchange
call(["bmx", "issue list"])
