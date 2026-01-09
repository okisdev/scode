import { invoke } from '@tauri-apps/api/core';

// ============================================================================
// Types
// ============================================================================

export interface UsageEntry {
  timestamp: string;
  session_id: string;
  model: string;
  input_tokens: number;
  output_tokens: number;
  cache_creation_tokens: number;
  cache_read_tokens: number;
  cost_usd: number;
  project_path: string;
}

export interface DailyUsage {
  date: string;
  input_tokens: number;
  output_tokens: number;
  cache_creation_tokens: number;
  cache_read_tokens: number;
  total_cost: number;
  models_used: string[];
  request_count: number;
}

export interface SessionUsage {
  session_id: string;
  project_path: string;
  project_display_name: string;
  project_full_path: string;
  input_tokens: number;
  output_tokens: number;
  cache_creation_tokens: number;
  cache_read_tokens: number;
  total_cost: number;
  last_activity: string;
  request_count: number;
  models_used: string[];
}

export interface ProjectUsage {
  project_path: string;
  display_name: string;
  full_path: string;
  session_count: number;
  input_tokens: number;
  output_tokens: number;
  cache_creation_tokens: number;
  cache_read_tokens: number;
  total_cost: number;
  request_count: number;
  last_activity: string;
  models_used: string[];
}

export interface ModelUsage {
  model: string;
  display_name: string;
  input_tokens: number;
  output_tokens: number;
  total_cost: number;
  request_count: number;
  percentage: number;
}

export interface UsageSummary {
  total_input_tokens: number;
  total_output_tokens: number;
  total_cache_creation_tokens: number;
  total_cache_read_tokens: number;
  total_cost: number;
  total_requests: number;
  session_count: number;
  project_count: number;
}

// ============================================================================
// Tauri Invoke Wrappers
// ============================================================================

export async function getUsageSummary(): Promise<UsageSummary> {
  return invoke<UsageSummary>('get_usage_summary');
}

export async function getDailyUsage(days?: number): Promise<DailyUsage[]> {
  return invoke<DailyUsage[]>('get_daily_usage', { days });
}

export async function getSessionUsage(): Promise<SessionUsage[]> {
  return invoke<SessionUsage[]>('get_session_usage');
}

export async function getRecentUsage(minutes?: number): Promise<UsageEntry[]> {
  return invoke<UsageEntry[]>('get_recent_usage', { minutes });
}

export async function getProjectUsage(): Promise<ProjectUsage[]> {
  return invoke<ProjectUsage[]>('get_project_usage');
}

export async function getModelUsage(): Promise<ModelUsage[]> {
  return invoke<ModelUsage[]>('get_model_usage');
}

// ============================================================================
// Path Utilities
// ============================================================================

/**
 * Check if a path looks like an encoded absolute path
 * Encoded paths start with `-` followed by common root directories
 */
function isEncodedAbsolutePath(path: string): boolean {
  if (!path.startsWith('-')) {
    return false;
  }
  const lower = path.toLowerCase();
  return (
    lower.startsWith('-users-') ||
    lower.startsWith('-home-') ||
    lower.startsWith('-var-') ||
    lower.startsWith('-tmp-') ||
    lower.startsWith('-opt-') ||
    lower.startsWith('-usr-') ||
    lower.startsWith('-private-')
  );
}

/**
 * Decode Claude project path name
 * "-Users-Shared-GitHub-scode" → "/Users/Shared/GitHub/scode"
 * Only decodes paths that look like encoded absolute paths
 */
export function decodeProjectPath(encoded: string): string {
  if (isEncodedAbsolutePath(encoded)) {
    return encoded.replace(/-/g, '/');
  }
  return encoded;
}

/**
 * Get project display name (last part of path)
 */
export function getProjectDisplayName(encoded: string): string {
  const decoded = decodeProjectPath(encoded);
  const parts = decoded.split('/').filter((s) => s.length > 0);
  // biome-ignore lint/style/useAtIndex: tsconfig uses es2021
  return parts[parts.length - 1] || encoded;
}

// ============================================================================
// Formatting Utilities
// ============================================================================

export function formatTokens(tokens: number): string {
  if (tokens >= 1_000_000) {
    return `${(tokens / 1_000_000).toFixed(2)}M`;
  }
  if (tokens >= 1000) {
    return `${(tokens / 1000).toFixed(1)}K`;
  }
  return tokens.toString();
}

export function formatCost(cost: number): string {
  if (cost >= 1) {
    return `$${cost.toFixed(2)}`;
  }
  if (cost >= 0.01) {
    return `$${cost.toFixed(3)}`;
  }
  return `$${cost.toFixed(4)}`;
}

export function formatRelativeTime(timestamp: string): string {
  const date = new Date(timestamp);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60_000);
  const diffHours = Math.floor(diffMs / 3_600_000);
  const diffDays = Math.floor(diffMs / 86_400_000);

  if (diffMins < 1) {
    return 'just now';
  }
  if (diffMins < 60) {
    return `${diffMins}m ago`;
  }
  if (diffHours < 24) {
    return `${diffHours}h ago`;
  }
  if (diffDays < 7) {
    return `${diffDays}d ago`;
  }
  return date.toLocaleDateString();
}

export function getTotalTokens(usage: {
  input_tokens: number;
  output_tokens: number;
  cache_creation_tokens?: number;
  cache_read_tokens?: number;
}): number {
  return (
    usage.input_tokens +
    usage.output_tokens +
    (usage.cache_creation_tokens ?? 0) +
    (usage.cache_read_tokens ?? 0)
  );
}

export function getModelDisplayName(model: string): string {
  // Check more specific patterns first (e.g., opus-4-5 before opus-4)
  if (model.includes('opus-4-5')) {
    return 'Opus 4.5';
  }
  if (model.includes('sonnet-4-5')) {
    return 'Sonnet 4.5';
  }
  if (model.includes('opus-4')) {
    return 'Opus 4';
  }
  if (model.includes('sonnet-4')) {
    return 'Sonnet 4';
  }
  if (model.includes('3-5-sonnet') || model.includes('3.5-sonnet')) {
    return 'Sonnet 3.5';
  }
  if (model.includes('3-5-haiku') || model.includes('3.5-haiku')) {
    return 'Haiku 3.5';
  }
  if (model.includes('3-opus')) {
    return 'Opus 3';
  }
  if (model.includes('3-sonnet')) {
    return 'Sonnet 3';
  }
  if (model.includes('3-haiku')) {
    return 'Haiku 3';
  }
  return model;
}
