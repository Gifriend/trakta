import { createContext } from 'svelte';
import type { Locale } from './i18n';

export type Theme = 'classic' | 'neo';
export type DisplayMode = 'light' | 'dark';

export const [getPreferences, setPreferences] = createContext<{
	readonly theme: Theme;
	readonly mode: DisplayMode;
	readonly locale: Locale;
	setTheme: (theme: Theme) => void;
	setMode: (mode: DisplayMode) => void;
	setLocale: (locale: Locale) => void;
	t: (message: string, values?: Record<string, string>) => string;
}>();
