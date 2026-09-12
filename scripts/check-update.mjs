import { execFile } from "node:child_process"
import { promisify } from "node:util"

const execFileAsync = promisify(execFile)
const pluginDirectory = process.argv[2] || process.cwd()
const repository = process.argv[3] || "wernerjr/opencode-dev-skills"

const installed = (await execFileAsync("git", ["rev-parse", "HEAD"], { cwd: pluginDirectory })).stdout.trim()
const response = await fetch(`https://api.github.com/repos/${repository}/commits/main`, {
  headers: { accept: "application/vnd.github+json", "user-agent": "opencode-dev-skills" },
})
if (!response.ok) throw new Error(`GitHub returned ${response.status}`)
const data = await response.json()
process.stdout.write(JSON.stringify({ installed, latest: data.sha, outdated: installed !== data.sha }))
