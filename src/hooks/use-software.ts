import { useQuery } from '@tanstack/react-query';

import { queryKeys } from '@/lib/query-keys';
import { detectSoftware, SOFTWARE_LIST, type Software } from '@/lib/software';

import { useScodeConfig } from './use-scode-config';

export interface SoftwareStatus {
  software: Software;
  installed: boolean;
  enabled: boolean;
}

async function getSoftwareInstallStatus(): Promise<Map<string, boolean>> {
  const results = await Promise.all(
    SOFTWARE_LIST.map(async (software) => ({
      id: software.id,
      installed: await detectSoftware(software),
    }))
  );

  return new Map(results.map((r) => [r.id, r.installed]));
}

export function useSoftware() {
  const { config } = useScodeConfig();

  const { data: installedMap } = useQuery({
    queryKey: queryKeys.software.installed(),
    queryFn: getSoftwareInstallStatus,
    staleTime: 10 * 60 * 1000, // 10 minutes
  });

  // All software with their status
  const allWithStatus: SoftwareStatus[] = SOFTWARE_LIST.map((software) => ({
    software,
    // Direct mode is always "installed", detect mode checks the map
    installed:
      software.mode === 'direct'
        ? true
        : (installedMap?.get(software.id) ?? false),
    enabled: config.enabledSoftware.includes(software.id),
  }));

  // Enabled software (for Sidebar)
  // Direct mode: only check if enabled
  // Detect mode: check both installed and enabled
  const enabled = allWithStatus
    .filter((s) => {
      if (s.software.mode === 'direct') {
        return s.enabled;
      }
      return s.installed && s.enabled;
    })
    .map((s) => s.software);

  return {
    all: SOFTWARE_LIST,
    allWithStatus,
    enabled,
  };
}
