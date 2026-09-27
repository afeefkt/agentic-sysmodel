@echo off
REM Launch the agentic-sysmodel opencode team inside WSL (Ubuntu).
REM Usage: start-agent.bat            -> new session (default agent: sysarch)
REM        start-agent.bat -c         -> continue last session
REM        start-agent.bat -s <id>    -> resume a specific session
REM Reminder: start FreeCAD on Windows and click "Start RPC Server" first (for cad-designer).

title agentic-sysmodel (opencode / WSL)

REM Use the Linux opencode build explicitly: the Windows npm copy is also on the WSL PATH
REM and would start the MCP servers with Windows tools.
wsl.exe -d Ubuntu --cd "/mnt/d/AI_Learnigns/OMSysModeling/agentic-sysmodel" -- bash -lic "export PATH=\"$HOME/.opencode/bin:$HOME/.local/bin:$PATH\"; if [ -z \"$DEEPSEEK_API_KEY\" ]; then echo 'Note: DEEPSEEK_API_KEY not set - use /connect in opencode if not configured.'; fi; opencode %*; exec bash"
