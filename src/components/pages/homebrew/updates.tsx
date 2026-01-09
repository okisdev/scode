import { ArrowUpCircle, Loader2, RefreshCw } from 'lucide-react';

import { Button } from '@/components/ui/button';
import { useHomebrew } from '@/hooks/use-homebrew';

import { UpdatesList } from './components';

export function HomebrewUpdatesPage() {
  const { outdated, loading, operating, refresh, upgrade, upgradeAllPackages } =
    useHomebrew();

  return (
    <div className='flex flex-1 flex-col gap-6 p-6'>
      <div className='flex items-start justify-between'>
        <div className='space-y-1'>
          <h1 className='font-bold text-2xl'>Updates</h1>
          <p className='text-muted-foreground'>
            {outdated.length} packages can be updated
          </p>
        </div>
        <div className='flex gap-2'>
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
          <Button
            className='gap-2'
            disabled={operating || outdated.length === 0}
            onClick={upgradeAllPackages}
            size='sm'
          >
            {operating ? (
              <Loader2 className='size-4 animate-spin' />
            ) : (
              <ArrowUpCircle className='size-4' />
            )}
            Upgrade All
          </Button>
        </div>
      </div>

      <UpdatesList
        loading={loading}
        onUpgrade={upgrade}
        operating={operating}
        outdated={outdated}
      />
    </div>
  );
}
