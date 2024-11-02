export class WebSocketService {
  private ws: WebSocket | null = null
  private url: string
  private reconnectAttempts = 0
  private maxReconnectAttempts = 5
  private onOpenCallbacks: (() => void)[] = []
  private onCloseCallbacks: (() => void)[] = []
  private onMessageCallbacks: ((data: any) => void)[] = []
  
  constructor() {
    // 获取本地 IP 地址，用于局域网内连接
    const host = window.location.hostname === 'localhost' ? 'localhost' : window.location.hostname
    this.url = `ws://${host}:8080`
  }
  
  connect() {
    try {
      console.log('Connecting to:', this.url)
      this.ws = new WebSocket(this.url)
      
      this.ws.onopen = () => {
        console.log('WebSocket connected')
        this.reconnectAttempts = 0
        this.onOpenCallbacks.forEach(cb => cb())
      }
      
      this.ws.onclose = () => {
        console.log('WebSocket closed')
        this.onCloseCallbacks.forEach(cb => cb())
        this.tryReconnect()
      }
      
      this.ws.onerror = (error) => {
        console.error('WebSocket error:', error)
      }

      this.ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data)
          this.onMessageCallbacks.forEach(cb => cb(data))
        } catch (error) {
          console.error('Failed to parse message:', error)
        }
      }
      
    } catch (error) {
      console.error('Failed to connect:', error)
    }
  }
  
  onOpen(callback: () => void) {
    this.onOpenCallbacks.push(callback)
  }
  
  onClose(callback: () => void) {
    this.onCloseCallbacks.push(callback)
  }
  
  onMessage(callback: (data: any) => void) {
    this.onMessageCallbacks.push(callback)
  }

  private tryReconnect() {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++
      console.log(`Attempting to reconnect (${this.reconnectAttempts}/${this.maxReconnectAttempts})...`)
      setTimeout(() => {
        this.connect()
      }, 1000 * this.reconnectAttempts)
    }
  }
  
  send(data: string) {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(data)
    } else {
      console.warn('WebSocket is not connected')
    }
  }
  
  disconnect() {
    this.ws?.close()
    this.ws = null
  }
}

// Composable for Vue components
export function useWebSocket() {
  return new WebSocketService()
} 