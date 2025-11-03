<script setup>
import { ref } from 'vue';
import axios from 'axios';

// ⚠️ 實際應用中，這個 ID 應該是登入後儲存的。這裡用於測試
const currentTravellerId = ref(1); 
const title = ref('');
const destination = ref('');
const startDate = ref('');
const shortDescription = ref('');
const detailDescription = ref('');
const message = ref('');

const createItinerary = async () => {
    message.value = '';

    // 簡單的客戶端驗證
    if (shortDescription.value.length > 80) {
        message.value = '簡短描述不能超過 80 個字符。';
        return;
    }
    if (!currentTravellerId.value) {
        message.value = '請輸入您的旅行者 ID。';
        return;
    }

    try {
        const response = await axios.post('http://localhost:3000/api/itineraries', {
            traveller_id: currentTravellerId.value,
            title: title.value,
            destination: destination.value,
            start_date: startDate.value,
            short_description: shortDescription.value,
            detail_description: detailDescription.value
        });
        
        message.value = `行程 "${title.value}" 建立成功！ID: ${response.data.id}`;
        
        // 清空表單
        title.value = destination.value = startDate.value = shortDescription.value = detailDescription.value = '';

    } catch (error) {
        console.error('建立行程錯誤:', error);
        message.value = '建立行程失敗，請檢查 ID 是否有效或伺服器錯誤。';
    }
};
</script>

<template>
  <div class="card">
    <h2>建立新行程</h2>
    <form @submit.prevent="createItinerary">
      <p>⚠️ **測試用 ID**：</p>
      <div>
        <label for="travellerId">您的旅行者 ID (模擬登入):</label>
        <input type="number" id="travellerId" v-model="currentTravellerId" required>
      </div>

      <div>
        <label for="title">標題:</label>
        <input type="text" id="title" v-model="title" required>
      </div>
      <div>
        <label for="destination">目的地:</label>
        <input type="text" id="destination" v-model="destination" required>
      </div>
      <div>
        <label for="startDate">開始日期:</label>
        <input type="date" id="startDate" v-model="startDate" required>
      </div>
      <div>
        <label for="shortDesc">簡短描述 (80 字內):</label>
        <input type="text" id="shortDesc" v-model="shortDescription" maxlength="80" required>
      </div>
      <div>
        <label for="detailDesc">詳細描述:</label>
        <textarea id="detailDesc" v-model="detailDescription"></textarea>
      </div>
      
      <button type="submit">建立行程</button>
    </form>
    <p v-if="message" :class="message.includes('成功') ? 'success' : 'error'">{{ message }}</p>
  </div>
</template>

<style scoped>
textarea { width: 100%; height: 100px; }
</style>