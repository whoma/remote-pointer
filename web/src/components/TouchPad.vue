<template>
  <div class="touchpad" 
    tabindex="0" 
    ref="touchpad"
    @keydown="handleKeyDown"
    @compositionstart="handleCompositionStart"
    @compositionend="handleCompositionEnd"
  >
    <div class="connection-status" :class="{ connected: isConnected }">
      {{ isConnected ? '已连接' : '未连接' }}
    </div>
    <div class="touch-area"
      @touchstart="handleTouchStart"
      @touchmove="handleTouchMove"
      @touchend="handleTouchEnd"
    >
      <div>触控板模式</div>
    </div>
    
    <div class="mouse-buttons">
      <button class="mouse-button left" @click="handleMouseClick('left')">左键</button>
      <button class="mouse-button right" @click="handleMouseClick('right')">右键</button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useWebSocket } from '../services/websocket'

const touchpad = ref<HTMLElement | null>(null)
const isConnected = ref(false)
const lastTouchPosition = ref({ x: 0, y: 0 })
const hasMoved = ref(false)
const isComposing = ref(false)

const ws = useWebSocket()

// 处理输入法组合开始
const handleCompositionStart = () => {
  isComposing.value = true
}

// 处理输入法组合结束
const handleCompositionEnd = (event: CompositionEvent) => {
  isComposing.value = false
  const text = event.data
  if (text) {
    ws.send(JSON.stringify({
      type: 'KEY_INPUT',
      data: {
        text,
        timestamp: Date.now()
      }
    }))
  }
}

// 修改按键处理函数
const handleKeyDown = (event: KeyboardEvent) => {
  // 如果正在输入法组合，不处理按键事件
  if (isComposing.value) return

  // 处理普通字符输入
  if (event.key.length === 1) {
    ws.send(JSON.stringify({
      type: 'KEY_INPUT',
      data: {
        text: event.key,
        timestamp: Date.now()
      }
    }))
    return
  }

  // 处理特殊按键
  const specialKeys = ['Enter', 'Backspace', 'Tab', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Escape']
  if (specialKeys.includes(event.key)) {
    ws.send(JSON.stringify({
      type: 'SPECIAL_KEY',
      data: {
        key: event.key,
        timestamp: Date.now()
      }
    }))
    event.preventDefault()
  }
}

const handleTouchStart = (event: TouchEvent) => {
  const touch = event.touches[0]
  lastTouchPosition.value = {
    x: touch.clientX,
    y: touch.clientY
  }
  hasMoved.value = false
  event.preventDefault()
}

const handleTouchMove = (event: TouchEvent) => {
  // 检测触摸点数量
  if (event.touches.length === 2) {
    // 双指滚动
    const touch1 = event.touches[0]
    const touch2 = event.touches[1]
    const currentY = (touch1.clientY + touch2.clientY) / 2
    const lastY = lastTouchPosition.value.y
    const deltaY = lastY - currentY
    
    if (Math.abs(deltaY) > 0.5) {  // 添加一个小的阈值
      ws.send(JSON.stringify({
        type: 'MOUSE_SCROLL',
        data: {
          deltaY: deltaY * 0.3,
          timestamp: Date.now()
        }
      }))
    }
    
    lastTouchPosition.value = {
      x: (touch1.clientX + touch2.clientX) / 2,
      y: currentY
    }
  } else {
    // 单指移动鼠标
    const touch = event.touches[0]
    const deltaX = touch.clientX - lastTouchPosition.value.x
    const deltaY = touch.clientY - lastTouchPosition.value.y
    
    if (Math.abs(deltaX) > 0.2 || Math.abs(deltaY) > 0.2) {
      ws.send(JSON.stringify({
        type: 'MOUSE_MOVE',
        data: {
          deltaX: deltaX * 0.8,
          deltaY: deltaY * 0.8,
          timestamp: Date.now()
        }
      }))
      hasMoved.value = true
    }
    
    lastTouchPosition.value = {
      x: touch.clientX,
      y: touch.clientY
    }
  }
  
  event.preventDefault()
}

const handleTouchEnd = (event: TouchEvent) => {
  if (!hasMoved) {
    ws.send(JSON.stringify({
      type: 'MOUSE_CLICK',
      data: {
        button: 'left',
        timestamp: Date.now()
      }
    }))
  }
  event.preventDefault()
}

const handleMouseClick = (button: 'left' | 'right') => {
  ws.send(JSON.stringify({
    type: 'MOUSE_CLICK',
    data: {
      button,
      timestamp: Date.now()
    }
  }))
}

onMounted(() => {
  ws.connect()
  ws.onOpen(() => {
    isConnected.value = true
  })
  ws.onClose(() => {
    isConnected.value = false
  })
  
  // 自动获取焦点以接收键盘事件
  touchpad.value?.focus()
})

onUnmounted(() => {
  ws.disconnect()
})
</script>

<style scoped>
.touchpad {
  width: 100%;
  height: 70vh;
  background: #f5f5f5;
  border-radius: 12px;
  position: relative;
  display: flex;
  flex-direction: column;
  outline: none; /* 移除焦点时的轮廓 */
}

.connection-status {
  position: absolute;
  top: 10px;
  right: 10px;
  padding: 5px 10px;
  border-radius: 4px;
  background: rgba(255, 0, 0, 0.1);
  color: #ff0000;
}

.connection-status.connected {
  background: rgba(0, 255, 0, 0.1);
  color: #008000;
}

.touch-area {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #666;
  font-size: 14px;
  touch-action: none;
  user-select: none;
}

.mouse-buttons {
  display: flex;
  justify-content: space-around;
  padding: 15px;
  background: #fff;
  border-top: 1px solid #eee;
}

.mouse-button {
  width: 45%;
  padding: 12px;
  border: none;
  border-radius: 8px;
  background: #007AFF;
  color: white;
  font-size: 16px;
  touch-action: manipulation;
}

.mouse-button:active {
  background: #0056b3;
}

.mouse-button.left {
  background: #007AFF;
}

.mouse-button.right {
  background: #5856D6;
}

/* 修改发送按钮为删除按钮的样式 */
.delete-button {
  padding: 8px 16px;
  border: none;
  border-radius: 6px;
  background: #ff3b30; /* 使用红色表示删除 */
  color: white;
  font-size: 14px;
  white-space: nowrap;
}

.delete-button:active {
  background: #dc3545;
}

/* 添加键盘输入区域样式 */
.keyboard-input {
  display: flex;
  padding: 10px;
  background: #fff;
  border-top: 1px solid #eee;
  gap: 10px;
}

.keyboard-input input {
  flex: 1;
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 16px;
  outline: none;
}

.keyboard-input input:focus {
  border-color: #007AFF;
}
</style> 