import { useQueryClient } from '@tanstack/react-query';
import { useCallback } from 'react';

import { queryKeys } from '@/lib/query-keys';

import {
  useBlocksUsageQuery,
  useDailyUsageQuery,
  useModelUsageQuery,
  useProjectUsageQuery,
} from './queries/use-claude-usage-query';

export function useClaudeUsage() {
  const queryClient = useQueryClient();

  // Fetch 2 years of data to support year navigation
  const dailyQuery = useDailyUsageQuery(730);
  const modelQuery = useModelUsageQuery();
  const blocksQuery = useBlocksUsageQuery();
  const projectQuery = useProjectUsageQuery();

  const isLoading =
    dailyQuery.isLoading ||
    modelQuery.isLoading ||
    blocksQuery.isLoading ||
    projectQuery.isLoading;

  const error =
    dailyQuery.error ||
    modelQuery.error ||
    blocksQuery.error ||
    projectQuery.error;

  const refresh = useCallback(() => {
    queryClient.invalidateQueries({ queryKey: queryKeys.claudeCode.usage() });
  }, [queryClient]);

  return {
    daily: dailyQuery.data ?? [],
    models: modelQuery.data ?? [],
    projects: projectQuery.data ?? [],
    blocksEntries: blocksQuery.data ?? [],
    isLoading,
    error,
    refresh,
  };
}
