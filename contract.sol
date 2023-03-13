// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Define the GNGN token contract
contract GNGNToken is ERC20, Ownable {
    // Track blacklisted addresses
    mapping(address => bool) private _blacklist;

    // Constructor
constructor(uint256 _totalSupply) ERC20("GNGNToken", "gNGN") {
    _mint(msg.sender, _totalSupply);
}

    // Mint new tokens
    function mint(address to, uint256 amount) public onlyGovernorOrMultisig {
        _mint(to, amount);
    }

    // Burn tokens
    function burn(address from, uint256 amount) public onlyGovernorOrMultisig {
        _burn(from, amount);
    }

    // Blacklist an address
    function setBlacklist(address account, bool _isBlacklisted) public onlyGovernorOrMultisig {
        _blacklist[account] = _isBlacklisted;
        emit Blacklist(account, _isBlacklisted);
    }

    // Check if an address is blacklisted
    function isBlacklisted(address account) public view returns (bool) {
        return _blacklist[account];
    }

    // Check if an address is allowed to send and receive tokens
    function _isNotBlacklisted(address account) internal view returns (bool) {
        return !_blacklist[account];
    }

    // Override transfer function to check for blacklisted addresses
    function transfer(address to, uint256 value) public override returns (bool) {
        require(_isNotBlacklisted(msg.sender), "Sender is blacklisted");
        require(_isNotBlacklisted(to), "Recipient is blacklisted");
        return super.transfer(to, value);
    }

    // Override transferFrom function to check for blacklisted addresses
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        require(_isNotBlacklisted(from), "Sender is blacklisted");
        require(_isNotBlacklisted(to), "Recipient is blacklisted");
        return super.transferFrom(from, to, value);
    }

    // Define the role of the Governor
    modifier onlyGovernorOrMultisig() {
        require(msg.sender == owner() || isMultisigOwner(msg.sender), "Caller is not the Governor or part of multisig group");
        _;
    }

    // Event to notify when an address is blacklisted
event Blacklist(address indexed account, bool isBlacklisted);
}


// Multisig features
    struct Transfer {
        address recipient;
        uint256 amount;
        bool sent;
    }

    mapping(address => mapping(uint256 => Transfer)) public transfers;
    mapping(address => uint256) public numTransfers;
    uint256 public constant MAX_TRANSFERS = 100;

    struct Proposal {
        uint256 id;
        address recipient;
        uint256 amount;
        uint256 numVotes;
        mapping(address => bool) voted;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public numProposals;
    uint256 public constant VOTE_THRESHOLD = 3;

    // Modifier to ensure only multisig owners can call the function
    modifier onlyMultisigOwner() {
        require(isMultisigOwner(msg.sender), "Caller is not a multisig owner");
        _;
    }

    // Add multisig owner function
function addMultisigOwner(address _newOwner) public onlyGovernor {
    require(!isMultisigOwner[_newOwner], "Address is already a multisig owner");
    multisigOwners.push(_newOwner);
    isMultisigOwner[_newOwner] = true;
}

   // Remove multisig owner function
function removeMultisigOwner(address _ownerToRemove) public onlyGovernor {
    require(isMultisigOwner[_ownerToRemove], "Address is not a multisig owner");
    require(_ownerToRemove != governor, "Cannot remove the governor from the multisig group");
    isMultisigOwner[_ownerToRemove] = false;

    for (uint256 i = 0; i < multisigOwners.length - 1; i++) {
        if (multisigOwners[i] == _ownerToRemove) {
            multisigOwners[i] = multisigOwners[multisigOwners.length - 1];
            multisigOwners.pop();
            break;
        }
    }
}

// Update multisig threshold function
function updateMultisigThreshold(uint256 _newThreshold) public onlyGovernor {
    require(_newThreshold > 0 && _newThreshold <= multisigOwners.length, "Invalid threshold");
    multisigThreshold = _newThreshold;
}

// Multisig transfer function
function multisigTransfer(address _to, uint256 _value) public onlyMultisig returns (bool) {
    require(_to != address(0), "Invalid address");
    require(_value > 0 && _value <= balances[msg.sender], "Invalid amount");

    balances[msg.sender] -= _value;
    balances[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
}

// Multisig mint function
function multisigMint(address _to, uint256 _value) public onlyMultisig returns (bool) {
    require(_to != address(0), "Invalid address");
    require(_value > 0, "Invalid amount");

    totalSupply += _value;
    balances[_to] += _value;
    emit Transfer(address(0), _to, _value);
    return true;
}

// Multisig burn function
function multisigBurn(address _from, uint256 _value) public onlyMultisig returns (bool) {
    require(_from != address(0), "Invalid address");
    require(_value > 0 && _value <= balances[_from], "Invalid amount");

    totalSupply -= _value;
    balances[_from] -= _value;
    emit Transfer(_from, address(0), _value);
    return true;
    } 
    
// Define the Governor contract
contract Governor is Ownable {
    GNGNToken public gNGN;
    MultiSig public multisig;

   // Constructor
constructor(GNGNToken _gNGN) {
    gNGN = _gNGN;
    multisig = new MultiSig();
    multisig.addMultisigOwner(msg.sender);
}

// Mint new tokens using multisig
function multisigMint(address to, uint256 amount) external {
    multisig.multisigMint(to, amount);
}

// Burn tokens using multisig
function multisigBurn(address from, uint256 amount) external {
    multisig.multisigBurn(from, amount);
}

// Blacklist an address using multisig
function multisigSetBlacklist(address account, bool isBlacklisted) external {
    multisig.setBlacklist(account, isBlacklisted);

    function multisigSetBlacklist(address[] memory blacklist) public onlyOwners {
    require(blacklist.length <= MAX_OWNER_COUNT, "Blacklist size exceeds max owner count");
    for (uint256 i = 0; i < blacklist.length; i++) {
        require(blacklist[i] != address(0), "Invalid blacklist address");
    }
    _blacklist = blacklist;
}

function multisigRemoveOwner(address owner) public onlyOwners {
    require(_owners.length > 1, "Cannot remove the last owner");
    require(_blacklist.indexOf(owner) == -1, "Cannot remove a blacklisted owner");
    uint256 ownerIndex = _owners.indexOf(owner);
    require(ownerIndex != uint256(-1), "Owner not found");
    for (uint256 i = ownerIndex; i < _owners.length - 1; i++) {
        _owners[i] = _owners[i + 1];
    }
    _owners.pop();
    emit OwnerRemoved(owner);
}

function multisigExecute(
    address to,
    uint256 value,
    bytes memory data,
    uint8[] memory sigV,
    bytes32[] memory sigR,
    bytes32[] memory sigS
) public onlyOwners {
    require(to != address(0), "Invalid recipient address");
    require(value <= address(this).balance, "Insufficient balance");
    require(sigV.length == _owners.length, "Invalid number of signatures");
    require(sigR.length == _owners.length, "Invalid number of signatures");
    require(sigS.length == _owners.length, "Invalid number of signatures");
    require(!_blacklist.contains(to), "Recipient address is blacklisted");
    bytes32 txHash = keccak256(abi.encodePacked(to, value, data, _nonce));
    for (uint256 i = 0; i < _owners.length; i++) {
        address signer = ecrecover(txHash, sigV[i], sigR[i], sigS[i]);
        require(signer == _owners[i], "Invalid signature");
    }
    _nonce++;
    (bool success,) = to.call{value: value}(data);
    require(success, "Transaction execution failed");
    emit TransactionExecuted(to, value, data);
}

function multisigRecover(address[] memory tokens) public onlyOwners {
    for (uint256 i = 0; i < tokens.length; i++) {
        if (tokens[i] == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 token = IERC20(tokens[i]);
            token.transfer(msg.sender, token.balanceOf(address(this)));
        }
    }
}
