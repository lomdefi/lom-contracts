/**
 *Submitted for verification at hecoinfo.com on 2021-03-05
*/

pragma solidity ^0.5.16;

interface NFT{
    function transferFrom(address _from,address _to,uint256 _tokenId)external;
    function approve(address _approved,uint256 _tokenId) external;
    function safeTransferFrom(address _from,address _to,uint256 _tokenId) external;
    enum starType {st_nil,st1,st2,st3,st4,st5,st6}
    enum teamType {t_nil,t1,t2}
    function mint(address _to,uint256 _tokenId,uint256 _power,teamType _ttype,starType _stype,string calldata _uri) external ;
    function viewTokenID() view external returns(uint256);
    function mintWeapon(address _to,uint256 _wType,uint256 _amount,uint8 _team) external;
}

interface IERC20{
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

library SafeMath {
 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

   
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

  
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract WeaponSale{
    
    using SafeMath for *;
    
    address public owner;
    
    mapping(address => bool) public manager;
    
    IERC20 LOM = IERC20(0x7404DB858261673d47bDdc2970a23d2163720a5F);
    NFT nft = NFT(0x5500fd0bd849ef306b3BE6a037AE0B24d3505916);
    
    mapping(uint256=>uint256) public weaponAmount;
    mapping(uint256 => uint8) public weaponTeam;
    mapping(uint256=>uint256) public alreadSaleAmount;
    mapping(uint256 => uint256) public weaponPrice;
    mapping(uint256 => uint256) public weaponToPower;
    uint256[] public weaponType;
    mapping(uint256=>bool) public isCreateWType ;
    
    event BuyWeapon(address _ply,uint256 _wType,uint256 _wAmount);
    
    constructor() public {
        owner =msg.sender ;
    }
    
    
    function createWeaponAmount(uint256 _wType,uint256 _amont,uint256 _price,uint8 _team,uint256 _power) public onlyManager{
        //require(isCreateWType[_wType],"alreadyCreate");
        require(_team == 1 || _team ==2,"only 2 team");
        weaponAmount[_wType] = weaponAmount[_wType].add(_amont);
        if(weaponTeam[_wType] == 0){
            weaponTeam[_wType] = _team;
            weaponToPower[_wType] = _power;
        }
        weaponPrice[_wType] = _price;
        isCreateWType[_wType] = true;
        weaponType.push(_wType);
        
    }
    
    function changeWeaponPrice(uint256 _wType,uint256 _price) public onlyManager{
        weaponPrice[_wType] = _price;
    }
    
    function buyWeapon(uint256 _wType,uint256 _amont) public{
        require(isCreateWType[_wType],"alreadyCreate");
        uint256 needToken = _amont.mul(weaponPrice[_wType]); 
        uint256 token1 = needToken.mul(20).div(100);
        uint256 token2 = needToken.mul(10).div(100);
        LOM.transferFrom(msg.sender,address(1),needToken.sub(token1).sub(token2));
        LOM.transferFrom(msg.sender,address(0xeEC19F725e3f1FEf3E76a30f5544E9cB2D1E0a15),token1);
        LOM.transferFrom(msg.sender,address(0x33F88199De1264D906533e628865db50f3D79678),token2);
        
        nft.mintWeapon(msg.sender,_wType,_amont,weaponTeam[_wType]);
        emit BuyWeapon(msg.sender,_wType,_amont);
    }
    
    function getPowerByWeapon(uint256 _wType) view public returns(uint256){
        return weaponToPower[_wType];
    }
    
    function getWeaponLen() public view returns(uint256){
        return weaponType.length;
    }
    function addManager(address _mAddr) public onlyOwner{
        manager[_mAddr] = true;
    }
    modifier onlyManager(){
        require(manager[msg.sender]," onlyManager");
        _;
    }
    modifier onlyOwner(){
        require(msg.sender == owner,"only owner");
        _;
    }
}
