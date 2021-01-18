// SPDX-License-Identifier: MIT

pragma solidity >=0.7.5 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import './interfaces/IDePayPaymentProcessorV1Processor.sol';

contract DePayPaymentProcessorV1 is Ownable {
  
  using SafeMath for uint;
  using SafeERC20 for IERC20;

  // Address ZERO indicating ETH transfer, because ETH does not have an address like other tokens
  address private ZERO = 0x0000000000000000000000000000000000000000;

  // gas safe transfer of tokens (see: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2Pair.sol#L44)
  bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

  // List of whitelisted payment processors
  mapping (address => address) private processors;

  event Payment(
    address indexed sender,
    address payable indexed receiver
  );

  receive() external payable {
    // accepts eth payments which are required to
    // swap and pay from ETH to any token
    // especially unwrapping WETH as part of token conversions
  }

  function pay(
    address[] calldata path,
    uint amountIn,
    uint amountOut,
    address payable receiver,
    address[] calldata preProcessors,
    address[] calldata postProcessors
  ) external payable returns(bool) {
    if(path[0] == ZERO) { require(msg.value >= amountIn, 'DePay: Insufficient ETH amount payed in!'); }
    if(path[0] != ZERO) { _transferIn(path[0], amountIn); }

    _process(preProcessors, path, amountIn, amountOut);
    _pay(receiver, path[path.length-1], amountOut);
    _process(postProcessors, path, amountIn, amountOut);

    emit Payment(msg.sender, receiver);

    return true;
  }

  function _pay(address payable receiver, address token, uint amountOut) private {
    if(token == ZERO) {
      receiver.transfer(amountOut);
    } else {
      _safeTransfer(token, receiver, amountOut);
    }
  }

  // makes sure to transfer in the token used as means of payment
  function _transferIn(address token, uint amount) private {
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
  }

  // gas safe transfer of tokens (see: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2Pair.sol#L44)
  function _safeTransfer(address token, address to, uint value) private {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'DePay: Safe transfer failed!');
  }

  function addProcessor(address processor) external onlyOwner returns(bool) {
    processors[processor] = processor;
    return true;
  }

  function _process(
    address[] calldata _processors,
    address[] calldata path,
    uint amountIn,
    uint amountOut
  ) internal {
    for (uint256 i = 0; i < _processors.length; i++) {
      require(_isWhitelisted(_processors[i]), 'DePay: Processor not whitelisted!');
      address processor = processors[_processors[i]];
      (bool success, bytes memory returnData) = processor.delegatecall(abi.encodeWithSelector(
          IDePayPaymentProcessorV1Processor(processor).process.selector, path, amountIn, amountOut
      ));
      require(success, string(returnData));
    }
  }

  function isWhitelisted(
    address processorAddress
  ) external view returns(bool){
    return _isWhitelisted(processorAddress);
  }

  function _isWhitelisted(
    address processorAddress
  ) internal view returns(bool) {
    return (processors[processorAddress] != ZERO);
  }
  
  function payableOwner() view private returns(address payable) {
    return payable(owner());
  }

  // allows to withdraw accidentally sent ETH or tokens
  function withdraw(
    address tokenAddress,
    uint amount
  ) external onlyOwner returns(bool) {
    if(tokenAddress == ZERO) {
      payableOwner().transfer(amount);
    } else {
      _safeTransfer(tokenAddress, payableOwner(), amount);
    }
    return true;
  }
}
