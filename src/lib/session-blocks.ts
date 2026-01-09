import type { UsageEntry } from './claude-usage';

// Default session duration in hours (Claude's billing block duration)
export const DEFAULT_SESSION_DURATION_HOURS = 5;

export interface TokenCounts {
  inputTokens: number;
  outputTokens: number;
  cacheCreationTokens: number;
  cacheReadTokens: number;
}

export interface SessionBlock {
  id: string;
  startTime: Date;
  endTime: Date;
  actualEndTime?: Date;
  isActive: boolean;
  isGap?: boolean;
  entries: UsageEntry[];
  tokenCounts: TokenCounts;
  costUSD: number;
  models: string[];
}

export interface BurnRate {
  tokensPerMinute: number;
  costPerHour: number;
}

export interface ProjectedUsage {
  totalTokens: number;
  totalCost: number;
  remainingMinutes: number;
}

function floorToHour(timestamp: Date): Date {
  const floored = new Date(timestamp);
  floored.setUTCMinutes(0, 0, 0);
  return floored;
}

function getTotalTokensFromCounts(counts: TokenCounts): number {
  return (
    counts.inputTokens +
    counts.outputTokens +
    counts.cacheCreationTokens +
    counts.cacheReadTokens
  );
}

function createBlock(
  startTime: Date,
  entries: UsageEntry[],
  now: Date,
  sessionDurationMs: number
): SessionBlock {
  const endTime = new Date(startTime.getTime() + sessionDurationMs);
  const lastEntry = entries[entries.length - 1];
  const actualEndTime = lastEntry ? new Date(lastEntry.timestamp) : startTime;
  const isActive =
    now.getTime() - actualEndTime.getTime() < sessionDurationMs &&
    now < endTime;

  const tokenCounts: TokenCounts = {
    inputTokens: 0,
    outputTokens: 0,
    cacheCreationTokens: 0,
    cacheReadTokens: 0,
  };

  let costUSD = 0;
  const modelsSet = new Set<string>();

  for (const entry of entries) {
    tokenCounts.inputTokens += entry.input_tokens;
    tokenCounts.outputTokens += entry.output_tokens;
    tokenCounts.cacheCreationTokens += entry.cache_creation_tokens;
    tokenCounts.cacheReadTokens += entry.cache_read_tokens;
    costUSD += entry.cost_usd;
    modelsSet.add(entry.model);
  }

  return {
    id: startTime.toISOString(),
    startTime,
    endTime,
    actualEndTime,
    isActive,
    entries,
    tokenCounts,
    costUSD,
    models: Array.from(modelsSet),
  };
}

function createGapBlock(
  lastActivityTime: Date,
  nextActivityTime: Date,
  sessionDurationMs: number
): SessionBlock | null {
  const gapDuration = nextActivityTime.getTime() - lastActivityTime.getTime();
  if (gapDuration <= sessionDurationMs) {
    return null;
  }

  const gapStart = new Date(lastActivityTime.getTime() + sessionDurationMs);
  const gapEnd = nextActivityTime;

  return {
    id: `gap-${gapStart.toISOString()}`,
    startTime: gapStart,
    endTime: gapEnd,
    isActive: false,
    isGap: true,
    entries: [],
    tokenCounts: {
      inputTokens: 0,
      outputTokens: 0,
      cacheCreationTokens: 0,
      cacheReadTokens: 0,
    },
    costUSD: 0,
    models: [],
  };
}

export function identifySessionBlocks(
  entries: UsageEntry[],
  sessionDurationHours = DEFAULT_SESSION_DURATION_HOURS
): SessionBlock[] {
  if (entries.length === 0) {
    return [];
  }

  const sessionDurationMs = sessionDurationHours * 60 * 60 * 1000;
  const blocks: SessionBlock[] = [];
  const sortedEntries = [...entries].sort(
    (a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime()
  );

  let currentBlockStart: Date | null = null;
  let currentBlockEntries: UsageEntry[] = [];
  const now = new Date();

  for (const entry of sortedEntries) {
    const entryTime = new Date(entry.timestamp);

    if (currentBlockStart === null) {
      currentBlockStart = floorToHour(entryTime);
      currentBlockEntries = [entry];
    } else {
      const timeSinceBlockStart =
        entryTime.getTime() - currentBlockStart.getTime();
      const lastEntry = currentBlockEntries[currentBlockEntries.length - 1];
      if (!lastEntry) continue;

      const lastEntryTime = new Date(lastEntry.timestamp);
      const timeSinceLastEntry = entryTime.getTime() - lastEntryTime.getTime();

      if (
        timeSinceBlockStart > sessionDurationMs ||
        timeSinceLastEntry > sessionDurationMs
      ) {
        const block = createBlock(
          currentBlockStart,
          currentBlockEntries,
          now,
          sessionDurationMs
        );
        blocks.push(block);

        if (timeSinceLastEntry > sessionDurationMs) {
          const gapBlock = createGapBlock(
            lastEntryTime,
            entryTime,
            sessionDurationMs
          );
          if (gapBlock) {
            blocks.push(gapBlock);
          }
        }

        currentBlockStart = floorToHour(entryTime);
        currentBlockEntries = [entry];
      } else {
        currentBlockEntries.push(entry);
      }
    }
  }

  if (currentBlockStart !== null && currentBlockEntries.length > 0) {
    const block = createBlock(
      currentBlockStart,
      currentBlockEntries,
      now,
      sessionDurationMs
    );
    blocks.push(block);
  }

  return blocks;
}

export function calculateBurnRate(block: SessionBlock): BurnRate | null {
  if (block.entries.length === 0 || block.isGap) {
    return null;
  }

  const firstEntry = block.entries[0];
  const lastEntry = block.entries[block.entries.length - 1];
  if (!(firstEntry && lastEntry)) {
    return null;
  }

  const firstTime = new Date(firstEntry.timestamp);
  const lastTime = new Date(lastEntry.timestamp);
  const durationMinutes =
    (lastTime.getTime() - firstTime.getTime()) / (1000 * 60);

  if (durationMinutes <= 0) {
    return null;
  }

  const totalTokens = getTotalTokensFromCounts(block.tokenCounts);
  const tokensPerMinute = totalTokens / durationMinutes;
  const costPerHour = (block.costUSD / durationMinutes) * 60;

  return {
    tokensPerMinute,
    costPerHour,
  };
}

export function projectBlockUsage(block: SessionBlock): ProjectedUsage | null {
  if (!block.isActive || block.isGap) {
    return null;
  }

  const burnRate = calculateBurnRate(block);
  if (!burnRate) {
    return null;
  }

  const now = new Date();
  const remainingTime = block.endTime.getTime() - now.getTime();
  const remainingMinutes = Math.max(0, remainingTime / (1000 * 60));

  const currentTokens = getTotalTokensFromCounts(block.tokenCounts);
  const projectedAdditionalTokens = burnRate.tokensPerMinute * remainingMinutes;
  const totalTokens = currentTokens + projectedAdditionalTokens;

  const projectedAdditionalCost =
    (burnRate.costPerHour / 60) * remainingMinutes;
  const totalCost = block.costUSD + projectedAdditionalCost;

  return {
    totalTokens: Math.round(totalTokens),
    totalCost: Math.round(totalCost * 100) / 100,
    remainingMinutes: Math.round(remainingMinutes),
  };
}

export function filterRecentBlocks(
  blocks: SessionBlock[],
  days = 3
): SessionBlock[] {
  const now = new Date();
  const cutoffTime = new Date(now.getTime() - days * 24 * 60 * 60 * 1000);

  return blocks.filter((block) => {
    return block.startTime >= cutoffTime || block.isActive;
  });
}

export function getActiveBlock(blocks: SessionBlock[]): SessionBlock | null {
  return blocks.find((block) => block.isActive) ?? null;
}

export function formatDuration(minutes: number): string {
  const hours = Math.floor(minutes / 60);
  const mins = Math.round(minutes % 60);
  if (hours > 0) {
    return `${hours}h ${mins}m`;
  }
  return `${mins}m`;
}

export function formatBlockTime(block: SessionBlock): string {
  const start = block.startTime.toLocaleString();

  if (block.isGap) {
    const duration = Math.round(
      (block.endTime.getTime() - block.startTime.getTime()) / (1000 * 60 * 60)
    );
    return `${start} (${duration}h gap)`;
  }

  if (block.isActive) {
    const now = new Date();
    const elapsed = Math.round(
      (now.getTime() - block.startTime.getTime()) / (1000 * 60)
    );
    const remaining = Math.round(
      (block.endTime.getTime() - now.getTime()) / (1000 * 60)
    );
    return `${start} (${formatDuration(elapsed)} elapsed, ${formatDuration(remaining)} remaining)`;
  }

  if (block.actualEndTime) {
    const duration = Math.round(
      (block.actualEndTime.getTime() - block.startTime.getTime()) / (1000 * 60)
    );
    return `${start} (${formatDuration(duration)})`;
  }

  return start;
}
