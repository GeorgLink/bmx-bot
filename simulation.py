#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# imports
from subprocess import call, check_output
import json

# base line: python executes
# print "Hello World"

# access the bugmark exchange
#call(["ls", "-l"])
#raw_input("Press Enter to continue...")
#call(["bmx", "issue", "list"])
#call(["/home/deploy/.gem/ruby/2.5.0/bin/bmx", "issue", "list"])
issue_list = check_output(["bmx","issue","list"])
#print type(issue_list)
# issue_list = issue_list.replace(":uuid", "uuid")
print issue_list
# raw_input("ENTER")
#json_il = json.loads(issue_list)
#json.dumps(json_il, separators=(',',':'))
