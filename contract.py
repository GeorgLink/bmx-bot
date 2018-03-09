#!/usr/bin/env python3
# -*- coding: UTF-8 -*-

# (C) Copyright 2018
# Georg Link <linkgeorg@gmail.com>
#
# SPDX-License-Identifier: MPL-2.0

#####
# contract.py
#
# Contract class for simulating Bugmark Contract.
#####


class contract:

    def __int__(self, issue, maturation_date):
        self.issue = issue  # issue this contract is on
        self.maturation_date = maturation_date  # end of contract
        self.escrow = 0  # money paid into contract


class position:

    def __int__(self, user, contract, units, unit_price, un_fixed):
        self.user = user  # owner of the contract position
        self.contract = contract  # ownership in this contract
        self.units = units  # number of units this position has
        self.unit_price = unit_price  # price paid per unit
        self.un_fixed = un_fixed  # type of position: fixed or unfixed
