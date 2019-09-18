pragma solidity ^0.5.1;

/*


  $$$$$$$$\                  $$\             $$\     $$\                           $$$$$$$$\        $$\
  $$  _____|                 $$ |            $$ |    \__|                          \__$$  __|       $$ |
  $$ |  $$\    $$\  $$$$$$\  $$ |$$\   $$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\           $$ | $$$$$$\  $$ |  $$\  $$$$$$\  $$$$$$$\
  $$$$$\\$$\  $$  |$$  __$$\ $$ |$$ |  $$ |\_$$  _|  $$ |$$  __$$\ $$  __$$\          $$ |$$  __$$\ $$ | $$  |$$  __$$\ $$  __$$\
  $$  __|\$$\$$  / $$ /  $$ |$$ |$$ |  $$ |  $$ |    $$ |$$ /  $$ |$$ |  $$ |         $$ |$$ /  $$ |$$$$$$  / $$$$$$$$ |$$ |  $$ |
  $$ |    \$$$  /  $$ |  $$ |$$ |$$ |  $$ |  $$ |$$\ $$ |$$ |  $$ |$$ |  $$ |         $$ |$$ |  $$ |$$  _$$<  $$   ____|$$ |  $$ |
  $$$$$$$$\\$  /   \$$$$$$  |$$ |\$$$$$$  |  \$$$$  |$$ |\$$$$$$  |$$ |  $$ |         $$ |\$$$$$$  |$$ | \$$\ \$$$$$$$\ $$ |  $$ |
  \________|\_/     \______/ \__| \______/    \____/ \__| \______/ \__|  \__|         \__| \______/ \__|  \__| \_______|\__|  \__|


*/

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Interface {
  function transfer(address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BoardApprovable {
  using SafeMath for uint;
  using SafeMath for uint8;
  using SafeMath for uint32;
  using SafeMath for uint64;
  using SafeMath for uint128;
  using SafeMath for uint256;

  uint private _totalBoardMembers;
  uint private _boardMemberApprovedCount;
  uint private _minBoardMemberApprovalsForAction;
  uint private _mappingVersion;
  mapping(address => bool) private _boardMembers;
  mapping(uint => mapping(address => bool)) private _boardMemberVoted;

  event BoardMemberAdded(
    address indexed boardMemberAddress
  );

  event BoardMemberRemoved(
    address indexed boardMemberAddress
  );

  event BoardMemberApprovalAdded(
    address indexed boardMemberAddress,
    bool approved
  );

  event BoardApprovedAction(
    address indexed boardMemberAddress
  );

  modifier isBoardMember() {
    assert(_boardMembers[msg.sender]);
    _;
  }

  modifier isBoardApproved() {
    require(_boardMemberApprovedCount >= _minBoardMemberApprovalsForAction, "Board not approved");
    clearApprovals();
    emit BoardApprovedAction(msg.sender);
    _;
  }

  /**
  * @dev BoardApprovable constructor
  */
  constructor() internal {
    _totalBoardMembers = 5;
    _minBoardMemberApprovalsForAction = 3;

    // Load the default board members
    _boardMembers[0xE242CeF45608826216f7cA2d548c48562b50CdD0] = true; // pl
    _boardMembers[0x7B5973D4F41Af6bA50e2feD457d7c91D5A33349C] = true; // rp
    _boardMembers[0x54168F68D51a86DEdA3D5EA14A3E45bE74EFfbd4] = true; // jm
    _boardMembers[0x6102dB8E1d47D359CafF9ADa4f0b0a8378d35109] = true; // dj
    _boardMembers[0xaBE5EE06B246e23d69ffb44F6d5996686b69ce3b] = true; // rg
  }

  function setMinBoardMemberApprovalsForAction(uint count) external isBoardMember isBoardApproved {
    require(count > 0, "Count must be greater than zero");
    require(count <= _totalBoardMembers, "Count cannot exceed total board member count");

    _minBoardMemberApprovalsForAction = count;
  }

  function addBoardMember(address boardMemberAddress, uint newMinBoardMemberApprovalsForAction) external isBoardMember isBoardApproved {
    require(newMinBoardMemberApprovalsForAction > 0, "Count must be greater than zero");
    require(newMinBoardMemberApprovalsForAction <= _totalBoardMembers.add(1), "Count cannot exceed total board member count once added");

    if(!_boardMembers[boardMemberAddress]) {
      _boardMembers[boardMemberAddress] = true;
      _totalBoardMembers = _totalBoardMembers.add(1);
      _minBoardMemberApprovalsForAction = newMinBoardMemberApprovalsForAction;
      emit BoardMemberAdded(boardMemberAddress);
    }
  }

  function removeBoardMember(address boardMemberAddress, uint newMinBoardMemberApprovalsForAction) external isBoardMember isBoardApproved {
    require(_totalBoardMembers > 1, "Cannot remove the last board member");
    require(newMinBoardMemberApprovalsForAction > 0, "Count must be greater than zero");
    require(newMinBoardMemberApprovalsForAction <= _totalBoardMembers.sub(1), "Count cannot exceed total board member count once removed");

    if(_boardMembers[boardMemberAddress]) {
      _boardMembers[boardMemberAddress] = false;
      _totalBoardMembers = _totalBoardMembers.sub(1);
      _minBoardMemberApprovalsForAction = newMinBoardMemberApprovalsForAction;
      emit BoardMemberRemoved(boardMemberAddress);
    }
  }

  function addBoardMemberApproval(bool approved) external isBoardMember {
    if(approved) {
      if(!_boardMemberVoted[_mappingVersion][msg.sender]) {
        _boardMemberVoted[_mappingVersion][msg.sender] = approved;
        _boardMemberApprovedCount = _boardMemberApprovedCount.add(1);
        emit BoardMemberApprovalAdded(msg.sender, approved);
      }
    } else {
    // Remove previous approval if it exists
    if(_boardMemberVoted[_mappingVersion][msg.sender]) {
        _boardMemberVoted[_mappingVersion][msg.sender] = approved;
        _boardMemberApprovedCount = _boardMemberApprovedCount.sub(1);
        emit BoardMemberApprovalAdded(msg.sender, approved);
      }
    }
  }

  function isSenderBoardMember() external view returns(bool) {
    return _boardMembers[msg.sender];
  }

  function isSenderBoardMemberApproved() external view returns(bool) {
    return _boardMemberVoted[_mappingVersion][msg.sender];
  }

  function approvalCount() external view returns(uint) {
    return _mappingVersion;
  }

  /**
  * @dev Gets the current board status
  * @return Properties related to the board status.
  */
  function getBoardStatus() external view returns (bool, uint, uint, uint) {
    return (_boardMemberApprovedCount >= _minBoardMemberApprovalsForAction, _boardMemberApprovedCount,
        _totalBoardMembers, _minBoardMemberApprovalsForAction);
  }

  function clearApprovals() public isBoardMember {
    _mappingVersion = _mappingVersion.add(1);
    _boardMemberApprovedCount = 0;
  }
}

contract Freezable is BoardApprovable {
  mapping (address => bool) _frozen;

  event AddressFrozen(
    address Address
  );

  event AddressUnfrozen(
    address Address
  );

  /**
  * @dev Allows the owner to freeze an address
  * @param account is the address used by the function to freeze
  */
  function freezeAddress(address account) external isBoardMember isBoardApproved {
    require(_frozen[account] == false, "Freezable: Account already frozen, unable to freeze.");
    _frozen[account] = true;
    emit AddressFrozen(account);
  }

  /**
  * @dev Allows the owner to unfreeze an address
  * @param account is the address used by the function to unfreeze
  */
  function unfreezeAddress(address account) external isBoardMember isBoardApproved {
    require(_frozen[account] == true, "Freezable: Account not frozen, unable to unfreeze.");
    _frozen[account] = false;
    emit AddressUnfrozen(account);
  }

  /**
  * @return if the address is frozen
  */
  function isFrozen(address account) public view returns(bool) {
    return _frozen[account];
  }

  /**
  * @return if the address is frozen
  */
  function requireUnfrozen(address account) internal view returns(bool) {
    require(!isFrozen(account), "Address involved in transaction is frozen.");
  }
}

/**
* @dev Contract module which allows children to implement an emergency stop
* mechanism that can be triggered by an authorized account.
*
* This module is used through inheritance. It will make available the
* modifiers `whenNotPaused` and `whenPaused`, which can be applied to
* the functions of your contract. Note that they will not be pausable by
* simply including this module, only once the modifiers are put in place.
*/
contract Pausable is BoardApprovable {
  /**
  * @dev Emitted when the pause is triggered by a pauser (`account`).
  */
  event Paused(address account);

  /**
  * @dev Emitted when the pause is lifted by a pauser (`account`).
  */
  event Unpaused(address account);

  bool private _paused;

  /**
  * @dev Initializes the contract in unpaused state. Assigns the Pauser role
  * to the deployer.
  */
  constructor () internal {
    _paused = false;
  }

  /**
  * @dev Returns true if the contract is paused, and false otherwise.
  */
  function paused() public view returns (bool) {
    return _paused;
  }

  /**
  * @dev Modifier to make a function callable only when the contract is not paused.
  */
  modifier whenNotPaused() {
    require(!_paused, "Pausable: paused");
    _;
  }

  /**
  * @dev Modifier to make a function callable only when the contract is paused.
  */
  modifier whenPaused() {
    require(_paused, "Pausable: not paused");
    _;
  }

  /**
  * @dev Called by a pauser to pause, triggers stopped state.
  */
  function pause() external isBoardMember isBoardApproved whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

  /**
  * @dev Called by a pauser to unpause, returns to normal state.
  */
  function unpause() external isBoardMember isBoardApproved whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

contract EvolutionToken is ERC20Interface, BoardApprovable, Pausable, Freezable {
  using SafeMath for uint;
  using SafeMath for uint8;
  using SafeMath for uint32;
  using SafeMath for uint64;
  using SafeMath for uint128;
  using SafeMath for uint256;

  struct Pool {
    bool sellAllowed;
    uint256 floor;
    uint256 ceiling;
    uint256 total;
    uint256 totalDividends;
    uint256 buyReferrerPercent;
    uint256 buyHolderPercent;
    uint256 sellHolderPercent;
    uint256 buyMintOwnerPercent;
    uint256 sellHoldOwnerPercent;
    uint256 totalDividendsClaimed;
  }

  string private _name;
  string private _symbol;
  uint8 private _decimals;
  uint private _supply;
  uint256 private _totalTokensBought;
  uint256 private _totalTokensSold;
  uint256 private _currentPrice;
  uint256 private _increment;
  uint256 private _lowerCap;
  uint256 private _minimumEthSellAmount;
  uint256 private _percentBase;
  address payable _owner;
  mapping(address => uint256) private _balances;
  mapping (address => uint256) private _lastDividends;

  Pool private _pool;

  event onTokenPurchase(
    address indexed customerAddress,
    uint256 incomingEthereum,
    uint256 tokensMinted,
    address indexed referredBy
  );

  event onTokenSell(
    address indexed customerAddress,
    uint256 tokensBurned,
    uint256 ethereumEarned
  );

  event onReinvestment(
    address indexed customerAddress,
    uint256 ethereumReinvested,
    uint256 tokens
  );

  event onClaimDividend(
    address indexed customerAddress,
    uint256 ethereumWithdrawn
  );

  event onDividendIncrease(
    uint256 totalDividendIncrease
  );

  event onSellEnabledChange(
    bool enabled
  );

  event onPriceChange(
    uint256 price
  );

  event onMint(
    uint256 amount,
    uint256 supply
  );

  event onBurn(
    uint256 amount,
    uint256 supply
  );

  constructor() public {
    _owner = 0xD1D9Dad7FC00A933678eEf64b3CaC3a3AF0a5AB4; // cs03
    _name = "Evolution Token";
    _symbol = "EvolV";
    _decimals = 0;
    _supply = 600000000;
    _currentPrice = .000053 ether;
    _increment = .000000001 ether;
    _lowerCap = .0000053 ether;
    _minimumEthSellAmount = .01 ether;

    // _percentBase.div(uint256) will return a whole integer percentage value you can divide large numbers with
    _percentBase = 100;

    // Give founder all supply
    _balances[_owner] = _supply;

    // Set the pool initial values
    _pool.floor = 1 ether;
    _pool.ceiling = 10 ether;
    _pool.buyReferrerPercent = 5;
    _pool.buyHolderPercent = 10;
    _pool.sellHolderPercent = 10;
    _pool.buyMintOwnerPercent = 10;
    _pool.sellHoldOwnerPercent = 10;
  }

  /**
  * @dev Fallback function to handle ethereum that was sent straight to the contract
  */
  function() external payable {
    buy(address(0));
  }

  /**
  * @dev Gets the name of the token.
  * @return An string representing the name of the token.
  */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
  * @dev Gets the symbol of the token.
  * @return An string representing the symbol of the token.
  */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Gets the number of decimals of the token.
  * @return An uint8 representing the number of decimals of the token.
  */
  function decimals() external view returns (uint8) {
    return _decimals;
  }

  /**
  * @dev Gets the price increment for the token
  * @return An uint256 representing the price increment for the token.
  */
  function increment() external view returns (uint256) {
    return _increment;
  }

  /**
  * @dev Gets the lower cap price of the token
  * @return An uint256 representing the lower cap price of the token.
  */
  function lowerCap() external view returns (uint256) {
    return _lowerCap;
  }

  /**
  * @dev Gets the total accumilated dividends.
  * @return An uint256 representing number of current dividends.
  */
  function getTotalDividends() external view returns (uint256) {
    return _pool.totalDividends;
  }

  /**
  * @dev Gets the current price for 1 token.
  * @return An uint256 representing the current price for 1 token.
  */
  function currentPrice() external view returns (uint256) {
    return _currentPrice;
  }

  /**
  * @dev Gets the minimum ETH sell amount.
  * @return An uint256 representing the minimum number of ETH for a sell.
  */
  function minimumEthSellAmount() external view returns (uint256) {
    return _minimumEthSellAmount;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) external view returns (uint balance) {
    return _balances[owner];
  }

  /**
  * @dev Gets the total supply.
  * @return An uint representing the total supply.
  */
  function totalSupply() external view returns (uint) {
    return _supply;
  }

  /**
  * @dev Gets the total tokens sold.
  * @return An uint representing the total tokens sold.
  */
  function totalTokensSold() external view returns (uint) {
    return _totalTokensSold;
  }

  /**
  * @dev Gets the total tokens bought.
  * @return An uint representing the total tokens bought.
  */
  function totalTokensBought() external view returns (uint) {
    return _totalTokensBought;
  }

  /**
  * @dev ERC20 function to transfer tokens from the sender to another address.
  * @param recipient address The address which you want to transfer to.
  * @param amount uint256 the amount of tokens to be transferred.
  * @return Bool success
  */
  function transfer(address recipient, uint256 amount) external whenNotPaused  returns (bool) {
    return transferCore(msg.sender, recipient, amount);
  }

  /**
  * @dev Sets the name of the token. OnlyOwner
  * @param newName The new token name.
  */
  function setName(string calldata newName) external isBoardMember isBoardApproved {
    _name = newName;
  }

  /**
  * @dev Sets the symbol of the token. OnlyOwner
  * @param newSymbol The new symbol for the token.
  */
  function setSymbol(string calldata newSymbol) external isBoardMember isBoardApproved {
    _symbol = newSymbol;
  }

  /**
  * @dev Sets the increment for buys and sells. OnlyOwner
  * @param newIncrement The new increment for buys and sells.
  */
  function setIncrement(uint256 newIncrement) external isBoardMember isBoardApproved {
    _increment = newIncrement;
  }

  /**
  * @dev Sets the lower cap of the token value. OnlyOwner
  * @param newLowerCap The new lower cap of the token value.
  */
  function setLowerCap(uint256 newLowerCap) external isBoardMember isBoardApproved {
    _lowerCap = newLowerCap;
  }

  /**
  * @dev Updates the minimum ETH sell amount. OnlyOwner
  * @param newMinimumEthSellAmount The new minimum amount of ETH for a sell.
  */
  function setMinimumEthSellAmount(uint256 newMinimumEthSellAmount) external isBoardMember isBoardApproved {
    _minimumEthSellAmount = newMinimumEthSellAmount;
  }

  /**
  * @dev Fund Total dividends.  "Rain on holders propertionally."
  */
  function fundTotalDividends() external whenNotPaused payable {
    increaseTotalDividends(msg.value);
    emit onDividendIncrease(msg.value);
  }

  /**
  * @dev reinvest
  */
  function reinvest(address payable referrer) external returns(uint256 tokenAmount) {
    uint256 tokensFromReinvestment = 0;

    uint256 ethValue = dividendBalanceOf(msg.sender);
    require(ethValue > 0, "No dividends to reinvest.");

    _lastDividends[msg.sender] = _pool.totalDividends;

    tokensFromReinvestment = buyCore(referrer, ethValue);
    emit onReinvestment(msg.sender, ethValue, tokensFromReinvestment);

    return tokensFromReinvestment;
  }

  /**
  * @dev Claim the currently owed dividends.
  */
  function claimDividend() external whenNotPaused {
    requireUnfrozen(msg.sender);
    claimDividendCore(msg.sender);
  }

  /**
  * @dev Alias to sell and claim all dividends
  */
  function exit() external whenNotPaused {
    requireUnfrozen(msg.sender);
    uint256 _tokens = _balances[msg.sender];
    if(_tokens > 0) {
      // Will auto claim dividends
      sell(_tokens);
    }
  }

  /**
  * @dev Sets the pool floor
  * @param floor The updated floor of the pool
  * @return A bool to show it completed successfully
  */
  function setPoolFloor(uint256 floor) external isBoardMember isBoardApproved returns(bool) {
    require(floor < _pool.ceiling, "Ceiling must be greater than the floor.");
    _pool.floor = floor;
    updatePoolState(0, false);
    return true;
  }

  /**
  * @dev Sets the pool ceiling
  * @param ceiling The updated ceiling of the pool
  * @return A bool to show it completed successfully
  */
  function setPoolCeiling(uint256 ceiling) external isBoardMember isBoardApproved returns(bool) {
    require(ceiling > _pool.floor, "Ceiling must be greater than the ceiling.");
    _pool.ceiling = ceiling;
    updatePoolState(0, false);
    return true;
  }

  /**
  * @dev Sets the pool buyReferrerPercent
  * @param buyReferrerPercent The updated buyReferrerPercent of the pool
  * @return A bool to show it completed successfully
  */
  function setPoolBuyReferrerPercent(uint256 buyReferrerPercent) external isBoardMember isBoardApproved returns(bool) {
    require(buyReferrerPercent >= 0, "Must be >= 0.");
    _pool.buyReferrerPercent = buyReferrerPercent;
    return true;
  }

  /**
  * @dev Sets the pool buyHolderPercent
  * @param buyHolderPercent The updated buyHolderPercent of the pool
  * @return A bool to show it completed successfully
  */
  function setPoolBuyHolderPercent(uint256 buyHolderPercent) external isBoardMember isBoardApproved returns(bool) {
    require(buyHolderPercent >= 0, "Must be >= 0.");
    _pool.buyHolderPercent = buyHolderPercent;
    return true;
  }

  /**
  * @dev Sets the pool sellHolderPercent
  * @param sellHolderPercent The updated sellHolderPercent of the pool
  * @return A bool to show it completed successfully
  */
  function setPoolSellHolderPercent(uint256 sellHolderPercent) external isBoardMember isBoardApproved returns(bool) {
    require(sellHolderPercent >= 0, "Must be >= 0.");
    _pool.sellHolderPercent = sellHolderPercent;
    return true;
  }

  /**
  * @dev Sets the pool buyMintOwnerPercent
  * @param buyMintOwnerPercent The updated buyMintOwnerPercent of the pool
  * @return A bool to show it completed successfully
  */
  function setPoolBuyMintOwnerPercent(uint256 buyMintOwnerPercent) external isBoardMember isBoardApproved returns(bool) {
    require(buyMintOwnerPercent >= 0, "Must be >= 0.");
    _pool.buyMintOwnerPercent = buyMintOwnerPercent;
    return true;
  }

  /**
  * @dev Sets the pool sellHoldOwnerPercent
  * @param sellHoldOwnerPercent The updated sellHoldOwnerPercent of the pool
  * @return A bool to show it completed successfully
  */
  function setPoolSellHoldOwnerPercent(uint256 sellHoldOwnerPercent) external isBoardMember isBoardApproved returns(bool) {
    require(sellHoldOwnerPercent >= 0, "Must be >= 0.");
    _pool.sellHoldOwnerPercent = sellHoldOwnerPercent;
    return true;
  }

  /**
  * @dev Gets the current pool information.
  * @return Properties related to the pool information.
  */
  function getPoolInfo() external view
    returns (uint256,uint256,uint256,uint256,bool,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,bool)
  {
      uint256 dividendsUnclaimed = _pool.totalDividends.sub(_pool.totalDividendsClaimed);

    return (_pool.total, _pool.floor, _pool.ceiling, _pool.totalDividends, _pool.sellAllowed, address(this).balance,
          _pool.buyReferrerPercent, _pool.buyHolderPercent, _pool.sellHolderPercent, _pool.buyMintOwnerPercent,
          _pool.sellHoldOwnerPercent,_pool.totalDividendsClaimed, dividendsUnclaimed, getIsPoolBalanced());
  }

  /**
  * @dev Calculate buy numbers
  */
  function estimateBuy(uint256 value, bool hasReferrer) public view returns(uint256, uint256, uint256, uint256) {
    uint256 tokenAmount;
    uint256 referralDividend;
    uint256 holderDividend;
    uint256 poolIncreaseAmt;

    // Dividends
    if(hasReferrer) {
      referralDividend = value.div(divideByPercent(_pool.buyReferrerPercent));
      holderDividend = value.div(divideByPercent(_pool.buyHolderPercent));
    }
    else {
      holderDividend = value.div(divideByPercent(_pool.buyHolderPercent.add(_pool.buyReferrerPercent)));
    }

    // Tokens
    uint256 allDividends = holderDividend.add(referralDividend);
    poolIncreaseAmt = value.sub(allDividends);

    // Determine how many tokens can be bought with original value
    tokenAmount = calculateTokenAmount(value);

    return (tokenAmount, referralDividend, holderDividend, poolIncreaseAmt);
  }

  /**
  * @dev Burn an amount of tokens.
  * @param amount Amount of tokens to burn.
  */
  function burn(uint256 amount) public whenNotPaused {
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    _supply = _supply.sub(amount);
    emit Transfer(_owner, address(0), amount);
    emit onBurn(amount, _supply);
  }

  /**
  * @dev Buy tokens with sent ETH. Dividends are sent to the referrer (if exists) and all token holders.
  * @param referrer Address of the referrer.
  * @return Bool success
  */
  function buy(address payable referrer) public payable whenNotPaused returns (bool) {
    requireUnfrozen(msg.sender);
    require(msg.sender != referrer, "Buyer and referrer cannot be the same.");
    claimDividendByAddress(msg.sender);
    buyCore(referrer, msg.value);
    return true;
  }

  /**
  * @dev Mint new tokens.
  * @param amount Amount of tokens to mint.
  */
  function mint(uint256 amount) public isBoardMember isBoardApproved whenNotPaused {
    _supply = _supply.add(amount);
    _balances[_owner] = _balances[_owner].add(amount);
    emit Transfer(address(0), _owner, amount);
    emit onMint(amount, _supply);
  }

  /**
  * @dev Sells an amount of tokens, and triggers a dividend.
  * @param tokenAmount Amount of tokens to sell.
  * @return bool success
  */
  function sell(uint256 tokenAmount) public whenNotPaused returns (bool) {
    requireUnfrozen(msg.sender);
    require(_pool.sellAllowed, "Sell is not yet allowed.");
    require(tokenAmount > 0, "Must sell an amount greater than 0.");

    uint256 ethValueLeftAfterDividend = 0;
    uint256 holderDividend = 0;
    uint256 ethValue = tokenAmount.mul(_currentPrice);
    require(ethValue >= _minimumEthSellAmount, "Transaction minimum not met.");
    
    // Get current unpaid dividends
    uint256 owing = dividendBalanceOf(msg.sender);

    (ethValueLeftAfterDividend, holderDividend) = estimateSell(tokenAmount);
    uint256 unclaimed = _pool.totalDividends.sub(_pool.totalDividendsClaimed);
    uint256 totalRequired = ethValueLeftAfterDividend.add(unclaimed);
    require(address(this).balance >= totalRequired, "Unable to fund the sell transaction.");

    increaseTotalDividends(holderDividend);

    burnOnSell(msg.sender, tokenAmount);

    // Don't give the seller the dividend
    _lastDividends[msg.sender] = _pool.totalDividends.sub(owing);

    // Update the current price based on actual token amount sold
    _currentPrice = _currentPrice.sub(_increment.mul(tokenAmount));

    if(_currentPrice < _lowerCap) {
      _currentPrice = _lowerCap;
    }

    emit onPriceChange(_currentPrice);

    if(msg.sender != _owner) {
      msg.sender.transfer(ethValueLeftAfterDividend);
    }

    updatePoolState(ethValueLeftAfterDividend, false);

    emit onTokenSell(msg.sender, tokenAmount, holderDividend);

    // Update total tokens sold
    _totalTokensSold = _totalTokensSold.add(tokenAmount);

    return true;
  }

  /**
  * @dev Calculate sell numbers
  */
  function estimateSell(uint256 tokenAmount) public view returns(uint256 ethValue, uint256 dividendValue) {
    // Value = tokens * price
    uint256 value = tokenAmount.mul(_currentPrice);

    // Dividends
    uint256 holderDividend = value.div(divideByPercent(_pool.sellHolderPercent));
    uint256 valueToReceive = value.sub(holderDividend);

    return (valueToReceive, holderDividend);
  }

  /**
  * @dev Gets the current dividend balance owed to an address.
  * @param account Account address to get the dividend balance.
  * @return An uint256 representing number of dividends currently owed to the address.
  */
  function dividendBalanceOf(address account) public view returns (uint256) {
    uint256 newDividends = _pool.totalDividends.sub(_lastDividends[account]);
    uint256 product = _balances[account].mul(newDividends);
    return product.div(_supply);
  }

  /**
  * @dev Update the pool state based on recent change.
  * @param amountChange Recent change amount.
  * @param added Added if it was a purchase, false of it was a sell.
  */
  function updatePoolState(uint256 amountChange, bool added) internal {
    if(amountChange != 0) {
      if(added) {
        _pool.total = _pool.total.add(amountChange);
      }
      else {
        require(_pool.total.sub(amountChange) >= 0, "Pool total can not go below 0.");
        _pool.total = _pool.total.sub(amountChange);
      }
    }

    // If selling was allowed, only turn it off if <= floor
    if(_pool.sellAllowed && _pool.total <= _pool.floor) {
      _pool.sellAllowed = false;
      emit onSellEnabledChange(_pool.sellAllowed);
    }
    // If selling wasn't allowed, turn it back on if >= ceiling
    else if(!_pool.sellAllowed && _pool.total >= _pool.ceiling) {
      _pool.sellAllowed = true;
      emit onSellEnabledChange(_pool.sellAllowed);
    }
  }

  function calculateTokenAmount(uint256 valueIn) private view returns(uint256 valueOut) {
    return(valueIn.div(_currentPrice));
  }

  function buyCore(address payable referrer, uint256 msgValue) private returns(uint256) {
    // Dividends
    uint256 tokenAmount = 0;
    uint256 referralDividend = 0;
    uint256 holderDividend = 0;
    uint256 poolIncrease = 0;
    bool hasReferrer = false;

    if(referrer != address(0)) {
      hasReferrer = true;
    }

    (tokenAmount, referralDividend, holderDividend, poolIncrease) = estimateBuy(msgValue, hasReferrer);

    // Tokens
    require(poolIncrease >= _currentPrice, "Amount must be greater than or equal to the token price.");

    mintOnBuy(msg.sender, tokenAmount);
    increaseTotalDividends(holderDividend);
    updatePoolState(poolIncrease, true);

    // Pay Referrer if necessary
    if(hasReferrer) {
      referrer.transfer(referralDividend);
    }
    else {
      _owner.transfer(referralDividend);
    }

    emit onTokenPurchase(msg.sender, msgValue, tokenAmount, referrer);

    // Update the current price based on actual token amount sold
    _currentPrice = _currentPrice.add(_increment.mul(tokenAmount));
    emit onPriceChange(_currentPrice);

    // Update total tokens purchased
    _totalTokensBought = _totalTokensBought.add(tokenAmount);

    return tokenAmount;
  }

  /**
  * @dev mintOnBuy
  */
  function mintOnBuy(address sender, uint256 tokenAmount) private returns(bool) {
    uint256 ownerMintedTokens = 0;
    uint256 totalMintedTokens = tokenAmount;

    // give owner their percent
    if(_pool.buyMintOwnerPercent > 0) {
      ownerMintedTokens = tokenAmount.div(divideByPercent(_pool.buyMintOwnerPercent));
      _balances[_owner] = _balances[_owner].add(ownerMintedTokens);
      totalMintedTokens = totalMintedTokens.add(ownerMintedTokens);
    }

    _balances[sender] = _balances[sender].add(tokenAmount);
    _supply = _supply.add(totalMintedTokens);

    emit onMint(totalMintedTokens, _supply);
    return true;
  }

  /**
  * @dev Fund Total dividends.  "Rain on holders propertionally."
  */
  function increaseTotalDividends(uint256 value) private {
    _pool.totalDividends = _pool.totalDividends.add(value);
    emit onDividendIncrease(value);
  }

  /**
  * @dev Gets the dividend of a referrer
  * @return An uint256 representing the dividend for the referrer.
  */
  function divideByPercent(uint256 percent) private view returns (uint256) {
    return _percentBase.div(percent);
  }

  /**
  * @dev Transfer tokens from the sender to another address.
  * @param sender address The address which you want to transfer from.
  * @param recipient address The address which you want to transfer to.
  * @param amount uint256 the amount of tokens to be transferred.
  * @return Bool success
  */
  function transferCore(address payable sender, address recipient, uint256 amount) private whenNotPaused  returns (bool) {
    requireUnfrozen(sender);
    requireUnfrozen(recipient);
    require(sender != address(0), "Send cannot be empty.");
    require(recipient != address(0), "Recipient cannot be empty.");
    require(_balances[sender] >= amount, "Insufficient balance to send tokens.");
    require(sender != recipient, "Attempted to send tokens to same address.");

    address payable recip = address(uint160(recipient));

    // Withdraw all outstanding dividends first
    claimDividendByAddress(sender);
    claimDividendByAddress(recip);

    _balances[sender] = _balances[sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
    return true;
  }

 /**
  * @dev Claim the currently owed dividends.
  */
  function claimDividendByAddress(address payable sender) private whenNotPaused returns(uint256){
    requireUnfrozen(sender);
    return claimDividendCore(sender);
  }

  function claimDividendCore(address payable sender) private whenNotPaused returns(uint256){
    uint256 owing = dividendBalanceOf(sender);
    require(_pool.totalDividendsClaimed.add(owing) <= _pool.totalDividends, "Unable to fund dividend claim.");
    _lastDividends[sender] = _pool.totalDividends; // Must always execute even if no funds are claimed
    if (owing > 0) {
      sender.transfer(owing);
      _pool.totalDividendsClaimed = _pool.totalDividendsClaimed.add(owing);
      emit onClaimDividend(sender, owing);
    }
    return owing;
  }

  /**
  * @dev burnOnSell
  */
  function burnOnSell(address sender, uint256 tokenAmount) private returns(bool) {
    require(_balances[sender] >= tokenAmount, "Sender unable to fund burn. Insufficient tokens.");
    uint256 ownerSavedTokens = 0;
    uint256 totalBurnedTokens = tokenAmount;

    if(_pool.sellHoldOwnerPercent > 0) {
      ownerSavedTokens = tokenAmount.div(divideByPercent(_pool.sellHoldOwnerPercent));
      totalBurnedTokens = totalBurnedTokens.sub(ownerSavedTokens);
    }

    _balances[sender] = _balances[sender].sub(tokenAmount);
    _balances[_owner] = _balances[_owner].add(ownerSavedTokens);
    _supply = _supply.sub(totalBurnedTokens);

    emit onBurn(totalBurnedTokens, _supply);
    return true;
  }

  /**
  * @dev gets wether contract is funded for both the pool and unclaimed dividends
  * @return A bool to show if balanced
  */
  function getIsPoolBalanced() private view returns(bool) {
    uint256 dividendsUnclaimed = _pool.totalDividends.sub(_pool.totalDividendsClaimed);
    return (address(this).balance == _pool.total.add(dividendsUnclaimed));
  }
}
