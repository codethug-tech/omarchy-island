pragma Singleton
import "FileUrls.js" as FileUrls
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
// Omarchy manages lock screen
import "../theme"
Singleton {
    id: root
    property bool suspendAfterLock: false
    property string error: ""
    property string pendingResponse: ""
    property bool unlocking: false
    readonly property string wallpaperSource: (SystemInfo.wallpaper || SystemInfo.lockWallpaper) ? FileUrls.fromPath(SystemInfo.wallpaper || SystemInfo.lockWallpaper) : SystemInfo.wallpapers[0]?.url ?? ""
    readonly property int wallpaperDecodeWidth: Math.min(2560,Math.max(1920,...Quickshell.screens.map(s=>Math.round(s.width*s.devicePixelRatio))))
    // Keep one decoded image warm; lock surfaces reuse the same Qt image-cache key.
    readonly property Image wallpaperPreload: Image {
        source:root.wallpaperSource;sourceSize.width:root.wallpaperDecodeWidth
        asynchronous:true;cache:true;visible:false
    }

    readonly property bool verifyAuthenticating: verifyPam.active && !verifyPam.responseRequired
    readonly property bool verifyResponseVisible: verifyPam.responseVisible
    readonly property string verifyPrompt: verifyPam.responseRequired ? verifyPam.message : "Password"
    property string verifyPending: ""
    property bool authenticationVerified: false
    property string authenticationCheckResult: ""
    property int lockRevision: 0
    readonly property bool locked: { lockRevision; return sessionLock.locked; }
    function isLocked(): bool { return sessionLock.locked; }
    function refreshLockState(): void { lockRevision++; }
    readonly property bool secure: sessionLock.secure
    property string sleepMode: "suspend"
    readonly property bool authenticating: pam.active && !pam.responseRequired
    readonly property bool responseVisible: pam.responseVisible
    readonly property string prompt: pam.responseRequired ? pam.message : "Password"
    function lock(suspend: bool): void {
        IslandState.closeMenu();
        if (suspend) {
            suspendProc.running = true;
        } else {
            lockProc.running = true;
        }
    }
    function requestSleep(mode: string): void { if (["suspend", "suspend-then-hibernate", "hibernate", "hybrid-sleep"].includes(mode)) { sleepMode = mode; lock(true); } }
    function verifyPassword(response: string): void {
        if (Quickshell.env("MODESTY_PREVIEW") === "1" || locked || verifyAuthenticating) return;
        authenticationCheckResult = "";
        if (verifyPam.responseRequired) verifyPam.respond(response);
        else { verifyPending = response; if (!verifyPam.start()) { verifyPending = ""; authenticationCheckResult = "Authentication could not start."; } }
    }
    function cancelVerification(): void { verifyPending = ""; if (verifyPam.active) verifyPam.abort(); }
    PamContext {
        id: verifyPam
        config: "system-auth"
        configDirectory: "/etc/pam.d"
        onPamMessage: {
            if (responseRequired && root.verifyPending.length) { const response = root.verifyPending; root.verifyPending = ""; respond(response); }
        }
        onCompleted: result => {
            root.verifyPending = "";
            root.authenticationVerified = result === PamResult.Success;
            root.authenticationCheckResult = root.authenticationVerified ? "Password verified. Unlock authentication is working." : result === PamResult.Error ? "PAM could not load the system authentication configuration." : result === PamResult.MaxTries ? "Too many attempts. Wait before trying again." : "Authentication failed. Check the password and try again.";
        }
    }
    function submit(response: string): void {
        if (!locked || authenticating || unlocking) return;
        error = "";
        if (pam.responseRequired) pam.respond(response);
        else { pendingResponse = response; if (!pam.start()) { pendingResponse = ""; error = "Unable to start authentication"; } }
    }
    PamContext {
        id: pam
        config: "system-auth"
        configDirectory: "/etc/pam.d"
        onPamMessage: {
            if (responseRequired && root.pendingResponse.length) {
                const response = root.pendingResponse; root.pendingResponse = ""; respond(response);
            }
        }
        onCompleted: result => {
            root.pendingResponse = "";
            if (result === PamResult.Success) { root.error = ""; root.unlocking = true; unlockDelay.start(); }
            else root.error = result === PamResult.Failed ? "Incorrect password. Try again." : "Authentication could not complete. Try again.";
        }
    }
    // Authentication completes first; the compositor lock remains held until
    // every lock surface has finished its departure animation.
    Timer {
        id: unlockDelay; interval: Tokens.reducedMotion ? 1 : Preferences.lockDuration + 16
        onTriggered: {
            sessionLock.locked = false;
            root.refreshLockState();
            root.unlocking = false;
        }
    }
    QtObject {
        id: sessionLock
        property bool locked: false
        property bool secure: false
    }
    Process {
        id: lockProc; command: ["omarchy", "system", "lock"]
    }
    Process {
        id: suspendProc; command: ["systemctl", root.sleepMode]
        onExited: exitCode => { if (exitCode !== 0) root.error = "Could not suspend."; }
    }
}
