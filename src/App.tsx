import { getCurrentWindow } from '@tauri-apps/api/window';

import '@/styles/App.css';
import { AboutDialog } from '@/components/about-dialog';
import { AppSidebar } from '@/components/layout/app-sidebar';
import {
  ClaudeCodeGeneralPage,
  ClaudeCodeMcpPage,
  ClaudeCodePluginsPage,
  ClaudeCodeUsagePage,
} from '@/components/pages/claude-code';
import { HomePage } from '@/components/pages/home';
import {
  HomebrewCasksPage,
  HomebrewFormulaePage,
  HomebrewLogsPage,
  HomebrewOverviewPage,
  HomebrewTapsPage,
  HomebrewUpdatesPage,
} from '@/components/pages/homebrew';
import { McpPage } from '@/components/pages/mcp';
import { SettingsPage } from '@/components/pages/settings';
import { QueryProvider } from '@/components/providers/query-provider';
import { SidebarInset, SidebarProvider } from '@/components/ui/sidebar';
import { Toaster } from '@/components/ui/sonner';
import { useNavigation } from '@/hooks/use-navigation';
import type { Route } from '@/lib/navigation';

function App() {
  const { route, navigate, isGroupExpanded, toggleGroup } = useNavigation();

  const expandedGroups = new Set(
    ['claude-code', 'homebrew'].filter((g) => isGroupExpanded(g))
  );

  const renderPage = () => {
    switch (route) {
      case 'home':
        return <HomePage />;

      // Claude Code pages
      case 'claude-code/usage':
        return <ClaudeCodeUsagePage />;
      case 'claude-code/general':
        return <ClaudeCodeGeneralPage />;
      case 'claude-code/mcp':
        return <ClaudeCodeMcpPage />;
      case 'claude-code/plugins':
        return <ClaudeCodePluginsPage />;

      // Homebrew pages
      case 'homebrew/overview':
        return <HomebrewOverviewPage />;
      case 'homebrew/formulae':
        return <HomebrewFormulaePage />;
      case 'homebrew/casks':
        return <HomebrewCasksPage />;
      case 'homebrew/updates':
        return <HomebrewUpdatesPage />;
      case 'homebrew/taps':
        return <HomebrewTapsPage />;
      case 'homebrew/logs':
        return <HomebrewLogsPage />;

      // Other pages
      case 'mcp':
        return <McpPage />;
      case 'settings':
        return <SettingsPage />;

      default:
        return <HomePage />;
    }
  };

  return (
    <QueryProvider>
      <SidebarProvider>
        <AppSidebar
          expandedGroups={expandedGroups}
          onNavigate={(r: Route) => navigate(r)}
          onToggleGroup={toggleGroup}
          route={route}
        />
        <SidebarInset className='h-[calc(100svh-1rem)] overflow-auto'>
          <div
            className='h-1 w-full shrink-0'
            onMouseDown={() => getCurrentWindow().startDragging()}
          />
          {renderPage()}
        </SidebarInset>
      </SidebarProvider>
      <Toaster />
      <AboutDialog />
    </QueryProvider>
  );
}

export default App;
