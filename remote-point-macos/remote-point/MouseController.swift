//
//  Untitled.swift
//  remote-point
//
//  Created by 张文军 on 2024/11/2.
//
import Foundation
import CoreGraphics

class MouseController {
    // 添加单例实例
    static let shared = MouseController()
    
    private var sensitivity: Double = 1.0
    
    // 私有初始化方法，确保只能通过 shared 访问
    private init() {}
    
    // 设置鼠标灵敏度
    func setSensitivity(_ value: Double) {
        sensitivity = max(0.5, min(value, 3.0))  // 扩大灵敏度范围到 0.5-3.0
    }
    
    // 获取当前鼠标位置
    private func getCurrentMouseLocation() -> CGPoint? {
        CGEvent(source: nil)?.location
    }
    
    // 移动鼠标
    func moveMouseBy(dx: Double, dy: Double) {  // 重命名方法以匹配调用
        guard let currentLocation = getCurrentMouseLocation() else { return }
        
        let adjustedX = currentLocation.x + CGFloat(dx * sensitivity)
        let adjustedY = currentLocation.y + CGFloat(dy * sensitivity)
        
        let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
                              mouseCursorPosition: CGPoint(x: adjustedX, y: adjustedY),
                              mouseButton: .left)
        
        moveEvent?.post(tap: .cghidEventTap)
    }
    
    // 滚动处理
    func scroll(deltaY: Double) {
        print("Received deltaY: \(deltaY)")
        
        // 保持 deltaY 方向不变，只调整速度
        let scrollMultiplier = 3.0  // 移除负号，保持方向一致
        let adjustedDelta = deltaY * scrollMultiplier
        
        print("Adjusted deltaY: \(adjustedDelta)")
        
        let scrollEvent = CGEvent(scrollWheelEvent2Source: nil,
                                units: .pixel,
                                wheelCount: 1,
                                wheel1: Int32(adjustedDelta),
                                wheel2: 0,
                                wheel3: 0)
        
        scrollEvent?.post(tap: .cghidEventTap)
    }
    
    // 鼠标点击
    func click(button: CGMouseButton = .left) {
        guard let currentLocation = getCurrentMouseLocation() else { return }
        
        // 按下
        let clickDown = CGEvent(mouseEventSource: nil,
                              mouseType: .leftMouseDown,
                              mouseCursorPosition: currentLocation,
                              mouseButton: button)
        
        // 释放
        let clickUp = CGEvent(mouseEventSource: nil,
                            mouseType: .leftMouseUp,
                            mouseCursorPosition: currentLocation,
                            mouseButton: button)
        
        clickDown?.post(tap: .cghidEventTap)
        clickUp?.post(tap: .cghidEventTap)
    }
    
    // 右键点击
    func rightClick() {
        guard let currentLocation = getCurrentMouseLocation() else { return }
        
        // 按下右键
        let clickDown = CGEvent(mouseEventSource: nil,
                              mouseType: .rightMouseDown,
                              mouseCursorPosition: currentLocation,
                              mouseButton: .right)
        
        // 释放右键
        let clickUp = CGEvent(mouseEventSource: nil,
                            mouseType: .rightMouseUp,
                            mouseCursorPosition: currentLocation,
                            mouseButton: .right)
        
        clickDown?.post(tap: .cghidEventTap)
        clickUp?.post(tap: .cghidEventTap)
    }
    
    // 添加左键点击方法
    func leftClick() {
        guard let currentLocation = getCurrentMouseLocation() else { return }
        
        // 按下左键
        let clickDown = CGEvent(mouseEventSource: nil,
                              mouseType: .leftMouseDown,
                              mouseCursorPosition: currentLocation,
                              mouseButton: .left)
        
        // 释放左键
        let clickUp = CGEvent(mouseEventSource: nil,
                            mouseType: .leftMouseUp,
                            mouseCursorPosition: currentLocation,
                            mouseButton: .left)
        
        clickDown?.post(tap: .cghidEventTap)
        clickUp?.post(tap: .cghidEventTap)
    }
    
    // 重命名现有的 click 方法为 clickButton（如果需要的话）
    func clickButton(button: CGMouseButton = .left) {
        guard let currentLocation = getCurrentMouseLocation() else { return }
        
        let mouseDownType: CGEventType = button == .left ? .leftMouseDown : .rightMouseDown
        let mouseUpType: CGEventType = button == .left ? .leftMouseUp : .rightMouseUp
        
        let clickDown = CGEvent(mouseEventSource: nil,
                              mouseType: mouseDownType,
                              mouseCursorPosition: currentLocation,
                              mouseButton: button)
        
        let clickUp = CGEvent(mouseEventSource: nil,
                            mouseType: mouseUpType,
                            mouseCursorPosition: currentLocation,
                            mouseButton: button)
        
        clickDown?.post(tap: .cghidEventTap)
        clickUp?.post(tap: .cghidEventTap)
    }
}
