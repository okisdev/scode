export interface ConfirmAction {
  type: 'uninstall' | 'untap' | 'cleanup' | 'clear-logs';
  name?: string;
  isCask?: boolean;
}
