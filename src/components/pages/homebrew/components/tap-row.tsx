import { GitBranch, Minus } from 'lucide-react';
import { Button } from '@/components/ui/button';
import type { Tap } from '@/lib/homebrew';

interface TapRowProps {
  tap: Tap;
  onUntap: () => void;
  operating: boolean;
}

export function TapRow({ tap, onUntap, operating }: TapRowProps) {
  return (
    <div className='flex items-center justify-between rounded-xl bg-muted p-4'>
      <div className='flex items-center gap-4'>
        <div className='flex size-10 shrink-0 items-center justify-center rounded-lg bg-muted-foreground/10'>
          <GitBranch className='size-5 text-muted-foreground' />
        </div>
        <div className='flex flex-col gap-0.5'>
          <span className='font-medium'>{tap.name}</span>
          {tap.official && (
            <span className='text-muted-foreground text-sm'>Official</span>
          )}
        </div>
      </div>
      {!tap.official && (
        <Button
          disabled={operating}
          onClick={onUntap}
          size='sm'
          variant='ghost'
        >
          <Minus className='size-4' />
        </Button>
      )}
    </div>
  );
}
