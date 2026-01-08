import { Skeleton } from '@/components/ui/skeleton';
import type { Tap } from '@/lib/homebrew';
import { TapRow } from './tap-row';

interface TapsListProps {
  loading: boolean;
  taps: Tap[];
  operating: boolean;
  onUntap: (name: string) => void;
}

export function TapsList({ loading, taps, operating, onUntap }: TapsListProps) {
  if (loading) {
    return (
      <div className='grid grid-cols-2 gap-3'>
        {Array.from({ length: 4 }).map((_, i) => (
          <Skeleton className='h-[72px] w-full rounded-xl' key={i} />
        ))}
      </div>
    );
  }

  if (taps.length === 0) {
    return (
      <p className='py-8 text-center text-muted-foreground'>
        No taps configured
      </p>
    );
  }

  return (
    <div className='grid grid-cols-2 gap-3'>
      {taps.map((tap) => (
        <TapRow
          key={tap.name}
          onUntap={() => onUntap(tap.name)}
          operating={operating}
          tap={tap}
        />
      ))}
    </div>
  );
}
