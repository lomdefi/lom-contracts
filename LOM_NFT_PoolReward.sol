/**
 * LOM NFT Pool Reward Contract
*/

pragma solidity ^0.5.16;


library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
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


contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint amount) external;


    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        //According to https://eips.ethereum.org/EIPS/eip-1052
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }


    function callOptionalReturn(IERC20 token, bytes memory data) private {

        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
interface NFT{
    function transferFrom(address _from,address _to,uint256 _tokenId)external;
    function approve(address _approved,uint256 _tokenId) external;
    function safeTransferFrom(address _from,address _to,uint256 _tokenId) external;
    enum starType {st_nil,st1,st2,st3,st4,st5,st6}
    enum teamType {t_nil,t1,t2}
    function mint(address _to,uint256 _tokenId,uint256 _power,teamType _ttype,starType _stype,string calldata _uri) external ;
    function viewTokenID() view external returns(uint256);
    function setTokenTypeAttributes(uint256 _tokenId,uint8 _typeAttributes,uint256 _tvalue) external;
    function transferList(address _to,uint256[] calldata _tokenIdList) external;
    function ownerOf(uint256 _tokenID) external returns (address _owner);
    function starAttributes(uint256 _tokenID) external view returns(uint8,uint8,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256);
}

interface IWeaponToPower{
    function getPowerByWeapon(uint256 _wType) view external returns(uint256) ;
}
contract IRewardDistributionRecipient is Ownable {
    address rewardDistribution;

    function notifyRewardAmount(uint256 reward) external;

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}


contract TokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    
    NFT public y = NFT(0x5500fd0bd849ef306b3BE6a037AE0B24d3505916);
    IWeaponToPower public  iwtp = IWeaponToPower(0xDE107294D43143bc46026a113Ba1225929582141);
    
    uint256 maxWithAmount = 10;
    uint256 private _totalSupply;
    uint256 public _totalNFT;
    mapping(address => uint256) private _balances;
    mapping(address => uint256[]) public _nftBalances;
    mapping(uint8 => uint256) public _nftTypeTotalBalance; // type=>number;
    mapping(address => mapping(uint256 => bool)) public isInStating;
    

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function balanceOfNFT(address account) public view returns(uint256){
        return _nftBalances[account].length;
    }
    function balanceOfByIdex(address account,uint256 index) public view returns(uint256){
        return _nftBalances[account][index];
    }

    function _stake(uint256[] memory amount) internal {
        uint256 len = amount.length;
        uint256 totalAmount;
        uint256 powerAmount = 0;
        uint256 tokenID;
        uint8 stype;//ABCDEF
        
        uint256 wType;
        uint256 ytem;
        
        for(uint256 i=0;i<len;i++){
            
            tokenID = amount[i];
            require(!isInStating[msg.sender][tokenID],"already exit");
            require(y.ownerOf(tokenID) == msg.sender,"not ownerOf");
            (,stype,powerAmount,wType,,,,,,,ytem) = y.starAttributes(tokenID);
            totalAmount = totalAmount.add(powerAmount);
            if(wType !=0){
                totalAmount = totalAmount.add(iwtp.getPowerByWeapon(wType));
            }
            isInStating[msg.sender][tokenID] = true;
            _nftTypeTotalBalance[stype] = _nftTypeTotalBalance[stype].add(1);
            _nftBalances[msg.sender].push(tokenID);
        }
        _totalNFT = _totalNFT.add(len);
        _totalSupply = _totalSupply.add(totalAmount);
        _balances[msg.sender] = _balances[msg.sender].add(totalAmount);
        y.transferList(address(this),amount);
  
    }

    function _withdraw() internal {
        uint256 len = _nftBalances[msg.sender].length;
        if(len ==0){
            return;
        }
        //uint256[] memory nftList = new uint256[](len);
        uint256 totalAmount;
        uint256 powerAmount = 0;
        uint256 tokenID;
        uint8 stype;//ABCDEF
        
        uint256 wType;
        uint256 ytem;
        uint256[] memory nftTokenIDlist;
        uint256 j = 0;
        
        uint256 end = 0;
        if(len > maxWithAmount){
            end = len-maxWithAmount;
            nftTokenIDlist = new uint256[](maxWithAmount);
        }else{
            nftTokenIDlist = new uint256[](len);
        }
        for(uint256 i = len-1;i >= end; i--){
            tokenID = _nftBalances[msg.sender][i];
            
            (,stype,powerAmount,wType,,,,,,,ytem) = y.starAttributes(tokenID);
            totalAmount = totalAmount.add(powerAmount);
            if(wType !=0){
                totalAmount = totalAmount.add(iwtp.getPowerByWeapon(wType));
            }
            _nftTypeTotalBalance[stype] = _nftTypeTotalBalance[stype].sub(1);
            nftTokenIDlist[j] = tokenID;
            j++;
            
            //delete _nftBalances[msg.sender][i];
            _nftBalances[msg.sender].pop();
            isInStating[msg.sender][tokenID] = false;
            _totalNFT = _totalNFT.sub(1);
            //_nftBalances[msg.sender].length--;
            if(i==end){
                break;
            }
            
        }
        
        _totalSupply = _totalSupply.sub(totalAmount);
        _balances[msg.sender] = _balances[msg.sender].sub(totalAmount);
        y.transferList(msg.sender,nftTokenIDlist);
    }
}

contract LOM_NFT_PoolReward is TokenWrapper, IRewardDistributionRecipient {
    IERC20 public xCoin = IERC20(0x7404DB858261673d47bDdc2970a23d2163720a5F);
    uint256 public constant DURATION = 180 days;

    uint256 public initreward = 30000000*1e18;
    uint256 public starttime ;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    
    bool public endCalcReward;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
    
    constructor(uint256 _startTime) public{
        starttime = _startTime;
        periodFinish = starttime.add(DURATION);
    }
    

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256[] memory tokenIDList) public updateReward(msg.sender)  checkStart{ 
        require(tokenIDList.length > 0, "Cannot stake 0");
        super._stake(tokenIDList);
        emit Staked(msg.sender, tokenIDList.length);
    }

    function withdraw() public updateReward(msg.sender)  checkStart{
        
        super._withdraw();
        emit Withdrawn(msg.sender,balanceOfNFT(msg.sender));
    }

    function exit() external {
        withdraw();
        getReward();
    }

    function getReward() public updateReward(msg.sender)  checkStart{
        if(endCalcReward){
            return;
        }
        uint256 reward = earned(msg.sender);
        if (reward > 0 && block.timestamp <= periodFinish) {
            rewards[msg.sender] = 0;
            require(xCoin.balanceOf(address(this)) >0,"getReward: total hot is zero");
            if(xCoin.balanceOf(address(this)) <= reward){
                reward = xCoin.balanceOf(address(this));
            }
            xCoin.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }
    
    function setRewardStop() public onlyRewardDistribution{
        endCalcReward = true;
    }
    function withTRC20(address tokenAddr, address recipient,uint256 amount) public onlyRewardDistribution{
        require(tokenAddr != address(0),"DPAddr: tokenAddr is zero");
        require(recipient != address(0),"DPAddr: recipient is zero");
        IERC20  tkCoin = IERC20(tokenAddr);
        if(tkCoin.balanceOf(address(this)) >= amount){
            tkCoin.transfer(recipient,amount);
        }else{
            tkCoin.transfer(recipient,tkCoin.balanceOf(address(this))) ;
        }
    }

    function EmergencyWithNFT(address _to,uint256 _tokenID) public onlyRewardDistribution{
        y.transferFrom(address(this),_to,_tokenID);
    }
    modifier checkStart(){
        require(block.timestamp > starttime,"not start");
        _;
    }
    

    function notifyRewardAmount(uint256 reward)
        external
        onlyRewardDistribution
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }
}
