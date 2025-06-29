const fs = require('fs');
const path = require('path');
const solc = require('solc');

const fileName = 'ERC1967ProxyFlat.sol';
const contractName = 'ERC1967Proxy';

// Read source
const source = fs.readFileSync(
  path.join(__dirname, `../contracts/${fileName}`),
  'utf8'
);

// Solidity compiler input
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

// Compile
const output = JSON.parse(solc.compile(JSON.stringify(input)));

// Debug in case of errors
if (output.errors) {
  output.errors.forEach((err) =>
    console.log(err.severity, err.formattedMessage)
  );
}

// Check and extract contract safely
const compiled = output.contracts?.[fileName]?.[contractName];
if (!compiled) {
  throw new Error(`❌ Could not find ${contractName} in ${fileName}`);
}

// Save to artifacts
fs.mkdirSync('artifacts', { recursive: true });
fs.writeFileSync(
  `artifacts/${contractName}.json`,
  JSON.stringify(compiled, null, 2)
);

console.log(`✅ Compiled ${contractName} → artifacts/${contractName}.json`);
