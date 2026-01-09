import {
  AppWindow,
  ArrowUpCircle,
  Beer,
  Package as PackageIcon,
  RefreshCw,
  Sparkles,
  Stethoscope,
} from 'lucide-react';
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

import { ActionButton, StatCard } from './components';

export function HomebrewOverviewPage() {
  const {
    info,
    outdated,
    loading,
    operating,
    operatingStates,
    refresh,
    update,
    upgradeAllPackages,
    cleanup,
    doctor,
  } = useHomebrew();

  const [doctorOutput, setDoctorOutput] = useState<string | null>(null);
  const [showCleanupConfirm, setShowCleanupConfirm] = useState(false);

  const handleDoctor = async () => {
    const result = await doctor();
    setDoctorOutput(result);
  };

  const handleCleanup = async () => {
    await cleanup();
    setShowCleanupConfirm(false);
  };

  return (
    <div className='flex flex-1 flex-col gap-6 p-6'>
      <div className='flex items-start justify-between'>
        <div className='space-y-1'>
          <h1 className='font-bold text-2xl'>Overview</h1>
          <p className='text-muted-foreground'>
            Homebrew status and quick actions
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

      <div className='grid grid-cols-4 gap-4'>
        <StatCard
          description={info?.prefix || 'Homebrew path'}
          icon={<Beer className='size-4 text-muted-foreground' />}
          loading={loading}
          title='Version'
          value={info?.version || '-'}
        />
        <StatCard
          description='Command-line tools'
          icon={<PackageIcon className='size-4 text-muted-foreground' />}
          loading={loading}
          title='Formulae'
          value={info?.formulae_count ?? '-'}
        />
        <StatCard
          description='GUI applications'
          icon={<AppWindow className='size-4 text-muted-foreground' />}
          loading={loading}
          title='Casks'
          value={info?.cask_count ?? '-'}
        />
        <StatCard
          description='Packages to update'
          icon={<ArrowUpCircle className='size-4 text-muted-foreground' />}
          loading={loading}
          title='Updates'
          value={info?.outdated_count ?? '-'}
        />
      </div>

      <div className='rounded-xl bg-muted/50 p-5'>
        <div className='space-y-1'>
          <h3 className='font-semibold'>Quick Actions</h3>
          <p className='text-muted-foreground text-sm'>
            Common Homebrew operations
          </p>
        </div>
        <div className='mt-4 flex flex-wrap gap-3'>
          <ActionButton
            disabled={operating}
            icon={<RefreshCw className='size-4' />}
            label='Update Homebrew'
            loading={operatingStates.updating}
            onClick={update}
          />
          <ActionButton
            disabled={operating || outdated.length === 0}
            icon={<ArrowUpCircle className='size-4' />}
            label='Upgrade All'
            loading={operatingStates.upgradingAll}
            onClick={upgradeAllPackages}
          />
          <ActionButton
            disabled={operating}
            icon={<Sparkles className='size-4' />}
            label='Cleanup'
            loading={operatingStates.cleaningUp}
            onClick={() => setShowCleanupConfirm(true)}
          />
          <ActionButton
            disabled={operating}
            icon={<Stethoscope className='size-4' />}
            label='Doctor'
            loading={operatingStates.doctoring}
            onClick={handleDoctor}
          />
        </div>
        {doctorOutput && (
          <div className='mt-4 max-h-48 overflow-auto rounded-lg bg-muted p-3'>
            <pre className='whitespace-pre-wrap font-mono text-xs'>
              {doctorOutput || 'Your system is ready to brew.'}
            </pre>
          </div>
        )}
      </div>

      <AlertDialog
        onOpenChange={setShowCleanupConfirm}
        open={showCleanupConfirm}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Cleanup Homebrew?</AlertDialogTitle>
            <AlertDialogDescription>
              This will remove old versions and clear the download cache. This
              action cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleCleanup}>
              Confirm
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
