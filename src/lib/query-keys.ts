export const queryKeys = {
  // Scode app config
  scode: {
    all: ['scode'] as const,
    config: () => [...queryKeys.scode.all, 'config'] as const,
  },

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
    projects: () => [...queryKeys.mcp.all, 'projects'] as const,
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
    // Usage
    usage: () => [...queryKeys.claudeCode.all, 'usage'] as const,
    usageSummary: () => [...queryKeys.claudeCode.usage(), 'summary'] as const,
    dailyUsage: (days?: number) =>
      [...queryKeys.claudeCode.usage(), 'daily', { days }] as const,
    sessionUsage: () => [...queryKeys.claudeCode.usage(), 'sessions'] as const,
    recentUsage: (minutes?: number) =>
      [...queryKeys.claudeCode.usage(), 'recent', { minutes }] as const,
    projectUsage: () => [...queryKeys.claudeCode.usage(), 'projects'] as const,
    modelUsage: () => [...queryKeys.claudeCode.usage(), 'models'] as const,
  },
} as const;
