import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Plus } from 'lucide-react';

export function McpServersPage() {
  return (
    <div className="flex flex-1 flex-col gap-4 p-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">MCP Servers</h1>
          <p className="text-muted-foreground">
            Manage your Model Context Protocol servers
          </p>
        </div>
        <Button>
          <Plus className="mr-2 size-4" />
          Add Server
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Global MCP Servers</CardTitle>
          <CardDescription>
            These servers are available across all projects
          </CardDescription>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground">
            MCP servers will be loaded from ~/.claude.json
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
