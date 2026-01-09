import { Clock } from 'lucide-react';
import { useMemo } from 'react';

import {
  formatCost,
  formatRelativeTime,
  formatTokens,
  getModelDisplayName,
  getProjectDisplayName,
} from '@/lib/claude-usage';

interface RecentSessionsProps {
  entries: {
    timestamp: string;
    session_id: string;
    model: string;
    input_tokens: number;
    output_tokens: number;
    cache_creation_tokens: number;
    cache_read_tokens: number;
    cost_usd: number;
    project_path: string;
  }[];
  isLoading: boolean;
}

interface SessionSummary {
  sessionId: string;
  projectPath: string;
  projectName: string;
  lastActivity: string;
  totalCost: number;
  totalTokens: number;
  requestCount: number;
  models: string[];
}

function aggregateSessions(
  entries: RecentSessionsProps['entries']
): SessionSummary[] {
  const sessionMap = new Map<string, SessionSummary>();

  for (const entry of entries) {
    const existing = sessionMap.get(entry.session_id);
    const tokens =
      entry.input_tokens +
      entry.output_tokens +
      entry.cache_creation_tokens +
      entry.cache_read_tokens;

    if (existing) {
      existing.totalCost += entry.cost_usd;
      existing.totalTokens += tokens;
      existing.requestCount += 1;
      if (!existing.models.includes(entry.model)) {
        existing.models.push(entry.model);
      }
      // Update last activity if this entry is more recent
      if (entry.timestamp > existing.lastActivity) {
        existing.lastActivity = entry.timestamp;
      }
    } else {
      sessionMap.set(entry.session_id, {
        sessionId: entry.session_id,
        projectPath: entry.project_path,
        projectName: getProjectDisplayName(entry.project_path),
        lastActivity: entry.timestamp,
        totalCost: entry.cost_usd,
        totalTokens: tokens,
        requestCount: 1,
        models: [entry.model],
      });
    }
  }

  // Sort by last activity (most recent first)
  return Array.from(sessionMap.values()).sort(
    (a, b) =>
      new Date(b.lastActivity).getTime() - new Date(a.lastActivity).getTime()
  );
}

export function RecentSessions({ entries, isLoading }: RecentSessionsProps) {
  const sessions = useMemo(() => aggregateSessions(entries), [entries]);

  if (isLoading) {
    return (
      <div className='rounded-xl bg-muted/50 p-5'>
        <div className='mb-4 h-5 w-32 animate-pulse rounded bg-muted' />
        <div className='space-y-3'>
          {[...new Array(3)].map((_, i) => (
            <div className='h-16 animate-pulse rounded bg-muted' key={i} />
          ))}
        </div>
      </div>
    );
  }

  // Show only the 5 most recent sessions
  const recentSessions = sessions.slice(0, 5);

  if (recentSessions.length === 0) {
    return (
      <div className='rounded-xl bg-muted/50 p-5'>
        <div className='flex items-center gap-2 text-muted-foreground text-sm'>
          <Clock className='h-4 w-4' />
          <span>No recent sessions</span>
        </div>
      </div>
    );
  }

  return (
    <div className='rounded-xl bg-muted/50 p-5'>
      <div className='mb-4 font-medium text-sm'>Recent Sessions</div>
      <div className='space-y-3'>
        {recentSessions.map((session) => (
          <div
            className='flex items-start justify-between'
            key={session.sessionId}
          >
            <div className='min-w-0 flex-1'>
              <div className='flex items-center gap-2'>
                <span className='truncate font-medium text-sm'>
                  {session.projectName}
                </span>
                <span className='shrink-0 text-muted-foreground text-xs'>
                  {formatRelativeTime(session.lastActivity)}
                </span>
              </div>
              <div className='mt-1 flex flex-wrap gap-x-3 gap-y-1 text-muted-foreground text-xs'>
                <span>{formatTokens(session.totalTokens)} tokens</span>
                <span>{session.requestCount} requests</span>
                {session.models.slice(0, 2).map((model) => (
                  <span className='rounded bg-muted px-1.5 py-0.5' key={model}>
                    {getModelDisplayName(model)}
                  </span>
                ))}
                {session.models.length > 2 && (
                  <span className='rounded bg-muted px-1.5 py-0.5'>
                    +{session.models.length - 2}
                  </span>
                )}
              </div>
            </div>
            <div className='ml-4 shrink-0 text-right'>
              <div className='font-medium text-sm'>
                {formatCost(session.totalCost)}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
