import { expect } from 'chai'
import { ethers } from 'hardhat'

describe('Savings Box', () => {
  it('Should set the charity address correctly', async () => {
    const SavingsBox = await ethers.getContractFactory('SavingsBox')
    const savingsBox = await SavingsBox.deploy(process.env.CHARITY_ADDRESS)
    await savingsBox.deployed()

    expect(await savingsBox.charity()).to.equal(process.env.CHARITY_ADDRESS)
  })
  it('deposit should credit the eth to the savers array', async () => {
    const SavingsBox = await ethers.getContractFactory('SavingsBox')
    const savingsBox = await SavingsBox.deploy(process.env.CHARITY_ADDRESS)
    await savingsBox.deployed()

    const [signer] = await ethers.getSigners()

    await savingsBox.deposit(signer.address, {
      value: ethers.utils.parseEther('.01'),
    })

    const saver = await savingsBox.savers(0)

    expect(saver.balance).to.equal(ethers.utils.parseEther('.01'))
    expect(await savingsBox.addressToIndex(signer.address)).to.equal(1)
  })
  // scenario where user misses all payments except first
  it('should only credit the user with 40% (he missed all payments)', async () => {
    const [signer, signerTwo] = await ethers.getSigners()

    const SavingsBox = await ethers.getContractFactory('SavingsBox')
    const savingsBox = await SavingsBox.deploy(signerTwo.address)
    await savingsBox.deployed()

    await savingsBox.deposit(signer.address, {
      value: ethers.utils.parseEther('1'),
    })

    // scenario where user withdraws before due date
    await expect(savingsBox.withdraw(signer.address)).to.be.revertedWith(
      'contract has not expired.'
    )

    const fiftyTwoWeeks = 52 * 7 * 24 * 60 * 60

    const blockNumBefore = await ethers.provider.getBlockNumber()
    const blockBefore = await ethers.provider.getBlock(blockNumBefore)
    const timestampBefore = blockBefore.timestamp

    // forward time 52 weeks from now
    await ethers.provider.send('evm_increaseTime', [fiftyTwoWeeks])
    await ethers.provider.send('evm_mine', [])

    const blockNumAfter = await ethers.provider.getBlockNumber()
    const blockAfter = await ethers.provider.getBlock(blockNumAfter)
    const timestampAfter = blockAfter.timestamp

    // deposit again
    await savingsBox.deposit(signer.address, {
      value: ethers.utils.parseEther('1'),
    })

    // balance should be two now
    expect((await savingsBox.savers(0)).balance).to.equal(
      ethers.utils.parseEther('2')
    )

    // expect user to have 11 late payments
    expect((await savingsBox.savers(0)).latePayments).to.equal(11)

    // withdraw all the money (he should have his 2ETH back minus 60%)
    console.log(ethers.utils.formatEther(await signer.getBalance()))
    console.log(
      'charity address balance before: ',
      ethers.utils.formatEther(await signerTwo.getBalance())
    )
    await savingsBox.withdraw(signer.address)
    console.log(ethers.utils.formatEther(await signer.getBalance()))
    console.log(
      'charity address balance after: ',
      ethers.utils.formatEther(await signerTwo.getBalance())
    )
    // expect charity to have 55% of the 2ETH (he missed 11 payments) + 10,000ETH (initial balance)
    expect(ethers.utils.formatEther(await signerTwo.getBalance())).to.equal(
      '10001.1'
    )
    // expect saver to recover 45% of his 2ETH back
    expect(
      Number(ethers.utils.formatEther(await signer.getBalance()))
    ).to.be.closeTo(10000 - 2 + 2 * 0.45, 0.015)
  })
})
