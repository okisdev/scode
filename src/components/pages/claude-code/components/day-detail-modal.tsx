import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import type { DailyUsage } from '@/lib/claude-usage';
import {
  formatCost,
  formatTokens,
  getModelDisplayName,
} from '@/lib/claude-usage';

interface DayDetailModalProps {
  date: string;
  daily: DailyUsage[];
  open: boolean;
  onClose: () => void;
}

function getModelColor(displayName: string): string {
  if (displayName.includes('Opus')) {
    return 'bg-purple-500';
  }
  if (displayName.includes('Sonnet')) {
    return 'bg-blue-500';
  }
  if (displayName.includes('Haiku')) {
    return 'bg-green-500';
  }
  return 'bg-gray-500';
}

export function DayDetailModal({
  date,
  daily,
  open,
  onClose,
}: DayDetailModalProps) {
  const dayData = daily.find((d) => d.date === date);

  const formattedDate = new Date(date).toLocaleDateString('en-US', {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  });

  const totalTokens = dayData
    ? dayData.input_tokens +
      dayData.output_tokens +
      dayData.cache_creation_tokens +
      dayData.cache_read_tokens
    : 0;

  return (
    <Dialog onOpenChange={(isOpen) => !isOpen && onClose()} open={open}>
      <DialogContent className='sm:max-w-md'>
        <DialogHeader>
          <DialogTitle>{formattedDate}</DialogTitle>
        </DialogHeader>

        {dayData ? (
          <div className='space-y-6'>
            {/* Summary stats */}
            <div className='flex gap-6 text-sm'>
              <div>
                <div className='text-muted-foreground'>Cost</div>
                <div className='font-semibold text-lg'>
                  {formatCost(dayData.total_cost)}
                </div>
              </div>
              <div>
                <div className='text-muted-foreground'>Tokens</div>
                <div className='font-semibold text-lg'>
                  {formatTokens(totalTokens)}
                </div>
              </div>
              <div>
                <div className='text-muted-foreground'>Requests</div>
                <div className='font-semibold text-lg'>
                  {dayData.request_count}
                </div>
              </div>
            </div>

            {/* Token breakdown */}
            <div className='rounded-lg bg-muted/50 p-4'>
              <div className='mb-3 font-medium text-sm'>Token Breakdown</div>
              <div className='grid grid-cols-2 gap-3 text-sm'>
                <div className='flex justify-between'>
                  <span className='text-muted-foreground'>Input</span>
                  <span>{formatTokens(dayData.input_tokens)}</span>
                </div>
                <div className='flex justify-between'>
                  <span className='text-muted-foreground'>Output</span>
                  <span>{formatTokens(dayData.output_tokens)}</span>
                </div>
                <div className='flex justify-between'>
                  <span className='text-muted-foreground'>Cache Write</span>
                  <span>{formatTokens(dayData.cache_creation_tokens)}</span>
                </div>
                <div className='flex justify-between'>
                  <span className='text-muted-foreground'>Cache Read</span>
                  <span>{formatTokens(dayData.cache_read_tokens)}</span>
                </div>
              </div>
            </div>

            {/* Models used */}
            {dayData.models_used.length > 0 && (
              <div>
                <div className='mb-3 font-medium text-sm'>Models Used</div>
                <div className='flex flex-wrap gap-2'>
                  {dayData.models_used.map((model) => {
                    const displayName = getModelDisplayName(model);
                    const color = getModelColor(displayName);
                    return (
                      <div
                        className='flex items-center gap-1.5 rounded-full bg-muted px-3 py-1 text-sm'
                        key={model}
                      >
                        <div className={`h-2 w-2 rounded-full ${color}`} />
                        <span>{displayName}</span>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}
          </div>
        ) : (
          <div className='py-8 text-center text-muted-foreground'>
            No usage data for this day
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
