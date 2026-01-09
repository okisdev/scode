import type { DailyUsage } from '@/lib/claude-usage';
import { formatCost, formatTokens } from '@/lib/claude-usage';

interface DailyTableProps {
  daily: DailyUsage[];
  isLoading: boolean;
}

export function DailyTable({ daily, isLoading }: DailyTableProps) {
  if (isLoading) {
    return (
      <div className='rounded-xl bg-muted/50 p-5'>
        <div className='mb-3 h-5 w-32 animate-pulse rounded bg-muted' />
        <div className='space-y-2'>
          {[...new Array(5)].map((_, i) => (
            <div className='h-8 animate-pulse rounded bg-muted' key={i} />
          ))}
        </div>
      </div>
    );
  }

  // Sort by date descending (newest first)
  const sortedDaily = [...daily].sort(
    (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()
  );

  if (sortedDaily.length === 0) {
    return (
      <div className='rounded-xl bg-muted/50 p-5'>
        <div className='font-medium text-sm'>Daily Usage</div>
        <div className='mt-3 text-muted-foreground text-sm'>No usage data</div>
      </div>
    );
  }

  return (
    <div className='rounded-xl bg-muted/50 p-5'>
      <div className='mb-4 font-medium text-sm'>Daily Usage</div>
      <div className='overflow-x-auto'>
        <table className='w-full text-sm'>
          <thead>
            <tr className='text-left text-muted-foreground text-xs'>
              <th className='pr-4 pb-2 font-medium'>Date</th>
              <th className='pr-4 pb-2 text-right font-medium'>Cost</th>
              <th className='pr-4 pb-2 text-right font-medium'>Input</th>
              <th className='pr-4 pb-2 text-right font-medium'>Output</th>
              <th className='pr-4 pb-2 text-right font-medium'>Cache</th>
              <th className='pb-2 text-right font-medium'>Requests</th>
            </tr>
          </thead>
          <tbody className='divide-y divide-muted'>
            {sortedDaily.map((day) => {
              const date = new Date(day.date);
              const formattedDate = date.toLocaleDateString('en-US', {
                month: 'short',
                day: 'numeric',
              });
              const cacheTokens =
                day.cache_creation_tokens + day.cache_read_tokens;

              return (
                <tr className='hover:bg-muted/30' key={day.date}>
                  <td className='py-2 pr-4'>{formattedDate}</td>
                  <td className='py-2 pr-4 text-right'>
                    {formatCost(day.total_cost)}
                  </td>
                  <td className='py-2 pr-4 text-right text-muted-foreground'>
                    {formatTokens(day.input_tokens)}
                  </td>
                  <td className='py-2 pr-4 text-right text-muted-foreground'>
                    {formatTokens(day.output_tokens)}
                  </td>
                  <td className='py-2 pr-4 text-right text-muted-foreground'>
                    {formatTokens(cacheTokens)}
                  </td>
                  <td className='py-2 text-right text-muted-foreground'>
                    {day.request_count}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
