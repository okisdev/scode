import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';

interface SettingSectionProps {
  title: string;
  description: string;
  children: React.ReactNode;
}

function SettingSection({ title, description, children }: SettingSectionProps) {
  return (
    <div className='rounded-xl bg-muted/50 p-5'>
      <div className='space-y-1'>
        <h3 className='font-semibold'>{title}</h3>
        <p className='text-muted-foreground text-sm'>{description}</p>
      </div>
      <div className='mt-4'>{children}</div>
    </div>
  );
}

export function ClaudeCodePage() {
  return (
    <div className='flex flex-1 flex-col gap-6 p-6'>
      <div className='space-y-1'>
        <h1 className='font-bold text-2xl'>Claude Code</h1>
        <p className='text-muted-foreground'>
          Manage Claude Code configuration
        </p>
      </div>

      <Tabs className='flex-1' defaultValue='general'>
        <TabsList>
          <TabsTrigger value='general'>General</TabsTrigger>
          <TabsTrigger value='mcp'>MCP</TabsTrigger>
          <TabsTrigger value='plugins'>Plugins</TabsTrigger>
        </TabsList>

        <TabsContent className='mt-4 space-y-4' value='general'>
          <SettingSection
            description='Configure sandbox settings'
            title='Sandbox Mode'
          >
            <p className='text-muted-foreground text-sm'>
              ~/.claude/settings.local.json
            </p>
          </SettingSection>
        </TabsContent>

        <TabsContent className='mt-4 space-y-4' value='mcp'>
          <SettingSection
            description='MCP servers configured in Claude Code'
            title='MCP Servers'
          >
            <p className='text-muted-foreground text-sm'>
              ~/.claude.json → mcpServers
            </p>
          </SettingSection>
        </TabsContent>

        <TabsContent className='mt-4 space-y-4' value='plugins'>
          <SettingSection
            description='Manage installed plugins'
            title='Plugins'
          >
            <p className='text-muted-foreground text-sm'>~/.claude/plugins/</p>
          </SettingSection>
        </TabsContent>
      </Tabs>
    </div>
  );
}
