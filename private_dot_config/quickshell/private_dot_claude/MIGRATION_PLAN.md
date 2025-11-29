# QuickShell Config & Appearance Migration Plan

## Status: Phase 1 Complete ✓

### Phase 1: Core Configuration System (COMPLETED)

#### What Was Done:
1. ✅ Fixed theme.json typo (`darkl` → `dark`)
2. ✅ Merged ConfigOptions.qml into Config.qml
3. ✅ Added missing launcher configurations to config.json
4. ✅ Refactored Appearance.qml to load from theme.json based on config
5. ✅ Replaced all `ConfigOptions` with `Config.options` throughout codebase
6. ✅ Removed old ConfigLoader.qml service
7. ✅ Cleaned up ConfigLoader references in shell.qml and test.qml
8. ✅ Fixed remaining ConfigOptions references in:
   - services/AppSearch.qml:15
   - services/MaterialThemeLoader.qml:37

#### Current System Architecture:
- **Config.qml** (modules/common/Config.qml): Single source of truth for all configuration
  - Uses FileView + JsonAdapter to load config/config.json
  - Auto-reloads on file changes
  - Access via `Config.options.*`

- **Appearance.qml** (modules/common/Appearance.qml): Theme and styling system
  - Loads theme colors from config/theme.json
  - Reads theme mode from `Config.options.ui.theme` (dark/light)
  - Applies font settings from `Config.options.font`
  - Access via `Appearance.*` for colors, fonts, animations, etc.

---

## Phase 2: Widget & Component Migration (IN PROGRESS)

### Priority 1: Topbar Components (COMPLETED ✓)

These components have been migrated to use Config/Appearance:

#### ✅ modules/topbar/Topbar.qml
- ✅ Migrated background color to `Appearance.colors.colLayer0`
- ✅ Migrated height to `Appearance.sizes.barHeight`
- ✅ Migrated margins to `Config.options.bar.margins`

#### ✅ modules/topbar/Clock.qml
- ✅ Added `Config.options.time.format` to config.json
- ✅ Migrated time format to `Config.options.time.format`
- ✅ Migrated text color to `Appearance.m3colors.m3primaryText`
- ✅ Migrated font size to `Appearance.font.pixelSize.textMedium`
- ✅ Migrated font family to `Appearance.font.family.uiFont`
- ✅ Migrated radius to `Appearance.rounding.unsharpen`
- ✅ Migrated animation duration to `Appearance.animation.elementMoveFast.duration`

#### ✅ modules/topbar/Workspaces.qml
- ✅ Added `Config.options.bar.workspaces.*` to config.json
- ✅ Migrated workspace size to `Config.options.bar.workspaces.size`
- ✅ Migrated spacing to `Config.options.bar.workspaces.spacing`
- ✅ Migrated colors to `Appearance.colors.colLayer1Hover`
- ✅ Migrated radius to `Appearance.rounding.small`
- ✅ Migrated icon size to `Config.options.bar.workspaces.iconSize`
- ✅ Migrated icon color to `Appearance.m3colors.m3primaryText`
- ✅ Migrated animation durations to `Appearance.animation.elementMoveFast.duration`

#### ✅ modules/topbar/ActiveWindow.qml
- ✅ Migrated text color to `Appearance.m3colors.m3primaryText`
- ✅ Migrated font size to `Appearance.font.pixelSize.iconLarge`
- ✅ Migrated font family to `Appearance.font.family.uiFont`

#### ✅ modules/topbar/SysTray.qml
- ✅ Added `Config.options.bar.tray.*` to config.json
- ✅ Migrated spacing to `Config.options.bar.tray.spacing`
- ✅ Migrated item size to `Config.options.bar.tray.itemSize`
- ✅ Migrated icon size to `Config.options.bar.tray.iconSize`
- ✅ Migrated radius to `Appearance.rounding.unsharpen`
- ✅ Migrated animation durations to `Appearance.animation.elementMoveFast.duration`

#### 🟡 modules/topbar/AppDrawer.qml
- Review for hardcoded styling
- May need integration with Config.options.bar

#### 🟡 modules/topbar/ControlCenter.qml
- Review for styling consistency
- May need config integration

#### 🟡 modules/topbar/VolumeIndicator.qml & VolumePopup.qml
- Check for hardcoded colors and sizes
- May relate to Config.options.audio

#### 🟡 modules/topbar/PomodoroIndicator.qml & PomodoroPopup.qml
- Should use `Config.options.time.pomodoro` settings
- Review styling consistency

---

### Priority 2: Overview Module (MEDIUM PRIORITY)

#### ✅ modules/overview/Overview.qml
- **Already migrated!** Uses Config.options properly

#### ✅ modules/overview/OverviewWidget.qml
- **Already migrated!** Uses Config.options.overview settings

#### 🟡 modules/overview/OverviewWindow.qml
- Review for any remaining hardcoded values
- Verify integration with Config.options

#### 🟡 modules/overview/SearchWidget.qml
- Verify uses Config.options.search settings
- Check styling consistency with Appearance

---

### Priority 3: Launcher Module (MEDIUM PRIORITY)

#### ✅ modules/launcher/Launcher.qml
- **Already migrated!** Uses Config.options properly

#### 🟡 modules/launcher/AppListSimple.qml
- Review for Config.options.launcher usage
- Check styling consistency

#### 🟡 modules/launcher/AppItemSimple.qml
- Review item sizing and colors
- Should use Appearance for styling

#### 🟡 modules/launcher/ContentListSimple.qml
- Review for hardcoded values
- Verify Config integration

#### 🟡 modules/launcher/WrapperSimple.qml (if exists)
- Review wrapper styling
- Check Config.options.launcher integration

---

### Priority 4: WindowSwitcher Module (MEDIUM PRIORITY)

#### ✅ modules/windowswitcher/WindowSwitcher.qml
- **Partially migrated** - uses Appearance for some styling
- **Lines 138-139**: Uses `Appearance.rounding.large` ✓
- **Line 138**: Uses `Appearance.m3colors.m3layerBackground2` ✓
- **Line 148**: Uses `Appearance.m3colors.m3shadowColor` ✓
- **Line 182-183**: Uses `Appearance.m3colors.*` ✓
- **Line 107**: Hardcoded timer interval `100`
  - Should use: `Config.options.hacks.arbitraryRaceConditionDelay`

---

### Priority 5: Common Widgets (LOW-MEDIUM PRIORITY)

89 widget files total. Focus on frequently used widgets first:

#### 🔴 High-Use Widgets (Review First):
1. **StyledText.qml** - Core text styling
2. **StyledTextInput.qml** - Input field styling
3. **StyledTextArea.qml** - Text area styling
4. **RippleButton.qml** - Button component
5. **DialogButton.qml** - Dialog buttons
6. **MaterialSymbol.qml** - Icon component
7. **StyledScrollBar.qml** - Scrollbar styling
8. **StyledProgressBar.qml** - Progress indicators
9. **Toolbar.qml** - Toolbar component
10. **ToolbarButton.qml** - Toolbar buttons

#### 🟡 Medium-Use Widgets:
11. **FloatingActionButton.qml**
12. **GroupButton.qml**
13. **SelectionGroupButton.qml**
14. **MenuButton.qml**
15. **NotificationItem.qml**
16. **NotificationGroup.qml**
17. **ConfigRow.qml**
18. **ConfigSwitch.qml**
19. **ConfigSpinBox.qml**
20. **StyledSwitch.qml**
21. **StyledSlider.qml**
22. **StyledSpinBox.qml**
23. **NavigationRail.qml**
24. **NavigationRailButton.qml**
25. **PrimaryTabButton.qml**
26. **SecondaryTabButton.qml**

#### ⚪ Lower Priority Widgets:
27-89. All remaining widgets in modules/common/widgets/

---

## Phase 3: Missing Configuration Options (TODO)

Add these missing options to config.json:

### Bar Configuration Extensions:
```json
{
  "bar": {
    "height": 40,
    "margins": 15,
    "spacing": 10,
    "clock": {
      "format": "ddd MMM dd  hh:mm"  // Already exists in time.format, create alias
    },
    "workspaces": {
      "size": 24,
      "iconSize": 16,
      "spacing": 4,
      "radius": 4
    },
    "activeWindow": {
      "maxWidth": 400,
      "showIcon": true,
      "showTitle": true
    }
  }
}
```

### Animation Configuration:
```json
{
  "animation": {
    "enable": true,
    "duration": {
      "fast": 200,
      "normal": 300,
      "slow": 500
    }
  }
}
```

### Window Switcher Configuration:
```json
{
  "windowSwitcher": {
    "itemSize": 100,
    "spacing": 15,
    "containerWidth": 600,
    "showDelay": 100
  }
}
```

---

## Phase 4: Theme.json Extensions (TODO)

Consider adding these theme-specific values to theme.json:

### Extended Color Palette:
```json
{
  "dark": {
    // ... existing colors ...
    "barBackground": "#1a1b26cc",
    "barForeground": "#e6e6e6e6",
    "workspaceActive": "#ffffff26",
    "workspaceInactive": "#00000000",
    "tooltipBackground": "#1f2335",
    "tooltipText": "#c0caf5"
  }
}
```

---

## Migration Checklist Template

For each component/widget migration:

```markdown
### Component: [Name]
- [ ] Identify all hardcoded colors → use Appearance.colors.* or Appearance.m3colors.*
- [ ] Identify all hardcoded sizes → use Appearance.sizes.* or add to Config
- [ ] Identify all hardcoded fonts → use Appearance.font.*
- [ ] Identify all hardcoded animations → use Appearance.animation.*
- [ ] Identify all hardcoded radii → use Appearance.rounding.*
- [ ] Add missing config options to config.json if needed
- [ ] Test component with different themes (dark/light)
- [ ] Test component with different config values
- [ ] Document any new config options added
```

---

## Testing Strategy

### After Each Widget Migration:
1. Test with dark theme
2. Test with light theme
3. Test with modified config values
4. Verify hot-reload works
5. Check for visual regressions

### Full System Testing:
1. Switch between dark/light themes
2. Modify config.json and verify changes apply
3. Modify theme.json and verify colors update
4. Test on different screen sizes/DPI
5. Verify all animations work consistently

---

## Future Enhancements

### Dynamic Theme Switching:
- Add function to Appearance.qml to reload theme on config change
- Add IPC command to switch themes without restart
- Add UI toggle for dark/light mode

### Config Validation:
- Add schema validation for config.json
- Add default value fallbacks for missing options
- Add error handling for malformed JSON

### Per-Monitor Configuration:
- Add support for per-monitor bar settings
- Add support for different themes per monitor

---

## Session Notes

### Session 1:
- ✅ Completed Phase 1: Core configuration system
- ✅ Verified no dead code or unused imports remain
- 📝 Created comprehensive migration plan

### Session 2 (Current):
- ✅ Completed Priority 1: Topbar Components migration
- ✅ Added `Config.options.time.format` to config.json
- ✅ Added `Config.options.bar.margins` and `spacing` to config.json
- ✅ Added `Config.options.bar.workspaces.*` to config.json
- ✅ Added `Config.options.bar.tray.*` to config.json
- ✅ Migrated Clock.qml - all styling now uses Config/Appearance
- ✅ Migrated Topbar.qml - height, color, margins from Config/Appearance
- ✅ Migrated Workspaces.qml - sizes, colors, animations from Config/Appearance
- ✅ Migrated ActiveWindow.qml - text styling from Appearance
- ✅ Migrated SysTray.qml - sizes, animations from Config/Appearance

### Next Session Tasks:
1. Test all topbar components with dark/light themes
2. Review and migrate remaining topbar components:
   - AppDrawer.qml
   - ControlCenter.qml
   - VolumeIndicator.qml & VolumePopup.qml
   - PomodoroIndicator.qml & PomodoroPopup.qml
3. Move to Priority 2: Overview Module components
4. Continue with Priority 3: Launcher Module components

---

## Quick Reference

### How to Use Config:
```qml
import qs.modules.common

// Access config values
Config.options.bar.bottom
Config.options.overview.scale
Config.options.search.searchEnabled
Config.options.font.family.uiFont
Config.options.hacks.arbitraryRaceConditionDelay
```

### How to Use Appearance:
```qml
import qs.modules.common

// Colors
Appearance.m3colors.m3primaryText
Appearance.colors.colLayer1
Appearance.colors.colPrimary

// Fonts
Appearance.font.family.uiFont
Appearance.font.pixelSize.textBase

// Sizes
Appearance.sizes.barHeight
Appearance.rounding.small

// Animations
Appearance.animation.elementMoveFast.duration
Appearance.animation.elementMove.numberAnimation
```

### Config File Locations:
- Main config: `~/.config/quickshell/config/config.json`
- Theme colors: `~/.config/quickshell/config/theme.json`
- Config definition: `~/.config/quickshell/modules/common/Config.qml`
- Appearance definition: `~/.config/quickshell/modules/common/Appearance.qml`

---

*Generated: 2025-10-15*
*Last Updated: 2025-10-19*
