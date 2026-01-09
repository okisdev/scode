import { AlertCircle, RefreshCw } from 'lucide-react';
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
import { useHomebrew } from '@/hooks/use-homebrew';

import { FormulaeTab } from './components';

export function HomebrewFormulaePage() {
  const {
    formulae,
    searchResults,
    loading,
    operating,
    searching,
    error,
    refresh,
    search,
    clearSearch,
    install,
    uninstall,
    upgrade,
  } = useHomebrew();

  const [formulaeSearch, setFormulaeSearch] = useState('');
  const [uninstallTarget, setUninstallTarget] = useState<string | null>(null);

  // Debounced search
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  useEffect(() => {
    if (debounceRef.current) {
      clearTimeout(debounceRef.current);
    }
    if (formulaeSearch.trim()) {
      debounceRef.current = setTimeout(() => {
        search(formulaeSearch, false);
      }, 300);
    } else {
      clearSearch();
    }
    return () => {
      if (debounceRef.current) {
        clearTimeout(debounceRef.current);
      }
    };
  }, [formulaeSearch, search, clearSearch]);

  const installedFormulaNames = new Set(formulae.map((f) => f.name));

  const filteredFormulae = formulaeSearch.trim()
    ? formulae.filter((f) =>
        f.name.toLowerCase().includes(formulaeSearch.toLowerCase())
      )
    : formulae;

  const handleUninstall = async () => {
    if (uninstallTarget) {
      await uninstall(uninstallTarget, false);
      setUninstallTarget(null);
    }
  };

  return (
    <div className='flex flex-1 flex-col gap-6 p-6'>
      <div className='flex items-start justify-between'>
        <div className='space-y-1'>
          <h1 className='font-bold text-2xl'>Formulae</h1>
          <p className='text-muted-foreground'>
            Command-line tools and libraries
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

      <FormulaeTab
        filteredFormulae={filteredFormulae}
        formulaeSearch={formulaeSearch}
        installedFormulaNames={installedFormulaNames}
        loading={loading}
        onInstall={(name) => install(name, false)}
        onUninstall={(name) => setUninstallTarget(name)}
        onUpgrade={upgrade}
        operating={operating}
        searching={searching}
        searchResults={searchResults}
        setFormulaeSearch={setFormulaeSearch}
      />

      <AlertDialog
        onOpenChange={(open) => !open && setUninstallTarget(null)}
        open={uninstallTarget !== null}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Uninstall {uninstallTarget}?</AlertDialogTitle>
            <AlertDialogDescription>
              This will remove {uninstallTarget} from your system. You can
              reinstall it later if needed.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleUninstall}>
              Confirm
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
