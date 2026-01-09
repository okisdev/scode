import { homeDir } from '@tauri-apps/api/path';
import { exists, readTextFile, writeTextFile } from '@tauri-apps/plugin-fs';

// ============================================================================
// Types
// ============================================================================

export type McpServerType = 'http' | 'sse' | 'stdio';

export interface HttpMcpServer {
  type: 'http' | 'sse';
  url: string;
  headers?: Record<string, string>;
}

export interface StdioMcpServer {
  type: 'stdio';
  command: string;
  args?: string[];
  env?: Record<string, string>;
}

export type McpServer = HttpMcpServer | StdioMcpServer;

export interface McpServersConfig {
  [name: string]: McpServer;
}

export interface ProjectMcpConfig {
  mcpServers?: McpServersConfig;
  enabledMcpjsonServers?: string[];
  disabledMcpjsonServers?: string[];
  [key: string]: unknown;
}

export interface McpServerEntry {
  name: string;
  config: McpServer;
  scope: 'global' | 'project';
  projectPath?: string;
}

interface ClaudeJson {
  mcpServers?: McpServersConfig;
  projects?: Record<string, ProjectMcpConfig>;
  [key: string]: unknown;
}

// ============================================================================
// Path Helpers
// ============================================================================

async function getClaudeJsonPath(): Promise<string> {
  const home = await homeDir();
  const normalizedHome = home.endsWith('/') ? home.slice(0, -1) : home;
  return `${normalizedHome}/.claude.json`;
}

// ============================================================================
// Core Read/Write Functions
// ============================================================================

async function loadClaudeJson(): Promise<ClaudeJson> {
  try {
    const path = await getClaudeJsonPath();
    const fileExists = await exists(path);
    if (!fileExists) {
      return {};
    }
    const content = await readTextFile(path);
    return JSON.parse(content) as ClaudeJson;
  } catch {
    return {};
  }
}

async function saveClaudeJson(config: ClaudeJson): Promise<void> {
  const path = await getClaudeJsonPath();
  await writeTextFile(path, JSON.stringify(config, null, 2));
}

// ============================================================================
// Global MCP Server Operations
// ============================================================================

export async function loadGlobalMcpServers(): Promise<McpServersConfig> {
  const claudeJson = await loadClaudeJson();
  return claudeJson.mcpServers ?? {};
}

export async function addGlobalMcpServer(
  name: string,
  config: McpServer
): Promise<void> {
  const claudeJson = await loadClaudeJson();
  const mcpServers = claudeJson.mcpServers ?? {};
  mcpServers[name] = config;
  claudeJson.mcpServers = mcpServers;
  await saveClaudeJson(claudeJson);
}

export async function updateGlobalMcpServer(
  name: string,
  config: McpServer
): Promise<void> {
  const claudeJson = await loadClaudeJson();
  const mcpServers = claudeJson.mcpServers ?? {};
  if (!(name in mcpServers)) {
    throw new Error(`MCP server "${name}" not found`);
  }
  mcpServers[name] = config;
  claudeJson.mcpServers = mcpServers;
  await saveClaudeJson(claudeJson);
}

export async function removeGlobalMcpServer(name: string): Promise<void> {
  const claudeJson = await loadClaudeJson();
  const mcpServers = claudeJson.mcpServers ?? {};
  if (!(name in mcpServers)) {
    throw new Error(`MCP server "${name}" not found`);
  }
  delete mcpServers[name];
  claudeJson.mcpServers = mcpServers;
  await saveClaudeJson(claudeJson);
}

// ============================================================================
// Project MCP Server Operations
// ============================================================================

export async function loadProjectMcpServers(
  projectPath: string
): Promise<McpServersConfig> {
  const claudeJson = await loadClaudeJson();
  const projects = claudeJson.projects ?? {};
  const project = projects[projectPath] ?? {};
  return project.mcpServers ?? {};
}

export async function addProjectMcpServer(
  projectPath: string,
  name: string,
  config: McpServer
): Promise<void> {
  const claudeJson = await loadClaudeJson();
  const projects = claudeJson.projects ?? {};
  const project = projects[projectPath] ?? {};
  const mcpServers = project.mcpServers ?? {};

  mcpServers[name] = config;
  project.mcpServers = mcpServers;
  projects[projectPath] = project;
  claudeJson.projects = projects;

  await saveClaudeJson(claudeJson);
}

export async function updateProjectMcpServer(
  projectPath: string,
  name: string,
  config: McpServer
): Promise<void> {
  const claudeJson = await loadClaudeJson();
  const projects = claudeJson.projects ?? {};
  const project = projects[projectPath] ?? {};
  const mcpServers = project.mcpServers ?? {};

  if (!(name in mcpServers)) {
    throw new Error(
      `MCP server "${name}" not found in project "${projectPath}"`
    );
  }

  mcpServers[name] = config;
  project.mcpServers = mcpServers;
  projects[projectPath] = project;
  claudeJson.projects = projects;

  await saveClaudeJson(claudeJson);
}

export async function removeProjectMcpServer(
  projectPath: string,
  name: string
): Promise<void> {
  const claudeJson = await loadClaudeJson();
  const projects = claudeJson.projects ?? {};
  const project = projects[projectPath] ?? {};
  const mcpServers = project.mcpServers ?? {};

  if (!(name in mcpServers)) {
    throw new Error(
      `MCP server "${name}" not found in project "${projectPath}"`
    );
  }

  delete mcpServers[name];
  project.mcpServers = mcpServers;
  projects[projectPath] = project;
  claudeJson.projects = projects;

  await saveClaudeJson(claudeJson);
}

// ============================================================================
// Project List
// ============================================================================

export interface ProjectInfo {
  path: string;
  displayName: string;
  serverCount: number;
}

export async function listProjectsWithMcp(): Promise<ProjectInfo[]> {
  const claudeJson = await loadClaudeJson();
  const projects = claudeJson.projects ?? {};

  return Object.entries(projects)
    .filter(([, project]) => {
      const mcpServers = project.mcpServers ?? {};
      return Object.keys(mcpServers).length > 0;
    })
    .map(([path, project]) => {
      const mcpServers = project.mcpServers ?? {};
      const displayName = path.split('/').filter(Boolean).pop() ?? path;
      return {
        path,
        displayName,
        serverCount: Object.keys(mcpServers).length,
      };
    })
    .sort((a, b) => a.displayName.localeCompare(b.displayName));
}

export async function listAllProjects(): Promise<string[]> {
  const claudeJson = await loadClaudeJson();
  const projects = claudeJson.projects ?? {};
  return Object.keys(projects).sort();
}

// ============================================================================
// Helpers
// ============================================================================

export function isHttpServer(server: McpServer): server is HttpMcpServer {
  return server.type === 'http' || server.type === 'sse';
}

export function isStdioServer(server: McpServer): server is StdioMcpServer {
  return server.type === 'stdio';
}

export function getServerTypeLabel(type: McpServerType): string {
  switch (type) {
    case 'http':
      return 'HTTP';
    case 'sse':
      return 'SSE';
    case 'stdio':
      return 'Stdio';
  }
}

export function getServerDescription(server: McpServer): string {
  if (isHttpServer(server)) {
    return server.url;
  }
  if (isStdioServer(server)) {
    const args = server.args?.join(' ') ?? '';
    return args ? `${server.command} ${args}` : server.command;
  }
  return '';
}
