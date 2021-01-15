import chai, { expect } from 'chai'
import {
  Contract,
  providers,
  Wallet 
} from 'ethers'
import { 
  solidity,
} from 'ethereum-waffle'
import IERC20 from '../artifacts/@openzeppelin/contracts/token/ERC20/IERC20.sol/IERC20.json'
import DePayPaymentProcessorV1 from '../artifacts/contracts/DePayPaymentProcessorV1.sol/DePayPaymentProcessorV1.json'
import IDePayPaymentProcessorV1 from '../artifacts/contracts/interfaces/IDePayPaymentProcessorV1.sol/IDePayPaymentProcessorV1.json'

const { waffle, ethers } = require("hardhat")
const {
  provider,
  deployContract,
  deployMockContract,
  loadFixture,
} = waffle

chai.use(solidity)

describe('DePayPaymentProcessorV1', () => {
  
  const [ownerWallet, otherWallet] = provider.getWallets()
  
  async function fixture() {
    const contract = await deployContract(ownerWallet, DePayPaymentProcessorV1)
    return {
      contract,
      ownerWallet,
      otherWallet
    }
  }

  it('deploys contract successfully', async () => {
    await loadFixture(fixture)
  })

  it('has the same interface as IDePayPaymentProcessorV1', async () => {
    const { contract, ownerWallet } = await loadFixture(fixture)
    const interfaceContract = await deployMockContract(ownerWallet, IDePayPaymentProcessorV1.abi)
    let inheritedFragmentNames: string[] = ['OwnershipTransferred', 'transferOwnership', 'owner', 'renounceOwnership']
    let contractFragmentsWithoutInheritance = contract.interface.fragments.filter((fragment: any)=> inheritedFragmentNames.indexOf(fragment.name) < 0)
    expect(
      JSON.stringify(contractFragmentsWithoutInheritance)
    ).to.eq(
      JSON.stringify(interfaceContract.interface.fragments)
    )
  })

  it('sets deployer wallet as the contract owner', async () => {
    const {contract, ownerWallet} = await loadFixture(fixture)
    const owner = await contract.owner()
    expect(owner).to.equal(ownerWallet.address)
  })

  it('contract can receive ETH (required for ETH transfers and swapping)', async () => {
    const {contract, otherWallet} = await loadFixture(fixture)

    await expect(
      await otherWallet.sendTransaction({ to: contract.address, value: 100, gasPrice: 0 })
    ).to.changeEtherBalance(contract, 100)
  })

  it('allows owner to withdraw ETH that remained in the contract', async () => {
    const {contract, ownerWallet, otherWallet} = await loadFixture(fixture)
    await otherWallet.sendTransaction({ to: contract.address, value: 100, gasPrice: 0 })
    
    await expect(
      await contract.connect(ownerWallet).withdraw('0x0000000000000000000000000000000000000000', 100)
    ).to.changeEtherBalance(ownerWallet, 100)
  })

  it('does not allow others to withdraw ETH that remained in the contract', async () => {
    const {contract, ownerWallet, otherWallet} = await loadFixture(fixture)
    await otherWallet.sendTransaction({ to: contract.address, value: 100, gasPrice: 0 })
    
    await expect(
      contract.connect(otherWallet).withdraw('0x0000000000000000000000000000000000000000', 100)
    ).to.be.revertedWith(
      'VM Exception while processing transaction: revert Ownable: caller is not the owner'
    )
  })

  // it('can withdraw tokens that have been sent into the contract', async () => {
  //   const {contract, otherWallet} = await loadFixture(fixture)
  //   await otherWallet.sendTransaction({ to: contract.address, value: 100, gasPrice: 0 })

  //   await expect(
  //     await contract.connect(wallet).withdraw(token, amount)
  //   ).to.changeEtherBalance(contract, 100)
  // })
})
