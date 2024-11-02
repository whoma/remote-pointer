import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var serverManager: ServerManager = .shared
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupStatusItem()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "touchpad", accessibilityDescription: "Remote Point")
        }
        
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "重启服务器", action: #selector(restartServer), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Connected Devices: 0", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc private func restartServer() {
        serverManager.stopServer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.serverManager.startServer()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 创建一个信号量来等待服务器停止
        let semaphore = DispatchSemaphore(value: 0)
        
        serverManager.stopServer {
            semaphore.signal()
        }
        
        // 等待最多 2 秒
        _ = semaphore.wait(timeout: .now() + 2)
        
        NotificationCenter.default.post(name: Notification.Name("ApplicationWillTerminate"), object: nil)
    }
} 