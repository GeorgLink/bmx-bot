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


class Person():
    # The most generic person, defining the interface
    # person characteristics:
    productivity = 1  # how much work this person can do in a day
    non_active_days = 0  # how many days before coming back to the community
    skills = None  # skills this person has
    money = 0

    def __init__(self, name, issue_tracker=None, bmx=None):
        # bugmark related variables
        self.name = name  # name of person
        self.tracker = issue_tracker  # reference to the issue tracker
        self.bmx = bmx  # reference to the futures trading market place

    def community_work(self):
        # decides to do work in community
        # e.g. close bugs
        return None

    def trade_bugmark(self):
        # decide what to trade on bugmark
        # e.g. make buy offer
        return None

    def get_money(self):
        return self.money

    def set_money(self, money):
        self.money = money
        return self.money


class PTrivialCase1Worker(Person):
    # Worker for Trivial Case 1
    # Persona:
    #  - finds an UNFIXED offer and matches it
    def __init__(self, name, issue_tracker=None, bmx=None):
        super(self.__class__, self).__init__(name, issue_tracker, bmx)
        # self.productivity = 10
        # self.non_active_days = 0
        # self.skills = 'all'
        # self.bugmark_email = email  # user account email on bugmark
        # self.bugmark_password = pwd  # password on bugmark
        # self.bugmark_uuid = bugmark_user  # USER_UUID on bugmark
        # self.tracker = issue_tracker  # reference to the issue tracker

        # check_output(["bmx", "user", "create",
        #               "--usermail="+self.bugmark_email,
        #               "--password="+str(self.bugmark_password),
        #               "--balance=0"])

    def community_work(self, issue):
        self.tracker.get_issue(issue).close()
        # issue.close()
        # only do work, if has fixed position on an issue
        # eg:
        # get issues id bugmark id
        # self.tracker.issue.do_work(productivity)
        # if issue.complete >= 1.00 then issue.close()
        return None

    def trade_bugmark(self, issue, maturation, volume="20", price="1.00",
                      side="fixed"):
        # Trivial Case 1: find an open UNFIXED offer and buy it
        # offer_obj = json.loads(check_output(["bmx", "offer", "list",
        #                                      "--with-type=Offer::Buy::Unfixed",
        #                                      "--limit=1"])
        #                        .decode("utf-8"))
        # if len(offer_obj) > 0:
        # get offer ID to 'show' details and get match parameters
        # offer_uuid = offer_obj[0]['uuid']
        # offer_obj2 = check_output(["bmx", "offer", "show", offer_uuid])
        # offer = json.loads(offer_obj2.decode("utf-8"))

        # circumvent finding the issue by just providing it.
        # this works because there is no variability
        # offer_rtn = check_output(["bmx", "offer", "create_buy",
        #                           "--side=fixed",
        #                           "--volume=100",
        #                           "--price=0",
        #                           "--issue="+str(issue),
        #                           "--maturation=" + str(maturation),
        #                           "--userspec="+self.bugmark_email +
        #                           ":"+self.bugmark_password])
        # offer = json.loads(offer_rtn.decode("utf-8"))
        # # do the work and close the issue
        # # get repo uuid to be able to update issue
        # issue_rtn = check_output(["bmx", "issue", "show", str(issue)])
        # issue_obj = json.loads(issue_rtn.decode("utf-8"))
        # check_output(["bmx", "issue", "sync",
        #               str(issue),
        #               "--status=closed",
        #               "--repo_uuid="+issue_obj["stm_repo_uuid"]])
        # check_output(["bmx", "contract", "list"])
        #    return 1
        return None


class PTrivialCase1Funder(Person):
    # Funder for Trivial Case 1
    # Persona:
    #  - funds an issue with an UNFIXED offer
    def __init__(self, name, issue_tracker=None, bmx=None):
        super(self.__class__, self).__init__(name, issue_tracker, bmx)
        # self.productivity = 10
        # self.non_active_days = 0
        # self.skills = 'all'
        # self.tracker = issue_tracker  # reference to the issue tracker

        # check_output(["bmx", "user", "create",
        #               "--usermail="+self.bugmark_email,
        #               "--password="+str(self.bugmark_password),
        #               "--balance=100000000"])

    def community_work(self):
        # not implemented in Trivial Case 1
        return None

    def trade_bugmark(self, issue, maturation, volume=20, price=1.00,
                      side="unfixed"):
        # Trivial Case 1: create an UNFIXED offer
        # offer = check_output(["bmx", "offer", "create_buy",
        #                       "--side=unfixed",
        #                       "--volume=100",
        #                       "--price=1",
        #                       "--issue="+issue,
        #                       "--maturation=" + maturation,
        #                       "--userspec="+self.bugmark_email +
        #                       ":"+self.bugmark_password])
        self.bmx.make_unfixed_offer(issue, maturation, volume, price, self,
                                    maturation)
        return None


class PProfitMaxizer(Person):
    # Example instantiation of a person
    # Persona:
    #  - tries to make a living with open source and bugmark
    #  - cares most about profit
    def __init__(self, email=None, pwd=None, bugmark_user=None,
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
