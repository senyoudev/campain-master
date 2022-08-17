// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

contract CampaignFactory {
    Campaign[] public deployedCampaigns;

    function createCampaign(uint256 minimum) public {
        Campaign newCampaign = new Campaign(minimum, msg.sender);
        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns (Campaign[] memory) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        string description;
        uint value;
        address payable recipient;
        bool complete; 
        mapping(address => bool) approvals;
        uint approvalCount;
    }

    uint256 numRequests;
    mapping(uint256 => Request) public requests;

    address public manager;
    uint public minimunContribution;
    mapping(address=>bool) public approvers;
    uint public approversCount;

    modifier restricted {
        require(msg.sender == manager,"Only the campaign manager can do this action");
        _;
    }

    constructor(uint minimum,address creator) public {
        manager = creator;
        minimunContribution = minimum;
    }

    function contribute() public payable {
        require(msg.value > minimunContribution);
        approvers[msg.sender] = true;
        approversCount++;
    }


    function createRequest(string memory description,uint  value,address payable recipient) public restricted {
        require(approvers[msg.sender]);
        Request storage r = requests[numRequests++];
        r.description = description;
        r.value = value;
        r.recipient = recipient;
        r.complete = false;

    }

    function approveRequest(uint index) public {
        Request storage request = requests[index];
        require(approvers[msg.sender],"Only the ones who contribute can approve a request");
        require(!request.approvals[msg.sender],"You have already voted to approve this request");

        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }

    function finalizeRequest(uint index) public { 
        Request storage request = requests[index];
        require( request.approvalCount > (approversCount / 2),
            "This request needs more approvals before it can be finalized");
        require(!request.complete,"This request has already been finalized");
        request.recipient.transfer(request.value);
        request.complete = true;
    }   
}