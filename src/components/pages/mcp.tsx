import { Plus } from 'lucide-react';
import { Button } from '@/components/ui/button';

export function McpPage() {
  return (
    <div className='flex flex-1 flex-col gap-6 p-6'>
      <div className='flex items-center justify-between'>
        <div className='space-y-1'>
          <h1 className='font-bold text-2xl'>MCP</h1>
          <p className='text-muted-foreground'>
            Manage Model Context Protocol servers
          </p>
        </div>
        <Button size='sm'>
          <Plus className='mr-2 size-4' />
          Add Server
        </Button>
      </div>

      <div className='rounded-xl bg-muted/50 p-5'>
        <div className='space-y-1'>
          <h3 className='font-semibold'>Global Servers</h3>
          <p className='text-muted-foreground text-sm'>
            MCP servers available across all applications
          </p>
        </div>
        <div className='mt-4'>
          <p className='text-muted-foreground text-sm'>No servers configured</p>
        </div>
      </div>
    </div>
  );
}
