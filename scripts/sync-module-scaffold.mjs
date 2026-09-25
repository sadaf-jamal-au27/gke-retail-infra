#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const modulesDir = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "terraform", "modules");
const scaffoldDir = path.join(modulesDir, "_scaffold");

/** Child modules: no backend.tf (only live stacks configure GCS). */
const scaffoldFiles = ["versions.tf", "provider.tf"];

const modules = fs
  .readdirSync(modulesDir, { withFileTypes: true })
  .filter((d) => d.isDirectory() && !d.name.startsWith("_"))
  .map((d) => d.name);

for (const name of scaffoldFiles) {
  const content = fs.readFileSync(path.join(scaffoldDir, name), "utf8");
  for (const mod of modules) {
    fs.writeFileSync(path.join(modulesDir, mod, name), content);
    const backendPath = path.join(modulesDir, mod, "backend.tf");
    if (fs.existsSync(backendPath)) fs.unlinkSync(backendPath);
  }
}

for (const mod of modules) {
  const varsPath = path.join(modulesDir, mod, "variables.tf");
  let vars = fs.readFileSync(varsPath, "utf8");
  if (!vars.includes('variable "region"')) {
    vars = vars.replace(
      /variable "project_id" \{ type = string \}\n/,
      `variable "project_id" { type = string }\nvariable "region" { type = string }\n`
    );
  }
  fs.writeFileSync(varsPath, vars);

  for (const file of ["versions.tf", "provider.tf", "variables.tf", "main.tf", "outputs.tf"]) {
    if (!fs.existsSync(path.join(modulesDir, mod, file))) {
      console.warn(`WARN: ${mod} missing ${file}`);
    }
  }
}

console.log(`Synced module scaffold (versions.tf, provider.tf) for: ${modules.join(", ")}`);
