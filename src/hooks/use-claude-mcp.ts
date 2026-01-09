import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import {
  addGlobalMcpServer,
  addProjectMcpServer,
  listProjectsWithMcp,
  loadGlobalMcpServers,
  loadProjectMcpServers,
  type McpServer,
  type McpServersConfig,
  type ProjectInfo,
  removeGlobalMcpServer,
  removeProjectMcpServer,
  updateGlobalMcpServer,
  updateProjectMcpServer,
} from '@/lib/claude-mcp';
import { queryKeys } from '@/lib/query-keys';

// ============================================================================
// Global MCP Hook
// ============================================================================

export function useGlobalMcp() {
  const queryClient = useQueryClient();

  const serversQuery = useQuery<McpServersConfig>({
    queryKey: queryKeys.mcp.globalServers(),
    queryFn: loadGlobalMcpServers,
  });

  const addMutation = useMutation({
    mutationFn: ({ name, config }: { name: string; config: McpServer }) =>
      addGlobalMcpServer(name, config),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.mcp.servers() });
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ name, config }: { name: string; config: McpServer }) =>
      updateGlobalMcpServer(name, config),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.mcp.servers() });
    },
  });

  const removeMutation = useMutation({
    mutationFn: (name: string) => removeGlobalMcpServer(name),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.mcp.servers() });
    },
  });

  return {
    servers: serversQuery.data ?? {},
    isLoading: serversQuery.isLoading,
    error: serversQuery.error,
    refetch: serversQuery.refetch,

    addServer: addMutation.mutateAsync,
    updateServer: updateMutation.mutateAsync,
    removeServer: removeMutation.mutateAsync,

    isAdding: addMutation.isPending,
    isUpdating: updateMutation.isPending,
    isRemoving: removeMutation.isPending,
    isOperating:
      addMutation.isPending ||
      updateMutation.isPending ||
      removeMutation.isPending,
  };
}

// ============================================================================
// Project MCP Hook
// ============================================================================

export function useProjectMcp(projectPath: string) {
  const queryClient = useQueryClient();

  const serversQuery = useQuery<McpServersConfig>({
    queryKey: queryKeys.mcp.projectServers(projectPath),
    queryFn: () => loadProjectMcpServers(projectPath),
    enabled: !!projectPath,
  });

  const addMutation = useMutation({
    mutationFn: ({ name, config }: { name: string; config: McpServer }) =>
      addProjectMcpServer(projectPath, name, config),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.mcp.servers() });
      queryClient.invalidateQueries({ queryKey: queryKeys.mcp.projects() });
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ name, config }: { name: string; config: McpServer }) =>
      updateProjectMcpServer(projectPath, name, config),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.mcp.servers() });
    },
  });

  const removeMutation = useMutation({
    mutationFn: (name: string) => removeProjectMcpServer(projectPath, name),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.mcp.servers() });
      queryClient.invalidateQueries({ queryKey: queryKeys.mcp.projects() });
    },
  });

  return {
    servers: serversQuery.data ?? {},
    isLoading: serversQuery.isLoading,
    error: serversQuery.error,
    refetch: serversQuery.refetch,

    addServer: addMutation.mutateAsync,
    updateServer: updateMutation.mutateAsync,
    removeServer: removeMutation.mutateAsync,

    isAdding: addMutation.isPending,
    isUpdating: updateMutation.isPending,
    isRemoving: removeMutation.isPending,
    isOperating:
      addMutation.isPending ||
      updateMutation.isPending ||
      removeMutation.isPending,
  };
}

// ============================================================================
// Projects List Hook
// ============================================================================

export function useMcpProjects() {
  const projectsQuery = useQuery<ProjectInfo[]>({
    queryKey: queryKeys.mcp.projects(),
    queryFn: listProjectsWithMcp,
  });

  return {
    projects: projectsQuery.data ?? [],
    isLoading: projectsQuery.isLoading,
    error: projectsQuery.error,
    refetch: projectsQuery.refetch,
  };
}

// ============================================================================
// Combined MCP Hook (for page use)
// ============================================================================

export function useClaudeMcp() {
  const queryClient = useQueryClient();

  const globalServersQuery = useQuery<McpServersConfig>({
    queryKey: queryKeys.mcp.globalServers(),
    queryFn: loadGlobalMcpServers,
  });

  const projectsQuery = useQuery<ProjectInfo[]>({
    queryKey: queryKeys.mcp.projects(),
    queryFn: listProjectsWithMcp,
  });

  // Global mutations
  const addGlobalMutation = useMutation({
    mutationFn: ({ name, config }: { name: string; config: McpServer }) =>
      addGlobalMcpServer(name, config),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.mcp.servers() });
    },
  });

  const updateGlobalMutation = useMutation({
    mutationFn: ({ name, config }: { name: string; config: McpServer }) =>
      updateGlobalMcpServer(name, config),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.mcp.servers() });
    },
  });

  const removeGlobalMutation = useMutation({
    mutationFn: (name: string) => removeGlobalMcpServer(name),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.mcp.servers() });
    },
  });

  // Project mutations
  const addProjectMutation = useMutation({
    mutationFn: ({
      projectPath,
      name,
      config,
    }: {
      projectPath: string;
      name: string;
      config: McpServer;
    }) => addProjectMcpServer(projectPath, name, config),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.mcp.servers() });
      queryClient.invalidateQueries({ queryKey: queryKeys.mcp.projects() });
    },
  });

  const updateProjectMutation = useMutation({
    mutationFn: ({
      projectPath,
      name,
      config,
    }: {
      projectPath: string;
      name: string;
      config: McpServer;
    }) => updateProjectMcpServer(projectPath, name, config),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.mcp.servers() });
    },
  });

  const removeProjectMutation = useMutation({
    mutationFn: ({
      projectPath,
      name,
    }: {
      projectPath: string;
      name: string;
    }) => removeProjectMcpServer(projectPath, name),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.mcp.servers() });
      queryClient.invalidateQueries({ queryKey: queryKeys.mcp.projects() });
    },
  });

  const isOperating =
    addGlobalMutation.isPending ||
    updateGlobalMutation.isPending ||
    removeGlobalMutation.isPending ||
    addProjectMutation.isPending ||
    updateProjectMutation.isPending ||
    removeProjectMutation.isPending;

  return {
    // Data
    globalServers: globalServersQuery.data ?? {},
    projects: projectsQuery.data ?? [],

    // Loading states
    isLoading: globalServersQuery.isLoading || projectsQuery.isLoading,
    isOperating,

    // Global operations
    addGlobalServer: addGlobalMutation.mutateAsync,
    updateGlobalServer: updateGlobalMutation.mutateAsync,
    removeGlobalServer: removeGlobalMutation.mutateAsync,

    // Project operations
    addProjectServer: addProjectMutation.mutateAsync,
    updateProjectServer: updateProjectMutation.mutateAsync,
    removeProjectServer: removeProjectMutation.mutateAsync,

    // Refetch
    refetch: () => {
      globalServersQuery.refetch();
      projectsQuery.refetch();
    },
  };
}
