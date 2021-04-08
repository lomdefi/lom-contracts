pragma solidity ^0.5.16;


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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ILOMNFT
{
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );


  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;
    
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;
    
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;
    
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

  function totalSupply() external view returns (uint256);
  function tokenByIndex(uint256 _index) external view returns (uint256);
}


contract LOMBurnAllocate {

    uint256 public constant RATIOBASE = 100;
    uint256 public constant DESTROY_RATIO = 10;
    uint256 public constant HOLDER_RATIO = 30;
    uint256 public constant POOL_RATIO = 60;

    IERC20 public LOM;
    ILOMNFT public LOMNFT;

    

    uint256 public totalAllocated;
    uint256 public totalClaimed;
    uint256 public totalDestroyed;
    uint256 public totalPooled;


    mapping(address=>mapping(uint256=>uint256)) public weaponBalance;//ply -> weapon->number
    
    mapping(address => uint256) public canClaim;


    address payable public owner;
    address public poolAddress=address(0x03083F7f460BCCe7D08aB2ed7138f4C96C5Ba38E);

    constructor(address _LOM,address _LOMNFT) public {
        owner = msg.sender;
        LOM = IERC20(_LOM);
        LOMNFT = ILOMNFT(_LOMNFT);
    }

    function receive() external payable{
        owner.transfer(msg.value);
    }


    function balanceOfBurning() public view returns(uint256){
        return LOM.balanceOf(address(this));
    }


    function getUnAllocated() public view returns(uint256){
        uint256 currentBalance  = LOM.balanceOf(address(this));
        uint256 currentCanAllocated = SafeMath.sub(SafeMath.add(currentBalance,totalClaimed),totalAllocated);
        
        return currentCanAllocated;
    }

    function allocate() public {
        require(msg.sender==owner,"Only Owner Can Initiate Burning Fee Allocation");
        //Get Allocator Balance
        uint256 tokenCount = LOMNFT.totalSupply();

        uint256 currentBalance  = LOM.balanceOf(address(this));

        //Because there is history allocation and maybe somebody did'nt harvest,
        //total destoyed: total token moved to 0x0;
        //total pooled: total token moved to nft reward pool ;
        //total claimed: total token claimed by holder;
        //total Allocated: total allocated balance
        //We current can only alloc the token which gained singce last allocation.
        //THAT is (current balance)+(total destroyed)+(totalPooled)+(totalClaimed)-(totalAllocated);

        uint256 currentAlloc = SafeMath.sub(SafeMath.add(currentBalance,totalClaimed),totalAllocated);

        uint256 per = SafeMath.div(currentAlloc,RATIOBASE);

        require(per>0,"LOM::too little burning fee to allocate");

        uint256 thisDestroyed = SafeMath.mul(per,DESTROY_RATIO);
        uint256 thisPooled = SafeMath.mul(per,POOL_RATIO);
        uint256 currentCanAllocated = per*HOLDER_RATIO;

        //Destroy
        LOM.transfer(address(0x0),thisDestroyed);
        totalDestroyed = SafeMath.add(totalDestroyed,thisDestroyed);

        //Move to nft pool
        LOM.transfer(poolAddress,thisPooled);
        totalPooled = SafeMath.add(totalPooled,thisPooled);

        //Allocate for Holder and wait for claiming by holder
        uint256 piece = SafeMath.div(currentCanAllocated, tokenCount);
        require(piece>0,"LOM::too little burning fee to allocate");

        uint256 thisAllocated =0;
        uint i = 0;

        for(i=0;i<tokenCount;i++){
            uint256 tokenId= LOMNFT.tokenByIndex(i);
            address nftOwner = LOMNFT.ownerOf(tokenId);
            if(nftOwner==address(0x0))continue;

            uint256 amount=canClaim[nftOwner];
            canClaim[nftOwner]=SafeMath.add(amount,piece);
            thisAllocated=SafeMath.add(thisAllocated,piece);
        }

        totalAllocated =SafeMath.add(totalAllocated,currentAlloc);
    }


    function getAvailable() public view returns(uint256) {
        return canClaim[msg.sender];
    }

    function claim() public  {
        require(canClaim[msg.sender]>0,"LOM::nothing can be claimed");
        LOM.transfer(msg.sender,canClaim[msg.sender]);
        totalClaimed=SafeMath.add(totalClaimed,canClaim[msg.sender]);
        canClaim[msg.sender]=0;
    }

    
}
