import { createContext } from 'svelte';
import type { Locale } from './i18n';

export type Theme = 'classic' | 'neo';

export const [getPreferences, setPreferences] = createContext<{
	readonly theme: Theme;
	readonly locale: Locale;
	setTheme: (theme: Theme) => void;
	setLocale: (locale: Locale) => void;
	t: (message: string, values?: Record<string, string>) => string;
}>();
