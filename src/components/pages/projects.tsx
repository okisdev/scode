export function ProjectsPage() {
  return (
    <div className='flex flex-1 flex-col gap-6 p-6'>
      <div className='space-y-1'>
        <h1 className='font-bold text-2xl'>Projects</h1>
        <p className='text-muted-foreground'>
          Manage project-specific configurations
        </p>
      </div>

      <div className='rounded-xl bg-muted/50 p-5'>
        <div className='space-y-1'>
          <h3 className='font-semibold'>Project List</h3>
          <p className='text-muted-foreground text-sm'>
            Projects with Claude Code configurations
          </p>
        </div>
        <div className='mt-4'>
          <p className='text-muted-foreground text-sm'>
            Projects will be loaded from ~/.claude.json
          </p>
        </div>
      </div>
    </div>
  );
}
