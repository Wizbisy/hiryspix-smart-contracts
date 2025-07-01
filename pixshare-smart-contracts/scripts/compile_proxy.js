const fs = require('fs');
const path = require('path');
const solc = require('solc');

const fileName = 'ERC1967ProxyFlat.sol';
const contractName = 'ERC1967Proxy';

const source = fs.readFileSync(
  path.join(__dirname, `../contracts/${fileName}`),
  'utf8'
);

const input = {
  language: 'Solidity',
  sources: {
    [fileName]: { content: source }
  },
  settings: {
    outputSelection: {
      '*': {
        '*': ['abi', 'evm.bytecode']
      }
    }
  }
};

const output = JSON.parse(solc.compile(JSON.stringify(input)));

if (output.errors) {
  output.errors.forEach((err) =>
    console.log(err.severity, err.formattedMessage)
  );
}

const compiled = output.contracts?.[fileName]?.[contractName];
if (!compiled) {
  throw new Error(`❌ Could not find ${contractName} in ${fileName}`);
}

fs.mkdirSync('artifacts', { recursive: true });
fs.writeFileSync(
  `artifacts/${contractName}.json`,
  JSON.stringify(compiled, null, 2)
);

console.log(`✅ Compiled ${contractName} → artifacts/${contractName}.json`);
