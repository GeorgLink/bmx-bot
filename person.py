#!/usr/bin/env python3
# -*- coding: UTF-8 -*-

# (C) Copyright 2018
# Georg Link <linkgeorg@gmail.com>
#
# SPDX-License-Identifier: MPL-2.0

#####
# person.py
#
# Developer, investor, maintainer
# Simulates behavior of different types of people in an open source project
# Agent in this Agent-Based-Modeling simulation
#####


class Person:
    # The most generic person, defining the interface
    # person characteristics:
    productivity = 1  # how much work this person can do in a day
    non_active_days = 0  # how many days before coming back to the community
    skills = None  # skills this person has

    def __int__(self, email=None, pwd=None, bugmark_user=None,
                issue_tracker=None):
        # bugmark related variables
        self.bugmark_email = email  # user account email on bugmark
        self.bugmark_password = pwd  # password on bugmark
        self.bugmark_uuid = bugmark_user  # USER_UUID on bugmark
        self.tracker = issue_tracker  # reference to the issue tracker

    def community_work(self):
        # decides to do work in community
        # e.g. close bugs
        return None

    def trade_bugmark(self):
        # decide what to trade on bugmark
        # e.g. make buy offer
        return None


class ProfitMaxizer(Person):
    # Example instantiation of a person
    # Persona:
    #  - tries to make a living with open source and bugmark
    #  - cares most about profit
    def __int__(self, email=None, pwd=None, bugmark_user=None,
                issue_tracker=None):
        super(self.__class__, self).__init__(email, pwd, bugmark_user,
                                             issue_tracker)
        self.productivity = 10
        self.non_active_days = 0
        self.skills = 'all'

    def community_work(self):
        # only do work, if has fixed position on an issue
        # eg:
        # get issues id bugmark id
        # self.tracker.issue.do_work(productivity)
        # if issue.complete >= 1.00 then issue.close()
        return None

    def trade_bugmark(self):
        # buy largest possible contract that person has skills to fix
        # look for bugmark offers and compare to workload required on issue
        # trade on the most favorable issue
        return None
