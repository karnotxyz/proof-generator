const fs = require("fs");

let file = process.argv[2];
console.log(file);

const data = JSON.parse(fs.readFileSync(file,
  "utf8"));
data.public_memory = data.public_memory.map((e) => ({
  ...e,
  value: `0x${e.value}`,
}));
fs.writeFileSync(file, JSON.stringify(data, null, 2));
