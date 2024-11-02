<template>
  <div class="app">
    <TouchPad />
    <SettingsPanel v-if="showSettings" />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import TouchPad from './components/TouchPad.vue'
import SettingsPanel from './components/SettingsPanel.vue'

const showSettings = ref(false)
</script>

<style>
.app {
  height: 100vh;
  padding: 20px;
  box-sizing: border-box;
  background: #ffffff;
}

/* 移动端适配 */
@media (max-width: 768px) {
  .app {
    padding: 10px;
  }
}
</style> 