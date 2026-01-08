import { Plus } from 'lucide-react';
import { Button } from '@/components/ui/button';

export function McpServersPage() {
  return (
    <div className='flex flex-1 flex-col gap-6 p-6'>
      <div className='flex items-center justify-between'>
        <div className='space-y-1'>
          <h1 className='font-bold text-2xl'>MCP Servers</h1>
          <p className='text-muted-foreground'>
            Manage your Model Context Protocol servers
          </p>
        </div>
        <Button>
          <Plus className='mr-2 size-4' />
          Add Server
        </Button>
      </div>

      <div className='rounded-xl bg-muted/50 p-5'>
        <div className='space-y-1'>
          <h3 className='font-semibold'>Global MCP Servers</h3>
          <p className='text-muted-foreground text-sm'>
            These servers are available across all projects
          </p>
        </div>
        <div className='mt-4'>
          <p className='text-muted-foreground text-sm'>
            MCP servers will be loaded from ~/.claude.json
          </p>
        </div>
      </div>
    </div>
  );
}
