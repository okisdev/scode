import { getCurrentWindow } from '@tauri-apps/api/window';
import { useState } from 'react';

import '@/styles/App.css';
import { AboutDialog } from '@/components/about-dialog';
import { AppSidebar } from '@/components/layout/app-sidebar';
import { ClaudeCodePage } from '@/components/pages/claude-code';
import { HomePage } from '@/components/pages/home';
import { HomebrewPage } from '@/components/pages/homebrew';
import { McpPage } from '@/components/pages/mcp';
import { SettingsPage } from '@/components/pages/settings';
import { QueryProvider } from '@/components/providers/query-provider';
import { SidebarInset, SidebarProvider } from '@/components/ui/sidebar';
import { Toaster } from '@/components/ui/sonner';

function App() {
  const [currentPage, setCurrentPage] = useState('home');

  const renderPage = () => {
    switch (currentPage) {
      case 'home':
        return <HomePage />;
      case 'claude-code':
        return <ClaudeCodePage />;
      case 'mcp':
        return <McpPage />;
      case 'homebrew':
        return <HomebrewPage />;
      case 'settings':
        return <SettingsPage />;
      default:
        return <HomePage />;
    }
  };

  return (
    <QueryProvider>
      <SidebarProvider>
        <AppSidebar currentPage={currentPage} onNavigate={setCurrentPage} />
        <SidebarInset className='h-[calc(100svh-1rem)] overflow-auto'>
          <div
            className='h-6 w-full shrink-0'
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
