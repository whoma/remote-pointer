//
//  ContentView.swift
//  remote-point
//
//  Created by 张文军 on 2024/11/2.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var serverManager = ServerManager.shared
    @State private var isSettingsShown = false
    @State private var showLogs = false
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧区域：状态和二维码
            VStack(spacing: 16) {
                // 状态指示器
                HStack {
                    Circle()
                        .fill(serverManager.isRunning ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(serverManager.isRunning ? "服务器运行中" : "服务器已停止")
                        .font(.system(size: 13, weight: .medium))
                }
                .padding(.top, 20)
                
                // 二维码显示区域
                if serverManager.isRunning {
                    QRCodeView(url: serverManager.serverURL)
                        .frame(width: 180, height: 180)
                        .background(Color(NSColor.windowBackgroundColor))
                        .cornerRadius(6)
                        .shadow(radius: 0.5)
                } else {
                    VStack {
                        Image(systemName: "qrcode")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("启动服务器后显示二维码")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 180, height: 180)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(6)
                }
                
                // 控制按钮
                HStack(spacing: 12) {
                    Button(action: {
                        if serverManager.isRunning {
                            serverManager.stopServer()
                        } else {
                            serverManager.startServer()
                        }
                    }) {
                        Text(serverManager.isRunning ? "停止服务器" : "启动服务器")
                            .frame(width: 100)
                    }
                    .controlSize(.regular)
                    
                    Button(action: {
                        isSettingsShown.toggle()
                    }) {
                        Image(systemName: "gear")
                    }
                    .controlSize(.regular)
                }
                .padding(.bottom, 20)
            }
            .frame(width: 220)
            .background(Color(NSColor.controlBackgroundColor))
            
            // 分隔线
            Divider()
            
            // 右侧区域：日志
            VStack(alignment: .leading, spacing: 8) {
                Text("运行日志")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.top, 20)
                    .padding(.horizontal, 16)
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(serverManager.logs.indices, id: \.self) { index in
                                let log = serverManager.logs[index]
                                HStack(alignment: .top, spacing: 8) {
                                    Text(formatDate(log.timestamp))
                                        .foregroundColor(.secondary)
                                        .font(.system(.caption, design: .monospaced))
                                    
                                    Text(log.message)
                                        .foregroundColor(log.type.color)
                                        .font(.system(.caption, design: .monospaced))
                                }
                                .padding(.horizontal, 16)
                                .id(index)
                            }
                        }
                        .onChange(of: serverManager.logs.count) { _ in
                            withAnimation {
                                proxy.scrollTo(serverManager.logs.count - 1, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.textBackgroundColor))
        }
        .frame(width: 700, height: 400)
        .sheet(isPresented: $isSettingsShown) {
            SettingsView(isPresented: $isSettingsShown)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}


#Preview {
    ContentView()
}
