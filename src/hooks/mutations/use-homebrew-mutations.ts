import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import {
  addTap,
  brewDoctor,
  cleanupBrew,
  clearLogs,
  installPackage,
  removeTap,
  uninstallPackage,
  updateBrew,
  upgradeAll,
  upgradePackage,
} from '@/lib/homebrew';
import { queryKeys } from '@/lib/query-keys';

export function useInstallPackage() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ name, isCask }: { name: string; isCask: boolean }) =>
      installPackage(name, isCask),
    onMutate: ({ name }) => {
      return toast.loading(`Installing ${name}...`);
    },
    onSuccess: (_, { name, isCask }, toastId) => {
      if (isCask) {
        queryClient.invalidateQueries({ queryKey: queryKeys.homebrew.casks() });
      } else {
        queryClient.invalidateQueries({
          queryKey: queryKeys.homebrew.formulae(),
        });
      }
      queryClient.invalidateQueries({ queryKey: queryKeys.homebrew.info() });
      queryClient.invalidateQueries({ queryKey: queryKeys.homebrew.logs() });
      toast.success(`${name} installed`, { id: toastId });
    },
    onError: (error, { name }, toastId) => {
      toast.error(`Failed to install ${name}`, {
        id: toastId,
        description: error instanceof Error ? error.message : 'Unknown error',
      });
    },
  });
}

export function useUninstallPackage() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ name, isCask }: { name: string; isCask: boolean }) =>
      uninstallPackage(name, isCask),
    onMutate: ({ name }) => {
      return toast.loading(`Uninstalling ${name}...`);
    },
    onSuccess: (_, { name, isCask }, toastId) => {
      if (isCask) {
        queryClient.invalidateQueries({ queryKey: queryKeys.homebrew.casks() });
      } else {
        queryClient.invalidateQueries({
          queryKey: queryKeys.homebrew.formulae(),
        });
      }
      queryClient.invalidateQueries({ queryKey: queryKeys.homebrew.info() });
      queryClient.invalidateQueries({ queryKey: queryKeys.homebrew.logs() });
      toast.success(`${name} uninstalled`, { id: toastId });
    },
    onError: (error, { name }, toastId) => {
      toast.error(`Failed to uninstall ${name}`, {
        id: toastId,
        description: error instanceof Error ? error.message : 'Unknown error',
      });
    },
  });
}

export function useUpgradePackage() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (name: string) => upgradePackage(name),
    onMutate: (name) => {
      return toast.loading(`Upgrading ${name}...`);
    },
    onSuccess: (_, name, toastId) => {
      queryClient.invalidateQueries({
        queryKey: queryKeys.homebrew.formulae(),
      });
      queryClient.invalidateQueries({ queryKey: queryKeys.homebrew.casks() });
      queryClient.invalidateQueries({
        queryKey: queryKeys.homebrew.outdated(),
      });
      queryClient.invalidateQueries({ queryKey: queryKeys.homebrew.info() });
      queryClient.invalidateQueries({ queryKey: queryKeys.homebrew.logs() });
      toast.success(`${name} upgraded`, { id: toastId });
    },
    onError: (error, name, toastId) => {
      toast.error(`Failed to upgrade ${name}`, {
        id: toastId,
        description: error instanceof Error ? error.message : 'Unknown error',
      });
    },
  });
}

export function useUpdateBrew() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: updateBrew,
    onMutate: () => {
      return toast.loading('Updating Homebrew...');
    },
    onSuccess: (output, _, toastId) => {
      queryClient.invalidateQueries({ queryKey: queryKeys.homebrew.all });
      const isUpToDate =
        output.includes('Already up-to-date') ||
        output.includes('already up-to-date');
      if (isUpToDate) {
        toast.info('Already up-to-date', { id: toastId });
      } else {
        toast.success('Homebrew updated', { id: toastId });
      }
    },
    onError: (error, _, toastId) => {
      toast.error('Failed to update Homebrew', {
        id: toastId,
        description: error instanceof Error ? error.message : 'Unknown error',
      });
    },
  });
}

export function useUpgradeAll() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: upgradeAll,
    onMutate: () => {
      return toast.loading('Upgrading all packages...');
    },
    onSuccess: (_, __, toastId) => {
      queryClient.invalidateQueries({ queryKey: queryKeys.homebrew.all });
      toast.success('All packages upgraded', { id: toastId });
    },
    onError: (error, _, toastId) => {
      toast.error('Failed to upgrade packages', {
        id: toastId,
        description: error instanceof Error ? error.message : 'Unknown error',
      });
    },
  });
}

export function useCleanupBrew() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: cleanupBrew,
    onMutate: () => {
      return toast.loading('Cleaning up...');
    },
    onSuccess: (_, __, toastId) => {
      queryClient.invalidateQueries({ queryKey: queryKeys.homebrew.info() });
      queryClient.invalidateQueries({ queryKey: queryKeys.homebrew.logs() });
      toast.success('Cleanup completed', { id: toastId });
    },
    onError: (error, _, toastId) => {
      toast.error('Failed to cleanup', {
        id: toastId,
        description: error instanceof Error ? error.message : 'Unknown error',
      });
    },
  });
}

export function useBrewDoctor() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: brewDoctor,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.homebrew.logs() });
    },
  });
}

export function useAddTap() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (name: string) => addTap(name),
    onMutate: (name) => {
      return toast.loading(`Adding tap ${name}...`);
    },
    onSuccess: (_, name, toastId) => {
      queryClient.invalidateQueries({ queryKey: queryKeys.homebrew.taps() });
      queryClient.invalidateQueries({ queryKey: queryKeys.homebrew.logs() });
      toast.success(`Tap ${name} added`, { id: toastId });
    },
    onError: (error, name, toastId) => {
      toast.error(`Failed to add tap ${name}`, {
        id: toastId,
        description: error instanceof Error ? error.message : 'Unknown error',
      });
    },
  });
}

export function useRemoveTap() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (name: string) => removeTap(name),
    onMutate: (name) => {
      return toast.loading(`Removing tap ${name}...`);
    },
    onSuccess: (_, name, toastId) => {
      queryClient.invalidateQueries({ queryKey: queryKeys.homebrew.taps() });
      queryClient.invalidateQueries({ queryKey: queryKeys.homebrew.logs() });
      toast.success(`Tap ${name} removed`, { id: toastId });
    },
    onError: (error, name, toastId) => {
      toast.error(`Failed to remove tap ${name}`, {
        id: toastId,
        description: error instanceof Error ? error.message : 'Unknown error',
      });
    },
  });
}

export function useClearLogs() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () => clearLogs('homebrew'),
    onSuccess: () => {
      queryClient.setQueryData(queryKeys.homebrew.logs(), []);
      toast.success('Logs cleared');
    },
    onError: (error) => {
      toast.error('Failed to clear logs', {
        description: error instanceof Error ? error.message : 'Unknown error',
      });
    },
  });
}
