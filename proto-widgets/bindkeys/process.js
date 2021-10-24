#!/usr/bin/env node
const path = require('path');
const { parseJson, padZeros } = require('./utils');
const { displayKeys } = require('./display');

const now = new Date();
const dateString = [
  `${now.getFullYear()}`,
  `${padZeros(now.getMonth() + 1, 2)}`,
  `${padZeros(now.getDate(),2)}`
].join('-');

const inFile = path.resolve(__dirname, `keyHistory/${dateString}`);
parseJson(inFile);

// process.stdin.resume();
// process.stdin.setEncoding('utf-8');

// let buff = "";
// process.stdin.on('data', data => {
//   buff += data;
// }).on('end', () => {
//   const oldKeys = require(path.resolve(__dirname, `keyHistory/2021-08-25.parsed`));
//   displayKeys(buff, oldKeys);
// });
