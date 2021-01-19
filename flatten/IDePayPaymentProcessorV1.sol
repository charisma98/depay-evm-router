// Root file: contracts/interfaces/IDePayPaymentProcessorV1.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.5 <0.8.0;

interface IDePayPaymentProcessorV1 {

  event Payment(
    address indexed sender,
    address payable indexed receiver
  );

  function pay(
    address[] calldata path,
    uint amountIn,
    uint amountOut,
    address payable receiver,
    address[] calldata preProcessors,
    address[] calldata postProcessors
  ) external payable returns(bool);

  function approveProcessor(
    address processor
  ) external returns(bool);

  function isApproved(
    address processorAddress
  ) external view returns(bool);

  function withdraw(
    address tokenAddress, 
    uint amount
  ) external returns(bool);
  
}
