import { invoke } from '@tauri-apps/api/core';

export interface BrewInfo {
  version: string;
  prefix: string;
  formulae_count: number;
  cask_count: number;
  outdated_count: number;
}

export interface Package {
  name: string;
  version: string;
  description?: string;
  installed: boolean;
  outdated: boolean;
  current_version?: string;
  latest_version?: string;
}

export interface Cask {
  name: string;
  version: string;
  description?: string;
  installed: boolean;
  outdated: boolean;
  icon?: string;
}

export interface Tap {
  name: string;
  official: boolean;
  remote?: string;
}

export interface LogEntry {
  timestamp: string;
  category: string;
  action: string;
  target: string;
  success: boolean;
  output: string;
}

// Logging commands
export async function getLogs(
  category: string,
  limit?: number
): Promise<LogEntry[]> {
  return invoke<LogEntry[]>('get_logs', { category, limit });
}

export async function clearLogs(category: string): Promise<void> {
  return invoke<void>('clear_logs', { category });
}

// Homebrew commands
export async function getBrewInfo(): Promise<BrewInfo> {
  return invoke<BrewInfo>('brew_info');
}

export async function listFormulae(): Promise<Package[]> {
  return invoke<Package[]>('brew_list_formulae');
}

export async function listCasks(): Promise<Cask[]> {
  return invoke<Cask[]>('brew_list_casks');
}

export async function getOutdated(): Promise<Package[]> {
  return invoke<Package[]>('brew_outdated');
}

export async function listTaps(): Promise<Tap[]> {
  return invoke<Tap[]>('brew_list_taps');
}

export async function searchPackages(
  query: string,
  isCask: boolean
): Promise<Package[]> {
  return invoke<Package[]>('brew_search', { query, isCask });
}

export async function installPackage(
  name: string,
  isCask: boolean
): Promise<string> {
  return invoke<string>('brew_install', { name, isCask });
}

export async function uninstallPackage(
  name: string,
  isCask: boolean
): Promise<string> {
  return invoke<string>('brew_uninstall', { name, isCask });
}

export async function upgradePackage(name: string): Promise<string> {
  return invoke<string>('brew_upgrade', { name });
}

export async function updateBrew(): Promise<string> {
  return invoke<string>('brew_update');
}

export async function upgradeAll(): Promise<string> {
  return invoke<string>('brew_upgrade_all');
}

export async function cleanupBrew(): Promise<string> {
  return invoke<string>('brew_cleanup');
}

export async function brewDoctor(): Promise<string> {
  return invoke<string>('brew_doctor');
}

export async function addTap(name: string): Promise<string> {
  return invoke<string>('brew_tap', { name });
}

export async function removeTap(name: string): Promise<string> {
  return invoke<string>('brew_untap', { name });
}
