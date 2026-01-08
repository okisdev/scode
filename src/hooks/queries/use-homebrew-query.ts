import { useQueries, useQuery } from '@tanstack/react-query';
import {
  getBrewInfo,
  getLogs,
  getOutdated,
  listCasks,
  listFormulae,
  listTaps,
  searchPackages,
} from '@/lib/homebrew';
import { queryKeys } from '@/lib/query-keys';

export function useBrewInfoQuery() {
  return useQuery({
    queryKey: queryKeys.homebrew.info(),
    queryFn: getBrewInfo,
  });
}

export function useFormulaeQuery() {
  return useQuery({
    queryKey: queryKeys.homebrew.formulae(),
    queryFn: listFormulae,
  });
}

export function useCasksQuery() {
  return useQuery({
    queryKey: queryKeys.homebrew.casks(),
    queryFn: listCasks,
  });
}

export function useOutdatedQuery() {
  return useQuery({
    queryKey: queryKeys.homebrew.outdated(),
    queryFn: getOutdated,
    staleTime: 2 * 60 * 1000, // 2 minutes
  });
}

export function useTapsQuery() {
  return useQuery({
    queryKey: queryKeys.homebrew.taps(),
    queryFn: listTaps,
  });
}

export function useHomebrewLogsQuery(limit = 50) {
  return useQuery({
    queryKey: queryKeys.homebrew.logs(),
    queryFn: () => getLogs('homebrew', limit),
  });
}

export function useHomebrewSearchQuery(query: string, isCask: boolean) {
  return useQuery({
    queryKey: queryKeys.homebrew.search(query, isCask),
    queryFn: () => searchPackages(query, isCask),
    enabled: query.trim().length > 0,
    staleTime: 30 * 1000, // 30 seconds
    gcTime: 60 * 1000, // 1 minute
  });
}

export function useHomebrewDataQuery() {
  const results = useQueries({
    queries: [
      { queryKey: queryKeys.homebrew.info(), queryFn: getBrewInfo },
      { queryKey: queryKeys.homebrew.formulae(), queryFn: listFormulae },
      { queryKey: queryKeys.homebrew.casks(), queryFn: listCasks },
      { queryKey: queryKeys.homebrew.outdated(), queryFn: getOutdated },
      { queryKey: queryKeys.homebrew.taps(), queryFn: listTaps },
    ],
  });

  const [infoQuery, formulaeQuery, casksQuery, outdatedQuery, tapsQuery] =
    results;

  return {
    info: infoQuery.data ?? null,
    formulae: formulaeQuery.data ?? [],
    casks: casksQuery.data ?? [],
    outdated: outdatedQuery.data ?? [],
    taps: tapsQuery.data ?? [],
    loading: results.some((r) => r.isLoading),
    error: results.find((r) => r.error)?.error?.message ?? null,
    // 返回 refetch 函数供手动刷新
    refetchAll: () => Promise.all(results.map((r) => r.refetch())),
  };
}
