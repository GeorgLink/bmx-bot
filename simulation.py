#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# imports
from subprocess import call, check_output
import json

# base line: python executes
# print "Hello World"

# access the bugmark exchange and get list of issues
issue_list = check_output(["bmx","issue","list"])
# print the list of issues
json_il = json.loads(issue_list)
for p in json_il:
    print p['uuid']
