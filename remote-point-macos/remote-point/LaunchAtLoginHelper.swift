//
//  LaunchAtLoginHelper.swift
//  remote-point
//
//  Created by 张文军 on 2024/11/2.
//

import Foundation
import ServiceManagement

enum LaunchAtLoginHelper {
    static func set(_ enable: Bool) {
        if enable {
            enableLaunchAtLogin()
        } else {
            disableLaunchAtLogin()
        }
    }
    
    private static func enableLaunchAtLogin() {
        guard let bundleId = Bundle.main.bundleIdentifier else { return }
        
        if #available(macOS 13.0, *) {
            // 使用新的 ServiceManagement API
            try? SMAppService.mainApp.register()
        } else {
            // 使用旧的 ServiceManagement API
            let helper = bundleId + ".LaunchHelper"
            SMLoginItemSetEnabled(helper as CFString, true)
        }
    }
    
    private static func disableLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            // 使用新的 ServiceManagement API
            try? SMAppService.mainApp.unregister()
        } else {
            // 使用旧的 ServiceManagement API
            guard let bundleId = Bundle.main.bundleIdentifier else { return }
            let helper = bundleId + ".LaunchHelper"
            SMLoginItemSetEnabled(helper as CFString, false)
        }
    }
}
