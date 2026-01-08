import { Box } from 'lucide-react';
import { Skeleton } from '@/components/ui/skeleton';
import type { Package } from '@/lib/homebrew';
import { EmptyState } from './empty-state';
import { PackageItem } from './package-item';

interface UpdatesListProps {
  loading: boolean;
  outdated: Package[];
  operating: boolean;
  onUpgrade: (name: string) => void;
}

export function UpdatesList({
  loading,
  outdated,
  operating,
  onUpgrade,
}: UpdatesListProps) {
  if (loading) {
    return (
      <div className='grid grid-cols-2 gap-2'>
        {Array.from({ length: 4 }).map((_, i) => (
          <Skeleton className='h-12 w-full rounded-lg' key={i} />
        ))}
      </div>
    );
  }

  if (outdated.length === 0) {
    return (
      <EmptyState
        icon={<Box className='size-12 text-muted-foreground' />}
        message='All packages are up to date'
      />
    );
  }

  return (
    <div className='grid grid-cols-2 gap-2'>
      {outdated.map((pkg) => (
        <PackageItem
          key={pkg.name}
          onUpgrade={() => onUpgrade(pkg.name)}
          operating={operating}
          pkg={pkg}
          type='formula'
          variant='installed'
        />
      ))}
    </div>
  );
}
