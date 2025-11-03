<script setup>
// --- 這整個 SCRIPT 區塊完全沒動 ---
import { ref, computed, onMounted, watch } from 'vue';
import axios from 'axios';
import { auth } from './firebase';
import { onAuthStateChanged, onIdTokenChanged, signOut } from 'firebase/auth';

const isLoading = ref(false);

(async () => {
  const u = auth.currentUser;
  if (u) {
    const t = await u.getIdToken();
    axios.defaults.headers.common['Authorization'] = `Bearer ${t}`;
  }
})();

onIdTokenChanged(auth, async (user) => {
  if (user) {
    const t = await user.getIdToken(/* forceRefresh */ true);
    axios.defaults.headers.common['Authorization'] = `Bearer ${t}`;
  } else {
    delete axios.defaults.headers.common['Authorization'];
  }
});

axios.interceptors.request.use(
    (config) => {
      isLoading.value = true;
      return config;
    },
    (error) => {
      isLoading.value = false;
      return Promise.reject(error);
    }
);

axios.interceptors.response.use(
    (response) => {
      isLoading.value = false;
      return response;
    },
    (error) => {
      isLoading.value = false;
      return Promise.reject(error);
    }
);

import AuthAndCreate from './components/AuthAndCreate.vue';
import ItineraryManager from './components/ItineraryManager.vue';
import ProfileCard from './components/ProfileCard.vue';

const isAuthenticated = ref(false);
const userEmail = ref(null);
const refreshKey = ref(0);
const viewEmail = ref(null);

async function applyAuthHeader(user) {
  if (!user) {
    delete axios.defaults.headers.common['Authorization'];
    return;
  }
  const token = await user.getIdToken();
  axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
}

function syncViewEmailFromURL() {
  const params = new URLSearchParams(window.location.search);
  const qEmail = params.get('profile');

  if (qEmail && qEmail.includes('@')) {
    viewEmail.value = qEmail;
  } else {
    viewEmail.value = userEmail.value;
  }
}

function goHome() {
  window.location.href = '/';
}

function handleItineraryUpdate() {
  refreshKey.value++;
}

async function handleLogout() {
  await signOut(auth);
}

const effectiveEmail = computed(() => viewEmail.value || userEmail.value || '');

const isViewingSomeoneElse = computed(() => {
  return (
      userEmail.value &&
      effectiveEmail.value &&
      userEmail.value !== effectiveEmail.value
  );
});

function handleNoData() {
  if (isViewingSomeoneElse.value) {
    alert("This user has no trips or does not exist. Returning to homepage.");
    window.location.href = "/";
  }
}

onMounted(() => {
  onAuthStateChanged(auth, async (user) => {
    if (user) {
      isAuthenticated.value = true;
      userEmail.value = user.email || null;
      await applyAuthHeader(user);
      localStorage.setItem('tripplanner_userEmail', userEmail.value || '');
    } else {
      isAuthenticated.value = false;
      userEmail.value = null;
      await applyAuthHeader(null);
      localStorage.removeItem('tripplanner_userEmail');
    }
    syncViewEmailFromURL();
  });

  syncViewEmailFromURL();
});

watch(userEmail, () => {
  const params = new URLSearchParams(window.location.search);
  const qEmail = params.get('profile');
  if (!qEmail) {
    viewEmail.value = userEmail.value;
  }
});
</script>

<template>
  <div v-if="isLoading" class="loading-overlay"></div>

  <div class="min-h-screen bg-gray-100 p-1 md:p-2">

    <header class="bg-indigo-600 text-white p-2 rounded-lg shadow-lg mb-4 flex justify-between items-center sticky top-1 md:top-2 z-50">

      <h1 class="text-2xl font-bold flex items-center space-x-2 ">
        <strong><span><a href="/" style="color:white">DragonFlyX</a></span></strong>
        <span
            v-if="isAuthenticated && isViewingSomeoneElse"
            class="text-xs font-normal bg-white/20 rounded px-2 py-0.5"
        >
          viewing {{ effectiveEmail }}
        </span>
      </h1>
      <div v-if="userEmail" class="flex items-center space-x-3">
        <p class="text-sm">{{ userEmail }}</p>
        <button
            @click="handleLogout"
            class="py-1 px-3 bg-red-400 text-white text-sm font-semibold rounded-md hover:bg-red-500 transition shadow-sm"
        >
          Logout
        </button>
      </div>
    </header>

    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 max-w-7xl mx-auto">

      <div v-if="!isAuthenticated" class="lg:col-span-12">
        <div class="lg:col-span-12 space-y-6">
          <div class="bg-white p-6 rounded-xl shadow-lg border border-gray-200">
            <h2 class="text-2xl font-bold mb-1 text-gray-800 text-center">🐲 DragonFlyX 🚁</h2>
            <div class="space-y-1 text-gray-700"><p><strong>The Trip Planner.</strong></p></div><br>
            <div class="space-y-1 text-gray-700 text-center md:text-left">
              <p><strong>Team name:</strong> <span class="text-indigo-600">Kenting 🏖️</span></p>
              <p><strong>Team member:</strong> Po-Chun Lu</p>
              <p><strong>Professor:</strong> Dr. Markus Eilsperger</p>
            </div>
          </div>
          <AuthAndCreate />
        </div>
      </div>

      <template v-else>
        <div class="lg:col-span-5 space-y-6">
          <div class="bg-white p-4 rounded-xl shadow-lg border border-gray-200">
            <h2 class="text-2xl font-bold mb-1 text-gray-800 text-center">🐲 DragonFlyX 🚁</h2>
            <div class="space-y-1 text-gray-700"><p><strong>The Trip Planner.</strong></p></div><br>
            <div class="space-y-1 text-gray-700 text-center md:text-left">
              <p><strong>Team name:</strong> <span class="text-indigo-600">Kenting 🏖️</span></p>
              <p><strong>Team member:</strong> Po-Chun Lu</p>
              <p><strong>Professor:</strong> Dr. Markus Eilsperger</p>
            </div>
          </div>
          <AuthAndCreate
              v-if="!isViewingSomeoneElse"
              :userEmail="userEmail"
              :isAuthenticated="isAuthenticated"
              @itinerary-updated="handleItineraryUpdate"
          />
          <div
              v-else
              class="bg-yellow-50 text-yellow-800 text-sm rounded-xl border border-yellow-300 shadow p-6"
          >
            <p class="font-semibold text-yellow-700 text-center">
              Viewing {{ effectiveEmail }}'s trips
            </p>
            <button
                class="mt-4 w-full py-2 px-4 bg-yellow-400 text-black font-semibold rounded-md hover:bg-yellow-500 transition shadow-sm"
                @click="goHome"
            >
              Go to Homepage
            </button>
          </div>
        </div>
        <div class="lg:col-span-7 space-y-4">
          <ProfileCard
              :userEmail="effectiveEmail"
              :currentUserEmail="userEmail"
          />
          <ItineraryManager
              :travellerEmail="effectiveEmail"
              :currentUserEmail="userEmail"
              :refreshSignal="refreshKey"
              @no-data="handleNoData"
          />
        </div>
      </template>
    </div></div></template>

<style scoped>
/* --- 這整個 STYLE 區塊完全沒動 --- */
.loading-overlay {
  position: fixed;
  inset: 0;
  background-color: rgba(255, 255, 255, 0);
  z-index: 9999;
  cursor: wait;
}
</style>