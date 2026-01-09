import { getCurrentWindow } from '@tauri-apps/api/window';
import { ChevronRight, Home, Settings } from 'lucide-react';

import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from '@/components/ui/collapsible';
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
  SidebarMenuSub,
  SidebarMenuSubButton,
  SidebarMenuSubItem,
} from '@/components/ui/sidebar';
import { useSoftware } from '@/hooks/use-software';
import {
  getSectionsForSoftware,
  isRouteInGroup,
  type Route,
} from '@/lib/navigation';

interface AppSidebarProps {
  route: Route;
  onNavigate: (route: Route) => void;
  expandedGroups: Set<string>;
  onToggleGroup: (groupId: string) => void;
}

export function AppSidebar({
  route,
  onNavigate,
  expandedGroups,
  onToggleGroup,
}: AppSidebarProps) {
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
                  isActive={route === 'home'}
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
                {enabled.map((software) => {
                  const sections = getSectionsForSoftware(software.id);
                  const isExpanded = expandedGroups.has(software.id);
                  const isGroupActive = isRouteInGroup(route, software.id);

                  // Software with sub-sections (collapsible)
                  if (sections) {
                    return (
                      <Collapsible
                        className='group/collapsible'
                        key={software.id}
                        onOpenChange={() => onToggleGroup(software.id)}
                        open={isExpanded}
                      >
                        <SidebarMenuItem>
                          <CollapsibleTrigger asChild>
                            <SidebarMenuButton
                              isActive={isGroupActive && !isExpanded}
                              tooltip={software.name}
                            >
                              <software.icon />
                              <span>{software.name}</span>
                              <ChevronRight
                                className={`ml-auto transition-transform duration-200 ${
                                  isExpanded ? 'rotate-90' : ''
                                }`}
                              />
                            </SidebarMenuButton>
                          </CollapsibleTrigger>
                          <CollapsibleContent>
                            <SidebarMenuSub>
                              {sections.map((section) => {
                                const sectionRoute =
                                  `${software.id}/${section.id}` as Route;
                                return (
                                  <SidebarMenuSubItem key={section.id}>
                                    <SidebarMenuSubButton
                                      isActive={route === sectionRoute}
                                      onClick={() => onNavigate(sectionRoute)}
                                    >
                                      <span>{section.label}</span>
                                    </SidebarMenuSubButton>
                                  </SidebarMenuSubItem>
                                );
                              })}
                            </SidebarMenuSub>
                          </CollapsibleContent>
                        </SidebarMenuItem>
                      </Collapsible>
                    );
                  }

                  // Software without sub-sections (simple button)
                  return (
                    <SidebarMenuItem key={software.id}>
                      <SidebarMenuButton
                        isActive={route === software.id}
                        onClick={() => onNavigate(software.id as Route)}
                        tooltip={software.name}
                      >
                        <software.icon />
                        <span>{software.name}</span>
                      </SidebarMenuButton>
                    </SidebarMenuItem>
                  );
                })}
              </SidebarMenu>
            </SidebarGroupContent>
          </SidebarGroup>
        )}
      </SidebarContent>
      <SidebarFooter>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton
              isActive={route === 'settings'}
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
