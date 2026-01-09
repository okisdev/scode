import type { LucideIcon } from 'lucide-react';

// Route type - hierarchical paths separated by /
export type Route =
  | 'home'
  | 'claude-code/usage'
  | 'claude-code/general'
  | 'claude-code/mcp'
  | 'claude-code/plugins'
  | 'homebrew/overview'
  | 'homebrew/formulae'
  | 'homebrew/casks'
  | 'homebrew/updates'
  | 'homebrew/taps'
  | 'homebrew/logs'
  | 'mcp'
  | 'settings';

export interface NavSection {
  id: string;
  label: string;
}

export interface NavGroup {
  id: string;
  label: string;
  icon: LucideIcon;
  sections: NavSection[];
  defaultSection: string;
}

export const CLAUDE_CODE_SECTIONS: NavSection[] = [
  { id: 'usage', label: 'Usage' },
  { id: 'general', label: 'General' },
  { id: 'mcp', label: 'MCP' },
  { id: 'plugins', label: 'Plugins' },
];

export const HOMEBREW_SECTIONS: NavSection[] = [
  { id: 'overview', label: 'Overview' },
  { id: 'formulae', label: 'Formulae' },
  { id: 'casks', label: 'Casks' },
  { id: 'updates', label: 'Updates' },
  { id: 'taps', label: 'Taps' },
  { id: 'logs', label: 'Logs' },
];

// Helper to get group ID from route
export function getGroupFromRoute(route: Route): string | null {
  if (route.includes('/')) {
    return route.split('/')[0];
  }
  return null;
}

// Helper to check if route belongs to a group
export function isRouteInGroup(route: Route, groupId: string): boolean {
  return route.startsWith(`${groupId}/`);
}

// Helper to get default route for a group
export function getDefaultRoute(groupId: string): Route {
  switch (groupId) {
    case 'claude-code':
      return 'claude-code/usage';
    case 'homebrew':
      return 'homebrew/overview';
    default:
      return 'home';
  }
}

// Get sections for a software ID
export function getSectionsForSoftware(
  softwareId: string
): NavSection[] | null {
  switch (softwareId) {
    case 'claude-code':
      return CLAUDE_CODE_SECTIONS;
    case 'homebrew':
      return HOMEBREW_SECTIONS;
    default:
      return null;
  }
}
