import { Loader2, Search } from 'lucide-react';
import { Input } from '@/components/ui/input';
import type { Package } from '@/lib/homebrew';
import { FormulaeList } from './formulae-list';

interface FormulaeTabProps {
  formulaeSearch: string;
  setFormulaeSearch: (value: string) => void;
  searching: boolean;
  loading: boolean;
  searchResults: Package[];
  filteredFormulae: Package[];
  installedFormulaNames: Set<string>;
  operating: boolean;
  onInstall: (name: string) => void;
  onUninstall: (name: string) => void;
  onUpgrade: (name: string) => void;
}

export function FormulaeTab({
  formulaeSearch,
  setFormulaeSearch,
  searching,
  loading,
  searchResults,
  filteredFormulae,
  installedFormulaNames,
  operating,
  onInstall,
  onUninstall,
  onUpgrade,
}: FormulaeTabProps) {
  const hasSearch = formulaeSearch.trim().length > 0;

  return (
    <>
      <div className='relative'>
        <Search className='absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground' />
        <Input
          className='pl-9'
          onChange={(e) => setFormulaeSearch(e.target.value)}
          placeholder='Search formulae...'
          value={formulaeSearch}
        />
        {searching && (
          <Loader2 className='absolute top-1/2 right-3 size-4 -translate-y-1/2 animate-spin text-muted-foreground' />
        )}
      </div>

      <FormulaeList
        filteredFormulae={filteredFormulae}
        hasSearch={hasSearch}
        installedNames={installedFormulaNames}
        loading={loading}
        onInstall={onInstall}
        onUninstall={onUninstall}
        onUpgrade={onUpgrade}
        operating={operating}
        searching={searching}
        searchResults={searchResults}
      />
    </>
  );
}
