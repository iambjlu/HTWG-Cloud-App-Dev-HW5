<script setup>
import { ref, onMounted } from 'vue';
import axios from 'axios';

// ⚠️ 實際應用中，這個 ID 應該是登入後儲存的。
const currentTravellerId = ref(1); 
const itineraries = ref([]);
const selectedItinerary = ref(null);
const loading = ref(false);
const error = ref('');

// 函數：獲取所有行程列表
const fetchItineraries = async () => {
    error.value = '';
    loading.value = true;
    selectedItinerary.value = null;

    if (!currentTravellerId.value) {
        error.value = '請輸入您的旅行者 ID 以查看行程。';
        loading.value = false;
        return;
    }

    try {
        const response = await axios.get(`http://localhost:3000/api/itineraries/${currentTravellerId.value}`);
        itineraries.value = response.data;
    } catch (e) {
        error.value = '無法載入行程列表，請檢查 ID 或後端。';
    } finally {
        loading.value = false;
    }
};

// 函數：查看單個行程詳情
const viewDetails = async (id) => {
    error.value = '';
    selectedItinerary.value = null; // 清除之前的詳情
    
    try {
        const response = await axios.get(`http://localhost:3000/api/itineraries/detail/${id}`);
        selectedItinerary.value = response.data;
    } catch (e) {
        error.value = '無法載入行程詳情。';
    }
};

// 在元件載入時自動獲取列表（用於測試）
onMounted(fetchItineraries);
</script>

<template>
  <div class="card">
    <h2>我的行程一覽</h2>

    <div style="margin-bottom: 20px;">
        <label for="travellerIdList">您的旅行者 ID (模擬登入):</label>
        <input type="number" id="travellerIdList" v-model="currentTravellerId" @change="fetchItineraries" required>
        <button @click="fetchItineraries" style="margin-left: 10px;">重新載入</button>
    </div>

    <p v-if="loading">載入中...</p>
    <p v-if="error" class="error">{{ error }}</p>

    <div v-if="itineraries.length > 0">
      <h3>行程列表 (點擊查看詳情)</h3>
      <ul class="itinerary-list">
        <li v-for="it in itineraries" :key="it.id" @click="viewDetails(it.id)" :class="{ active: selectedItinerary && selectedItinerary.id === it.id }">
          **{{ it.title }}** - {{ it.start_date }} 
        </li>
      </ul>
    </div>
    <p v-else-if="!loading && !error">目前沒有行程。</p>

    <div v-if="selectedItinerary" class="detail-box">
      <h3>行程詳情：{{ selectedItinerary.title }}</h3>
      <p><strong>目的地:</strong> {{ selectedItinerary.destination }}</p>
      <p><strong>開始日期:</strong> {{ selectedItinerary.start_date }}</p>
      <p><strong>簡短描述:</strong> {{ selectedItinerary.short_description }}</p>
      <h4>詳細說明:</h4>
      <p>{{ selectedItinerary.detail_description }}</p>
    </div>
  </div>
</template>

<style scoped>
.itinerary-list {
    list-style: none;
    padding: 0;
    cursor: pointer;
}
.itinerary-list li {
    padding: 10px;
    border-bottom: 1px solid #eee;
    transition: background-color 0.2s;
}
.itinerary-list li:hover {
    background-color: #f0f0f0;
}
.itinerary-list li.active {
    background-color: #e0e0ff;
    border-left: 5px solid blue;
}
.detail-box {
    margin-top: 20px;
    padding: 15px;
    border: 1px solid #ccc;
    border-radius: 5px;
}
</style>