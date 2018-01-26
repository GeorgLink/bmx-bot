#!/usr/bin/env python3
# -*- coding: UTF-8 -*-

# (C) Copyright 2018
# Georg Link <linkgeorg@gmail.com>
#
# SPDX-License-Identifier: MPL-2.0

#####
# bot.mozfest2017.py
#
# At MozFest 2017, Andy Leak developed a bot that would randomly create
# buy offers on Bugmark.
# This bot is a recreation in Python and using the Bugmark CLI.
#
#####

from subprocess import check_output
import json
import random
import time
import datetime

# possible maturation dates: array of dates determine by ???
maturations = []
# possible users: manually enter array of users and passwords
users = ["test"+str(x)+"@bugmark.net" for x in range(1,  5)]
password = "bugmark"
# possible issues: arrary of  first four issues from Bugmark
issues = []
# access the bugmark exchange and get list of issues
issue_list = check_output(["bmx", "issue", "list"])
# extract first four issues from the list of issues
json_il = json.loads(issue_list.decode("utf-8"))
for p in json_il:
    issues.append(p['uuid'])
    if(len(issues) > 3):
        break
# pssible volumes: array of increments of 5 from 30 to 50
volumes = [x*5 for x in range(6, 11)]
# possible prices: array of increments of .05 from .05 to 0.95
prices = [x*.05 for x in range(1, 20)]
# possible sides: array with values 'fixed' and 'unfixed'
sides = ['fixed', 'unfixed']


# function buy
# random combination of user, issue, volume, price, and side
def buy():
    secure_random = random.SystemRandom()
    new_offer = check_output(["bmx", "offer", "buy",
                              "--side="+secure_random.choice(sides),
                              "--volume="+secure_random.choice(volumes),
                              "--price="+secure_random.choice(prices),
                              "--issue="+secure_random.choice(issues),
                              "--maturation=" +
                              secure_random.choice(maturations)])
    new_contract = check_output(["bmx", "offer", "cross", new_offer["uuid"]])


# output
ttime = datetime.time()
print("----- BUGMARK OFFER BOT -------------------------------------------")
print("START "+ttime.strftime("%H:%M:%S")+" | C-c to exit")
print("Process Name: bot_buy")
print("Loading Environment...")

for x in range(1, 100):
    ttime = datetime.time()
    buy()
    open_offers = check_output(["bmx", "offer", "list"])
    contracts = check_output(["bmx", "contract", "list"])
    escrows = check_output(["bmx", "escrow", "list"])
    print("Cycle: "+str(x)+" | " +
          ttime.strftime("%H:%M:%S")+" | " +
          len(open_offers)+" open offers | " +
          len(contracts)+" contracts | " +
          len(escrows)+" escrows")
    if x < 50:
        time.sleep(5)
    else:
        time.sleep(20)
ttime = datetime.time()
print("Terminating after 99 cycles "+ttime.strftime("%H:%M:%S"))
