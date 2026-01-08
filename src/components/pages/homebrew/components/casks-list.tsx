import { Globe, HardDrive, Loader2 } from 'lucide-react';
import { Skeleton } from '@/components/ui/skeleton';
import type { Cask, Package } from '@/lib/homebrew';
import { PackageItem } from './package-item';

interface CasksListProps {
  loading: boolean;
  hasSearch: boolean;
  searching: boolean;
  searchResults: Package[];
  filteredCasks: Cask[];
  installedNames: Set<string>;
  operating: boolean;
  onInstall: (name: string) => void;
  onUninstall: (name: string) => void;
}

export function CasksList({
  loading,
  hasSearch,
  searching,
  searchResults,
  filteredCasks,
  installedNames,
  operating,
  onInstall,
  onUninstall,
}: CasksListProps) {
  if (loading) {
    return (
      <div className='space-y-2'>
        <div className='flex items-center gap-2 text-muted-foreground text-sm'>
          <HardDrive className='size-4' />
          <span>Installed</span>
        </div>
        <div className='grid grid-cols-2 gap-2'>
          {Array.from({ length: 6 }).map((_, i) => (
            <Skeleton className='h-12 w-full rounded-lg' key={i} />
          ))}
        </div>
      </div>
    );
  }

  // Filter out already installed packages from network results
  const networkResults = searchResults.filter(
    (pkg) => !installedNames.has(pkg.name)
  );

  return (
    <div className='space-y-4'>
      {/* Installed */}
      <div className='space-y-2'>
        <div className='flex items-center gap-2 text-muted-foreground text-sm'>
          <HardDrive className='size-4' />
          <span>Installed ({filteredCasks.length})</span>
        </div>
        {filteredCasks.length === 0 ? (
          <p className='py-4 text-center text-muted-foreground text-sm'>
            {hasSearch ? 'No matching installed casks' : 'No casks installed'}
          </p>
        ) : (
          <div className='grid grid-cols-2 gap-2'>
            {filteredCasks.map((cask) => (
              <PackageItem
                key={cask.name}
                onUninstall={() => onUninstall(cask.name)}
                operating={operating}
                pkg={cask}
                type='cask'
                variant='installed'
              />
            ))}
          </div>
        )}
      </div>

      {/* Available (only show when searching) */}
      {hasSearch && (
        <div className='space-y-2'>
          <div className='flex items-center gap-2 text-muted-foreground text-sm'>
            <Globe className='size-4' />
            <span>
              Available
              {searching ? '' : ` (${networkResults.length})`}
            </span>
            {searching && <Loader2 className='size-3 animate-spin' />}
          </div>
          {searching ? (
            <div className='grid grid-cols-2 gap-2'>
              {Array.from({ length: 4 }).map((_, i) => (
                <Skeleton className='h-12 w-full rounded-lg' key={i} />
              ))}
            </div>
          ) : networkResults.length === 0 ? (
            <p className='py-4 text-center text-muted-foreground text-sm'>
              No available applications found
            </p>
          ) : (
            <div className='grid grid-cols-2 gap-2'>
              {networkResults.map((pkg) => (
                <PackageItem
                  isInstalled={installedNames.has(pkg.name)}
                  key={pkg.name}
                  onInstall={() => onInstall(pkg.name)}
                  operating={operating}
                  pkg={pkg}
                  type='cask'
                  variant='search'
                />
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
