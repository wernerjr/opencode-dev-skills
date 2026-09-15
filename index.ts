import { execFile } from "node:child_process"
import { promisify } from "node:util"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { homedir } from "node:os"
import { rm, readdir } from "node:fs/promises"

const execFileAsync = promisify(execFile)
const packageDirectory = dirname(fileURLToPath(import.meta.url))
const skillsDirectory = join(packageDirectory, "skills")
const repository = process.env.OPENCODE_DEV_SKILLS_REPOSITORY || "wernerjr/opencode-dev-skills"

const bootstrap = `When a user wants to triage, rank, pick, or fix GitHub issues, load dev-orchestrator. If there is even a small chance this workflow applies, load it before acting. Available skills: dev-orchestrator, rank-github-issues, dispatch-issue-fix, fix-security-issue, fix-code-issue.`

async function currentCommit() {
  try {
    const result = await execFileAsync("git", ["rev-parse", "HEAD"], { cwd: packageDirectory })
    return result.stdout.trim()
  } catch {
    return "unknown"
  }
}

async function checkForUpdate() {
  const response = await fetch(`https://api.github.com/repos/${repository}/commits/main`, {
    headers: { accept: "application/vnd.github+json", "user-agent": "opencode-dev-skills" },
  })
  if (!response.ok) throw new Error(`GitHub returned ${response.status}`)
  const data = await response.json()
  return { installed: await currentCommit(), latest: data.sha || "unknown" }
}

async function log(client: any, level: "warn" | "info", message: string) {
  try {
    await client?.app?.log?.({ body: { service: "opencode-dev-skills", level, message } })
  } catch {
    // Logging must never prevent the native skills from loading.
  }
}

async function notify(client: any, message: string) {
  try {
    await client?.tui?.toast?.show?.({ body: { message, variant: "warning" } })
  } catch {
    await log(client, "warn", message)
  }
}

async function clearPluginCache(client: any) {
  const cacheRoot = join(homedir(), ".cache", "opencode", "packages")
  let entries: string[] = []
  try {
    entries = (await readdir(cacheRoot)).filter((entry) => entry.startsWith("opencode-dev-skills@"))
  } catch (error) {
    await log(client, "warn", `Could not list plugin cache at ${cacheRoot}: ${String(error)}`)
  }
  for (const entry of entries) {
    const candidate = join(cacheRoot, entry)
    try {
      await rm(candidate, { recursive: true, force: true })
    } catch (error) {
      await log(client, "warn", `Could not clear plugin cache at ${candidate}: ${String(error)}`)
    }
  }
  await log(client, "info", "Restart OpenCode to pull the new skill version.")
}

export default async function OpencodeDevSkillsPlugin({ client }: any) {
  return {
    config: async (config: any) => {
      config.skills ??= {}
      config.skills.paths = Array.isArray(config.skills.paths) ? config.skills.paths : []
      if (!config.skills.paths.includes(skillsDirectory)) config.skills.paths.push(skillsDirectory)
    },
    event: async ({ event }: any) => {
      if (event?.type !== "session.created") return
      try {
        const { installed, latest } = await checkForUpdate()
        if (installed !== "unknown" && latest !== "unknown" && installed !== latest) {
          const message = `opencode-dev-skills has a newer commit on GitHub (${latest.slice(0, 12)}). Update: clear the plugin cache and restart OpenCode.`
          await notify(client, message)
          if (process.env.OPENCODE_DEV_SKILLS_AUTO_UPDATE === "1") await clearPluginCache(client)
        }
      } catch (error) {
        await log(client, "warn", `Update check failed: ${String(error)}`)
      }
    },
    "experimental.chat.messages.transform": async (_input: any, output: any) => {
      if (!Array.isArray(output?.messages) || output.messages.length === 0) return
      const firstUser = output.messages.find((message: any) => message?.info?.role === "user")
      if (!firstUser?.parts?.length) return
      if (firstUser.parts.some((part: any) => part?.type === "text" && part.text?.includes("dev-orchestrator"))) return
      const firstPart = firstUser.parts[0]
      firstUser.parts.unshift({ ...firstPart, type: "text", text: bootstrap })
    },
  }
}
