import { RefreshCw } from 'lucide-react';

import { Button } from '@/components/ui/button';
import { useHomebrew } from '@/hooks/use-homebrew';

import { LogsList } from './components';

export function HomebrewLogsPage() {
  const { logs, loading, operating, refresh } = useHomebrew();

  return (
    <div className='flex flex-1 flex-col gap-6 p-6'>
      <div className='flex items-start justify-between'>
        <div className='space-y-1'>
          <h1 className='font-bold text-2xl'>Logs</h1>
          <p className='text-muted-foreground'>
            {logs.length} operations recorded
          </p>
        </div>
        <Button
          className='gap-2'
          disabled={loading || operating}
          onClick={refresh}
          size='sm'
          variant='outline'
        >
          <RefreshCw className={`size-4 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </Button>
      </div>

      <LogsList loading={loading} logs={logs} />
    </div>
  );
}
