#!/usr/bin/env python3
# -*- coding: UTF-8 -*-

# (C) Copyright 2018
# Georg Link <linkgeorg@gmail.com>
#
# SPDX-License-Identifier: MPL-2.0

#####
# run.py
#
# Offer classes for simulating Bugmark offers.
#####


class offer:

    def __int__(self, contract, units, unit_price, expiration_date,
                un_fixed, buy_sell, position=None):
        self.contract = contract  # contract this offer is for
        self.units = units  # number of units to by of a contract
        self.unit_price = unit_price  # unit price
        self.expiration_date = expiration_date  # day the offer expires
        self.un_fixed = un_fixed  # or unfixed
        self.sell_buy = buy_sell  # offer is for selling or buying
        self.position = position  # references position that is being sold
        self.status = 'open'  # status of offer
