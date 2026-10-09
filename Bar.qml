import QtQuick
import Quickshell
import Quickshell.Io
import "modules/island" as Island
import "modules/settings" as Settings
import "services"
import "theme"

Item {
    id: root

    // Host-injected properties by Omarchy
    property string omarchyPath: ""
    property var shell: null
    property var manifest: null
    property var barWidgetRegistry: null
    property var pluginRegistry: null
    property var barConfig: ({})

    // Target display (primary screen)
    readonly property var targetScreen: Quickshell.screens.find(s => s.name === Quickshell.env("MODESTY_SCREEN")) ?? Quickshell.screens[0]

    // Modesty Settings Window
    Settings.SettingsWindow {
        id: settingsWindow
    }

    Island.Island {
        id: island
        dropTargetWindow: dropTarget
        screen: root.targetScreen
    }

    Island.IslandDropTarget {
        id: dropTarget
        sourceIsland: island
    }

    IpcHandler {
        target: "island"
        function action(name: string): void { Bindings.trigger(name); }
        function open(panel: string): void { IslandState.openMenu(panel); }
        function toggle(panel: string): void { IslandState.toggle(panel); }
        function close(): void { IslandState.closeMenu(); }
        function hello(): void { if (!Session.isLocked()) { IslandState.closeMenu(); Context.show("welcome", "", "", 0); } }
        function lock(): void { Session.lock(false); }
        function wallpaper(path: string): void { SystemInfo.applyWallpaper(path); }
        function file(path: string): bool { return IslandDrop.accept([path]); }
        function geometry(): string {
            return JSON.stringify(Object.assign(island.surface.diagnostics(), {
                fullscreen: island.fullscreen,
                hiddenByFullscreen: island.hiddenByFullscreen
            }));
        }
        function tray(index: int): void { if (Tray.items[index]) Tray.show(Tray.items[index]); }
        function status(): string { return IslandState.state; }
        function mediaDebug(): string {
            return JSON.stringify({
                playing: Media.playing,
                title: Media.title,
                artist: Media.artist,
                length: Media.length,
                position: Media.position,
                trackKey: LiveMedia.trackKey,
                loadedKey: LiveMedia.loadedKey,
                linesCount: LiveMedia.lines ? LiveMedia.lines.length : 0,
                hasSyncedLyrics: LiveMedia.hasSyncedLyrics,
                listening: LiveMedia.listening,
                expanded: LiveMedia.expanded,
                compactTitle: LiveMedia.compactTitle,
                lyricIndex: LiveMedia.lyricIndex,
                lyric: LiveMedia.lyric,
                error: LiveMedia.error
            });
        }
        function health(): string {
            return JSON.stringify({
                preview: SystemInfo.preview,
                locked: Session.isLocked(),
                wifiAvailable: Wireless.available,
                bluetoothAvailable: Radio.available,
                error: SystemInfo.error
            });
        }
    }
}
