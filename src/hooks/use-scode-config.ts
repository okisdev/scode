import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { queryKeys } from '@/lib/query-keys';
import {
  loadConfig,
  type ScodeConfig,
  toggleSoftwareEnabled,
} from '@/lib/scode-config';

export function useScodeConfig() {
  const queryClient = useQueryClient();

  const { data: config } = useQuery<ScodeConfig>({
    queryKey: queryKeys.scode.config(),
    queryFn: loadConfig,
    staleTime: Number.POSITIVE_INFINITY,
  });

  const toggleMutation = useMutation({
    mutationFn: ({
      softwareId,
      enabled,
    }: {
      softwareId: string;
      enabled: boolean;
    }) => toggleSoftwareEnabled(softwareId, enabled),
    onSuccess: (newConfig) => {
      queryClient.setQueryData(queryKeys.scode.config(), newConfig);
    },
    onError: (error) => {
      console.error('Failed to toggle software:', error);
    },
  });

  return {
    config: config ?? { enabledSoftware: [] },
    toggleEnabled: (softwareId: string, enabled: boolean) =>
      toggleMutation.mutate({ softwareId, enabled }),
    isToggling: toggleMutation.isPending,
  };
}
