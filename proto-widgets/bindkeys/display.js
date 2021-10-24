const { padLeft, padRight } = require('./utils');

const clr = (name, text, bold) => {
  const fg = {
    rst:  "\x1b[0m",
    bold: "\x1b[1m",
    black : "\x1b[30m",
    red : "\x1b[31m",
    green : "\x1b[32m",
    yellow : "\x1b[33m",
    blue : "\x1b[34m",
    magenta : "\x1b[35m",
    cyan : "\x1b[36m",
    white : "\x1b[37m",
  };
  return `${bold ? fg.bold : ''}${fg[name]}${text}${fg.rst}`
};

const center = (spacing, text) => {
    return [
      `${" ".repeat(Math.floor(spacing - text.length / 2))}`,
      text,
      `${" ".repeat(Math.ceil(spacing - text.length / 2))}`
    ].join('');
};

const displayKeys = (curr, old) => {
  const status = { removed: [], added: [], same: [] };

  const output = curr.split('\n').map(line => {
    const parts = line.split(/" | "/);
    if (!parts || parts.length !== 3) return false;
    const curr = { mode: parts[0].trim(''), key: `"${parts[1]}"`, command: parts[2].trim('') };
    const lineOut = [`${clr('blue', padRight(curr.mode, 7))}`,null,];
    const paddedKey = center(10, curr.key);

    const matched = old.some(oldkey => {
      if (oldkey[0] === curr.mode && oldkey[1] === curr.key && oldkey[2] === curr.command) {
        status.same.push(curr);
        lineOut[1] = paddedKey;
        return true;
      }
      return false;
    });

    if (!matched) {
      status.added.push(curr);
      lineOut[1] = `${clr('red', paddedKey, true)}`;
      lineOut[2] = `${clr('cyan', curr.command, true)}`;
    } else {
      lineOut[2] = `${curr.command}`;
      }
    // TODO: add change information
    return lineOut.join('  ');
  }).filter(Boolean);
  console.log(output.join('\n'));
};

module.exports = { displayKeys }
