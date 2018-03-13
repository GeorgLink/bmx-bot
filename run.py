#!/usr/bin/env python3
# -*- coding: UTF-8 -*-

# (C) Copyright 2018
# Georg Link <linkgeorg@gmail.com>
#
# SPDX-License-Identifier: MPL-2.0

#####
# run.py
#
# Run the simmulation for bugmark futures market
#####

import issuetracker
import market
import person
import sys

print("start simulation")

# Step 1: define the simulation parameters
print("environment settings", end="")
sys.stdout.flush()
number_of_workers = 10  # how many people we start with
number_of_issues = 10  # how many issues we create every day
funder_starting_funds = 1000000  # how much money the funder starts with
worker_starting_funds = 0  # how much money a worker starts with
simulation_time = 3  # how many days to simulate
print(" [DONE]")

# Step 2: load issue tracker
print("load issue tracker", end="")
sys.stdout.flush()
tracker = issuetracker.IssueTracker()
print(" [DONE]")

# Step 2: load market
print("load futures trading market", end="")
sys.stdout.flush()
bmx = market.Market()
print(" [DONE]")


# Step 3: instantiate people (agents)
print("instantiate agents", end="")
sys.stdout.flush()
funder = person.PTrivialCase1Funder("funder", tracker, bmx)
funder.set_money(funder_starting_funds)
list_of_workers = []  # array to store all workers
for w in range(number_of_workers):
    new_worker = person.PTrivialCase1Worker("worker"+str(w), tracker, bmx)
    new_worker.set_money(worker_starting_funds)
    list_of_workers.append(new_worker)
    # print(list_of_workers)
print(" [DONE]")


# Step 4: run simulation
print("run simulation:")
# for d = 0 to number of days
for d in range(simulation_time):
    print("day "+str(d)+":", end="")
    # for i = 0 to number of issues
    for i in range(number_of_issues):
        print(" "+str(i), end="")
        new_issue = tracker.open_issue()  # create a new issue
        # print(new_issue.get_id())
        funder.trade_bugmark(new_issue.get_id(), d+1)
        # bmx.list_offers()
        # print(new_issue.get_status())
        worker = list_of_workers[i]
        worker.trade_bugmark(new_issue.get_id(), d+1)
        worker.community_work(new_issue.get_id())
        # print(new_issue.get_status())
    print(" next day")  # go to next day
print("simulation complete !")
