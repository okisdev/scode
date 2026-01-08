import { homeDir } from '@tauri-apps/api/path';
import { exists } from '@tauri-apps/plugin-fs';
import { Beer, type LucideIcon, Plug, Terminal } from 'lucide-react';

export interface Software {
  id: string;
  name: string;
  description: string;
  icon: LucideIcon;
  detectPaths: string[];
}

export const SOFTWARE_LIST: Software[] = [
  {
    id: 'claude-code',
    name: 'Claude Code',
    description: 'Claude Code settings',
    icon: Terminal,
    detectPaths: ['~/.claude.json', '~/.claude/'],
  },
  {
    id: 'mcp',
    name: 'MCP',
    description: 'MCP servers',
    icon: Plug,
    detectPaths: [], // Always available if Claude Code exists
  },
  {
    id: 'homebrew',
    name: 'Homebrew',
    description: 'Homebrew packages',
    icon: Beer,
    detectPaths: ['/opt/homebrew', '/usr/local/Homebrew'],
  },
];

async function expandPath(path: string): Promise<string> {
  if (path.startsWith('~/')) {
    const home = await homeDir();
    return path.replace('~/', home);
  }
  return path;
}

export async function detectSoftware(software: Software): Promise<boolean> {
  // MCP is available if Claude Code is detected
  if (software.id === 'mcp') {
    const claudeCode = SOFTWARE_LIST.find((s) => s.id === 'claude-code');
    if (claudeCode) {
      return detectSoftware(claudeCode);
    }
    return false;
  }

  if (software.detectPaths.length === 0) {
    return true;
  }

  for (const path of software.detectPaths) {
    const expandedPath = await expandPath(path);
    if (await exists(expandedPath)) {
      return true;
    }
  }
  return false;
}

export async function getInstalledSoftware(): Promise<Software[]> {
  const results = await Promise.all(
    SOFTWARE_LIST.map(async (software) => ({
      software,
      installed: await detectSoftware(software),
    }))
  );

  return results.filter((r) => r.installed).map((r) => r.software);
}
