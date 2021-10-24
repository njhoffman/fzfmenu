const fs = require('fs');

const parseJson = (inFile) => {
  const mappings = require(inFile);
  const parsed = mappings.map(map => {
    const parts = map.split(/" | "/);
    console.log(parts, map);
    return [parts[0].trim(''), `"${parts[1]}"`, parts[2].trim('')];
  });

  const outFile = `${inFile}.parsed.json`;
  fs.writeFileSync(outFile, JSON.stringify(parsed, null, 2));
}

const padZeros = (num, numZeros) => (Array(numZeros).join('0') + num).slice(-numZeros)

const padRight = (input, len) => {
  const str = input.toString() || '';
  return len > str.length
    ? str + (new Array(len - str.length + 1)).join(' ')
    : str;
};

const padLeft = (input, len) => {
  const str = input.toString() || '';
  return len > str.length
    ? (new Array(len - str.length + 1)).join(' ') + str
    : str;
};


module.exports = { parseJson, padRight, padLeft, padZeros };
