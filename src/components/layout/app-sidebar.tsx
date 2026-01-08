import { getCurrentWindow } from '@tauri-apps/api/window';
import { Home, Settings } from 'lucide-react';
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
} from '@/components/ui/sidebar';
import { useSoftware } from '@/hooks/use-software';

interface AppSidebarProps {
  currentPage: string;
  onNavigate: (page: string) => void;
}

export function AppSidebar({ currentPage, onNavigate }: AppSidebarProps) {
  const { enabled } = useSoftware();

  const handleDragStart = () => {
    getCurrentWindow().startDragging();
  };

  return (
    <Sidebar variant='inset'>
      <SidebarHeader>
        <div
          className='flex items-center gap-2 px-2 py-2 pt-6'
          onMouseDown={handleDragStart}
        >
          <span className='font-semibold'>Scode</span>
        </div>
      </SidebarHeader>
      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupContent>
            <SidebarMenu>
              <SidebarMenuItem>
                <SidebarMenuButton
                  isActive={currentPage === 'home'}
                  onClick={() => onNavigate('home')}
                  tooltip='Home'
                >
                  <Home />
                  <span>Home</span>
                </SidebarMenuButton>
              </SidebarMenuItem>
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>

        {enabled.length > 0 && (
          <SidebarGroup>
            <SidebarGroupLabel>Software</SidebarGroupLabel>
            <SidebarGroupContent>
              <SidebarMenu>
                {enabled.map((software) => (
                  <SidebarMenuItem key={software.id}>
                    <SidebarMenuButton
                      isActive={currentPage === software.id}
                      onClick={() => onNavigate(software.id)}
                      tooltip={software.name}
                    >
                      <software.icon />
                      <span>{software.name}</span>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                ))}
              </SidebarMenu>
            </SidebarGroupContent>
          </SidebarGroup>
        )}
      </SidebarContent>
      <SidebarFooter>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton
              isActive={currentPage === 'settings'}
              onClick={() => onNavigate('settings')}
              tooltip='Settings'
            >
              <Settings />
              <span>Settings</span>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>
    </Sidebar>
  );
}
