import { ChevronLeft, ChevronRight } from 'lucide-react';
import { useMemo, useState } from 'react';

import { Button } from '@/components/ui/button';
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from '@/components/ui/tooltip';
import type { DailyUsage } from '@/lib/claude-usage';
import { formatCost, formatTokens } from '@/lib/claude-usage';

import { DayDetailModal } from './day-detail-modal';

interface UsageCalendarProps {
  daily: DailyUsage[];
  isLoading: boolean;
}

interface DayData {
  date: Date;
  dateStr: string;
  cost: number;
  tokens: number;
  requests: number;
  level: number;
  isInYear: boolean;
  isFuture: boolean;
}

const MONTH_LABELS = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const DAY_LABELS = ['Mon', '', 'Wed', '', 'Fri', '', 'Sun'];

const LEVEL_COLORS = [
  'bg-muted',
  'bg-green-200 dark:bg-green-900',
  'bg-green-400 dark:bg-green-700',
  'bg-green-600 dark:bg-green-500',
  'bg-green-800 dark:bg-green-300',
];

const CELL_SIZE = 10;
const CELL_GAP = 3;

function getColorLevel(cost: number): number {
  if (cost === 0) return 0;
  if (cost < 1) return 1;
  if (cost < 5) return 2;
  if (cost < 10) return 3;
  return 4;
}

function generateYearCalendarData(
  daily: DailyUsage[],
  year: number
): {
  weeks: DayData[][];
  monthPositions: { month: number; weekIndex: number }[];
} {
  const dailyMap = new Map<string, DailyUsage>();
  for (const d of daily) {
    dailyMap.set(d.date, d);
  }

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  // Start from January 1st of the selected year
  const jan1 = new Date(year, 0, 1);
  // Find the Monday of the week containing Jan 1 (or Jan 1 if it's Monday)
  // getDay(): 0=Sunday, 1=Monday, ..., 6=Saturday
  const jan1Day = jan1.getDay();
  const startDate = new Date(jan1);
  // If Jan 1 is Sunday (0), go back 6 days to Monday
  // If Jan 1 is Monday (1), stay at Jan 1
  // If Jan 1 is Tuesday (2), go back 1 day
  const daysToMonday = jan1Day === 0 ? 6 : jan1Day - 1;
  startDate.setDate(jan1.getDate() - daysToMonday);

  // End at December 31st of the selected year
  const dec31 = new Date(year, 11, 31);
  // Find the Sunday of the week containing Dec 31
  const dec31Day = dec31.getDay();
  const endDate = new Date(dec31);
  // If Dec 31 is Sunday (0), stay at Dec 31
  // Otherwise, go forward to next Sunday
  const daysToSunday = dec31Day === 0 ? 0 : 7 - dec31Day;
  endDate.setDate(dec31.getDate() + daysToSunday);

  const days: DayData[] = [];
  const currentDate = new Date(startDate);

  while (currentDate <= endDate) {
    const dateStr = currentDate.toISOString().split('T')[0];
    const usage = dailyMap.get(dateStr);
    const isFuture = currentDate > today;
    const isInYear = currentDate.getFullYear() === year;

    const hasData = !isFuture && isInYear;
    const cost = hasData ? (usage?.total_cost ?? 0) : 0;
    const tokens = hasData
      ? (usage?.input_tokens ?? 0) +
        (usage?.output_tokens ?? 0) +
        (usage?.cache_creation_tokens ?? 0) +
        (usage?.cache_read_tokens ?? 0)
      : 0;
    const requests = hasData ? (usage?.request_count ?? 0) : 0;

    days.push({
      date: new Date(currentDate),
      dateStr,
      cost,
      tokens,
      requests,
      level: hasData ? getColorLevel(cost) : -1,
      isInYear,
      isFuture,
    });

    currentDate.setDate(currentDate.getDate() + 1);
  }

  // Group into weeks (columns) - each week has 7 days (Mon-Sun)
  const weeks: DayData[][] = [];
  for (let i = 0; i < days.length; i += 7) {
    weeks.push(days.slice(i, i + 7));
  }

  // Calculate month label positions
  const monthPositions: { month: number; weekIndex: number }[] = [];
  const seenMonths = new Set<number>();

  weeks.forEach((week, weekIndex) => {
    // Check first day of week that's in the target year
    for (const day of week) {
      if (day.isInYear) {
        const month = day.date.getMonth();
        if (!seenMonths.has(month)) {
          seenMonths.add(month);
          monthPositions.push({ month, weekIndex });
        }
        break;
      }
    }
  });

  return { weeks, monthPositions };
}

interface DayCellProps {
  day: DayData;
  onClick: () => void;
}

function DayCell({ day, onClick }: DayCellProps) {
  // Empty cell for dates outside the year or future dates
  if (!day.isInYear || day.isFuture) {
    return (
      <div
        style={{
          width: CELL_SIZE,
          height: CELL_SIZE,
          borderRadius: 2,
        }}
      />
    );
  }

  const formattedDate = day.date.toLocaleDateString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });

  return (
    <Tooltip>
      <TooltipTrigger asChild>
        <button
          className={`cursor-pointer transition-colors hover:ring-1 hover:ring-foreground/30 ${LEVEL_COLORS[day.level]}`}
          onClick={onClick}
          style={{
            width: CELL_SIZE,
            height: CELL_SIZE,
            borderRadius: 2,
          }}
          type='button'
        />
      </TooltipTrigger>
      <TooltipContent className='text-xs' side='top'>
        <div className='font-medium'>{formattedDate}</div>
        {day.cost > 0 ? (
          <div className='mt-1 text-muted-foreground'>
            {formatCost(day.cost)} · {formatTokens(day.tokens)} tokens ·{' '}
            {day.requests} req
          </div>
        ) : (
          <div className='mt-1 text-muted-foreground'>No usage</div>
        )}
      </TooltipContent>
    </Tooltip>
  );
}

export function UsageCalendar({ daily, isLoading }: UsageCalendarProps) {
  const currentYear = new Date().getFullYear();
  const [selectedYear, setSelectedYear] = useState(currentYear);
  const [selectedDate, setSelectedDate] = useState<string | null>(null);

  const { weeks, monthPositions } = useMemo(
    () => generateYearCalendarData(daily, selectedYear),
    [daily, selectedYear]
  );

  if (isLoading) {
    return (
      <div className='rounded-xl bg-muted/50 p-5'>
        <div className='mb-3 h-5 w-32 animate-pulse rounded bg-muted' />
        <div className='h-24 animate-pulse rounded bg-muted' />
      </div>
    );
  }

  const canGoNext = selectedYear < currentYear;
  const canGoPrev = selectedYear > currentYear - 5;

  // Calculate total width for positioning month labels
  const totalWidth = weeks.length * (CELL_SIZE + CELL_GAP) - CELL_GAP;

  return (
    <>
      <div className='overflow-x-auto rounded-xl bg-muted/50 p-5'>
        {/* Header with year navigation */}
        <div className='mb-4 flex items-center justify-between'>
          <div className='flex items-center gap-1'>
            <Button
              className='h-7 w-7'
              disabled={!canGoPrev}
              onClick={() => setSelectedYear((y) => y - 1)}
              size='icon'
              variant='ghost'
            >
              <ChevronLeft className='h-4 w-4' />
            </Button>
            <span className='w-12 text-center font-medium text-sm'>
              {selectedYear}
            </span>
            <Button
              className='h-7 w-7'
              disabled={!canGoNext}
              onClick={() => setSelectedYear((y) => y + 1)}
              size='icon'
              variant='ghost'
            >
              <ChevronRight className='h-4 w-4' />
            </Button>
          </div>
          {/* Legend */}
          <div className='flex items-center text-[10px] text-muted-foreground'>
            <span className='mr-1'>Less</span>
            {LEVEL_COLORS.map((color, i) => (
              <div
                className={color}
                key={i}
                style={{
                  width: CELL_SIZE,
                  height: CELL_SIZE,
                  marginLeft: i === 0 ? 0 : 2,
                  borderRadius: 2,
                }}
              />
            ))}
            <span className='ml-1'>More</span>
          </div>
        </div>

        {/* Calendar container */}
        <div className='inline-flex'>
          {/* Day labels - need extra top margin to align with grid (skip month label row) */}
          <div
            className='flex flex-col pr-2 text-[10px] text-muted-foreground'
            style={{ gap: CELL_GAP, marginTop: 20 }}
          >
            {DAY_LABELS.map((label, i) => (
              <div
                className='w-6 text-right'
                key={i}
                style={{ height: CELL_SIZE, lineHeight: `${CELL_SIZE}px` }}
              >
                {label}
              </div>
            ))}
          </div>

          {/* Grid with month labels */}
          <div>
            {/* Month labels */}
            <div
              className='relative mb-1'
              style={{ width: totalWidth, height: 16 }}
            >
              {monthPositions.map(({ month, weekIndex }) => (
                <div
                  className='absolute text-[10px] text-muted-foreground'
                  key={month}
                  style={{
                    left: weekIndex * (CELL_SIZE + CELL_GAP),
                  }}
                >
                  {MONTH_LABELS[month]}
                </div>
              ))}
            </div>

            {/* Grid */}
            <div className='flex' style={{ gap: CELL_GAP }}>
              {weeks.map((week, weekIndex) => (
                <div
                  className='flex flex-col'
                  key={weekIndex}
                  style={{ gap: CELL_GAP }}
                >
                  {week.map((day, dayIndex) => (
                    <DayCell
                      day={day}
                      key={`${weekIndex}-${dayIndex}`}
                      onClick={() =>
                        day.isInYear &&
                        !day.isFuture &&
                        setSelectedDate(day.dateStr)
                      }
                    />
                  ))}
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {selectedDate && (
        <DayDetailModal
          daily={daily}
          date={selectedDate}
          onClose={() => setSelectedDate(null)}
          open={true}
        />
      )}
    </>
  );
}
