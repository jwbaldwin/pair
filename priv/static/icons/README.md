# Custom Icons

This directory contains custom SVG icons for the Pair application.

## Usage

1. **Add an icon**: Copy your SVG code from Figma and save it as `icon-name.svg` in this directory
2. **Use the icon**: Reference it in your templates with `<.icon name="icon-name" class="h-5 w-5" />`

## Guidelines

- Use kebab-case for icon filenames (e.g., `my-icon.svg`)
- Ensure SVGs have proper viewBox attributes for scaling
- Use `currentColor` for stroke/fill to inherit text color
- Keep SVGs optimized and clean

## Integration

The icon system automatically:
- Loads SVG files from this directory
- Merges CSS classes with existing SVG classes
- Falls back to heroicons for `hero-` prefixed icons
- Shows a warning symbol for missing icons
