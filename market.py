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
    positions = []

    def __init__(self, issue, maturation_date):
        self.issue = issue  # issue this contract is on
        self.maturation_date = maturation_date  # end of contract
        self.escrow = 0  # money paid into contract

    def set_issue(self, issue):
        self.issue = issue

    def set_maturation_date(self, maturation_date):
        self.maturation_date = maturation_date

    def add_position(self, position):
        self.positions.append(position)


class Position():

    def __init__(self, user, contract, units, unit_price, un_fixed):
        self.user = user  # owner of the contract position
        self.contract = contract  # ownership in this contract
        self.units = units  # number of units this position has
        self.unit_price = unit_price  # price paid per unit
        self.un_fixed = un_fixed  # type of position: fixed or unfixed
        self.contract.add_position(self)

class Offer():

    def __init__(self, user, contract, units, unit_price, expiration_date,
                 un_fixed, buy_sell, position=None):
        self.user = user #user who made this offer
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
        if user.get_money() < (units * unit_price):
            return {0, "insufficient funds"}
        # TODO:

        contract = self.find_or_create_Contract(issue, maturation_date)
        # create a new offer
        new_offer = Offer(user, contract, units, unit_price, expiration_date,
                          "unfixed", "buy")
        # attatch new offer to offers list
        self.offers.append(new_offer)
        # attatch new offer to open offers list
        self.open_offers.append(new_offer)
        self.cross_offers()
        return new_offer

    def make_fixed_offer(self, issue, maturation_date, units, unit_price, user,
                         expiration_date):
        if user.get_money() < units * unit_price:
            return {0, "insufficient funds"}
        # user can offer to buy a fixed position in a contract

        # TODO:
        contract = self.find_or_create_Contract(issue, maturation_date)
        # create a new offer
        new_offer = Offer(user, contract, units, unit_price, expiration_date,
                          "fixed", "buy")
        # attatch new offer to offers list
        self.offers.append(new_offer)
        # attatch new offer to open offers list
        self.open_offers.append(new_offer)
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
        # find matching offers

        for i in range(len(self.open_offers)):
            for j in range(i):
                if self.open_offers[i].un_fixed != self.open_offers[j].un_fixed:

                    # create positions
                    new_position1 = Position(self.open_offers[i].user,
                     self.open_offers[i].contract, self.open_offers[i].units,
                      self.open_offers[i].unit_price, self.open_offers[i].un_fixed)
                    new_position2 = Position(self.open_offers[j].user,
                     self.open_offers[j].contract, self.open_offers[j].units,
                      self.open_offers[j].unit_price, self.open_offers[j].un_fixed)

                      #add the positions in lists
                    self.positions.append(new_position1)

                    self.positions.append(new_position2)

                    self.active_positions.append(new_position1)

                    self.active_positions.append(new_position2)

                    self.contracts.append(self.open_offers[i].contract)

                    self.active_contracts.append(self.open_offers[i-1].contract)
                    break

        # TODO: matching and crossing algorithm
        return None

    def find_or_create_Contract(self, issue, maturation_date):
        #find existing contract in contracts[]
        for i in range(len(self.contracts)):
            if ((self.contracts[i].issue == issue) and
            (self.contracts[i].maturation_date == maturation_date)):
                return self.contracts[i]
        #or create new contract
        contract = Contract(issue, maturation_date)
        self.contracts.append(contract)
        return contract

    def payout_contracts(self):
        # pay users for contracts that matured

        # TODO: payout algorithm
        return None

    def list_offers(self):
        # print("bmx list offers:")
        for o in self.offers:
            print(o)
        return None
