<template>
  <div class="touchpad">
    <div class="connection-status" :class="{ connected: isConnected }">
      {{ isConnected ? '已连接' : '未连接' }}
    </div>
    <div class="control-mode">
      <button @click="toggleMode">
        当前模式: {{ controlMode }}
      </button>
    </div>
    <div class="touch-area"
      ref="touchpad"
      @touchstart="handleTouchStart"
      @touchmove="handleTouchMove"
      @touchend="handleTouchEnd"
    >
      <div v-if="controlMode === '陀螺仪' && isCalibrating" class="calibrating">
        校准中...请保持手机水平
      </div>
      <div v-else>
        {{ controlMode === '触控板' ? '触控板模式' : '陀螺仪模式' }}
      </div>
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
const controlMode = ref<'触控板' | '陀螺仪'>('触控板')
const gyroEnabled = ref(false)

// 陀螺仪相关参数
const lastGyroData = ref({ beta: 0, gamma: 0 })
const gyroSensitivity = 3.0
const gyroThreshold = 0.2
const basePosition = ref({ beta: 0, gamma: 0 })
const isCalibrating = ref(false)

const ws = useWebSocket()

// 切换控制模式
const toggleMode = () => {
  controlMode.value = controlMode.value === '触控板' ? '陀螺仪' : '触控板'
  if (controlMode.value === '陀螺仪') {
    requestGyroscopePermission()
  }
}

// 请求陀螺仪权限
const requestGyroscopePermission = async () => {
  try {
    // @ts-ignore
    if (typeof DeviceOrientationEvent.requestPermission === 'function') {
      // @ts-ignore
      const permission = await DeviceOrientationEvent.requestPermission()
      if (permission === 'granted') {
        gyroEnabled.value = true
        calibrateGyroscope()
        startGyroscope()
      }
    } else {
      // 对于不需要权限的设备，直接启用陀螺仪
      gyroEnabled.value = true
      calibrateGyroscope()
      startGyroscope()
    }
  } catch (error) {
    console.error('Gyroscope permission denied:', error)
  }
}

// 添加陀螺仪校准
const calibrateGyroscope = () => {
  isCalibrating.value = true
  setTimeout(() => {
    window.addEventListener('deviceorientation', (event) => {
      if (isCalibrating.value && event.beta !== null && event.gamma !== null) {
        basePosition.value = {
          beta: event.beta,
          gamma: event.gamma
        }
        isCalibrating.value = false
      }
    }, { once: true })
  }, 500)
}

// 处理陀螺仪数据
const handleGyroscope = (event: DeviceOrientationEvent) => {
  if (controlMode.value !== '陀螺仪' || !gyroEnabled.value || isCalibrating.value) return
  
  const { beta, gamma } = event
  if (beta === null || gamma === null) return
  
  // 计算相对于基准位置的变化
  const deltaX = (gamma - basePosition.value.gamma) * gyroSensitivity
  const deltaY = (beta - basePosition.value.beta) * gyroSensitivity
  
  if (Math.abs(deltaX) > gyroThreshold || Math.abs(deltaY) > gyroThreshold) {
    ws.send(JSON.stringify({
      type: 'MOUSE_MOVE',
      data: {
        deltaX: -deltaX,  // 反转 X 轴使移动更直观
        deltaY: deltaY,
        timestamp: Date.now()
      }
    }))
  }
}

// 启动陀螺仪监听
const startGyroscope = () => {
  window.addEventListener('deviceorientation', handleGyroscope)
}

// 停止陀螺仪监听
const stopGyroscope = () => {
  window.removeEventListener('deviceorientation', handleGyroscope)
}

// 触控板相关处理函数保持不变
const handleTouchStart = (event: TouchEvent) => {
  if (controlMode.value !== '触控板') return
  const touch = event.touches[0]
  lastTouchPosition.value = {
    x: touch.clientX,
    y: touch.clientY
  }
  hasMoved.value = false
  event.preventDefault()
}

const handleTouchMove = (event: TouchEvent) => {
  if (controlMode.value !== '触控板') return
  
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
          deltaY: -deltaY * 0.8,
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
  if (controlMode.value !== '触控板') return
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

onMounted(() => {
  ws.connect()
  ws.onOpen(() => {
    isConnected.value = true
  })
  ws.onClose(() => {
    isConnected.value = false
  })
})

onUnmounted(() => {
  ws.disconnect()
  stopGyroscope()
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

.control-mode {
  padding: 10px;
  text-align: center;
}

.control-mode button {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  background: #007AFF;
  color: white;
  font-size: 16px;
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

.calibrating {
  color: #007AFF;
  font-weight: bold;
}
</style> 