// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract RegisterOwner {
    AggregatorV3Interface priceFeed;
    address contractOwnerAddress;

    constructor() {
        contractOwnerAddress = msg.sender;
    }

    /*
    @title A sports booking client side contract
    @author Vishwanath
    @notice This contract stores all the arena owner's details and the event's available at that arena under allVenues
    @dev The contract can be improved by separating the functions to another contract and using interface for it.
    */
    struct Venue {
        address ownerAdress; // Adress of the arena owner
        string sportName; // Sport 's name ex: cricket
        string sportLocationAddress; // Arena location ex: NYC soccer ground
        uint256 sportBookingFeesUsd; // Fees to book the arena ex: 10 USD
        string[] slots; // Slots that can be booked ex: "9am - 10am", "10am-12pm"
    }

    struct Event {
        uint256 feesPaidUsd;
        address ownerAddress;
        string sportName;
        string slot;
    }

    mapping(uint256 => Event[]) public allEvents; // timestamp => Event[]
    mapping(uint256 => mapping(uint256 => address)) public eventToUser; // timestamp => (event_index => userAddress)
    address[] public allUsers;
    mapping(uint256 => uint256[]) public bookedIndex; // timestamp => index of events booked on this timestamp[]

    mapping(address => Venue[]) public allVenues;
    address[] public allOwnerAddress;

    modifier onlyOwner() {
        require(
            msg.sender == contractOwnerAddress,
            "You are not contract owner"
        );
        _;
    }

    function setPriceFeedAddress(
        address _chainlinkPriceFeedAddress
    ) external onlyOwner {
        priceFeed = AggregatorV3Interface(_chainlinkPriceFeedAddress);
    }

    function getEthPriceUsd() public returns (uint256) {
        (, int256 latestPrice, , , ) = priceFeed.latestRoundData();
        uint256 price = uint256(latestPrice) * 10000000000;
        return price;
    }

    event PriceDetails(uint256 _valueSent, uint256 _valueToBeSent);

    function compareFeesAndReceivedValue(
        uint256 _ethValueSent,
        uint256 _feesInUsd
    ) internal returns (bool) {
        (, int256 latestPrice, , , ) = priceFeed.latestRoundData();
        uint256 price = uint256(latestPrice);
        uint256 _feesInWei = ((_feesInUsd * 10 ** 18) * 10 ** 18) / price;
        emit PriceDetails(_ethValueSent, _feesInWei);

        if (_ethValueSent > _feesInWei) {
            return true;
        }
        return false;
    }

    function bookEvent(
        address _user,
        uint256 _eventIndex,
        uint256 _date,
        bool addUser
    ) external payable {
        for (
            uint256 _bookIndex = 0;
            _bookIndex < bookedIndex[_date].length;
            _bookIndex++
        ) {
            if (_eventIndex == bookedIndex[_date][_bookIndex]) {
                revert("Event is booked");
            }
        }
        Event memory existEvent = allEvents[_date][_eventIndex];
        require(
            compareFeesAndReceivedValue(msg.value, existEvent.feesPaidUsd),
            "Value sent is less than the fees"
        );

        eventToUser[_date][_eventIndex] = _user;
        bookedIndex[_date].push(_eventIndex);
        if (addUser) {
            allUsers.push(_user);
        }
    }

    function createAllEvent(Venue[] memory _venue, uint256 _date) internal {
        for (uint256 venueIndex = 0; venueIndex < _venue.length; venueIndex++) {
            Venue memory venue = _venue[venueIndex];
            for (
                uint256 slotIndex = 0;
                slotIndex < venue.slots.length;
                slotIndex++
            ) {
                Event memory newEvent = Event(
                    venue.sportBookingFeesUsd,
                    venue.ownerAdress,
                    venue.sportName,
                    venue.slots[slotIndex]
                );
                allEvents[_date].push(newEvent);
            }
        }
    }

    function createEventList(uint256 _dateTimestamp) public {
        require(allEvents[_dateTimestamp].length == 0, "Already created");
        for (
            uint256 addressIndex = 0;
            addressIndex < allOwnerAddress.length;
            addressIndex++
        ) {
            Venue[] memory venueList = allVenues[allOwnerAddress[addressIndex]];
            createAllEvent(venueList, _dateTimestamp);
        }
    }

    modifier ownerExist() {
        Venue[] memory venueList = allVenues[msg.sender];
        require(venueList.length <= 0, "venues Does'nt exist");
        _;
    }

    function registerVenue(
        string memory _sportName,
        string memory _sportLocationAddress,
        uint256 _sportBookingFeesUsd,
        string[] memory _slots
    ) public {
        // Adding new venue with same _sport name will replace the existing one

        Venue memory newVenue = Venue(
            msg.sender,
            _sportName,
            _sportLocationAddress,
            _sportBookingFeesUsd,
            _slots
        );

        allVenues[msg.sender].push(newVenue);
        allOwnerAddress.push(msg.sender);
    }

    function getSlots(
        address _ownerAddress,
        uint256 venueIndex
    ) public view returns (string[] memory) {
        return allVenues[_ownerAddress][venueIndex].slots;
    }

    function deleteAllVenues() public ownerExist {
        delete allVenues[msg.sender];
    }

    function venueExist(string memory _sportName) public view returns (bool) {
        Venue[] memory _venueList = allVenues[msg.sender];
        for (
            uint256 venueIndex = 0;
            venueIndex < _venueList.length;
            venueIndex++
        ) {
            if (
                keccak256(abi.encode(_sportName)) ==
                keccak256(abi.encode(_venueList[venueIndex].sportName))
            ) {
                return true;
            }
        }
        return false;
    }

    function getAllOwnerAddress() public view returns (address[] memory) {
        return allOwnerAddress;
    }

    function getOwnerVenues(
        address _ownerAddress
    ) public view returns (Venue[] memory) {
        return allVenues[_ownerAddress];
    }
}
