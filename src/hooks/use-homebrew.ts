import { useQueryClient } from '@tanstack/react-query';
import { useCallback, useState } from 'react';
import { queryKeys } from '@/lib/query-keys';
import {
  useAddTap,
  useBrewDoctor,
  useCleanupBrew,
  useClearLogs,
  useInstallPackage,
  useRemoveTap,
  useUninstallPackage,
  useUpdateBrew,
  useUpgradeAll,
  useUpgradePackage,
} from './mutations/use-homebrew-mutations';
import {
  useHomebrewDataQuery,
  useHomebrewLogsQuery,
  useHomebrewSearchQuery,
} from './queries/use-homebrew-query';

export function useHomebrew() {
  const queryClient = useQueryClient();

  const [searchQuery, setSearchQuery] = useState('');
  const [searchIsCask, setSearchIsCask] = useState(false);

  // Queries
  const { info, formulae, casks, outdated, taps, loading, error, refetchAll } =
    useHomebrewDataQuery();
  const { data: logs = [] } = useHomebrewLogsQuery();
  const { data: searchResults = [], isLoading: searching } =
    useHomebrewSearchQuery(searchQuery, searchIsCask);

  // Mutations
  const installMutation = useInstallPackage();
  const uninstallMutation = useUninstallPackage();
  const upgradeMutation = useUpgradePackage();
  const updateMutation = useUpdateBrew();
  const upgradeAllMutation = useUpgradeAll();
  const cleanupMutation = useCleanupBrew();
  const doctorMutation = useBrewDoctor();
  const addTapMutation = useAddTap();
  const removeTapMutation = useRemoveTap();
  const clearLogsMutation = useClearLogs();

  const operating =
    installMutation.isPending ||
    uninstallMutation.isPending ||
    upgradeMutation.isPending ||
    updateMutation.isPending ||
    upgradeAllMutation.isPending ||
    cleanupMutation.isPending ||
    doctorMutation.isPending ||
    addTapMutation.isPending ||
    removeTapMutation.isPending;

  const operatingStates = {
    updating: updateMutation.isPending,
    upgradingAll: upgradeAllMutation.isPending,
    cleaningUp: cleanupMutation.isPending,
    doctoring: doctorMutation.isPending,
  };

  const refresh = useCallback(async () => {
    await refetchAll();
  }, [refetchAll]);

  const search = useCallback((query: string, isCask: boolean) => {
    setSearchQuery(query);
    setSearchIsCask(isCask);
  }, []);

  const clearSearch = useCallback(() => {
    setSearchQuery('');
  }, []);

  const install = useCallback(
    async (name: string, isCask: boolean) => {
      await installMutation.mutateAsync({ name, isCask });
    },
    [installMutation]
  );

  const uninstall = useCallback(
    async (name: string, isCask: boolean) => {
      await uninstallMutation.mutateAsync({ name, isCask });
    },
    [uninstallMutation]
  );

  const upgrade = useCallback(
    async (name: string) => {
      await upgradeMutation.mutateAsync(name);
    },
    [upgradeMutation]
  );

  const update = useCallback(async () => {
    await updateMutation.mutateAsync();
  }, [updateMutation]);

  const upgradeAllPackages = useCallback(async () => {
    await upgradeAllMutation.mutateAsync();
  }, [upgradeAllMutation]);

  const cleanup = useCallback(async () => {
    await cleanupMutation.mutateAsync();
  }, [cleanupMutation]);

  const doctor = useCallback(async () => {
    return await doctorMutation.mutateAsync();
  }, [doctorMutation]);

  const tapRepo = useCallback(
    async (name: string) => {
      await addTapMutation.mutateAsync(name);
    },
    [addTapMutation]
  );

  const untapRepo = useCallback(
    async (name: string) => {
      await removeTapMutation.mutateAsync(name);
    },
    [removeTapMutation]
  );

  const refreshLogs = useCallback(async () => {
    await queryClient.invalidateQueries({
      queryKey: queryKeys.homebrew.logs(),
    });
  }, [queryClient]);

  const clearAllLogs = useCallback(async () => {
    await clearLogsMutation.mutateAsync();
  }, [clearLogsMutation]);

  return {
    // Data
    info,
    formulae,
    casks,
    outdated,
    taps,
    searchResults,
    logs,
    // Loading states
    loading,
    operating,
    operatingStates,
    searching,
    // Error
    error,
    // Actions
    refresh,
    search,
    clearSearch,
    install,
    uninstall,
    upgrade,
    update,
    upgradeAllPackages,
    cleanup,
    doctor,
    tapRepo,
    untapRepo,
    refreshLogs,
    clearAllLogs,
  };
}
