import {
  ChevronDown,
  ChevronRight,
  FolderOpen,
  Globe,
  Pencil,
  Plug,
  Plus,
  RefreshCw,
  Terminal,
  Trash2,
  X,
} from 'lucide-react';
import { useState } from 'react';

import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { Button } from '@/components/ui/button';
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from '@/components/ui/collapsible';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Skeleton } from '@/components/ui/skeleton';
import { useClaudeMcp, useProjectMcp } from '@/hooks/use-claude-mcp';
import {
  getServerDescription,
  getServerTypeLabel,
  type HttpMcpServer,
  isHttpServer,
  isStdioServer,
  type McpServer,
  type McpServerType,
  type StdioMcpServer,
} from '@/lib/claude-mcp';

// ============================================================================
// Types
// ============================================================================

interface DeleteTarget {
  name: string;
  scope: 'global' | 'project';
  projectPath?: string;
}

interface EditTarget {
  name: string;
  config: McpServer;
  scope: 'global' | 'project';
  projectPath?: string;
}

// ============================================================================
// Server Row Component
// ============================================================================

interface McpServerRowProps {
  name: string;
  config: McpServer;
  onEdit: () => void;
  onDelete: () => void;
  disabled?: boolean;
}

function McpServerRow({
  name,
  config,
  onEdit,
  onDelete,
  disabled,
}: McpServerRowProps) {
  const typeLabel = getServerTypeLabel(config.type);
  const description = getServerDescription(config);
  const isHttp = isHttpServer(config);

  return (
    <div className='flex items-center justify-between rounded-lg bg-muted p-4'>
      <div className='flex items-center gap-4'>
        <div className='flex size-10 shrink-0 items-center justify-center rounded-lg bg-muted-foreground/10'>
          {isHttp ? (
            <Globe className='size-5 text-muted-foreground' />
          ) : (
            <Terminal className='size-5 text-muted-foreground' />
          )}
        </div>
        <div className='flex flex-col gap-0.5'>
          <div className='flex items-center gap-2'>
            <span className='font-medium'>{name}</span>
            <span className='rounded bg-muted-foreground/10 px-1.5 py-0.5 text-muted-foreground text-xs'>
              {typeLabel}
            </span>
          </div>
          <span className='max-w-md truncate text-muted-foreground text-sm'>
            {description}
          </span>
        </div>
      </div>
      <div className='flex items-center gap-1'>
        <Button disabled={disabled} onClick={onEdit} size='sm' variant='ghost'>
          <Pencil className='size-4' />
        </Button>
        <Button
          disabled={disabled}
          onClick={onDelete}
          size='sm'
          variant='ghost'
        >
          <Trash2 className='size-4' />
        </Button>
      </div>
    </div>
  );
}

// ============================================================================
// Key-Value Editor Component
// ============================================================================

interface KeyValuePair {
  key: string;
  value: string;
}

interface KeyValueEditorProps {
  label: string;
  value: Record<string, string>;
  onChange: (value: Record<string, string>) => void;
}

function KeyValueEditor({ label, value, onChange }: KeyValueEditorProps) {
  const pairs: KeyValuePair[] = Object.entries(value).map(([k, v]) => ({
    key: k,
    value: v,
  }));

  const updatePair = (
    index: number,
    field: 'key' | 'value',
    newValue: string
  ) => {
    const newPairs = [...pairs];
    newPairs[index] = { ...newPairs[index], [field]: newValue };
    const newRecord: Record<string, string> = {};
    for (const pair of newPairs) {
      if (pair.key.trim()) {
        newRecord[pair.key] = pair.value;
      }
    }
    onChange(newRecord);
  };

  const addPair = () => {
    onChange({ ...value, '': '' });
  };

  const removePair = (key: string) => {
    const newRecord = { ...value };
    delete newRecord[key];
    onChange(newRecord);
  };

  return (
    <div className='space-y-2'>
      <Label>{label}</Label>
      <div className='space-y-2'>
        {pairs.map((pair, index) => (
          <div className='flex items-center gap-2' key={index}>
            <Input
              className='flex-1'
              onChange={(e) => updatePair(index, 'key', e.target.value)}
              placeholder='Key'
              value={pair.key}
            />
            <Input
              className='flex-1'
              onChange={(e) => updatePair(index, 'value', e.target.value)}
              placeholder='Value'
              value={pair.value}
            />
            <Button
              onClick={() => removePair(pair.key)}
              size='sm'
              type='button'
              variant='ghost'
            >
              <X className='size-4' />
            </Button>
          </div>
        ))}
      </div>
      <Button
        className='w-full'
        onClick={addPair}
        size='sm'
        type='button'
        variant='outline'
      >
        <Plus className='mr-2 size-4' />
        Add {label.replace('(optional)', '').trim()}
      </Button>
    </div>
  );
}

// ============================================================================
// Server Dialog Component
// ============================================================================

interface McpServerDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  mode: 'add' | 'edit';
  editTarget?: EditTarget;
  projects: string[];
  onSubmit: (data: {
    name: string;
    config: McpServer;
    scope: 'global' | 'project';
    projectPath?: string;
  }) => Promise<void>;
  isSubmitting: boolean;
}

function McpServerDialog({
  open,
  onOpenChange,
  mode,
  editTarget,
  projects,
  onSubmit,
  isSubmitting,
}: McpServerDialogProps) {
  const [name, setName] = useState('');
  const [type, setType] = useState<McpServerType>('http');
  const [scope, setScope] = useState<'global' | 'project'>('global');
  const [projectPath, setProjectPath] = useState('');

  // HTTP/SSE fields
  const [url, setUrl] = useState('');
  const [headers, setHeaders] = useState<Record<string, string>>({});

  // Stdio fields
  const [command, setCommand] = useState('');
  const [args, setArgs] = useState('');
  const [env, setEnv] = useState<Record<string, string>>({});

  // Initialize form when editing
  const initForm = () => {
    if (mode === 'edit' && editTarget) {
      setName(editTarget.name);
      setType(editTarget.config.type);
      setScope(editTarget.scope);
      setProjectPath(editTarget.projectPath ?? '');

      if (isHttpServer(editTarget.config)) {
        setUrl(editTarget.config.url);
        setHeaders(editTarget.config.headers ?? {});
        setCommand('');
        setArgs('');
        setEnv({});
      } else if (isStdioServer(editTarget.config)) {
        setCommand(editTarget.config.command);
        setArgs(editTarget.config.args?.join(' ') ?? '');
        setEnv(editTarget.config.env ?? {});
        setUrl('');
        setHeaders({});
      }
    } else {
      // Reset for add mode
      setName('');
      setType('http');
      setScope('global');
      setProjectPath('');
      setUrl('');
      setHeaders({});
      setCommand('');
      setArgs('');
      setEnv({});
    }
  };

  const handleSubmit = async () => {
    let config: McpServer;

    if (type === 'http' || type === 'sse') {
      const httpConfig: HttpMcpServer = { type, url };
      if (Object.keys(headers).length > 0) {
        httpConfig.headers = headers;
      }
      config = httpConfig;
    } else {
      const stdioConfig: StdioMcpServer = { type: 'stdio', command };
      const argsArray = args
        .split(' ')
        .map((a) => a.trim())
        .filter(Boolean);
      if (argsArray.length > 0) {
        stdioConfig.args = argsArray;
      }
      if (Object.keys(env).length > 0) {
        stdioConfig.env = env;
      }
      config = stdioConfig;
    }

    await onSubmit({
      name,
      config,
      scope,
      projectPath: scope === 'project' ? projectPath : undefined,
    });

    onOpenChange(false);
  };

  const isValid = () => {
    if (!name.trim()) return false;
    if (type === 'http' || type === 'sse') {
      return url.trim().length > 0;
    }
    return command.trim().length > 0;
  };

  return (
    <Dialog
      onOpenChange={(open) => {
        if (open) initForm();
        onOpenChange(open);
      }}
      open={open}
    >
      <DialogContent className='max-w-lg'>
        <DialogHeader>
          <DialogTitle>
            {mode === 'add' ? 'Add MCP Server' : 'Edit MCP Server'}
          </DialogTitle>
          <DialogDescription>
            {mode === 'add'
              ? 'Configure a new MCP server for Claude Code.'
              : 'Update the MCP server configuration.'}
          </DialogDescription>
        </DialogHeader>

        <div className='space-y-4 py-4'>
          {/* Name */}
          <div className='space-y-2'>
            <Label htmlFor='name'>Name</Label>
            <Input
              disabled={mode === 'edit'}
              id='name'
              onChange={(e) => setName(e.target.value)}
              placeholder='my-server'
              value={name}
            />
          </div>

          {/* Type */}
          <div className='space-y-2'>
            <Label>Type</Label>
            <Select
              onValueChange={(v) => setType(v as McpServerType)}
              value={type}
            >
              <SelectTrigger className='w-full'>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value='http'>HTTP (Recommended)</SelectItem>
                <SelectItem value='sse'>SSE (Deprecated)</SelectItem>
                <SelectItem value='stdio'>Stdio (Local Process)</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Scope (only for add mode) */}
          {mode === 'add' && (
            <div className='space-y-2'>
              <Label>Scope</Label>
              <Select
                onValueChange={(v) => setScope(v as 'global' | 'project')}
                value={scope}
              >
                <SelectTrigger className='w-full'>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value='global'>Global (All Projects)</SelectItem>
                  <SelectItem value='project'>Project Specific</SelectItem>
                </SelectContent>
              </Select>
            </div>
          )}

          {/* Project Selection */}
          {mode === 'add' && scope === 'project' && (
            <div className='space-y-2'>
              <Label>Project</Label>
              <Select onValueChange={setProjectPath} value={projectPath}>
                <SelectTrigger className='w-full'>
                  <SelectValue placeholder='Select a project...' />
                </SelectTrigger>
                <SelectContent>
                  {projects.map((p) => (
                    <SelectItem key={p} value={p}>
                      {p.split('/').pop()}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}

          {/* HTTP/SSE Fields */}
          {(type === 'http' || type === 'sse') && (
            <>
              <div className='space-y-2'>
                <Label htmlFor='url'>URL</Label>
                <Input
                  id='url'
                  onChange={(e) => setUrl(e.target.value)}
                  placeholder='https://mcp.example.com/mcp'
                  value={url}
                />
              </div>
              <KeyValueEditor
                label='Headers (optional)'
                onChange={setHeaders}
                value={headers}
              />
            </>
          )}

          {/* Stdio Fields */}
          {type === 'stdio' && (
            <>
              <div className='space-y-2'>
                <Label htmlFor='command'>Command</Label>
                <Input
                  id='command'
                  onChange={(e) => setCommand(e.target.value)}
                  placeholder='npx -y @example/mcp-server'
                  value={command}
                />
              </div>
              <div className='space-y-2'>
                <Label htmlFor='args'>Arguments (space-separated)</Label>
                <Input
                  id='args'
                  onChange={(e) => setArgs(e.target.value)}
                  placeholder='--flag value'
                  value={args}
                />
              </div>
              <KeyValueEditor
                label='Environment Variables (optional)'
                onChange={setEnv}
                value={env}
              />
            </>
          )}
        </div>

        <DialogFooter>
          <Button onClick={() => onOpenChange(false)} variant='outline'>
            Cancel
          </Button>
          <Button disabled={!isValid() || isSubmitting} onClick={handleSubmit}>
            {isSubmitting
              ? 'Saving...'
              : mode === 'add'
                ? 'Add Server'
                : 'Save'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

// ============================================================================
// Project Section Component
// ============================================================================

interface ProjectMcpSectionProps {
  projectPath: string;
  displayName: string;
  serverCount: number;
  onEdit: (name: string, config: McpServer) => void;
  onDelete: (name: string) => void;
  disabled?: boolean;
}

function ProjectMcpSection({
  projectPath,
  displayName,
  serverCount,
  onEdit,
  onDelete,
  disabled,
}: ProjectMcpSectionProps) {
  const [isOpen, setIsOpen] = useState(false);
  const { servers, isLoading } = useProjectMcp(projectPath);

  const serverEntries = Object.entries(servers);

  return (
    <Collapsible onOpenChange={setIsOpen} open={isOpen}>
      <CollapsibleTrigger asChild>
        <button
          className='flex w-full items-center gap-2 rounded-lg p-3 text-left hover:bg-muted/50'
          type='button'
        >
          {isOpen ? (
            <ChevronDown className='size-4 text-muted-foreground' />
          ) : (
            <ChevronRight className='size-4 text-muted-foreground' />
          )}
          <FolderOpen className='size-4 text-muted-foreground' />
          <span className='flex-1 truncate font-medium'>{displayName}</span>
          <span className='text-muted-foreground text-sm'>
            {serverCount} server{serverCount !== 1 ? 's' : ''}
          </span>
        </button>
      </CollapsibleTrigger>
      <CollapsibleContent>
        <div className='ml-6 space-y-2 pb-2'>
          {isLoading ? (
            <div className='space-y-2'>
              <Skeleton className='h-16 w-full rounded-lg' />
              <Skeleton className='h-16 w-full rounded-lg' />
            </div>
          ) : serverEntries.length === 0 ? (
            <p className='py-4 text-center text-muted-foreground text-sm'>
              No servers configured
            </p>
          ) : (
            serverEntries.map(([name, config]) => (
              <McpServerRow
                config={config}
                disabled={disabled}
                key={name}
                name={name}
                onDelete={() => onDelete(name)}
                onEdit={() => onEdit(name, config)}
              />
            ))
          )}
        </div>
      </CollapsibleContent>
    </Collapsible>
  );
}

// ============================================================================
// Main Page Component
// ============================================================================

export function ClaudeCodeMcpPage() {
  const {
    globalServers,
    projects,
    isLoading,
    isOperating,
    addGlobalServer,
    updateGlobalServer,
    removeGlobalServer,
    addProjectServer,
    updateProjectServer,
    removeProjectServer,
    refetch,
  } = useClaudeMcp();

  const [dialogOpen, setDialogOpen] = useState(false);
  const [dialogMode, setDialogMode] = useState<'add' | 'edit'>('add');
  const [editTarget, setEditTarget] = useState<EditTarget | undefined>();
  const [deleteTarget, setDeleteTarget] = useState<DeleteTarget | null>(null);

  const globalServerEntries = Object.entries(globalServers);
  const allProjectPaths = projects.map((p) => p.path);

  const handleAddClick = () => {
    setDialogMode('add');
    setEditTarget(undefined);
    setDialogOpen(true);
  };

  const handleEditGlobal = (name: string, config: McpServer) => {
    setDialogMode('edit');
    setEditTarget({ name, config, scope: 'global' });
    setDialogOpen(true);
  };

  const handleEditProject = (
    projectPath: string,
    name: string,
    config: McpServer
  ) => {
    setDialogMode('edit');
    setEditTarget({ name, config, scope: 'project', projectPath });
    setDialogOpen(true);
  };

  const handleDeleteGlobal = (name: string) => {
    setDeleteTarget({ name, scope: 'global' });
  };

  const handleDeleteProject = (projectPath: string, name: string) => {
    setDeleteTarget({ name, scope: 'project', projectPath });
  };

  const handleSubmit = async (data: {
    name: string;
    config: McpServer;
    scope: 'global' | 'project';
    projectPath?: string;
  }) => {
    if (dialogMode === 'add') {
      if (data.scope === 'global') {
        await addGlobalServer({ name: data.name, config: data.config });
      } else if (data.projectPath) {
        await addProjectServer({
          projectPath: data.projectPath,
          name: data.name,
          config: data.config,
        });
      }
    } else if (data.scope === 'global') {
      await updateGlobalServer({ name: data.name, config: data.config });
    } else if (data.projectPath) {
      await updateProjectServer({
        projectPath: data.projectPath,
        name: data.name,
        config: data.config,
      });
    }
  };

  const handleConfirmDelete = async () => {
    if (!deleteTarget) return;

    if (deleteTarget.scope === 'global') {
      await removeGlobalServer(deleteTarget.name);
    } else if (deleteTarget.projectPath) {
      await removeProjectServer({
        projectPath: deleteTarget.projectPath,
        name: deleteTarget.name,
      });
    }

    setDeleteTarget(null);
  };

  return (
    <div className='flex flex-1 flex-col gap-6 p-6'>
      {/* Header */}
      <div className='flex items-start justify-between'>
        <div className='space-y-1'>
          <h1 className='font-bold text-2xl'>MCP Servers</h1>
          <p className='text-muted-foreground'>
            Manage MCP servers for Claude Code
          </p>
        </div>
        <div className='flex items-center gap-2'>
          <Button
            disabled={isLoading || isOperating}
            onClick={() => refetch()}
            size='sm'
            variant='outline'
          >
            <RefreshCw
              className={`mr-2 size-4 ${isLoading ? 'animate-spin' : ''}`}
            />
            Refresh
          </Button>
          <Button disabled={isOperating} onClick={handleAddClick} size='sm'>
            <Plus className='mr-2 size-4' />
            Add Server
          </Button>
        </div>
      </div>

      {/* Global Servers Section */}
      <div className='rounded-xl bg-muted/50 p-5'>
        <div className='mb-4 flex items-center gap-2'>
          <Plug className='size-5 text-muted-foreground' />
          <div>
            <h3 className='font-semibold'>Global Servers</h3>
            <p className='text-muted-foreground text-sm'>
              MCP servers available across all projects
            </p>
          </div>
        </div>

        {isLoading ? (
          <div className='space-y-2'>
            <Skeleton className='h-16 w-full rounded-lg' />
            <Skeleton className='h-16 w-full rounded-lg' />
          </div>
        ) : globalServerEntries.length === 0 ? (
          <p className='py-8 text-center text-muted-foreground'>
            No global MCP servers configured
          </p>
        ) : (
          <div className='space-y-2'>
            {globalServerEntries.map(([name, config]) => (
              <McpServerRow
                config={config}
                disabled={isOperating}
                key={name}
                name={name}
                onDelete={() => handleDeleteGlobal(name)}
                onEdit={() => handleEditGlobal(name, config)}
              />
            ))}
          </div>
        )}
      </div>

      {/* Project Servers Section */}
      <div className='rounded-xl bg-muted/50 p-5'>
        <div className='mb-4 flex items-center gap-2'>
          <FolderOpen className='size-5 text-muted-foreground' />
          <div>
            <h3 className='font-semibold'>Project Servers</h3>
            <p className='text-muted-foreground text-sm'>
              MCP servers configured for specific projects
            </p>
          </div>
        </div>

        {isLoading ? (
          <div className='space-y-2'>
            <Skeleton className='h-12 w-full rounded-lg' />
            <Skeleton className='h-12 w-full rounded-lg' />
          </div>
        ) : projects.length === 0 ? (
          <p className='py-8 text-center text-muted-foreground'>
            No project-specific MCP servers configured
          </p>
        ) : (
          <div className='space-y-1'>
            {projects.map((project) => (
              <ProjectMcpSection
                disabled={isOperating}
                displayName={project.displayName}
                key={project.path}
                onDelete={(name) => handleDeleteProject(project.path, name)}
                onEdit={(name, config) =>
                  handleEditProject(project.path, name, config)
                }
                projectPath={project.path}
                serverCount={project.serverCount}
              />
            ))}
          </div>
        )}
      </div>

      {/* Add/Edit Dialog */}
      <McpServerDialog
        editTarget={editTarget}
        isSubmitting={isOperating}
        mode={dialogMode}
        onOpenChange={setDialogOpen}
        onSubmit={handleSubmit}
        open={dialogOpen}
        projects={allProjectPaths}
      />

      {/* Delete Confirmation Dialog */}
      <AlertDialog
        onOpenChange={(open) => !open && setDeleteTarget(null)}
        open={deleteTarget !== null}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              Remove MCP Server &ldquo;{deleteTarget?.name}&rdquo;?
            </AlertDialogTitle>
            <AlertDialogDescription>
              This will remove the server from your configuration. This action
              cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleConfirmDelete}>
              Remove
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
