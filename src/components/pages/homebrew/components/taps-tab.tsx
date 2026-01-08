import { GitBranch, Plus } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import type { Tap } from '@/lib/homebrew';
import { TapsList } from './taps-list';

interface TapsTabProps {
  newTapName: string;
  setNewTapName: (value: string) => void;
  handleAddTap: () => void;
  loading: boolean;
  operating: boolean;
  taps: Tap[];
  onUntap: (name: string) => void;
}

export function TapsTab({
  newTapName,
  setNewTapName,
  handleAddTap,
  loading,
  operating,
  taps,
  onUntap,
}: TapsTabProps) {
  return (
    <>
      <div className='flex items-center gap-3'>
        <div className='relative flex-1'>
          <GitBranch className='absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground' />
          <Input
            className='pl-9'
            onChange={(e) => setNewTapName(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                handleAddTap();
              }
            }}
            placeholder='user/repo (e.g., homebrew/cask-fonts)'
            value={newTapName}
          />
        </div>
        <Button
          className='gap-2'
          disabled={operating || !newTapName.trim()}
          onClick={handleAddTap}
          variant='outline'
        >
          <Plus className='size-4' />
          Add Tap
        </Button>
      </div>

      <div className='space-y-1'>
        <h3 className='font-semibold'>Configured Taps</h3>
        <p className='text-muted-foreground text-sm'>
          {taps.length} third-party repositories
        </p>
      </div>

      <TapsList
        loading={loading}
        onUntap={onUntap}
        operating={operating}
        taps={taps}
      />
    </>
  );
}
