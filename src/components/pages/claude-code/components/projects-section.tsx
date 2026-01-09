import { Folder, Info } from 'lucide-react';

import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from '@/components/ui/tooltip';
import type { ProjectUsage } from '@/lib/claude-usage';
import { formatCost, formatTokens } from '@/lib/claude-usage';

interface ProjectsSectionProps {
  projects: ProjectUsage[];
  isLoading: boolean;
}

export function ProjectsSection({ projects, isLoading }: ProjectsSectionProps) {
  if (isLoading) {
    return (
      <div className='rounded-xl bg-muted/50 p-5'>
        <div className='mb-3 h-5 w-24 animate-pulse rounded bg-muted' />
        <div className='space-y-2'>
          {[...new Array(3)].map((_, i) => (
            <div className='h-12 animate-pulse rounded bg-muted' key={i} />
          ))}
        </div>
      </div>
    );
  }

  // Sort by cost descending
  const sortedProjects = [...projects].sort(
    (a, b) => b.total_cost - a.total_cost
  );

  if (sortedProjects.length === 0) {
    return (
      <div className='rounded-xl bg-muted/50 p-5'>
        <div className='font-medium text-sm'>Projects</div>
        <div className='mt-3 text-muted-foreground text-sm'>
          No project data
        </div>
      </div>
    );
  }

  const maxCost = Math.max(...sortedProjects.map((p) => p.total_cost));

  return (
    <div className='rounded-xl bg-muted/50 p-5'>
      <div className='mb-4 font-medium text-sm'>Projects</div>
      <div className='space-y-3'>
        {sortedProjects.map((project) => {
          const totalTokens =
            project.input_tokens +
            project.output_tokens +
            project.cache_creation_tokens +
            project.cache_read_tokens;
          const barWidth =
            maxCost > 0 ? (project.total_cost / maxCost) * 100 : 0;

          return (
            <div key={project.project_path}>
              <div className='flex items-center justify-between text-sm'>
                <div className='flex items-center gap-2'>
                  <Folder className='h-4 w-4 text-muted-foreground' />
                  <span className='font-medium'>{project.display_name}</span>
                  <Tooltip>
                    <TooltipTrigger asChild>
                      <button
                        className='text-muted-foreground hover:text-foreground'
                        type='button'
                      >
                        <Info className='h-3.5 w-3.5' />
                      </button>
                    </TooltipTrigger>
                    <TooltipContent className='max-w-xs' side='top'>
                      <code className='break-all text-xs'>
                        {project.full_path}
                      </code>
                    </TooltipContent>
                  </Tooltip>
                </div>
                <span>{formatCost(project.total_cost)}</span>
              </div>
              <div className='mt-1 flex items-center gap-4 text-muted-foreground text-xs'>
                <span>{project.session_count} sessions</span>
                <span>{formatTokens(totalTokens)} tokens</span>
                <span>{project.request_count} requests</span>
              </div>
              <div className='mt-1.5 h-1 w-full rounded-full bg-muted'>
                <div
                  className='h-full rounded-full bg-blue-500'
                  style={{ width: `${barWidth}%` }}
                />
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
