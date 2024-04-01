// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.20;

// import "./ERC20CollateralizedLending.sol";

// contract Ledger {
//     address public mainAddress;             // Contract Owner/Deployer address
//     address public feeRecipient;          // platform fee address

//     uint public totalLendingRequestsCount = 0;   // Total count of LendingRequest created
//     uint public borrowerFeeAmount = 0.01 ether; // platform fee for Borrower

//     mapping (address => mapping(uint => address)) userRequests; // mapping of LendingRequests per User
//     mapping (address => uint) allRequests;                      // lending request count per User
//     mapping (uint => address) allLendingRequests;               // All Lending Requests mapped by their Id

//     // events
//     event LendingRequestCreated(address indexed _from, address indexed _lendingRequest, uint _amount, uint _daysToLend);
//     event LendingRequestFunded(address indexed _from, address indexed _lendingRequest, uint _amount);
//     event LendingRequestPayback(address indexed _from, address indexed _lendingRequest, uint _amount);
//     event NewUserRegistered(address indexed _from);


//     constructor(address _feeRecipient) public{
//         mainAddress = msg.sender;
//         feeRecipient = _feeRecipient;
//     }


//     // function to create a a loan request
//     function createLendingRequest(uint _amount, uint _daysToLend) public payable {
//         require(_amount > 0, "Amount must be greater than 0");                   // check if the amount is greater than 0
//         require(_daysToLend > 0, "Days to lend must be greater than 0");         // check if the days to lend is greater than 0
//         require(msg.value >= _amount, "Insufficient balance");                   // check if the user has enough balance

//         // create a new lending request
//         ERC20CollateralizedLending lendingRequest = new ERC20CollateralizedLending(msg.sender, _amount, _daysToLend);

//         // add the lending request to the user's lending requests mapping
//         userRequests[msg.sender][allRequests[msg.sender]] = address(lendingRequest);
        
//         allRequests[msg.sender]++;         // increment the user's lending requests count
//         allLendingRequests[totalLendingRequestsCount] = address(lendingRequest);         // add the lending request to the all lending requests
//         totalLendingRequestsCount++;           // increment the total lending requests count

//         // emit the event
//         emit LendingRequestCreated(msg.sender, address(lendingRequest), _amount, _daysToLend);
//     }


//     // function to fund a lending request
//     function fundLendingRequest(address _lendingRequest) public payable {
//         ERC20CollateralizedLending lendingRequest = ERC20CollateralizedLending(_lendingRequest);
//         require(lendingRequest.getState() == ERC20CollateralizedLending.State.WaitingForFunding, "Lending request is not in the WaitingForFunding state");
//         require(msg.value >= lendingRequest.getAmount(), "Insufficient balance");

//         lendingRequest.fundLendingRequest{value: msg.value}();

//         emit LendingRequestFunded(msg.sender, _lendingRequest, msg.value);
//     }


//     // funtion to get the count of all lending requests
//     function getAllLendingRequestsCount() public view returns(uint) {
//         return totalLendingRequestsCount;
//     }

//     // function to get the count of all lending requests of a user
//     function getUserLendingRequestsCount(address _user) public view returns(uint) {
//         return allRequests[_user];
//     }
    
//     // function to get a specific lending request of a user
//     function getUserLendingRequest(address _user, uint _index) public view returns(address) {
//         return userRequests[_user][_index];
//     }


//     // function update fee
//     function updateFee(uint _newFee) public {
//         require(msg.sender == mainAddress, "Only the owner can update the fee");
//         borrowerFeeAmount = _newFee;
//     }

//     // function get fee
//     function getFee() public view returns(uint) {
//         return borrowerFeeAmount;
//     }

// }