<script setup>
import { ref } from 'vue';
import axios from 'axios';

const email = ref('');
const name = ref('');
const message = ref('');
const newTravellerId = ref(null); // 用於儲存新註冊的 ID

const register = async () => {
    message.value = '';
    newTravellerId.value = null;

    try {
        const response = await axios.post('http://localhost:3000/api/register', {
            email: email.value,
            name: name.value
        });
        
        // 成功訊息
        message.value = `註冊成功！歡迎 ${response.data.name}。您的 ID 是 ${response.data.id}`;
        newTravellerId.value = response.data.id;
        
        // 清空表單
        email.value = '';
        name.value = '';

    } catch (error) {
        console.error('註冊錯誤:', error);
        if (error.response && error.response.data) {
            message.value = `錯誤: ${error.response.data.message}`;
        } else {
            message.value = '註冊失敗，請檢查網路或伺服器。';
        }
    }
};
</script>

<template>
  <div class="card">
    <h2>註冊新旅行者</h2>
    <form @submit.prevent="register">
      <div>
        <label for="email">電子郵件:</label>
        <input type="email" id="email" v-model="email" required>
      </div>
      <div>
        <label for="name">姓名:</label>
        <input type="text" id="name" v-model="name" required>
      </div>
      <button type="submit">註冊</button>
    </form>
    
    <p v-if="message" :class="newTravellerId ? 'success' : 'error'">{{ message }}</p>
    <p v-if="newTravellerId">
        **請記住此 ID**，之後建立行程會用到：<strong style="color: blue;">{{ newTravellerId }}</strong>
    </p>
  </div>
</template>

<style scoped>
.success { color: green; }
.error { color: red; }
</style>