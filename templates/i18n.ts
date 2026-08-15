/**
 * Lightweight Zero-dependency i18n Adapter for Obsidian Plugins
 * (Raw Key Approach)
 */

import en from "./locales/en.json";
import ja from "./locales/ja.json";

export type TranslationDict = Record<string, string>;
export type SupportedLocale = "en" | "ja" | string;

const builtinTranslations: Record<string, TranslationDict> = {
    en: en as TranslationDict,
    ja: ja as TranslationDict,
};

let customTranslations: Record<string, TranslationDict> = {};

/**
 * Detect current Obsidian locale
 */
export function getObsidianLocale(): string {
    // 1. Check window.localStorage (Obsidian's language setting key)
    try {
        const storedLang = window.localStorage.getItem("language");
        if (storedLang) {
            return storedLang.toLowerCase();
        }
    } catch {
        // ignore
    }

    // 2. Check moment.js locale if available in Obsidian environment
    try {
        if (typeof (window as unknown as { moment?: { locale: () => string } }).moment?.locale === "function") {
            const momentLocale = (window as unknown as { moment: { locale: () => string } }).moment.locale();
            if (momentLocale) {
                return momentLocale.toLowerCase();
            }
        }
    } catch {
        // ignore
    }

    // 3. Fallback to navigator.language
    if (typeof navigator !== "undefined" && navigator.language) {
        return navigator.language.toLowerCase().split("-")[0];
    }

    return "en";
}

/**
 * Register external or custom translation dictionary (e.g. from user overlay or i18n-plus)
 */
export function registerCustomLocale(locale: string, dict: TranslationDict): void {
    const key = locale.toLowerCase();
    customTranslations[key] = {
        ...(customTranslations[key] || {}),
        ...dict,
    };
}

/**
 * Format string with placeholder parameters:
 * formatString("Hello {name}!", { name: "Obsidian" }) => "Hello Obsidian!"
 */
function interpolate(template: string, params?: Record<string, string | number>): string {
    if (!params) return template;
    return template.replace(/\{(\w+)\}/g, (match, key) => {
        return Object.prototype.hasOwnProperty.call(params, key) ? String(params[key]) : match;
    });
}

/**
 * Translate a message by original English text
 * Fallback chain: Custom Locale -> Built-in Locale -> Built-in 'en' -> Raw Key
 */
export function t(key: string, params?: Record<string, string | number>, forcedLocale?: string): string {
    const locale = (forcedLocale || getObsidianLocale()).toLowerCase();
    const shortLocale = locale.split("-")[0];

    // 1. Look in custom translations
    if (customTranslations[locale]?.[key]) {
        return interpolate(customTranslations[locale][key], params);
    }
    if (customTranslations[shortLocale]?.[key]) {
        return interpolate(customTranslations[shortLocale][key], params);
    }

    // 2. Look in built-in translations
    if (builtinTranslations[locale]?.[key]) {
        return interpolate(builtinTranslations[locale][key], params);
    }
    if (builtinTranslations[shortLocale]?.[key]) {
        return interpolate(builtinTranslations[shortLocale][key], params);
    }

    // 3. Fallback to built-in 'en' dictionary
    if (builtinTranslations.en?.[key]) {
        return interpolate(builtinTranslations.en[key], params);
    }

    // 4. Return raw key with interpolation
    return interpolate(key, params);
}

export default t;
