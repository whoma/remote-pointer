//
//  ServerManager.swift
//  remote-point
//
//  Created by 张文军 on 2024/11/2.
//

import Foundation
import Network
import SwiftUI

class ServerManager: ObservableObject {
    static let shared = ServerManager()
    
    @Published var isRunning = false
    @Published var serverURL = ""
    @Published var logs: [(timestamp: Date, message: String, type: LogType)] = []
    
    enum LogType {
        case info
        case success
        case warning
        case error
        case websocket
        case mouse
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            case .websocket: return .purple
            case .mouse: return .gray
            }
        }
    }
    
    private let defaults = UserDefaults.standard
    
    private var serverIP: String {
        get { defaults.string(forKey: "serverIP") ?? "0.0.0.0" }
        set { defaults.set(newValue, forKey: "serverIP") }
    }
    
    private var serverPort: UInt16 {
        get { UInt16(defaults.integer(forKey: "serverPort")) != 0 ? UInt16(defaults.integer(forKey: "serverPort")) : 8080 }
        set { defaults.set(Int(newValue), forKey: "serverPort") }
    }
    
    private var webAppURL: String {
        get { defaults.string(forKey: "webAppURL") ?? "http://localhost:5173" }
        set { defaults.set(newValue, forKey: "webAppURL") }
    }
    
    private var webSocketServer: WebSocketServer?
    
    private init() {
        webSocketServer = WebSocketServer()
        setupWebSocketCallbacks()
    }
    
    private func setupWebSocketCallbacks() {
        webSocketServer?.onClientConnected = { [weak self] clientId in
            self?.addLog("新客户端连接: \(clientId)", type: .websocket)
        }
        
        webSocketServer?.onClientDisconnected = { [weak self] clientId in
            self?.addLog("客户端断开连接: \(clientId)", type: .websocket)
        }
        
        webSocketServer?.onMessageReceived = { [weak self] message in
            self?.addLog("收到消息: \(message)", type: .websocket)
        }
        
        webSocketServer?.onMouseEvent = { [weak self] event in
            self?.addLog("鼠标事件: \(event)", type: .mouse)
        }
    }
    
    func addLog(_ message: String, type: LogType = .info) {
        DispatchQueue.main.async {
            self.logs.append((timestamp: Date(), message: message, type: type))
            if self.logs.count > 1000 {  // 增加日志容量
                self.logs.removeFirst()
            }
        }
    }
    
    func startServer() {
        addLog("正在启动服务器...", type: .info)
        webSocketServer?.start(port: serverPort)
        isRunning = true
        
        let ip = getLocalIPAddress() ?? serverIP
        let wsURL = "ws://\(ip):\(serverPort)"
        let encodedWsURL = wsURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        serverURL = "\(webAppURL)?wsUrl=\(encodedWsURL)"
        addLog("服务器已启动: \(wsURL)", type: .success)
        addLog("Web App URL: \(serverURL)", type: .info)
    }
    
    func stopServer(completion: (() -> Void)? = nil) {
        addLog("正在停止服务器...", type: .warning)
        webSocketServer?.stop { [weak self] in
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.serverURL = ""
                self?.addLog("服务器已停止", type: .success)
                completion?()
            }
        }
    }
    
    func updateConfig(ip: String, port: UInt16, webAppURL: String) {
        self.serverIP = ip
        self.serverPort = port
        self.webAppURL = webAppURL
        addLog("配置已更新: IP=\(ip), Port=\(port)")
    }
    
    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else {
            addLog("无法获取本地IP地址")
            return nil
        }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            let interface = ptr?.pointee
            let addrFamily = interface?.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: (interface?.ifa_name)!)
                if name == "en0" || name == "en1" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface?.ifa_addr,
                              socklen_t((interface?.ifa_addr.pointee.sa_len)!),
                              &hostname,
                              socklen_t(hostname.count),
                              nil,
                              0,
                              NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        return address
    }
}
