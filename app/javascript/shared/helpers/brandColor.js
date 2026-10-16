import { mix, parseToRgba } from 'color2k';

export const DEFAULT_BRAND_COLOR = '#2781f6';

// Keep the shipped palette when no installation override is configured.
const HEX_COLOR = /^#[0-9a-f]{6}$/i;
const LIGHT_BLUE_TINTS = [0.99, 0.97, 0.93, 0.85, 0.76, 0.65, 0.5, 0.3];
const DARK_BLUE_SHADES = [0.04, 0.08, 0.2, 0.28, 0.36, 0.45, 0.55, 0.7];
const WOOT_TINTS = {
  25: 1,
  50: 0.83,
  75: 0.67,
  100: 0.5,
  200: 0.33,
  300: 0.165,
  400: 0.07,
  500: 0,
};
const WOOT_SHADES = { 600: 0.14, 700: 0.28, 800: 0.42, 900: 0.69 };
const BRAND_PROPERTIES = [
  '--brand-color',
  '--brand-color-hex',
  '--brand-border-blue',
  '--brand-solid-active-light',
  '--brand-solid-active-dark',
  ...Object.keys({ ...WOOT_TINTS, ...WOOT_SHADES }).map(
    step => `--woot-${step}`
  ),
  ...Array.from({ length: 12 }, (_, index) => index + 1).flatMap(step => [
    `--brand-blue-light-${step}`,
    `--brand-blue-dark-${step}`,
  ]),
];

const toChannels = color => parseToRgba(color).slice(0, 3).map(Math.round);
const toRgb = color => toChannels(color).join(' ');

export const applyBrandColor = color => {
  const style = document.documentElement.style;
  // Only remove tokens owned by this helper, including when resetting the color.
  BRAND_PROPERTIES.forEach(name => style.removeProperty(name));

  if (typeof color !== 'string' || !HEX_COLOR.test(color)) return;
  if (color.toLowerCase() === DEFAULT_BRAND_COLOR) return;

  const setColor = (name, value) => style.setProperty(name, toRgb(value));
  const tint = amount => mix(color, '#ffffff', amount);
  const shade = amount => mix(color, '#000000', amount);

  setColor('--brand-color', color);
  style.setProperty('--brand-color-hex', color);
  style.setProperty(
    '--brand-border-blue',
    `${toChannels(color).join(', ')}, 0.5`
  );

  Object.entries(WOOT_TINTS).forEach(([step, amount]) => {
    setColor(`--woot-${step}`, tint(amount));
  });
  Object.entries(WOOT_SHADES).forEach(([step, amount]) => {
    setColor(`--woot-${step}`, shade(amount));
  });

  const lightPalette = [
    ...LIGHT_BLUE_TINTS.map(tint),
    color,
    shade(0.08),
    shade(0.2),
    shade(0.65),
  ];
  const darkPalette = [
    ...DARK_BLUE_SHADES.map(amount => mix('#111113', color, amount)),
    color,
    tint(0.1),
    tint(0.45),
    tint(0.8),
  ];

  // Mode-specific aliases in the existing theme also cover elements mounted later.
  [lightPalette, darkPalette].forEach((palette, index) => {
    const mode = index === 0 ? 'light' : 'dark';
    palette.forEach((value, step) => {
      setColor(`--brand-blue-${mode}-${step + 1}`, value);
    });
  });
  setColor('--brand-solid-active-light', tint(0.5));
  setColor('--brand-solid-active-dark', mix('#353942', color, 0.42));
};
