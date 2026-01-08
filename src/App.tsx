import { useState } from 'react';

import '@/styles/App.css';
import { SidebarInset, SidebarProvider } from '@/components/ui/sidebar';
import { AppSidebar } from '@/components/layout/app-sidebar';
import { HomePage } from '@/components/pages/home';
import { ClaudeSettingsPage } from '@/components/pages/claude-settings';
import { McpServersPage } from '@/components/pages/mcp-servers';
import { ProjectsPage } from '@/components/pages/projects';

function App() {
  const [currentPage, setCurrentPage] = useState('home');

  const renderPage = () => {
    switch (currentPage) {
      case 'home':
        return <HomePage />;
      case 'claude-settings':
        return <ClaudeSettingsPage />;
      case 'mcp-servers':
        return <McpServersPage />;
      case 'projects':
        return <ProjectsPage />;
      default:
        return <HomePage />;
    }
  };

  return (
    <SidebarProvider>
      <AppSidebar currentPage={currentPage} onNavigate={setCurrentPage} />
      <SidebarInset>{renderPage()}</SidebarInset>
    </SidebarProvider>
  );
}

export default App;
