interface DeviceOrientationEvent extends Event {
  alpha: number | null;
  beta: number | null;
  gamma: number | null;
  absolute: boolean;
}

interface DeviceOrientationEventStatic extends EventTarget {
  requestPermission?: () => Promise<'granted' | 'denied' | 'default'>;
}

interface Window {
  DeviceOrientationEvent: {
    prototype: DeviceOrientationEvent;
    new(type: string, eventInitDict?: DeviceOrientationEventInit): DeviceOrientationEvent;
    requestPermission?: () => Promise<'granted' | 'denied' | 'default'>;
  }
} 