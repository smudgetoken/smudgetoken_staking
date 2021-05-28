pragma solidity ^0.5.11;


contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    
    
    constructor()
        public
    {
        owner = msg.sender;
    }

    
    modifier onlyOwner()
    {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    
    
    
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership()
        public
        onlyOwner
    {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

contract Claimable is Ownable
{
    address public pendingOwner;

    
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }

    
    
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

    
    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

contract ERC20 {
    function totalSupply()
        public
        view
        returns (uint);

    function balanceOf(
        address who
        )
        public
        view
        returns (uint);

    function allowance(
        address owner,
        address spender
        )
        public
        view
        returns (uint);

    function transfer(
        address to,
        uint value
        )
        public
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint    value
        )
        public
        returns (bool);

    function approve(
        address spender,
        uint    value
        )
        public
        returns (bool);
}

library ERC20SafeTransfer {
    function safeTransferAndVerify(
        address token,
        address to,
        uint    value
        )
        internal
    {
        safeTransferWithGasLimitAndVerify(
            token,
            to,
            value,
            gasleft()
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint    value
        )
        internal
        returns (bool)
    {
        return safeTransferWithGasLimit(
            token,
            to,
            value,
            gasleft()
        );
    }

    function safeTransferWithGasLimitAndVerify(
        address token,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
    {
        require(
            safeTransferWithGasLimit(token, to, value, gasLimit),
            "TRANSFER_FAILURE"
        );
    }

    function safeTransferWithGasLimit(
        address token,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
        returns (bool)
    {
        
        
        

        
        bytes memory callData = abi.encodeWithSelector(
            bytes4(0xa9059cbb),
            to,
            value
        );
        (bool success, ) = token.call.gas(gasLimit)(callData);
        return checkReturnValue(success);
    }

    function safeTransferFromAndVerify(
        address token,
        address from,
        address to,
        uint    value
        )
        internal
    {
        safeTransferFromWithGasLimitAndVerify(
            token,
            from,
            to,
            value,
            gasleft()
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint    value
        )
        internal
        returns (bool)
    {
        return safeTransferFromWithGasLimit(
            token,
            from,
            to,
            value,
            gasleft()
        );
    }

    function safeTransferFromWithGasLimitAndVerify(
        address token,
        address from,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
    {
        bool result = safeTransferFromWithGasLimit(
            token,
            from,
            to,
            value,
            gasLimit
        );
        require(result, "TRANSFER_FAILURE");
    }

    function safeTransferFromWithGasLimit(
        address token,
        address from,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
        returns (bool)
    {
        
        
        

        
        bytes memory callData = abi.encodeWithSelector(
            bytes4(0x23b872dd),
            from,
            to,
            value
        );
        (bool success, ) = token.call.gas(gasLimit)(callData);
        return checkReturnValue(success);
    }

    function checkReturnValue(
        bool success
        )
        internal
        pure
        returns (bool)
    {
        
        
        
        if (success) {
            assembly {
                switch returndatasize()
                
                case 0 {
                    success := 1
                }
                
                case 32 {
                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }
                
                default {
                    success := 0
                }
            }
        }
        return success;
    }
}

library MathUint {
    function mul(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a * b;
        require(a == 0 || c / a == b, "MUL_OVERFLOW");
    }

    function sub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint)
    {
        require(b <= a, "SUB_UNDERFLOW");
        return a - b;
    }

    function add(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }

    function decodeFloat(
        uint f
        )
        internal
        pure
        returns (uint value)
    {
        uint numBitsMantissa = 23;
        uint exponent = f >> numBitsMantissa;
        uint mantissa = f & ((1 << numBitsMantissa) - 1);
        value = mantissa * (10 ** exponent);
    }
}

contract ReentrancyGuard {
    
    uint private _guardValue;

    
    modifier nonReentrant()
    {
        
        require(_guardValue == 0, "REENTRANCY");

        
        _guardValue = 1;

        
        _;

        
        _guardValue = 0;
    }
}

contract IProtocolFeeVault {
    uint public constant REWARD_PERCENTAGE      = 70;
    uint public constant DAO_PERDENTAGE         = 20;

    address public userStakingPoolAddress;
    address public lrcAddress;
    address public tokenSellerAddress;
    address public daoAddress;

    uint claimedReward;
    uint claimedDAOFund;
    uint claimedBurn;

    event LRCClaimed(uint amount);
    event DAOFunded(uint amountDAO, uint amountBurn);
    event TokenSold(address token, uint amount);
    event SettingsUpdated(uint time);

    
    
    
    
    function updateSettings(
        address _userStakingPoolAddress,
        address _tokenSellerAddress,
        address _daoAddress
        )
        external;

    
    
    
    
    
    function claimStakingReward(uint amount) external;

    
    
    function fundDAO() external;

    
    
    
    
    function sellTokenForsmudge(
        address token,
        uint    amount
        )
        external;

    
    
    
    
    
    
    
    
    
    function getProtocolFeeStats()
        public
        view
        returns (
            uint accumulatedFees,
            uint accumulatedBurn,
            uint accumulatedDAOFund,
            uint accumulatedReward,
            uint remainingFees,
            uint remainingBurn,
            uint remainingDAOFund,
            uint remainingReward
        );
}

contract IUserStakingPool {
    uint public constant MIN_CLAIM_DELAY        = 90 days;
    uint public constant MIN_WITHDRAW_DELAY     = 90 days;

    address public lrcAddress;
    address public protocolFeeVaultAddress;

    uint    public numAddresses;

    event ProtocolFeeVaultChanged (address feeVaultAddress);

    event smudgeStaked       (address indexed user,  uint amount);
    event smudgeWithdrawn    (address indexed user,  uint amount);
    event smudgeRewarded     (address indexed user,  uint amount);

    
    
    function setProtocolFeeVault(address _protocolFeeVaultAddress)
        external;

    
    function getTotalStaking()
        public
        view
        returns (uint);
