import { RefreshCw } from 'lucide-react';
import { useState } from 'react';

import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { Button } from '@/components/ui/button';
import { useHomebrew } from '@/hooks/use-homebrew';

import { TapsTab } from './components';

export function HomebrewTapsPage() {
  const { taps, loading, operating, refresh, tapRepo, untapRepo } =
    useHomebrew();

  const [newTapName, setNewTapName] = useState('');
  const [untapTarget, setUntapTarget] = useState<string | null>(null);

  const handleAddTap = () => {
    if (newTapName.trim()) {
      tapRepo(newTapName.trim());
      setNewTapName('');
    }
  };

  const handleUntap = async () => {
    if (untapTarget) {
      await untapRepo(untapTarget);
      setUntapTarget(null);
    }
  };

  return (
    <div className='flex flex-1 flex-col gap-6 p-6'>
      <div className='flex items-start justify-between'>
        <div className='space-y-1'>
          <h1 className='font-bold text-2xl'>Taps</h1>
          <p className='text-muted-foreground'>
            Third-party Homebrew repositories
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

      <TapsTab
        handleAddTap={handleAddTap}
        loading={loading}
        newTapName={newTapName}
        onUntap={(name) => setUntapTarget(name)}
        operating={operating}
        setNewTapName={setNewTapName}
        taps={taps}
      />

      <AlertDialog
        onOpenChange={(open) => !open && setUntapTarget(null)}
        open={untapTarget !== null}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Remove tap {untapTarget}?</AlertDialogTitle>
            <AlertDialogDescription>
              This will remove the {untapTarget} repository. Packages from this
              tap will no longer be available.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleUntap}>Confirm</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
