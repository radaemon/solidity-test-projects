import { expect } from 'chai'
import { ethers } from 'hardhat'

describe('Greeter', () => {
  it('Should return the new greeting once its changed', async () => {
    const Greeter = await ethers.getContractFactory('Greeting')
    const greeter = await Greeter.deploy()
    await greeter.deployed()

    const txn = await greeter.setGreeter('Hello World!')

    await txn.wait()

    expect(await greeter.greeter()).to.equal('Hello World!')
  })
})
