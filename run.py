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
import person

# Step 1: define the simulation parameters
number_of_people = 10  # how many people we start with
number_of_issues = 10  # how many issues we start with
rate_of_new_issues = 3  # create x new issues every day
starting_funds = 1000  # how much money every person starts with
file_for_issue_tracker_oracle = "./issues.csv"  # where to export the issue ...
# ... tracker information to
simulation_time = 100  # how many days to simulate
# ...

# Step 2: load issue tracker
tracker = issuetracker.IssueTracker()
# for i = 1 to number of issues
tracker.open_issue()  # (x10)


# Step 3: instantiate people (agents)
# list of people = new person (x10)
new_person = person.ProfitMaximizer()

# Step 4: run simulation
# First: randomly let persons trade and do work until they are all exhausted
# Second: match offers on bugmark
# Third: advance day by 1 in bugmark and simulation
# end after simulation_time is expired
# return to First.
