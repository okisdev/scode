import { Globe, HardDrive, Loader2 } from 'lucide-react';
import { Skeleton } from '@/components/ui/skeleton';
import type { Package } from '@/lib/homebrew';
import { PackageItem } from './package-item';

interface FormulaeListProps {
  loading: boolean;
  hasSearch: boolean;
  searching: boolean;
  searchResults: Package[];
  filteredFormulae: Package[];
  installedNames: Set<string>;
  operating: boolean;
  onInstall: (name: string) => void;
  onUninstall: (name: string) => void;
  onUpgrade: (name: string) => void;
}

export function FormulaeList({
  loading,
  hasSearch,
  searching,
  searchResults,
  filteredFormulae,
  installedNames,
  operating,
  onInstall,
  onUninstall,
  onUpgrade,
}: FormulaeListProps) {
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
          <span>Installed ({filteredFormulae.length})</span>
        </div>
        {filteredFormulae.length === 0 ? (
          <p className='py-4 text-center text-muted-foreground text-sm'>
            {hasSearch
              ? 'No matching installed formulae'
              : 'No formulae installed'}
          </p>
        ) : (
          <div className='grid grid-cols-2 gap-2'>
            {filteredFormulae.map((pkg) => (
              <PackageItem
                key={pkg.name}
                onUninstall={() => onUninstall(pkg.name)}
                onUpgrade={pkg.outdated ? () => onUpgrade(pkg.name) : undefined}
                operating={operating}
                pkg={pkg}
                type='formula'
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
              No available packages found
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
                  type='formula'
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
