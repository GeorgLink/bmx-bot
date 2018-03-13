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


class Contract():

    def __init__(self, issue, maturation_date):
        self.issue = issue  # issue this contract is on
        self.maturation_date = maturation_date  # end of contract
        self.escrow = 0  # money paid into contract

    def set_issue(self, issue):
        self.issue = issue

    def set_maturation_date(self, maturation_date):
        self.maturation_date = maturation_date


class Position():

    def __init__(self, user, contract, units, unit_price, un_fixed):
        self.user = user  # owner of the contract position
        self.contract = contract  # ownership in this contract
        self.units = units  # number of units this position has
        self.unit_price = unit_price  # price paid per unit
        self.un_fixed = un_fixed  # type of position: fixed or unfixed


class Offer():

    def __init__(self, contract, units, unit_price, expiration_date,
                 un_fixed, buy_sell, position=None):
        self.contract = contract  # contract this offer is for
        self.units = units  # number of units to by of a contract
        self.unit_price = unit_price  # unit price
        self.expiration_date = expiration_date  # day the offer expires
        self.un_fixed = un_fixed  # or unfixed
        self.sell_buy = buy_sell  # offer is for selling or buying
        self.position = position  # references position that is being sold
        self.status = 'open'  # status of offer


class Market():
    offers = []
    open_offers = []
    contracts = []
    active_contracts = []
    positions = []
    active_positions = []

    def make_unfixed_offer(self, issue, maturation_date, units, unit_price,
                           user, expiration_date):
        # user can offer to buy an unfixed position in a contract

        # check that user has enough money
        if user.get_money() < units * unit_price:
            return {0, "insufficient funds"}
        # TODO:
        new_contract = Contract(issue, maturation_date)
        # create a new offer
        new_offer = Offer(new_contract, units, unit_price, expiration_date,
                          "unfixed", "buy")
        # attatch new offer to offers list
        self.offers.append(new_offer)
        # attatch new offer to open offers list
        self.open_offers.append(new_offer)
        self.cross_offers()
        return new_offer

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

    def list_offers(self):
        # print("bmx list offers:")
        for o in self.offers:
            print(o)
        return None
