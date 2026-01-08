import { useQuery } from '@tanstack/react-query';
import { queryKeys } from '@/lib/query-keys';
import {
  getInstalledSoftware,
  SOFTWARE_LIST,
  type Software,
} from '@/lib/software';

export function useSoftware() {
  const { data: installed, isLoading: loading } = useQuery<Software[]>({
    queryKey: queryKeys.software.installed(),
    queryFn: getInstalledSoftware,
    staleTime: 10 * 60 * 1000, // 10 minutes
    placeholderData: SOFTWARE_LIST,
  });

  // Use SOFTWARE_LIST as fallback when loading or no data
  const finalInstalled = installed ?? SOFTWARE_LIST;

  return { installed: finalInstalled, loading, all: SOFTWARE_LIST };
}
