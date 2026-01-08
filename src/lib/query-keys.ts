export const queryKeys = {
  // Software
  software: {
    all: ['software'] as const,
    installed: () => [...queryKeys.software.all, 'installed'] as const,
  },

  // Homebrew
  homebrew: {
    all: ['homebrew'] as const,
    info: () => [...queryKeys.homebrew.all, 'info'] as const,
    formulae: () => [...queryKeys.homebrew.all, 'formulae'] as const,
    casks: () => [...queryKeys.homebrew.all, 'casks'] as const,
    outdated: () => [...queryKeys.homebrew.all, 'outdated'] as const,
    taps: () => [...queryKeys.homebrew.all, 'taps'] as const,
    logs: () => [...queryKeys.homebrew.all, 'logs'] as const,
    search: (query: string, isCask: boolean) =>
      [...queryKeys.homebrew.all, 'search', { query, isCask }] as const,
  },

  // MCP Servers
  mcp: {
    all: ['mcp'] as const,
    servers: () => [...queryKeys.mcp.all, 'servers'] as const,
    globalServers: () => [...queryKeys.mcp.servers(), 'global'] as const,
    projectServers: (projectPath: string) =>
      [...queryKeys.mcp.servers(), 'project', projectPath] as const,
  },

  // Claude Code
  claudeCode: {
    all: ['claude-code'] as const,
    config: () => [...queryKeys.claudeCode.all, 'config'] as const,
    settings: () => [...queryKeys.claudeCode.all, 'settings'] as const,
    localSettings: () =>
      [...queryKeys.claudeCode.all, 'local-settings'] as const,
  },
} as const;
