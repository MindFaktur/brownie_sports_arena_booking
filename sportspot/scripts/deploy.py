from brownie import accounts, RegisterOwner, MockV3Aggregator
from web3 import Web3


def deploy_register_owner():
    _register_owner = RegisterOwner.deploy({"from": accounts[0]})
    priceFeed = MockV3Aggregator.deploy(
        18, Web3.toWei(2000, "ether"), {"from": accounts[0]}
    )
    create_venues(_register_owner, priceFeed)


def create_venues(register_owner, _priceFeed):
    register_owner.setPriceFeedAddress(_priceFeed.address)
    # print(register_owner.getEthPriceUsd())

    register_owner.registerVenue(
        "cricket",
        "RN Shetty Stadium",
        10,
        ["9am-10am", "10am-12pm"],
        {"from": accounts[1]},
    )
    register_owner.registerVenue(
        "football",
        "RN Shetty Stadium",
        10,
        ["9am-10am", "10am-12pm", "12pm-1pm"],
        {"from": accounts[1]},
    )
    register_owner.registerVenue(
        "foose", "RN Shetty Stadium", 10, ["9am-10am"], {"from": accounts[2]}
    )
    register_owner.registerVenue(
        "koko",
        "RN Shetty Stadium",
        10,
        ["9am-10am", "10am-12pm"],
        {"from": accounts[3]},
    )
    register_owner.createEventList(12345678, {"from": accounts[0]})
    book_event = register_owner.bookEvent(
        accounts[1].address,
        0,
        12345678,
        True,
        {"from": accounts[0], "value": 50000000000000001},
    )
    print(book_event.events)

    for i in register_owner.getOwnerVenues(accounts[1]):
        print(i[0])
    # print(register_owner.allUsers)
    # print(type(register_owner.getOwnerVenues(accounts[1])))


def main():
    deploy_register_owner()
    # create_venues()
