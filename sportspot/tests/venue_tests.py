from brownie import accounts, RegisterOwner
import pytest


def test_register_venue():
    _register_owner = RegisterOwner.deploy({"from": accounts[0]})
    venue_values = ["cricket", "RN Shetty Stadium", 10, ["9am-10am", "10am-12pm"]]
    _register_owner.registerVenue(
        venue_values[0],
        venue_values[1],
        venue_values[2],
        venue_values[3],
        {"from": accounts[1]},
    )
    venue_values_returned = _register_owner.getOwnerVenues(accounts[1])
    for each_venue in venue_values_returned:
        for venue_val_index in range(0, len(venue_values) - 1):
            print(each_venue[venue_val_index])
            print(venue_values[venue_val_index])
            assert each_venue[venue_val_index] == venue_values[venue_val_index]
