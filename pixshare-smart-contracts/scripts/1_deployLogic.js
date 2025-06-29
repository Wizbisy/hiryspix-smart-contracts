require('dotenv').config();
const { ethers } = require('ethers');
const art = require('../artifacts/PostBoard.json');

const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const wallet   = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

(async () => {
  const Factory = new ethers.ContractFactory(art.abi, art.evm.bytecode.object, wallet);
  const tx = Factory.getDeployTransaction({
    gasLimit: 5_000_000,
    gasPrice: process.env.GAS_PRICE_WEI
  });

  const sent = await wallet.sendTransaction(tx);
  console.log('⏳  logic tx hash:', sent.hash);
  const receipt = await sent.wait();
  console.log('✅  logic deployed:', receipt.contractAddress);
})();
