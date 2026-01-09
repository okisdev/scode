import { TooltipProvider } from '@/components/ui/tooltip';
import { useClaudeUsage } from '@/hooks/use-claude-usage';

import { CostSummary } from './components/cost-summary';
import { DailyTable } from './components/daily-table';
import { ModelBreakdown } from './components/model-breakdown';
import { ProjectsSection } from './components/projects-section';
import { RecentSessions } from './components/recent-sessions';
import { UsageCalendar } from './components/usage-calendar';

export function ClaudeCodeUsagePage() {
  const { daily, models, projects, blocksEntries, isLoading } =
    useClaudeUsage();

  return (
    <TooltipProvider>
      <div className='flex flex-1 flex-col gap-6 p-6'>
        {/* Header */}
        <div className='space-y-1'>
          <h1 className='font-bold text-2xl'>Usage</h1>
          <p className='text-muted-foreground text-sm'>
            Track your Claude Code usage and costs
          </p>
        </div>

        {/* Cost Summary */}
        <CostSummary daily={daily} isLoading={isLoading} />

        {/* Calendar */}
        <UsageCalendar daily={daily} isLoading={isLoading} />

        {/* Models + Recent Sessions */}
        <div className='grid gap-6 lg:grid-cols-2'>
          <ModelBreakdown isLoading={isLoading} models={models} />
          <RecentSessions entries={blocksEntries} isLoading={isLoading} />
        </div>

        {/* Daily Table */}
        <DailyTable daily={daily} isLoading={isLoading} />

        {/* Projects */}
        <ProjectsSection isLoading={isLoading} projects={projects} />
      </div>
    </TooltipProvider>
  );
}
