#!/usr/bin/env python3
# -*- coding: UTF-8 -*-

# imports
from subprocess import check_output
import json

# access the bugmark exchange and get list of issues
issue_list = check_output(["bmx", "issue", "list"])
# print the list of issues
json_il = json.loads(issue_list.decode("utf-8"))
for p in json_il:
    print(p['uuid'])
