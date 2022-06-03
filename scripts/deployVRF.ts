import { ethers } from 'hardhat'

async function main() {
  const VRFV2 = await ethers.getContractFactory('VRFv2Consumer')
  const vrfv2 = await VRFV2.deploy(process.env.SUBSCRIPTION_ID_VRF)

  await vrfv2.deployed()

  console.log('Contract deployed to:', vrfv2.address)
}

main()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error(e)
    process.exit(1)
  })
