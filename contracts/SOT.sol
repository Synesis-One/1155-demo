pragma solidity 0.5.5;
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
contract SynesisOneToken is ERC20, ERC20Detailed {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    
    struct stakeTracker {
        uint256 lastBlockChecked;
        uint256 rewards;
        uint256 sotTokenPoolTokens;
       
    }
    
    IERC20 private sotToken;
    
    IERC20 private sotTokenV2;
    address public sotTokenUniswapV2Pair;
    address public governance;
    uint256 public cap;
    uint256 private lastBlockSent;
    uint256 public liquidityMultiplier = 90;
    uint256 public miningDifficulty = 45000;
    uint256 totalLiquidityStaked;
    
    mapping(address => stakeTracker) private stakedBalances;
    mapping(address => bool) public minters;
    
    event sotTokenPairAddressChanged(address indexed user, address sotTokenPairAddress);
    event difficultyChanged(address indexed user, uint256 difficulty);
    event sotTokenUniStaked(address indexed user, uint256 amount, uint256 totalLiquidityStaked);
    
    event sotTokenUniWithdrawn(address indexed user, uint256 amount, uint256 totalLiquidityStaked);
    
    event Rewards(address indexed user, uint256 reward);
    
    constructor(uint256 initialSupply, uint256 _cap) ERC20Detailed("Synesis One Token", "SOT", 18) public {
        _mint(msg.sender, initialSupply);
        governance = msg.sender;
        cap = _cap;
        // uint256 supply = 100;
        // _mint(msg.sender, supply.mul(10 ** 18));
        lastBlockSent = block.number;
    }
    function setSotTokenPairAddress(address _uniV2address) public onlyGovernance() {
        sotTokenUniswapV2Pair = _uniV2address;
        sotTokenV2 = IERC20(sotTokenUniswapV2Pair);
        emit sotTokenPairAddressChanged(msg.sender, sotTokenUniswapV2Pair);
    }

    
    function stakeSotTokenUni(uint256 amount) public updateStakingReward(msg.sender) {
        sotTokenV2.safeTransferFrom(msg.sender, address(this), amount);
        stakedBalances[msg.sender].sotTokenPoolTokens = stakedBalances[msg.sender].sotTokenPoolTokens.add(amount);
        totalLiquidityStaked = totalLiquidityStaked.add(amount);                                                                              
        emit sotTokenUniStaked(msg.sender, amount, totalLiquidityStaked);
    }
    
    function withdrawSotTokenUni(uint256 amount) public updateStakingReward(msg.sender) {
        sotTokenV2.safeTransfer(msg.sender, amount);
        stakedBalances[msg.sender].sotTokenPoolTokens = stakedBalances[msg.sender].sotTokenPoolTokens.sub(amount);
        totalLiquidityStaked = totalLiquidityStaked.sub(amount);                                                                              
        emit sotTokenUniWithdrawn(msg.sender, amount, totalLiquidityStaked);
    }
    
    function getReward() public updateStakingReward(msg.sender) {
        uint256 reward = stakedBalances[msg.sender].rewards;
       stakedBalances[msg.sender].rewards = 0;
       _mint(msg.sender, reward.mul(8) / 10);
       uint256 fundingPoolReward = reward.mul(2) / 10;
       _mint(address(this), fundingPoolReward);
       emit Rewards(msg.sender, reward);
    }
    
    function setMiningDifficulty(uint256 amount) public onlyGovernance() {
       miningDifficulty = amount;
       emit difficultyChanged(msg.sender, miningDifficulty);
   }
    
    function mint(address _to, uint256 _amount) public {
        require(msg.sender == governance || minters[msg.sender], "!governance && !minter");
        _mint(_to, _amount);
    //     _moveDelegates(address(0), _delegates[_to], _amount);
    }
    function setGovernance(address _governance) public onlyGovernance() {
        governance = _governance;
    }
    function setCap(uint256 _cap) public onlyGovernance() {
        
        cap = _cap;
    }
    function addMinter(address _minter) public onlyGovernance() {
       
        minters[_minter] = true;
    }

    function removeMinter(address _minter) public onlyGovernance() {
        
        minters[_minter] = false;
    }
    
     modifier onlyGovernance() {
        require(msg.sender == governance, 'only governance');
        _;
    }
    modifier updateStakingReward(address _account) {
        uint256 liquidityBonus;
        if (stakedBalances[_account].sotTokenPoolTokens > 0) {
            liquidityBonus = stakedBalances[_account].sotTokenPoolTokens/ liquidityMultiplier;
        }
        if (block.number > stakedBalances[_account].lastBlockChecked) {
            uint256 rewardBlocks = block.number
                                        .sub(stakedBalances[_account].lastBlockChecked);
                                        
            stakedBalances[_account].rewards = stakedBalances[_account].rewards
                                                .add(stakedBalances[_account].sotTokenPoolTokens)
                                                .add(liquidityBonus)
                                                .mul(rewardBlocks)
                                                / miningDifficulty;
            stakedBalances[_account].lastBlockChecked = block.number;
            emit Rewards(_account, stakedBalances[_account].rewards);                                                     
        }
        _;
    }
    
}
