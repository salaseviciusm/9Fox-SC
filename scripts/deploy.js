async function main() {
    const Nft = await ethers.getContractFactory("NineFoxNFT")
    
    console.log("Started")
    const nft = await Nft.deploy()
    console.log("Waiting on deployment")
    await nft.deployed()
    console.log("Contract deployed to address:", nft.address)
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error)
      process.exit(1)
    })


  