<template>
  <div class="settings-panel">
    <h2>设置</h2>
    <div class="setting-item">
      <label>触控灵敏度</label>
      <input type="range" min="1" max="100" v-model="sensitivity" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const sensitivity = ref(50)
</script>

<style scoped>
.settings-panel {
  padding: 20px;
  background: #ffffff;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.setting-item {
  margin: 10px 0;
}
</style> 