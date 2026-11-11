import { createContext } from 'svelte';
import type { Locale } from './i18n';
import type { CameraEffect } from './utils/camera';

export type DisplayMode = 'light' | 'dark';

export const THEMES = {
	classic: { label: 'Trakta', colors: { light: '#124e43', dark: '#111d19' } },
	neo: { label: 'Neobrutalism', colors: { light: '#dcf768', dark: '#181c31' } },
	glass: { label: 'Glassmorphism', colors: { light: '#e5ecff', dark: '#10162d' } },
	clay: { label: 'Claymorphism', colors: { light: '#f6e9ec', dark: '#211925' } },
	swiss: { label: 'Swiss Minimalist', colors: { light: '#f6f6f3', dark: '#141414' } },
	deco: { label: 'Art Deco', colors: { light: '#efe8d8', dark: '#161513' } }
} satisfies Record<string, { label: string; colors: Record<DisplayMode, string> }>;

export type Theme = keyof typeof THEMES;

export function isTheme(value: string | undefined): value is Theme {
	return value !== undefined && Object.hasOwn(THEMES, value);
}

export const [getPreferences, setPreferences] = createContext<{
	readonly theme: Theme;
	readonly mode: DisplayMode;
	readonly locale: Locale;
	readonly cameraEffect: CameraEffect;
	setTheme: (theme: Theme) => void;
	setMode: (mode: DisplayMode) => void;
	setLocale: (locale: Locale) => void;
	setCameraEffect: (effect: CameraEffect) => void;
	t: (message: string, values?: Record<string, string>) => string;
}>();
