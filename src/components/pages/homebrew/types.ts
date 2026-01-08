export interface ConfirmAction {
  type: 'uninstall' | 'untap' | 'cleanup';
  name?: string;
  isCask?: boolean;
}
