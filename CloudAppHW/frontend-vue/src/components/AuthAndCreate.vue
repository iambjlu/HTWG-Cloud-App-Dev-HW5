<!-- frontend-vue/src/components/AuthAndCreate.vue -->
<script setup>
import { ref } from 'vue';
import axios from 'axios';
import { auth } from '../firebase';
import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  updateProfile
} from 'firebase/auth';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL;

const props = defineProps({
  userEmail: {
    type: String,
    default: null
  },
  isAuthenticated: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits(['itinerary-updated']);

// --- Auth 狀態 ---
const authEmail = ref('');
const authPassword = ref('');
const authName = ref('');
const authMessage = ref('');

// Firebase 註冊
const register = async () => {
  authMessage.value = '';
  if (!authEmail.value || !authEmail.value.includes('@')) {
    authMessage.value = 'Invaild E-mail Address';
    return;
  }
  if (!authPassword.value || authPassword.value.length < 6) {
    authMessage.value = 'Password must be at least 6 characters';
    return;
  }

  try {
    const cred = await createUserWithEmailAndPassword(auth, authEmail.value, authPassword.value);
    if (authName.value) {
      await updateProfile(cred.user, { displayName: authName.value });
    }
    const token = await cred.user.getIdToken();
    // 通知後端補建 travellers 這個 user（若不存在）
    await axios.post(`${API_BASE_URL}/api/travellers/ensure`, { name: authName.value || cred.user.displayName || 'Anonymous' }, {
      headers: { Authorization: `Bearer ${token}` }
    });

    authMessage.value = `Register Successfully！User Email: ${cred.user.email}`;
  } catch (err) {
    console.error(err);
    authMessage.value = err?.message || 'Register failed';
  }
};

// Firebase 登入
const login = async () => {
  authMessage.value = '';
  try {
    const cred = await signInWithEmailAndPassword(auth, authEmail.value, authPassword.value);
    const token = await cred.user.getIdToken();
    await axios.post(`${API_BASE_URL}/api/travellers/ensure`, { name: cred.user.displayName || 'Anonymous' }, {
      headers: { Authorization: `Bearer ${token}` }
    });
    authMessage.value = `Login Successfully！User Email: ${cred.user.email}`;
  } catch (err) {
    console.error(err);
    authMessage.value = err?.message || 'Login failed';
  }
};

// --- 建立行程狀態 (Create) ---
const createTitle = ref('');
const createDestination = ref('');
const createStartDate = ref('');
const createEndDate = ref('');
const createShortDesc = ref('');
const createDetailDesc = ref('');
const createMessage = ref('');

const createItinerary = async () => {
  createMessage.value = '';

  if (createShortDesc.value.length > 80) {
    createMessage.value = 'Short Description should not longer than 80 letters.';
    return;
  }

  if (!props.userEmail) {
    createMessage.value = 'Please login or register.';
    return;
  }

  try {
    await axios.post(`${API_BASE_URL}/api/itineraries`, {
      // 後端會從 token 取 email，不再需要 traveller_email 放 body
      title: createTitle.value,
      destination: createDestination.value,
      start_date: createStartDate.value,
      end_date: createEndDate.value,
      short_description: createShortDesc.value,
      detail_description: createDetailDesc.value
    });

    createMessage.value = `Trip "${createTitle.value}" Created Successfully！`;

    createTitle.value = createDestination.value = createStartDate.value = createEndDate.value = createShortDesc.value = createDetailDesc.value = '';

    emit('itinerary-updated');

  } catch (error) {
    console.error('Error creating trip: ', error);
    createMessage.value = 'Error creating trip.';
  }
};
</script>

<template>
  <div class="space-y-6">
    <!-- 註冊/登入 (未認證時顯示) -->
    <div v-if="!isAuthenticated" class="bg-white p-6 rounded-xl shadow-lg border border-gray-200">
      <h2 class="text-xl font-semibold mb-4 text-gray-800 border-b pb-2">Register or Login</h2>
      <form @submit.prevent class="space-y-4">
        <div class="flex flex-col">
          <label for="authEmail" class="text-sm font-medium text-gray-700">E-mail</label>
          <input
              type="email"
              id="authEmail"
              v-model="authEmail"
              required
              class="mt-1 p-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              placeholder="Please enter your Email"
          >
        </div>
        <div class="flex flex-col">
          <label for="authPassword" class="text-sm font-medium text-gray-700">Password</label>
          <input
              type="password"
              id="authPassword"
              v-model="authPassword"
              required
              class="mt-1 p-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              placeholder="At least 6 characters"
          >
        </div>
        <div class="flex flex-col">
          <label for="authName" class="text-sm font-medium text-gray-700">Name (for Register)</label>
          <input
              type="text"
              id="authName"
              v-model="authName"
              class="mt-1 p-2 border border-gray-300 rounded-md"
              placeholder="Please enter your name"
          >
          <p class="text-xs text-gray-500 mt-1">
            First time? Use Register. Otherwise Login directly.
          </p>
        </div>

        <div class="grid grid-cols-2 gap-2">
          <button
              class="w-full py-2 px-4 rounded-md text-white bg-indigo-600 hover:bg-indigo-700 transition"
              @click="register"
              type="button"
          >
            Register
          </button>
          <button
              class="w-full py-2 px-4 rounded-md text-white bg-gray-800 hover:bg-gray-900 transition"
              @click="login"
              type="button"
          >
            Login
          </button>
        </div>
      </form>
      <p :class="{'text-green-600': authMessage.includes('Successfully'), 'text-red-600': !authMessage.includes('Successfully')}" class="mt-3 text-sm font-medium">
        {{ authMessage }}
      </p>
    </div>

    <!-- 建立行程表單 (已認證時顯示) -->
    <div v-else class="bg-white p-6 rounded-xl shadow-lg border border-gray-200">
      <h2 class="text-xl font-semibold mb-4 text-gray-800 border-b pb-2">Create new trip</h2>

      <form @submit.prevent="createItinerary" class="space-y-4">
        <div class="flex flex-col">
          <label for="createTitle" class="text-sm font-medium text-gray-700">Title:</label>
          <input type="text" id="createTitle" v-model="createTitle" required class="mt-1 p-2 border border-gray-300 rounded-md">
        </div>
        <div class="flex flex-col">
          <label for="createDestination" class="text-sm font-medium text-gray-700">Destination:</label>
          <input type="text" id="createDestination" v-model="createDestination" required class="mt-1 p-2 border border-gray-300 rounded-md">
        </div>
        <div class="flex flex-col">
          <label for="createStartDate" class="text-sm font-medium text-gray-700">Starting Date:</label>
          <input type="date" id="createStartDate" v-model="createStartDate" required class="mt-1 p-2 border border-gray-300 rounded-md">
        </div>
        <div class="flex flex-col">
          <label for="createEndDate" class="text-sm font-medium text-gray-700">Ending Date:</label>
          <input type="date" id="createEndDate" v-model="createEndDate" required class="mt-1 p-2 border border-gray-300 rounded-md">
        </div>
        <div class="flex flex-col">
          <label for="createShortDesc" class="text-sm font-medium text-gray-700">Short Description:</label>
          <input type="text" id="createShortDesc" v-model="createShortDesc" maxlength="80" required class="mt-1 p-2 border border-gray-300 rounded-md">
        </div>
        <div class="flex flex-col">
          <label for="createDetailDesc" class="text-sm font-medium text-gray-700">Long Description:</label>
          <textarea id="createDetailDesc" v-model="createDetailDesc" rows="3" class="mt-1 p-2 border border-gray-300 rounded-md"></textarea>
        </div>

        <button
            class="w-full py-2 px-4 rounded-md text-white bg-green-600 hover:bg-green-700 transition"
            type="submit"
        >Create
        </button>
      </form>
      <p :class="{'text-green-600': createMessage.includes('Successfully'), 'text-red-600': !createMessage.includes('Successfully')}" class="mt-3 text-sm font-medium">
        {{ createMessage }}
      </p>
    </div>
  </div>
</template>