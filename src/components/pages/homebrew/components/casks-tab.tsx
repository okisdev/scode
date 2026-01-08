import { Loader2, Search } from 'lucide-react';
import { Input } from '@/components/ui/input';
import type { Cask, Package } from '@/lib/homebrew';
import { CasksList } from './casks-list';

interface CasksTabProps {
  caskSearch: string;
  setCaskSearch: (value: string) => void;
  searching: boolean;
  loading: boolean;
  searchResults: Package[];
  filteredCasks: Cask[];
  installedCaskNames: Set<string>;
  operating: boolean;
  onInstall: (name: string) => void;
  onUninstall: (name: string) => void;
}

export function CasksTab({
  caskSearch,
  setCaskSearch,
  searching,
  loading,
  searchResults,
  filteredCasks,
  installedCaskNames,
  operating,
  onInstall,
  onUninstall,
}: CasksTabProps) {
  const hasSearch = caskSearch.trim().length > 0;

  return (
    <>
      <div className='relative'>
        <Search className='absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground' />
        <Input
          className='pl-9'
          onChange={(e) => setCaskSearch(e.target.value)}
          placeholder='Search casks...'
          value={caskSearch}
        />
        {searching && (
          <Loader2 className='absolute top-1/2 right-3 size-4 -translate-y-1/2 animate-spin text-muted-foreground' />
        )}
      </div>

      <CasksList
        filteredCasks={filteredCasks}
        hasSearch={hasSearch}
        installedNames={installedCaskNames}
        loading={loading}
        onInstall={onInstall}
        onUninstall={onUninstall}
        operating={operating}
        searching={searching}
        searchResults={searchResults}
      />
    </>
  );
}
