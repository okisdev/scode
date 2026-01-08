# Scode Project Guide

## Project Overview

Desktop application for managing local Claude Code configurations and MCP servers.

**Tech**: Tauri 2, React 19, TypeScript, Tailwind CSS 4, shadcn/ui, Vite

## Commands

```bash
pnpm install          # Install dependencies
pnpm tauri dev        # Start development
pnpm tauri build      # Build production app
pnpm lint             # Lint code
pnpm lint:fix         # Fix lint issues
```

## Project Structure

```
src/
├── components/
│   ├── layout/        # Layout components (AppSidebar)
│   ├── pages/         # Page components
│   └── ui/            # shadcn/ui components (do NOT modify)
├── hooks/             # Custom React hooks
├── lib/               # Utilities
├── styles/            # CSS
└── App.tsx            # Main entry
src-tauri/             # Rust backend
```

## Code Style

- **NO `any` types**
- Use `@/` path aliases
- Keep related code together (300-500 lines per file is fine)
- Functional components with hooks only

## UI Guidelines

- **NO borders** - Use `bg-muted/50` and spacing instead
- **NO Card components** - Use custom div with `bg-muted/50 rounded-xl`
- Consistent page layout across all pages (see existing pages for pattern)
- Use Lucide icons from `lucide-react`

## Configuration Files (Claude Code)

| File | Content |
|------|---------|
| `~/.claude.json` | Main config (MCP servers, projects) |
| `~/.claude/settings.json` | Settings (plugins, status line) |
| `~/.claude/settings.local.json` | Local overrides (sandbox mode) |

## Do NOT

- Use `any` type
- Use borders for visual separation
- Use Card components for simple layouts
- Access file system directly (use Tauri APIs)
- Modify files in `src/components/ui/`
