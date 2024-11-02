//
//  Untitled.swift
//  remote-point
//
//  Created by 张文军 on 2024/11/2.
//

import Foundation
import Network

class WebSocketServer {
    private var listener: NWListener?
    private var connectedClients: [NWConnection] = []
    private let clientsQueue = DispatchQueue(label: "com.remotepoint.clients")
    private var isShuttingDown = false
    
    var onClientConnected: ((String) -> Void)?
    var onClientDisconnected: ((String) -> Void)?
    var onMessageReceived: ((String) -> Void)?
    var onMouseEvent: ((String) -> Void)?
    
    func start(port: UInt16 = 8080) {
        if isShuttingDown {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.actualStart(port: port)
            }
            return
        }
        actualStart(port: port)
    }
    
    private func actualStart(port: UInt16) {
        let parameters = NWParameters(tls: nil)
        parameters.allowLocalEndpointReuse = true
        parameters.includePeerToPeer = true
        
        let wsOptions = NWProtocolWebSocket.Options()
        wsOptions.autoReplyPing = true
        parameters.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)
        
        do {
            stop { [weak self] in
                guard let self = self else { return }
                
                do {
                    self.listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: port))
                    
                    self.listener?.stateUpdateHandler = { [weak self] state in
                        switch state {
                        case .ready:
                            print("WebSocket server ready on port \(port)")
                        case .failed(let error):
                            print("WebSocket server failed with error: \(error)")
                            if let error = error as? POSIXError, error.code == .EADDRINUSE {
                                print("Port \(port) is in use, trying port \(port + 1)")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    self?.start(port: port + 1)
                                }
                            }
                        case .cancelled:
                            print("WebSocket server cancelled")
                        case .waiting(let error):
                            print("WebSocket server waiting: \(error)")
                        default:
                            break
                        }
                    }
                    
                    self.listener?.newConnectionHandler = { [weak self] connection in
                        self?.handleNewConnection(connection)
                    }
                    
                    print("Starting WebSocket server on port \(port)...")
                    self.listener?.start(queue: .main)
                    
                } catch {
                    print("Failed to create WebSocket server: \(error)")
                }
            }
        }
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        let clientId = UUID().uuidString
        clientsQueue.async { [weak self] in
            self?.connectedClients.append(connection)
            self?.onClientConnected?(clientId)
        }
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("Client connected")
                self?.setupReceive(connection)
            case .failed(let error):
                print("Client connection failed: \(error)")
                self?.removeConnection(connection)
            case .cancelled:
                print("Client connection cancelled")
                self?.removeConnection(connection)
            default:
                break
            }
        }
        
        connection.start(queue: .main)
    }
    
    private func removeConnection(_ connection: NWConnection) {
        clientsQueue.async { [weak self] in
            self?.connectedClients.removeAll { $0 === connection }
        }

    }
    
    private func setupReceive(_ connection: NWConnection) {
        connection.receiveMessage { [weak self] content, context, isComplete, error in
            if let error = error {
                print("Receive error: \(error)")
                return
            }
            
            if let content = content,
               let message = String(data: content, encoding: .utf8) {
                self?.handleMessage(message, from: connection)
            }
            
            if connection.state == .ready {
                self?.setupReceive(connection)
            }
        }
    }
    
    private func handleMessage(_ message: String, from connection: NWConnection) {
        onMessageReceived?(message)
        
        guard let data = message.data(using: .utf8) else { return }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let type = json?["type"] as? String,
               let mouseData = json?["data"] as? [String: Any] {
                let mouseEvent = "类型: \(type), 数据: \(mouseData)"
                onMouseEvent?(mouseEvent)
                
                DispatchQueue.main.async {
                    self.handleMouseCommand(type: type, data: mouseData)
                }
            }
        } catch {
            print("Failed to parse message: \(error)")
        }
    }
    
    private func handleMouseCommand(type: String, data: [String: Any]) {
        switch type {
        case "MOUSE_MOVE":
            if let deltaX = data["deltaX"] as? Double,
               let deltaY = data["deltaY"] as? Double {
                let maxDelta: Double = 100.0
                let boundedDx = max(min(deltaX, maxDelta), -maxDelta)
                let boundedDy = max(min(deltaY, maxDelta), -maxDelta)
                
                DispatchQueue.main.async {
                    MouseController.shared.moveMouseBy(dx: boundedDx, dy: boundedDy)
                }
            }
        case "MOUSE_SCROLL":
            if let deltaY = data["deltaY"] as? Double {
                let maxScroll: Double = 10.0
                let boundedDeltaY = max(min(deltaY, maxScroll), -maxScroll)
                
                DispatchQueue.main.async {
                    MouseController.shared.scroll(deltaY: boundedDeltaY)
                }
            }
        case "MOUSE_CLICK":
            if let button = data["button"] as? String {
                if button == "left" {
                    MouseController.shared.leftClick()
                } else if button == "right" {
                    MouseController.shared.rightClick()
                }
            }
        default:
            break
        }
    }
    
    func stop(completion: (() -> Void)? = nil) {
        isShuttingDown = true
        print("Stopping WebSocket server...")
        
        clientsQueue.async { [weak self] in
            guard let self = self else { return }
            
            let group = DispatchGroup()
            
            for connection in self.connectedClients {
                group.enter()
                connection.cancel()
                group.leave()
            }
            self.connectedClients.removeAll()
            
            group.notify(queue: .main) { [weak self] in
                self?.listener?.cancel()
                self?.listener = nil
                self?.isShuttingDown = false
                print("Server fully stopped")
                completion?()
            }
        }
    }
    
    func getConnectedClientCount() -> Int {
        var count = 0
        clientsQueue.sync {
            count = connectedClients.count
        }
        return count
    }
}
