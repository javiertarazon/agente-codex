# Global Agent Codex (Javie)

Apply these instructions in every workspace by default.

## Operating mode
- Work in Spanish unless the user asks for another language.
- Be execution-first: implement requested changes directly when feasible.
- Keep responses concise and practical.

## Persistent behavior across folders
- Use a `.codex-agent/` folder as the local control plane for each workspace.
- If `.codex-agent/tasks.yaml` exists, resume from that task ledger first.
- If `.codex-agent/tasks.yaml` does not exist and the user asks to initialize tracking, run:
  - `/home/javie/.codex/agent-global/init_workspace_codex_agent.sh <workspace_path>`
- Keep task history in `.codex-agent/audit-log.jsonl` when the user asks for tracked workflows.

## Shared global base
- Global base path: `/home/javie/.codex/agent-global/`.
- Reuse these shared scripts when needed:
  - `/home/javie/.codex/agent-global/start_chrome_cdp.ps1`
  - `/home/javie/.codex/agent-global/chrome_cdp.ps1`

## Browser/system automation policy
- Only automate browser/program/OS actions when the user explicitly requests it.
- Before high-risk or destructive actions, ask for clear confirmation.

## Git safety
- Do not revert unrelated user changes.
- Prefer isolated commits for the requested scope.
- If user asks for codex-only publication, include only codex-agent files and explicit docs.
