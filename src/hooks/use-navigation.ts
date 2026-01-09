import { useCallback, useEffect, useState } from 'react';

import {
  getGroupFromRoute,
  isRouteInGroup,
  type Route,
} from '@/lib/navigation';

const STORAGE_KEY = 'scode-nav-expanded';

export function useNavigation(initialRoute: Route = 'home') {
  const [route, setRoute] = useState<Route>(initialRoute);
  const [expandedGroups, setExpandedGroups] = useState<Set<string>>(() => {
    // Initialize from route - expand the group that contains the initial route
    const group = getGroupFromRoute(initialRoute);
    return group ? new Set([group]) : new Set();
  });

  // Smart expand: when route changes, expand its group and collapse others
  useEffect(() => {
    const group = getGroupFromRoute(route);
    if (group) {
      setExpandedGroups(new Set([group]));
    }
  }, [route]);

  // Persist expanded state
  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify([...expandedGroups]));
  }, [expandedGroups]);

  const navigate = useCallback((newRoute: Route) => {
    setRoute(newRoute);
  }, []);

  const toggleGroup = useCallback((groupId: string) => {
    setExpandedGroups((prev) => {
      const next = new Set(prev);
      if (next.has(groupId)) {
        next.delete(groupId);
      } else {
        // Smart expand: only one group open at a time
        next.clear();
        next.add(groupId);
      }
      return next;
    });
  }, []);

  const isGroupExpanded = useCallback(
    (groupId: string) => expandedGroups.has(groupId),
    [expandedGroups]
  );

  const isRouteActive = useCallback(
    (checkRoute: Route) => route === checkRoute,
    [route]
  );

  const isGroupActive = useCallback(
    (groupId: string) => isRouteInGroup(route, groupId),
    [route]
  );

  return {
    route,
    navigate,
    toggleGroup,
    isGroupExpanded,
    isRouteActive,
    isGroupActive,
  };
}
