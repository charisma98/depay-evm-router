// SPDX-License-Identifier: MIT

pragma solidity >=0.8.6 <0.9.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IWETH.sol";

contract DePayRouterV1WETHWrap01 {
  
  using SafeMath for uint;

  // Address representating ETH (e.g. in payment routing paths)
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  // Address of WETH.
  address public immutable WETH;

  // Indicates that this plugin requires delegate call
  bool public immutable delegate = true;

  // Pass WETH when deploying this contract.
  constructor (
    address _WETH
  ) {
    WETH = _WETH;
  }

  // WRAP ETH TO WETH to pay in WETH using the amount at index 0 (`amounts[0]`) as input amount,
  function execute(
    address[] calldata path,
    uint[] calldata amounts,
    address[] calldata addresses,
    string[] calldata data
  ) external payable returns(bool) {

    if(
      (path[0] == ETH && path[1] == WETH)
    ) {
      IWETH(WETH).deposit{value: amounts[0]}();
    }

    return true;
  }
}
