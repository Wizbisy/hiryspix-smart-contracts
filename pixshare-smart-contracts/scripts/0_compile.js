const fs   = require('fs');
const path = require('path');
const solc = require('solc');

/* --------------------------------------------
   1. Load root contract source
--------------------------------------------- */
const ROOT = path.resolve(__dirname, '../contracts/PostBoardUpgradeable.sol');
const source = fs.readFileSync(ROOT, 'utf8');

/* --------------------------------------------
   2. Standard‑JSON compiler input
--------------------------------------------- */
const input = {
  language: 'Solidity',
  sources: {
    'PostBoardUpgradeable.sol': {
      content: source,
    },
  },
  settings: {
    outputSelection: {
      '*': {
        '*': ['abi', 'evm.bytecode'],
      },
    },
  },
};

/* --------------------------------------------
   3. Import resolver for @openzeppelin paths
--------------------------------------------- */
function findImports(importPath) {
  try {
    // Resolve from node_modules or relative FS
    const resolved = require.resolve(importPath, {
      paths: [path.resolve(__dirname, '..')],
    });
    return { contents: fs.readFileSync(resolved, 'utf8') };
  } catch (err) {
    return { error: 'File not found: ' + importPath };
  }
}

/* --------------------------------------------
   4. Compile
--------------------------------------------- */
const output = JSON.parse(solc.compile(JSON.stringify(input), { import: findImports }));

if (output.errors) {
  // Show warnings & errors from solc
  output.errors.forEach(e => console.log(e.formattedMessage));
  // Stop on fatal error
  const fatal = output.errors.find(e => e.severity === 'error');
  if (fatal) process.exit(1);
}

/* --------------------------------------------
   5. Extract ABI + bytecode
--------------------------------------------- */
const contract = output.contracts['PostBoardUpgradeable.sol']['PostBoardUpgradeable'];

fs.mkdirSync('artifacts', { recursive: true });
fs.writeFileSync('artifacts/PostBoard.json', JSON.stringify(contract, null, 2));

console.log('✅  ABI & bytecode saved to artifacts/PostBoard.json');
