require('dotenv').config();
const fs = require('fs');
const { ethers } = require('ethers');
const art = require('../artifacts/PostBoard.json');

const iface = new ethers.Interface(art.abi);
const data = iface.encodeFunctionData('initialize', [process.env.OWNER_ADDRESS]);

fs.mkdirSync('artifacts', { recursive: true }); // ensure the folder exists
fs.writeFileSync('artifacts/initCalldata.txt', data);

console.log('✅  Calldata encoded:', data);