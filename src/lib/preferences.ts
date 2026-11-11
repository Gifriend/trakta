import { createContext } from 'svelte';

export type Theme = 'classic' | 'neo';

export const [getPreferences, setPreferences] = createContext<{
	readonly theme: Theme;
	setTheme: (theme: Theme) => void;
}>();
