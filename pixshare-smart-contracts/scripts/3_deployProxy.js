require('dotenv').config();
const { ethers } = require('ethers');
const implArt   = require('../artifacts/PostBoard.json');
const proxyArt  = require('../artifacts/ERC1967Proxy.json');
const initData  = require('fs').readFileSync('artifacts/initCalldata.txt','utf8').trim();
const provider  = new ethers.JsonRpcProvider(process.env.RPC_URL);
const wallet    = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

(async () => {
  const ProxyFactory = new ethers.ContractFactory(proxyArt.abi, proxyArt.evm.bytecode.object, wallet);

  const logicAddr = process.argv[2]; 
  if (!ethers.isAddress(logicAddr)) throw new Error('pass logic address');

  const tx = ProxyFactory.getDeployTransaction(
    logicAddr,
    initData,
    { gasLimit: 5_000_000, gasPrice: process.env.GAS_PRICE_WEI }
  );

  const sent = await wallet.sendTransaction(tx);
  console.log('⏳  proxy tx hash:', sent.hash);
  const receipt = await sent.wait();
  console.log('✅  proxy live at:', receipt.contractAddress);
})();
