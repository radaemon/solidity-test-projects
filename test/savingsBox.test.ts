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
  it('should only credit the user with 40% (he missed all payments)', async () => {
    const SavingsBox = await ethers.getContractFactory('SavingsBox')
    const savingsBox = await SavingsBox.deploy(process.env.CHARITY_ADDRESS)
    await savingsBox.deployed()

    const [signer] = await ethers.getSigners()

    await savingsBox.deposit(signer.address, {
      value: ethers.utils.parseEther('1'),
    })

    const fiftyTwoWeeks = 52 * 7 * 24 * 60 * 60

    const blockNumBefore = await ethers.provider.getBlockNumber()
    const blockBefore = await ethers.provider.getBlock(blockNumBefore)
    const timestampBefore = blockBefore.timestamp

    console.log('blockNumBefore:', blockNumBefore)
    console.log('block before:', blockBefore)
    console.log('timestamp:', timestampBefore)

    // forward time 52 weeks from now
    await ethers.provider.send('evm_increaseTime', [fiftyTwoWeeks])
    await ethers.provider.send('evm_mine', [])

    const blockNumAfter = await ethers.provider.getBlockNumber()
    const blockAfter = await ethers.provider.getBlock(blockNumAfter)
    const timestampAfter = blockAfter.timestamp

    console.log('blockNumAfter:', blockNumAfter)
    console.log('block after:', blockAfter)
    console.log('timestamp:', timestampAfter)

    // deposit again
    await savingsBox.deposit(signer.address, {
      value: ethers.utils.parseEther('1'),
    })

    // balance should be two now
    expect((await savingsBox.savers(0)).balance).to.equal(
      ethers.utils.parseEther('2')
    )
  })
  // scenario where user misses all payments except first
  // scenario where user withdraws after not missing payments
  // scenario where user withdraws before due date
})
