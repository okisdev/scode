# Scode Project Guide

## Project Overview

Desktop application for managing local Claude Code configurations and MCP servers.

**Tech**: Tauri 2, React 19, TypeScript, Tailwind CSS 4, shadcn/ui, Vite

## Setup Commands

```bash
# Install dependencies
pnpm install

# Start development (frontend + Tauri app)
pnpm tauri dev

# Start frontend only
pnpm dev

# Build production app
pnpm tauri build

# Lint and format
pnpm lint
pnpm lint:fix
```

## Project Structure

```
src/
├── components/
│   ├── layout/        # Layout components (AppSidebar)
│   ├── pages/         # Page components (Home, Settings, etc.)
│   └── ui/            # shadcn/ui components (50+ components)
├── hooks/             # Custom React hooks
├── lib/               # Utilities (cn, config helpers)
├── styles/            # CSS (App.css with Tailwind + shadcn variables)
└── App.tsx            # Main entry with routing
src-tauri/             # Rust backend
```

## Code Style

### TypeScript
- **NO `any` types** - Use proper typing
- Strict mode enabled
- Use ES modules (import/export), not CommonJS
- Use single quotes for strings

### Components
- **Keep related code together** - Prefer 300-500 lines in one file over many small files
- Don't split unless: reused elsewhere OR > 500 lines
- Functional components with hooks only

**File Structure**:
```typescript
// Imports
// Types & constants (local)
// Helper functions (local)
// Sub-components (local)
// Main export
```

### Naming
- Components: `PascalCase` (`AppSidebar.tsx`)
- Hooks/utils: `camelCase` (`useConfig.ts`)
- Types: `PascalCase` (`type McpServer = ...`)

### Imports
- Use `@/` path aliases (e.g., `@/components/ui/button`)
- Group: external packages → internal modules → relative imports

## UI Guidelines

### Core Principles
- Minimal, clean design
- Use spacing and subtle backgrounds over borders
- Use shadcn/ui components from `@/components/ui/`

### Colors (Semantic via CSS variables)
- Background: `bg-background`, `bg-card`, `bg-muted`
- Text: `text-foreground`, `text-muted-foreground`
- Primary actions: `bg-primary text-primary-foreground`
- Destructive: `bg-destructive text-destructive-foreground`

### Component Usage
- **Sidebar**: Main navigation (already configured)
- **Tabs**: Category switching within pages
- **Card**: Group related settings
- **Dialog**: Complex forms, editing
- **Switch/Checkbox**: Boolean settings
- **Sonner**: Toast notifications

### Icons
- Use Lucide icons from `lucide-react`
- Standard size: `size-4` for inline, `size-5` for buttons

## Configuration Files (Claude Code)

| File | Content |
|------|---------|
| `~/.claude.json` | Main config (MCP servers, projects, OAuth) |
| `~/.claude/settings.json` | Settings (plugins, status line, env) |
| `~/.claude/settings.local.json` | Local overrides (sandbox mode) |
| `~/.claude/plugins/` | Installed plugins directory |

## Do

- Use Tauri APIs for file system operations
- Use `cn()` utility for conditional class names
- Run `pnpm lint` before committing
- Handle config files carefully (sensitive data)
- Use existing shadcn/ui components before building custom

## Do NOT

- Create docs/README files unless explicitly asked
- Use `any` type
- Create unnecessary barrel files (`index.ts`)
- Use CommonJS syntax
- Access file system directly (use Tauri APIs)
- Store sensitive data in frontend state

## Key Patterns

### Page Navigation
```typescript
const [currentPage, setCurrentPage] = useState('home');
// Pass to AppSidebar for navigation
```

### Config Reading (TODO)
```typescript
// Use Tauri fs plugin for reading config files
import { readTextFile } from '@tauri-apps/plugin-fs';
const config = JSON.parse(await readTextFile(path));
```

### Styling with cn()
```typescript
import { cn } from '@/lib/utils';
<div className={cn('base-class', isActive && 'active-class')} />
```
