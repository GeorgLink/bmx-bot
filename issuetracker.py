#!/usr/bin/env python3
# -*- coding: UTF-8 -*-

# (C) Copyright 2018
# Georg Link <linkgeorg@gmail.com>
#
# SPDX-License-Identifier: MPL-2.0

#####
# issue-tracker.py
#
# Simulate the features of an issue tracker
#####


class IssueTracker():

    # max_issue_id = 0
    issues = []

    # def __init__(self):
    #    # create new issue tracker object
    #    # self.max_issue_id = 0

    def open_issue(self):
        # currently, we don't have any special information on an issue
        # step 1, create issue
        self.issues.append(Issue(len(self.issues)+1))
        # step 1, increase issue id counter
        # self.max_issue_id = len(issues)
        return self.get_issue(len(self.issues))

    def get_issue(self, id):
        # get a specific issue
        # step 1: find index
        index = next((i for i, item in enumerate(self.issues)
                     if item.id == id), -1)
        if index == -1:
            return None
        return self.issues[index]

    def list_open_issues(self):
        # filter list of issues to only open issues
        return [el for el in self.issues if el.status == 'open']

    def list_closed_issues(self):
        # filter list of issues to only open issues
        return [el for el in self.issues if el.status == 'closed']

    def list_issues(self):
        # filter list of issues to only open issues
        return self.issues

    def write_to_file(self, filepath):
        # write all issues and their status to a file
        # that will be read by the bugmark oracle
        return 0


class Issue():

    def __init__(self, id=0, difficulty=1):
        # creates a new open issue
        self.status = 'open'
        self.flag = 'fixed'  # enable closed and unfixed
        self.complete = 0.00
        self.difficulty = difficulty
        self.id = id

    def get_status(self):
        # get status of issue
        return self.status

    def get_id(self):
        # get id of issue
        return self.id

    def get_level_complete(self):
        # get percentage this is complete
        return self.complete

    def close(self):
        # close issue
        self.status = 'closed'
        return self

    def reopen(self):
        # reopen issue
        self.status = 'open'

    def get_worked_on(self, work):
        # add work done to this issue
        # some issues may need more work than others
        self.complete += work / self.difficulty
        return self
