import { TrendingDown, TrendingUp } from 'lucide-react';

import type { DailyUsage } from '@/lib/claude-usage';
import { formatCost } from '@/lib/claude-usage';

interface CostSummaryProps {
  daily: DailyUsage[];
  isLoading: boolean;
}

interface PeriodData {
  current: number;
  previous: number;
  change: number;
}

function calculatePeriodData(
  daily: DailyUsage[],
  periodDays: number
): PeriodData {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const currentPeriodStart = new Date(today);
  currentPeriodStart.setDate(today.getDate() - periodDays + 1);

  const previousPeriodStart = new Date(currentPeriodStart);
  previousPeriodStart.setDate(previousPeriodStart.getDate() - periodDays);

  let current = 0;
  let previous = 0;

  for (const day of daily) {
    const date = new Date(day.date);
    date.setHours(0, 0, 0, 0);

    if (date >= currentPeriodStart && date <= today) {
      current += day.total_cost;
    } else if (date >= previousPeriodStart && date < currentPeriodStart) {
      previous += day.total_cost;
    }
  }

  const change = previous > 0 ? ((current - previous) / previous) * 100 : 0;

  return { current, previous, change };
}

function getTodayData(daily: DailyUsage[]): PeriodData {
  const today = new Date().toISOString().split('T')[0];
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = yesterday.toISOString().split('T')[0];

  const todayUsage = daily.find((d) => d.date === today);
  const yesterdayUsage = daily.find((d) => d.date === yesterdayStr);

  const current = todayUsage?.total_cost ?? 0;
  const previous = yesterdayUsage?.total_cost ?? 0;
  const change = previous > 0 ? ((current - previous) / previous) * 100 : 0;

  return { current, previous, change };
}

interface CostCardProps {
  label: string;
  value: number;
  change: number;
  isLoading: boolean;
}

function CostCard({ label, value, change, isLoading }: CostCardProps) {
  if (isLoading) {
    return (
      <div className='flex flex-col gap-1'>
        <span className='text-muted-foreground text-sm'>{label}</span>
        <div className='h-8 w-20 animate-pulse rounded bg-muted' />
        <div className='h-4 w-16 animate-pulse rounded bg-muted' />
      </div>
    );
  }

  const isPositive = change > 0;
  const isNeutral = change === 0;

  return (
    <div className='flex flex-col gap-1'>
      <span className='text-muted-foreground text-sm'>{label}</span>
      <span className='font-semibold text-2xl'>{formatCost(value)}</span>
      {!isNeutral && (
        <div
          className={`flex items-center gap-1 text-sm ${
            isPositive ? 'text-red-500' : 'text-green-500'
          }`}
        >
          {isPositive ? (
            <TrendingUp className='h-3.5 w-3.5' />
          ) : (
            <TrendingDown className='h-3.5 w-3.5' />
          )}
          <span>{Math.abs(change).toFixed(0)}%</span>
        </div>
      )}
      {isNeutral && <div className='text-muted-foreground text-sm'>—</div>}
    </div>
  );
}

export function CostSummary({ daily, isLoading }: CostSummaryProps) {
  const todayData = getTodayData(daily);
  const weekData = calculatePeriodData(daily, 7);
  const monthData = calculatePeriodData(daily, 30);

  return (
    <div className='flex gap-12'>
      <CostCard
        change={todayData.change}
        isLoading={isLoading}
        label='Today'
        value={todayData.current}
      />
      <CostCard
        change={weekData.change}
        isLoading={isLoading}
        label='This Week'
        value={weekData.current}
      />
      <CostCard
        change={monthData.change}
        isLoading={isLoading}
        label='This Month'
        value={monthData.current}
      />
    </div>
  );
}
