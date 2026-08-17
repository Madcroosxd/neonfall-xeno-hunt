import fs from "node:fs";
import path from "node:path";

const outputDir = path.resolve("public/godot");
const wasmPath = path.join(outputDir, "index.wasm");
const enginePath = path.join(outputDir, "index.js");
const splitSize = 20 * 1024 * 1024;

if (!fs.existsSync(wasmPath)) throw new Error("Godot Web export is missing public/godot/index.wasm");
const wasm = fs.readFileSync(wasmPath);
fs.writeFileSync(`${wasmPath}.part0`, wasm.subarray(0, splitSize));
fs.writeFileSync(`${wasmPath}.part1`, wasm.subarray(splitSize));
fs.rmSync(wasmPath);

let engine = fs.readFileSync(enginePath, "utf8");
const marker = "\t\treturn fetch(file).then(function (response) {";
const splitLoader = `\t\tif (raw && file.endsWith('.wasm')) {
\t\t\tconst partFiles = [\`${"${file}"}.part0\`, \`${"${file}"}.part1\`];
\t\t\treturn Promise.all(partFiles.map(function (partFile) {
\t\t\t\treturn fetch(partFile).then(function (response) {
\t\t\t\t\tif (!response.ok) return Promise.reject(new Error(\`Failed loading Godot engine part '${"${partFile}"}'\`));
\t\t\t\t\treturn response.arrayBuffer();
\t\t\t\t});
\t\t\t})).then(function (parts) {
\t\t\t\ttracker[file].loaded = parts.reduce(function (total, part) { return total + part.byteLength; }, 0);
\t\t\t\ttracker[file].done = true;
\t\t\t\treturn new Response(new Blob(parts, { type: 'application/wasm' }), { headers: { 'Content-Type': 'application/wasm' } });
\t\t\t});
\t\t}
${marker}`;

if (!engine.includes("Godot engine part")) {
  if (!engine.includes(marker)) throw new Error("Godot engine loader marker changed");
  engine = engine.replace(marker, splitLoader);
  fs.writeFileSync(enginePath, engine);
}

console.log(`Godot Web build prepared: ${wasm.length} bytes split into platform-safe assets.`);
