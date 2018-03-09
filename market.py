#!/usr/bin/env python3
# -*- coding: UTF-8 -*-

# (C) Copyright 2018
# Georg Link <linkgeorg@gmail.com>
#
# SPDX-License-Identifier: MPL-2.0

#####
# market.py
#
# Simulated Bugmark market
#####


class market:
    offers = []
    open_offers = []
    contracts = []
    active_contracts = []
    positions = []
    active_positions = []

    def make_unfixed_offer(self, issue, maturation_date, units, unit_price,
                           user, expiration_date):
        # user can offer to buy an unfixed position in a contract

        # TODO:
        # create a new offer
        # attatch new offer to offers list
        # attatch new offer to open offers list
        self.cross_offers()
        return None

    def make_fixed_offer(self, issue, maturation_date, units, unit_price, user,
                         expiration_date):
        # user can offer to buy a fixed position in a contract

        # TODO:
        # create a new offer
        # attatch new offer to offers list
        # attatch new offer to open offers list
        self.cross_offers()
        return None

    def make_sell_offer(self, issue, position, units, unit_price, user):
        # allow a user to sell (partial) positions

        # TODO:
        # create a new offer
        # attatch new offer to offers list
        # attatch new offer to open offers list
        self.cross_offers()
        return None

    def cross_offers(self):
        # find matching offers and create positions

        # TODO: matching and crossing algorithm
        return None

    def payout_contracts(self):
        # pay users for contracts that matured

        # TODO: payout algorithm
        return None
