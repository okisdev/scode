import { homeDir } from '@tauri-apps/api/path';
import {
  exists,
  mkdir,
  readTextFile,
  writeTextFile,
} from '@tauri-apps/plugin-fs';

export interface ScodeConfig {
  enabledSoftware: string[];
}

const DEFAULT_CONFIG: ScodeConfig = {
  enabledSoftware: [],
};

async function getScodeDir(): Promise<string> {
  const home = await homeDir();
  // homeDir() may return path with trailing slash
  const normalizedHome = home.endsWith('/') ? home.slice(0, -1) : home;
  return `${normalizedHome}/.scode`;
}

async function getConfigPath(): Promise<string> {
  const scodeDir = await getScodeDir();
  return `${scodeDir}/config.json`;
}

async function ensureScodeDir(): Promise<void> {
  const scodeDir = await getScodeDir();
  try {
    const dirExists = await exists(scodeDir);
    if (!dirExists) {
      await mkdir(scodeDir, { recursive: true });
    }
  } catch {
    // Directory might not exist, try to create it
    await mkdir(scodeDir, { recursive: true });
  }
}

export async function loadConfig(): Promise<ScodeConfig> {
  try {
    const configPath = await getConfigPath();
    const configExists = await exists(configPath);
    if (!configExists) {
      return DEFAULT_CONFIG;
    }
    const content = await readTextFile(configPath);
    return JSON.parse(content) as ScodeConfig;
  } catch {
    return DEFAULT_CONFIG;
  }
}

export async function saveConfig(config: ScodeConfig): Promise<void> {
  await ensureScodeDir();
  const configPath = await getConfigPath();
  await writeTextFile(configPath, JSON.stringify(config, null, 2));
}

export async function toggleSoftwareEnabled(
  softwareId: string,
  enabled: boolean
): Promise<ScodeConfig> {
  const config = await loadConfig();

  if (enabled) {
    if (!config.enabledSoftware.includes(softwareId)) {
      config.enabledSoftware.push(softwareId);
    }
  } else {
    config.enabledSoftware = config.enabledSoftware.filter(
      (id) => id !== softwareId
    );
  }

  await saveConfig(config);
  return config;
}
