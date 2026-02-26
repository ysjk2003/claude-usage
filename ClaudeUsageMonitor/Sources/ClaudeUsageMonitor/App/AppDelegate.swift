import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
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
        popover.contentSize = NSSize(width: 300, height: 200)
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(viewModel: viewModel, onQuit: {
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
            popover.contentViewController = NSHostingController(
                rootView: PopoverView(viewModel: viewModel, onQuit: {
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
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let self = self, self.popover.isShown {
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
}
