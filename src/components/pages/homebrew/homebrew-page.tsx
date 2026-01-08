import {
  AlertCircle,
  AppWindow,
  ArrowUpCircle,
  Beer,
  Loader2,
  Package as PackageIcon,
  RefreshCw,
  Sparkles,
  Stethoscope,
} from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useHomebrew } from '@/hooks/use-homebrew';
import {
  ActionButton,
  CasksTab,
  FormulaeTab,
  LogsList,
  StatCard,
  TapsTab,
  UpdatesList,
} from './components';
import type { ConfirmAction } from './types';

export function HomebrewPage() {
  const {
    info,
    formulae,
    casks,
    outdated,
    taps,
    searchResults,
    logs,
    loading,
    operating,
    operatingStates,
    searching,
    error,
    refresh,
    search,
    clearSearch,
    install,
    uninstall,
    upgrade,
    update,
    upgradeAllPackages,
    cleanup,
    doctor,
    tapRepo,
    untapRepo,
  } = useHomebrew();

  const [formulaeSearch, setFormulaeSearch] = useState('');
  const [caskSearch, setCaskSearch] = useState('');
  const [newTapName, setNewTapName] = useState('');
  const [doctorOutput, setDoctorOutput] = useState<string | null>(null);
  const [confirmAction, setConfirmAction] = useState<ConfirmAction | null>(
    null
  );

  // Debounced search for formulae
  const formulaeDebounceRef = useRef<ReturnType<typeof setTimeout> | null>(
    null
  );
  useEffect(() => {
    if (formulaeDebounceRef.current) {
      clearTimeout(formulaeDebounceRef.current);
    }
    if (formulaeSearch.trim()) {
      formulaeDebounceRef.current = setTimeout(() => {
        search(formulaeSearch, false);
      }, 300);
    } else {
      clearSearch();
    }
    return () => {
      if (formulaeDebounceRef.current) {
        clearTimeout(formulaeDebounceRef.current);
      }
    };
  }, [formulaeSearch, search, clearSearch]);

  // Debounced search for casks
  const caskDebounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  useEffect(() => {
    if (caskDebounceRef.current) {
      clearTimeout(caskDebounceRef.current);
    }
    if (caskSearch.trim()) {
      caskDebounceRef.current = setTimeout(() => {
        search(caskSearch, true);
      }, 300);
    } else {
      clearSearch();
    }
    return () => {
      if (caskDebounceRef.current) {
        clearTimeout(caskDebounceRef.current);
      }
    };
  }, [caskSearch, search, clearSearch]);

  const handleDoctor = async () => {
    const result = await doctor();
    setDoctorOutput(result);
  };

  const handleAddTap = () => {
    if (newTapName.trim()) {
      tapRepo(newTapName.trim());
      setNewTapName('');
    }
  };

  const handleConfirmAction = async () => {
    if (!confirmAction) {
      return;
    }

    switch (confirmAction.type) {
      case 'uninstall':
        if (confirmAction.name !== undefined) {
          await uninstall(confirmAction.name, confirmAction.isCask ?? false);
        }
        break;
      case 'untap':
        if (confirmAction.name) {
          await untapRepo(confirmAction.name);
        }
        break;
      case 'cleanup':
        await cleanup();
        break;
      default:
        break;
    }
    setConfirmAction(null);
  };

  const getConfirmDialogContent = () => {
    if (!confirmAction) {
      return { title: '', description: '' };
    }

    switch (confirmAction.type) {
      case 'uninstall':
        return {
          title: `Uninstall ${confirmAction.name}?`,
          description: `This will remove ${confirmAction.name} from your system. You can reinstall it later if needed.`,
        };
      case 'untap':
        return {
          title: `Remove tap ${confirmAction.name}?`,
          description: `This will remove the ${confirmAction.name} repository. Packages from this tap will no longer be available.`,
        };
      case 'cleanup':
        return {
          title: 'Cleanup Homebrew?',
          description:
            'This will remove old versions and clear the download cache. This action cannot be undone.',
        };
      default:
        return { title: '', description: '' };
    }
  };

  const installedFormulaNames = new Set(formulae.map((f) => f.name));
  const installedCaskNames = new Set(casks.map((c) => c.name));

  // Filter local results based on search
  const filteredFormulae = formulaeSearch.trim()
    ? formulae.filter((f) =>
        f.name.toLowerCase().includes(formulaeSearch.toLowerCase())
      )
    : formulae;

  const filteredCasks = caskSearch.trim()
    ? casks.filter((c) =>
        c.name.toLowerCase().includes(caskSearch.toLowerCase())
      )
    : casks;

  const dialogContent = getConfirmDialogContent();

  return (
    <div className='flex flex-1 flex-col gap-6 p-6'>
      <div className='flex items-start justify-between'>
        <div className='space-y-1'>
          <h1 className='font-bold text-2xl'>Homebrew</h1>
          <p className='text-muted-foreground'>
            Manage Homebrew packages and applications
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

      {error && (
        <div className='flex items-center gap-2 rounded-xl bg-destructive/10 p-4 text-destructive'>
          <AlertCircle className='size-5' />
          <span>{error}</span>
        </div>
      )}

      <Tabs className='flex-1' defaultValue='overview'>
        <TabsList>
          <TabsTrigger value='overview'>Overview</TabsTrigger>
          <TabsTrigger value='formulae'>Formulae</TabsTrigger>
          <TabsTrigger value='casks'>Casks</TabsTrigger>
          <TabsTrigger value='updates'>
            Updates
            {!loading && outdated.length > 0 && (
              <span className='flex h-4 min-w-4 items-center justify-center rounded-full bg-amber-500 px-1 font-medium text-[11px] text-white'>
                {outdated.length}
              </span>
            )}
          </TabsTrigger>
          <TabsTrigger value='taps'>Taps</TabsTrigger>
          <TabsTrigger value='logs'>Logs</TabsTrigger>
        </TabsList>

        {/* Overview Tab */}
        <TabsContent className='mt-4 space-y-4' value='overview'>
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
                onClick={() => setConfirmAction({ type: 'cleanup' })}
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
        </TabsContent>

        {/* Formulae Tab */}
        <TabsContent className='mt-4 space-y-4' value='formulae'>
          <FormulaeTab
            filteredFormulae={filteredFormulae}
            formulaeSearch={formulaeSearch}
            installedFormulaNames={installedFormulaNames}
            loading={loading}
            onInstall={(name) => install(name, false)}
            onUninstall={(name) =>
              setConfirmAction({ type: 'uninstall', name, isCask: false })
            }
            onUpgrade={upgrade}
            operating={operating}
            searching={searching}
            searchResults={searchResults}
            setFormulaeSearch={setFormulaeSearch}
          />
        </TabsContent>

        {/* Casks Tab */}
        <TabsContent className='mt-4 space-y-4' value='casks'>
          <CasksTab
            caskSearch={caskSearch}
            filteredCasks={filteredCasks}
            installedCaskNames={installedCaskNames}
            loading={loading}
            onInstall={(name) => install(name, true)}
            onUninstall={(name) =>
              setConfirmAction({ type: 'uninstall', name, isCask: true })
            }
            operating={operating}
            searching={searching}
            searchResults={searchResults}
            setCaskSearch={setCaskSearch}
          />
        </TabsContent>

        {/* Updates Tab */}
        <TabsContent className='mt-4 space-y-4' value='updates'>
          <div className='flex items-center justify-between'>
            <div className='space-y-1'>
              <h3 className='font-semibold'>Available Updates</h3>
              <p className='text-muted-foreground text-sm'>
                {outdated.length} packages can be updated
              </p>
            </div>
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

          <UpdatesList
            loading={loading}
            onUpgrade={upgrade}
            operating={operating}
            outdated={outdated}
          />
        </TabsContent>

        {/* Taps Tab */}
        <TabsContent className='mt-4 space-y-4' value='taps'>
          <TapsTab
            handleAddTap={handleAddTap}
            loading={loading}
            newTapName={newTapName}
            onUntap={(name) => setConfirmAction({ type: 'untap', name })}
            operating={operating}
            setNewTapName={setNewTapName}
            taps={taps}
          />
        </TabsContent>

        {/* Logs Tab */}
        <TabsContent className='mt-4 flex flex-1 flex-col gap-4' value='logs'>
          <div className='shrink-0 space-y-1'>
            <h3 className='font-semibold'>Operation History</h3>
            <p className='text-muted-foreground text-sm'>
              {logs.length} operations recorded
            </p>
          </div>

          <LogsList loading={loading} logs={logs} />
        </TabsContent>
      </Tabs>

      {/* Confirmation Dialog */}
      <AlertDialog
        onOpenChange={(open) => !open && setConfirmAction(null)}
        open={confirmAction !== null}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>{dialogContent.title}</AlertDialogTitle>
            <AlertDialogDescription>
              {dialogContent.description}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleConfirmAction}>
              Confirm
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
