import { ChevronDown } from 'lucide-react';
import { useMemo, useState } from 'react';

import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from '@/components/ui/collapsible';
import type { ModelUsage } from '@/lib/claude-usage';
import { formatCost, formatTokens } from '@/lib/claude-usage';

interface ModelBreakdownProps {
  models: ModelUsage[];
  isLoading: boolean;
}

interface GroupedModel {
  displayName: string;
  totalCost: number;
  totalTokens: number;
  percentage: number;
  models: ModelUsage[];
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

function groupModels(models: ModelUsage[]): GroupedModel[] {
  const groups = new Map<string, GroupedModel>();

  for (const model of models) {
    const existing = groups.get(model.display_name);
    if (existing) {
      existing.totalCost += model.total_cost;
      existing.totalTokens += model.input_tokens + model.output_tokens;
      existing.models.push(model);
    } else {
      groups.set(model.display_name, {
        displayName: model.display_name,
        totalCost: model.total_cost,
        totalTokens: model.input_tokens + model.output_tokens,
        percentage: 0,
        models: [model],
      });
    }
  }

  // Recalculate percentages based on grouped totals
  const totalCost = Array.from(groups.values()).reduce(
    (sum, g) => sum + g.totalCost,
    0
  );
  for (const group of groups.values()) {
    group.percentage = totalCost > 0 ? (group.totalCost / totalCost) * 100 : 0;
  }

  return Array.from(groups.values()).sort((a, b) => b.totalCost - a.totalCost);
}

interface GroupedModelItemProps {
  group: GroupedModel;
}

function GroupedModelItem({ group }: GroupedModelItemProps) {
  const [open, setOpen] = useState(false);
  const barColor = getModelColor(group.displayName);
  const hasMultipleModels = group.models.length > 1;

  // Calculate percentage for each sub-model within the group
  const subModelPercentages = group.models.map((m) => ({
    ...m,
    groupPercentage:
      group.totalCost > 0 ? (m.total_cost / group.totalCost) * 100 : 0,
  }));

  return (
    <Collapsible onOpenChange={setOpen} open={open}>
      <div>
        <CollapsibleTrigger
          className='-mx-2 flex w-full items-center justify-between rounded px-2 py-1 text-sm hover:bg-muted/50'
          disabled={!hasMultipleModels}
        >
          <div className='flex items-center gap-2'>
            {hasMultipleModels && (
              <ChevronDown
                className={`h-3 w-3 text-muted-foreground transition-transform ${
                  open ? 'rotate-180' : ''
                }`}
              />
            )}
            {!hasMultipleModels && <div className='w-3' />}
            <span>{group.displayName}</span>
          </div>
          <span className='text-muted-foreground'>
            {formatCost(group.totalCost)} · {group.percentage.toFixed(0)}%
          </span>
        </CollapsibleTrigger>

        <div className='mt-1 ml-5'>
          <div className='h-1.5 w-full rounded-full bg-muted'>
            <div
              className={`h-full rounded-full ${barColor}`}
              style={{ width: `${group.percentage}%` }}
            />
          </div>
        </div>

        {hasMultipleModels && (
          <CollapsibleContent>
            <div className='mt-2 ml-5 space-y-1.5 text-xs'>
              {subModelPercentages
                .sort((a, b) => b.total_cost - a.total_cost)
                .map((model) => (
                  <div
                    className='flex items-center justify-between text-muted-foreground'
                    key={model.model}
                  >
                    <span className='truncate font-mono' title={model.model}>
                      {model.model}
                    </span>
                    <span className='ml-2 shrink-0'>
                      {formatCost(model.total_cost)} ·{' '}
                      {formatTokens(model.input_tokens + model.output_tokens)}
                    </span>
                  </div>
                ))}
            </div>
          </CollapsibleContent>
        )}
      </div>
    </Collapsible>
  );
}

export function ModelBreakdown({ models, isLoading }: ModelBreakdownProps) {
  const groupedModels = useMemo(() => groupModels(models), [models]);

  if (isLoading) {
    return (
      <div className='rounded-xl bg-muted/50 p-5'>
        <div className='mb-3 h-5 w-24 animate-pulse rounded bg-muted' />
        <div className='space-y-3'>
          {[...new Array(3)].map((_, i) => (
            <div className='h-8 animate-pulse rounded bg-muted' key={i} />
          ))}
        </div>
      </div>
    );
  }

  if (groupedModels.length === 0) {
    return (
      <div className='rounded-xl bg-muted/50 p-5'>
        <div className='font-medium text-sm'>Models</div>
        <div className='mt-3 text-muted-foreground text-sm'>No usage data</div>
      </div>
    );
  }

  return (
    <div className='rounded-xl bg-muted/50 p-5'>
      <div className='mb-4 font-medium text-sm'>Models</div>
      <div className='space-y-3'>
        {groupedModels.map((group) => (
          <GroupedModelItem group={group} key={group.displayName} />
        ))}
      </div>
    </div>
  );
}
