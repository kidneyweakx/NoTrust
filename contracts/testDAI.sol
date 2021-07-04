// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <=0.8.6;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract testDAI is ERC20 {
    constructor() ERC20('Test DAI Stablecoin', 'tDAI'){}

    function mint(address to, uint amount) external {
        _mint(to, amount);
    }
}