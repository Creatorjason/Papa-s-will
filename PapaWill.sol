//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract PapaWill{
    // mom signature,lawyer signature,son signature,daughter signature;
    /*[0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB,
    0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
    0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
    0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2]
    ,["mom","lawyer","son","daughter"]*/

    address[] public authorities;
    //uint internal propIndex;
    event PropertyAdded(string _name, string _to, uint _worth, string _location);
    event Inherited(string _to, uint _propIndex, address _authority);
    mapping(address => bool ) public isAuthorized; 

    mapping(uint => mapping(address => string)) public indexedAuth;
    mapping(string => uint) public relationIndex;
    mapping(string => address) public relationAddr;
    mapping(string => Property) public inheritedProperty;

    struct Property{
        string name;
        string location;
        uint worth;
        string to;
        //bool canSell;
        uint consentVote;
    }

    Property[] public properties;

    mapping(uint => mapping(address => bool)) public approval;

    uint public constant MINIMUM = 2;

    constructor(address[] memory _authorities, string[] memory _relation){
        require(_authorities.length != 0, "Signatories required");
        require(_relation.length != 0, "Relations required");
        for (uint i; i < _authorities.length ; i++ ){
            require(_authorities[i] != address(0), "Invalid address");
            address authority = _authorities[i];
            authorities.push(authority);
            isAuthorized[authority] = true;
            indexedAuth[i][authority] = _relation[i];
            relationIndex[_relation[i]]= i;
            relationAddr[_relation[i]] = authorities[i];
            }
    }

    modifier onlyAllowedRelation(string memory _name){
         require(msg.sender == relationAddr[_name], "Sorry, you don't have access to this property");
          _;

      }
    function papaProperties(
        string calldata _name, 
        string calldata _location, 
        uint _worth,
        //bool _canSell,
        string calldata _to
        ) 
        external 
    {   
        properties.push(Property({
            name:_name,
            location:_location,
            worth:_worth,
            to:_to,
            //canSell:_canSell,
            consentVote:0}));
            emit PropertyAdded(_name,_to,_worth,_location);

            

    }
    function addConsentVote(string calldata _name,  uint _propIndex) external onlyAllowedRelation(_name) {
        Property storage property = properties[_propIndex];
        if (msg.sender != relationAddr[property.to]){
            approval[_propIndex][msg.sender] = true;
            property.consentVote += 1;
            }else{
                revert("Only persons that this property isn't assigned to can call");
                }
    }
    

    function inherit(uint _propIndex, string calldata _name) external onlyAllowedRelation(_name) returns(bool confirm){
        Property storage property = properties[_propIndex]; 
        require(relationAddr[property.to] == msg.sender, "This property is not yours to inherit");
        require(property.consentVote >= MINIMUM, "You are not allowed to inherit this property, kindly get more consentVote");
        inheritedProperty[indexedAuth[relationIndex[_name]][msg.sender]] = properties[_propIndex];
        delete properties[_propIndex];
        emit Inherited(_name, _propIndex, msg.sender);
        confirm = true;

    }
   
}
