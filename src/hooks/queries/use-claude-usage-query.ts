import { useQuery } from '@tanstack/react-query';

import {
  getDailyUsage,
  getModelUsage,
  getProjectUsage,
  getRecentUsage,
  getSessionUsage,
  getUsageSummary,
} from '@/lib/claude-usage';
import { queryKeys } from '@/lib/query-keys';

export function useUsageSummaryQuery() {
  return useQuery({
    queryKey: queryKeys.claudeCode.usageSummary(),
    queryFn: getUsageSummary,
    staleTime: 30 * 1000, // 30 seconds
  });
}

export function useDailyUsageQuery(days?: number) {
  return useQuery({
    queryKey: queryKeys.claudeCode.dailyUsage(days),
    queryFn: () => getDailyUsage(days),
    staleTime: 60 * 1000, // 1 minute
  });
}

export function useSessionUsageQuery() {
  return useQuery({
    queryKey: queryKeys.claudeCode.sessionUsage(),
    queryFn: getSessionUsage,
    staleTime: 30 * 1000, // 30 seconds
  });
}

export function useRecentUsageQuery(minutes?: number, enabled = true) {
  return useQuery({
    queryKey: queryKeys.claudeCode.recentUsage(minutes),
    queryFn: () => getRecentUsage(minutes),
    staleTime: 5 * 1000, // 5 seconds
    refetchInterval: enabled ? 5 * 1000 : false, // Poll every 5 seconds when enabled
    enabled,
  });
}

export function useProjectUsageQuery() {
  return useQuery({
    queryKey: queryKeys.claudeCode.projectUsage(),
    queryFn: getProjectUsage,
    staleTime: 30 * 1000, // 30 seconds
  });
}

export function useModelUsageQuery() {
  return useQuery({
    queryKey: queryKeys.claudeCode.modelUsage(),
    queryFn: getModelUsage,
    staleTime: 30 * 1000, // 30 seconds
  });
}

// Get usage entries for session blocks (last 7 days = 10080 minutes)
export function useBlocksUsageQuery() {
  return useQuery({
    queryKey: queryKeys.claudeCode.recentUsage(10_080),
    queryFn: () => getRecentUsage(10_080),
    staleTime: 30 * 1000, // 30 seconds
  });
}
