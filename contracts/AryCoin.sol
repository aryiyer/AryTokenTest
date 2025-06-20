// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract AryCoin {
    // state variables

    uint public currentTokenId = 1;
    address owner;

    //mapping from address owner to pair of tokenList and size of list
    mapping(address => tokensOwned) owning;

    //All the data of each token is stored in these below mappings
    //tokenId to struct
    mapping(uint => tokenData) tokens;

    //address of account to check => address of operator to check = whether the operator has approval for the account.
    mapping(address => mapping(address => bool)) operatorApproval;

    //struct that holds token data
    struct tokenData {
        uint256 tokenId;
        string info;
        address[] ownerHistory;
        bool valid;
        address minter;
        address approved;
    }

    struct tokensOwned {
        uint[] tokenList;
        uint size;
    }

    // constructor:
    constructor(){
        //owner of the contract is the one who deploys it
        owner = msg.sender;
    }

    /*
    // FUNCTIONS
    */

    // Ary coin functionality:

    //mintCoin - takes in all the necessary fields as the form of a strict
    function mintCoin(string memory strInfo, address to) public {     
        //ensure that the minter is the owner of the contract
        require(msg.sender == owner, "Coin must be minted from the owner's account");

        tokenData memory dataStruct;
        dataStruct.tokenId = currentTokenId;
        dataStruct.info = strInfo;
        dataStruct.valid = true;
        dataStruct.minter = owner;
        
        //adding dataStruct to storage
        tokens[currentTokenId] = dataStruct;
        //adding tokenId and owner info to the struct in storage
        tokens[currentTokenId].ownerHistory.push(to);
        owning[to].tokenList.push(currentTokenId);
        owning[to].size ++;

        currentTokenId++;
    }

    //settleCoin

    // ERC721 Necessary:
    
    //balanceOf(owner)
    function balanceOf(address user) public view returns (uint) {
        //add check to ensure that user exists
        return(owning[user].size);
    }
    
    //ownerOf(tokenId) - returns the address of the owner of the given tokenId
    function ownerOf(uint tokenId) public view returns (address)  {
        //tokenId must exist
        require(contains(tokenId), "tokenId does not exist.");

        unchecked {
        uint recentOwnerIndex = tokens[tokenId].ownerHistory.length-1;
        require(recentOwnerIndex >= 0, "Error: Token does not have any owners!");
        return(
            tokens[tokenId].ownerHistory[recentOwnerIndex]
        );
        }
        
    }

    //safeTransferFrom(from, to, tokenId)

    //transferFrom(from, to, tokenId) - transfers a token from an address to an address
    function transferFrom(address from, address to, uint tokenId) public {
        //tokenId must exist
        require(contains(tokenId), "tokenId does not exist.");
        //from and to cannot be the zero address
        require((from != address(0) && to != address(0)), "Source and destination address cannot be zero.");

        //check that from address owns the token
        require(ownerOf(tokenId) == from, "From address does not own tokenId.");

        //check that caller of transfer is from
        require(msg.sender == from || msg.sender == getApproved(tokenId), "Caller must be from or must be approved");
            //delete token from old owner's mapping
            for(uint i = 0; i < owning[from].tokenList.length; i++){
                if (owning[from].tokenList[i] == tokenId){
                    console.log("deleted token");
                    delete owning[from].tokenList[i];
                    owning[from].size --;
                }
            }
            //add new owner to token's owner history
            tokens[tokenId].ownerHistory.push(to);

            //add token to new owner's owned tokens
            owning[to].tokenList.push(tokenId);
            owning[to].size ++;

            //removing token approvals
            tokens[tokenId].approved = address(0);

            //add event

    }

    //approve(to, tokenId) - allow an external address to transfer token. approval is cleared after the token is transferred.
    function approve(address to, uint tokenId) public {
        //tokenId must exist
        require(contains(tokenId), "tokenId does not exist.");

        //only token owner can call this function
        require(msg.sender == ownerOf(tokenId), "Only the token owner can approve an account.");
        bool isApproved = (getApproved(tokenId) != address(0));
        require(isApproved == false, "Token already has an other approved account. Max 1.");
        tokens[tokenId].approved = to;
    }

    //returns the address of the account approved for the token, or zero if none exists
    function getApproved(uint tokenId) public view returns (address) {
        //tokenId must exist
        require(contains(tokenId), "tokenId does not exist.");

        return(tokens[tokenId].approved);

        //sets reverts if token does not exist - what is reverts???
    }

    //setApprovalForAll(operator, _approved) - gives or takes operator approval to transfer ANY token that caller owns
    //only acts on the tokens belonging to msg.sender
    function setApprovalForAll(address operator, bool _approved) public {
        //operator cannot be 0 address
        require (operator != address(0), "Operator address cannot be the zero address!");

        //get all tokens from the caller
        uint[] memory ownedBySender = getOwning(msg.sender);
        for (uint i = 0; i < ownedBySender.length; i++){
            uint tokenId = ownedBySender[i];
            if (tokenId != 0){ //if not a defaut value (deleted)
                if (_approved){
                    bool isApproved = (getApproved(tokenId) != address(0));
                    require(isApproved == false, "Token already has an other approved account. Max 1.");
                    approve(operator, tokenId);
                } else {
                    tokens[tokenId].approved = address(0);
                }
            }
        }
    }
    //isApprovedForAll(owner, operator)


    //safeTransferFrom(from, to, tokenId, data)


    /*
    // EVENTS
    */

    // ERC721 Necessary:

    //Transfer(from, to, tokenId)

    //Approval(owner, approved, tokenId)

    //ApprovalForAll(owner, operator, approved)


    /*
    // Utility/Debugging methods
    */

   //returns the address of the message sender
   function getSenderAddress() public view returns (address) {
        return (msg.sender);
   }

    //Given a user account, returns an array with all of the tokens that they own.
   function getOwning(address acc) public view returns (uint[] memory) {
        return(owning[acc].tokenList);
   }

   function contains(uint tokenId) public view returns (bool) {
        return(tokens[tokenId].tokenId != 0); //if the key isn't mapped yet, the default value of tokenId is 0.
   }

}