import { History } from 'lucide-react';
import { useState } from 'react';
import { Skeleton } from '@/components/ui/skeleton';
import type { LogEntry } from '@/lib/homebrew';
import { EmptyState } from './empty-state';

interface LogsListProps {
  logs: LogEntry[];
  loading: boolean;
}

function LogLine({ entry, index }: { entry: LogEntry; index: number }) {
  const [expanded, setExpanded] = useState(false);
  const hasOutput = Boolean(entry.output);

  return (
    <div key={`${entry.timestamp}-${index}`}>
      <div
        className={`flex items-center gap-1 leading-relaxed ${hasOutput ? 'cursor-pointer hover:bg-zinc-800/50' : ''}`}
        onClick={() => hasOutput && setExpanded(!expanded)}
      >
        <span className='shrink-0 text-zinc-500'>[{entry.timestamp}]</span>
        <span className='shrink-0 text-purple-400'>[{entry.category}]</span>
        <span className='shrink-0 text-blue-400'>
          [{entry.action.toLowerCase()}]
        </span>
        <span
          className={`shrink-0 ${entry.success ? 'text-green-400' : 'text-red-400'}`}
        >
          {entry.success ? '✓' : '✗'}
        </span>
        <span className='truncate text-zinc-200'>{entry.target}</span>
        {hasOutput && (
          <span className='ml-auto shrink-0 text-zinc-600'>
            {expanded ? '▼' : '▶'}
          </span>
        )}
      </div>
      {expanded && entry.output && (
        <div className='ml-4 border-zinc-700 border-l pl-3 text-zinc-400'>
          <pre className='whitespace-pre-wrap'>{entry.output}</pre>
        </div>
      )}
    </div>
  );
}

export function LogsList({ logs, loading }: LogsListProps) {
  if (loading) {
    return (
      <div className='flex-1 rounded-xl bg-muted/50 p-4'>
        <div className='space-y-2'>
          {Array.from({ length: 6 }).map((_, i) => (
            <Skeleton className='h-5 w-full' key={i} />
          ))}
        </div>
      </div>
    );
  }

  if (logs.length === 0) {
    return (
      <div className='flex flex-1 items-center justify-center rounded-xl bg-zinc-950 dark:bg-zinc-900/50'>
        <EmptyState
          icon={<History className='size-12 text-muted-foreground' />}
          message='No operation logs yet'
        />
      </div>
    );
  }

  return (
    <div className='min-h-0 flex-1 overflow-auto rounded-xl bg-zinc-950 p-4 dark:bg-zinc-900/50'>
      <div className='space-y-0.5 font-mono text-sm'>
        {logs.map((entry, index) => (
          <LogLine
            entry={entry}
            index={index}
            key={`${entry.timestamp}-${index}`}
          />
        ))}
      </div>
    </div>
  );
}
