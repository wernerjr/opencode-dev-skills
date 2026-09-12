import { execFile } from "node:child_process"
import { promisify } from "node:util"
import { access } from "node:fs/promises"
import { join } from "node:path"

const execFileAsync = promisify(execFile)
const home = process.env.HOME || process.env.USERPROFILE || ""
const skillsRoots = [join(home, ".config", "opencode", "skills"), join(home, ".agents", "skills")]
let gitnexus = false
try {
  await execFileAsync("gitnexus", ["--version"])
  gitnexus = true
} catch {}
for (const root of skillsRoots) {
  try {
    await access(join(root, "gitnexus-exploring", "SKILL.md"))
    gitnexus = true
  } catch {}
}
let superpowers = false
for (const name of ["brainstorming", "writing-plans", "test-driven-development", "systematic-debugging", "verification-before-completion", "subagent-driven-development"]) {
  for (const root of skillsRoots) {
    try {
      await access(join(root, name, "SKILL.md"))
      superpowers = true
    } catch {}
  }
}
process.stdout.write(JSON.stringify({ gitnexus, superpowers }))
