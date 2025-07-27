# Gemini Configuration: Raspberry Pi 5 Project

**Session Initialization:**

- **Mandatory First Step:** At the beginning of any new session, read the `log.md` file to gain a complete understanding of the project's history, architecture, and current state before proceeding.

**Target Environment:**

- **Device:** Raspberry Pi 5
- **OS:** Ubuntu Server

**Execution Rules:**

- Do not execute shell commands unless the user instructs so.
- The user will manually copy and run all commands on the target device via a separate SSH session.
- My role is to provide commands as text/code blocks, not to execute them.

**Output Rules:**

- When providing a `kubectl` command, also provide its alias from the list at https://raw.githubusercontent.com/ahmetb/kubectl-aliases/refs/heads/master/.kubectl_aliases.
- Save any rules the user states into this `GEMINI.md` file.

**Kubernetes Rules:**

- **Manifest Convention:**
    - **Directory Structure:** `app/<namespace>/`
    - **File Name:** `<kind>.yaml` (e.g., `service-account.yaml`)
    - **Resource `metadata.name`:** `<namespace>-<kind>` (e.g., `kubernetes-dashboard-service-account`)
    - The `kind` should be kebab-case.