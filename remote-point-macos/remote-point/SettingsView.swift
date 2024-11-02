import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var serverManager = ServerManager.shared
    
    // 使用 @State 而不是 @AppStorage
    @State private var mouseSensitivity: Double
    @State private var scrollSensitivity: Double
    @State private var launchAtLogin: Bool
    @State private var serverIP: String
    @State private var serverPort: Int
    @State private var webAppURL: String
    
    private let defaults = UserDefaults.standard
    
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        
        // 从 UserDefaults 初始化所有状态
        let defaults = UserDefaults.standard
        let defaultPort = defaults.integer(forKey: "serverPort")
        
        // 初始化所有状态变量
        _mouseSensitivity = State(initialValue: defaults.double(forKey: "mouseSensitivity"))
        _scrollSensitivity = State(initialValue: defaults.double(forKey: "scrollSensitivity"))
        _launchAtLogin = State(initialValue: defaults.bool(forKey: "launchAtLogin"))
        _serverIP = State(initialValue: defaults.string(forKey: "serverIP") ?? "0.0.0.0")
        _serverPort = State(initialValue: defaultPort == 0 ? 8080 : defaultPort)
        _webAppURL = State(initialValue: defaults.string(forKey: "webAppURL") ?? "http://localhost:5173")
        
        // 设置默认值
        if defaults.double(forKey: "mouseSensitivity") == 0 {
            defaults.set(1.0, forKey: "mouseSensitivity")
            _mouseSensitivity = State(initialValue: 1.0)
        }
        if defaults.double(forKey: "scrollSensitivity") == 0 {
            defaults.set(1.0, forKey: "scrollSensitivity")
            _scrollSensitivity = State(initialValue: 1.0)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TabView {
                // 鼠标设置
                mouseSettingsView
                    .tabItem {
                        Label("鼠标", systemImage: "mouse")
                    }
                
                // 服务器设置
                serverSettingsView
                    .tabItem {
                        Label("服务器", systemImage: "network")
                    }
                
                // 通用设置
                generalSettingsView
                    .tabItem {
                        Label("通用", systemImage: "gear")
                    }
            }
            .padding(20)
            
            // 底部按钮
            HStack {
                Spacer()
                Button("取消") {
                    isPresented = false
                }
                Button("确定") {
                    saveSettings()
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 450, height: 300)
    }
    
    // MARK: - 子视图
    
    private var mouseSettingsView: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    HStack {
                        Text("鼠标灵敏度")
                        Spacer()
                        Text(String(format: "%.1f", mouseSensitivity))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $mouseSensitivity, in: 0.1...3.0, step: 0.1)
                }
                .padding(.vertical, 4)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("滚动灵敏度")
                        Spacer()
                        Text(String(format: "%.1f", scrollSensitivity))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $scrollSensitivity, in: 0.1...3.0, step: 0.1)
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var serverSettingsView: some View {
        Form {
            Section {
                TextField("服务器IP:", text: $serverIP)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                HStack {
                    Text("端口:")
                    TextField("端口", value: $serverPort, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 100)
                }
                
                TextField("Web App URL:", text: $webAppURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
    
    private var generalSettingsView: some View {
        Form {
            Section {
                Toggle("开机自启动", isOn: $launchAtLogin)
                    .toggleStyle(SwitchToggleStyle())
            }
        }
    }
    
    // MARK: - 私有方法
    
    private func saveSettings() {
        // 保存所有设置到 UserDefaults
        defaults.set(mouseSensitivity, forKey: "mouseSensitivity")
        defaults.set(scrollSensitivity, forKey: "scrollSensitivity")
        defaults.set(launchAtLogin, forKey: "launchAtLogin")
        defaults.set(serverIP, forKey: "serverIP")
        defaults.set(serverPort, forKey: "serverPort")
        defaults.set(webAppURL, forKey: "webAppURL")
        
        // 更新服务器配置
        serverManager.updateConfig(
            ip: serverIP,
            port: UInt16(serverPort),
            webAppURL: webAppURL
        )
        
        // 更新启动项设置
        LaunchAtLoginHelper.set(launchAtLogin)
        
        // 更新鼠标控制器设置
        MouseController.shared.setSensitivity(mouseSensitivity)
    }
}

#Preview {
    SettingsView(isPresented: .constant(true))
} 