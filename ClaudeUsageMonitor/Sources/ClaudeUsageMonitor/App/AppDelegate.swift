import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var dashboardWindow: NSWindow?
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    let viewModel = StatsViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: "Claude Usage")
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageLeading
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 420)
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(viewModel: viewModel, onOpenDashboard: { [weak self] in
                self?.openDashboard()
            }, onQuit: {
                NSApplication.shared.terminate(nil)
            })
        )

        // Start monitoring
        viewModel.startMonitoring()
        updateMenuBarText()

        // Periodically update menu bar text
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMenuBarText()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        viewModel.stopMonitoring()
    }

    private func updateMenuBarText() {
        if let button = statusItem.button {
            let text = viewModel.menuBarText
            button.title = text.isEmpty ? "" : " \(text)"
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            closePopover()
        } else {
            // Update content before showing
            popover.contentViewController = NSHostingController(
                rootView: PopoverView(viewModel: viewModel, onOpenDashboard: { [weak self] in
                    self?.openDashboard()
                }, onQuit: {
                    NSApplication.shared.terminate(nil)
                })
            )
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            updateMenuBarText()
            addEventMonitors()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        removeEventMonitors()
    }

    private func addEventMonitors() {
        // Detect clicks outside the app (other apps, desktop, etc.)
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
        // Detect clicks within the app but outside the popover
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let self = self, self.popover.isShown {
                // Allow clicks on the status bar button (handled by togglePopover)
                if event.window == self.statusItem.button?.window {
                    return event
                }
                self.closePopover()
            }
            return event
        }
    }

    private func removeEventMonitors() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }

    func openDashboard() {
        closePopover()

        if let window = dashboardWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let dashboardView = DashboardView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: dashboardView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingController
        window.title = "Claude Usage Dashboard"
        window.center()
        window.setFrameAutosaveName("DashboardWindow")
        window.minSize = NSSize(width: 700, height: 500)
        window.isReleasedWhenClosed = false
        window.delegate = self

        dashboardWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension AppDelegate: NSWindowDelegate {
    nonisolated func windowWillClose(_ notification: Notification) {
        Task { @MainActor in
            if let window = notification.object as? NSWindow, window === dashboardWindow {
                dashboardWindow = nil
            }
        }
    }
}
