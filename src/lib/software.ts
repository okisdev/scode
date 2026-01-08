import { homeDir } from '@tauri-apps/api/path';
import { exists } from '@tauri-apps/plugin-fs';
import { Plug } from 'lucide-react';
import type { ComponentType, SVGProps } from 'react';

import { ClaudeAiIcon } from '@/components/ui/svgs/claude-code';
import { Homebrew } from '@/components/ui/svgs/homebrew';

export type SoftwareMode = 'detect' | 'direct';

export interface Software {
  id: string;
  name: string;
  description: string;
  icon: ComponentType<SVGProps<SVGSVGElement>>;
  mode: SoftwareMode;
  detectPaths: string[]; // Only used when mode is 'detect'
}

export const SOFTWARE_LIST: Software[] = [
  {
    id: 'claude-code',
    name: 'Claude Code',
    description: 'Claude Code settings',
    icon: ClaudeAiIcon,
    mode: 'detect',
    detectPaths: ['~/.claude.json', '~/.claude/'],
  },
  {
    id: 'mcp',
    name: 'MCP',
    description: 'MCP servers',
    icon: Plug,
    mode: 'direct', // Always available, no detection needed
    detectPaths: [],
  },
  {
    id: 'homebrew',
    name: 'Homebrew',
    description: 'Homebrew packages',
    icon: Homebrew,
    mode: 'detect',
    detectPaths: ['/opt/homebrew', '/usr/local/Homebrew'],
  },
];

async function expandPath(path: string): Promise<string> {
  if (path.startsWith('~/')) {
    const home = await homeDir();
    // homeDir() may return path with trailing slash, ensure no double slashes
    const normalizedHome = home.endsWith('/') ? home.slice(0, -1) : home;
    return path.replace('~', normalizedHome);
  }
  return path;
}

export async function detectSoftware(software: Software): Promise<boolean> {
  // Direct mode: always available
  if (software.mode === 'direct') {
    return true;
  }

  // Detect mode: check if paths exist
  for (const path of software.detectPaths) {
    try {
      const expandedPath = await expandPath(path);
      if (await exists(expandedPath)) {
        return true;
      }
    } catch {}
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
