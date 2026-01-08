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

export function ClaudeSettingsPage() {
  return (
    <div className='flex flex-1 flex-col gap-6 p-6'>
      <div className='space-y-1'>
        <h1 className='font-bold text-2xl'>Claude Code Settings</h1>
        <p className='text-muted-foreground'>
          Configure your Claude Code preferences
        </p>
      </div>

      <Tabs className='flex-1' defaultValue='general'>
        <TabsList>
          <TabsTrigger value='general'>General</TabsTrigger>
          <TabsTrigger value='plugins'>Plugins</TabsTrigger>
          <TabsTrigger value='advanced'>Advanced</TabsTrigger>
        </TabsList>

        <TabsContent className='mt-4 space-y-4' value='general'>
          <SettingSection
            description='Configure sandbox settings for Claude Code'
            title='Sandbox Mode'
          >
            <p className='text-muted-foreground text-sm'>
              Settings will be loaded from ~/.claude/settings.local.json
            </p>
          </SettingSection>
        </TabsContent>

        <TabsContent className='mt-4 space-y-4' value='plugins'>
          <SettingSection
            description='Manage your Claude Code plugins'
            title='Installed Plugins'
          >
            <p className='text-muted-foreground text-sm'>
              Plugin list will be loaded from ~/.claude/plugins/
            </p>
          </SettingSection>
        </TabsContent>

        <TabsContent className='mt-4 space-y-4' value='advanced'>
          <SettingSection
            description='Configure environment variables for Claude Code'
            title='Environment Variables'
          >
            <p className='text-muted-foreground text-sm'>
              Environment settings from ~/.claude/settings.json
            </p>
          </SettingSection>
        </TabsContent>
      </Tabs>
    </div>
  );
}
