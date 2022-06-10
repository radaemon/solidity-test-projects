import { ethers, upgrades } from 'hardhat'

const proxyAddress = '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0'

async function main() {
  console.log(proxyAddress, 'original Box(proxy) address')
  const BoxV2 = await ethers.getContractFactory('BoxV2')
  // need to upgrade original box with this BoxV2 contract
  const boxV2 = await upgrades.upgradeProxy(proxyAddress, BoxV2)
  console.log(
    'proxy for new implementation (should remain equal): ',
    boxV2.address
  )

  console.log(
    await upgrades.erc1967.getImplementationAddress(boxV2.address),
    ' implementation address'
  )
  console.log(
    await upgrades.erc1967.getAdminAddress(boxV2.address),
    ' admin address'
  )
}

main().catch((e) => {
  console.error(e)
  process.exit(1)
})
