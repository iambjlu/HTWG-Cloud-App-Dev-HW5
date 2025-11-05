# locustfile.py

#before run:
# pip install locust
# export FIREBASE_API_KEY="your_firebase_web_api_key"
# locust -f main.py -H <host>

import os
import random
import string
import logging
from datetime import datetime, timedelta

from locust import HttpUser, task, between, events

logging.basicConfig(level=logging.INFO)

FIREBASE_API_KEY = os.getenv("FIREBASE_API_KEY")  # 必填：Firebase Web API Key
NAME_PREFIX = os.getenv("NAME_PREFIX", "LocustUser")
DOMAINS = os.getenv("EMAIL_DOMAIN", "example.com")  # 測試網域
# 目的地字串池
DESTS = [
    "Tokyo", "Seoul", "Osaka", "Kyoto", "Taipei", "Hualien", "Tainan",
    "Hong Kong", "Bangkok", "Singapore", "Bali", "Sydney", "Melbourne",
    "Paris", "London", "Berlin", "Munich", "Prague", "Vienna", "Zurich",
]
TITLES = ["Weekend Escape", "City Walk", "Foodie Trip", "Museum Run", "Beach Chill", "Mountain Hike"]
SHORTS = [
    "Quick getaway", "Local eats only", "Art & culture first",
    "Budget friendly", "Café hopping", "Night market sprint",
]

def rand_email():
    suffix = "".join(random.choices(string.ascii_lowercase + string.digits, k=8))
    return f"{NAME_PREFIX.lower()}_{suffix}@{DOMAINS}"

def rand_password():
    return "".join(random.choices(string.ascii_letters + string.digits, k=12))

def rand_dates():
    start_offset = random.randint(1, 120)             # 1~120 天後出發
    stay_len = random.randint(3, 10)                   # 3~10 天
    start_date = (datetime.utcnow() + timedelta(days=start_offset)).strftime("%Y-%m-%d")
    end_date = (datetime.utcnow() + timedelta(days=start_offset + stay_len)).strftime("%Y-%m-%d")
    return start_date, end_date

def itinerary_payload():
    start_date, end_date = rand_dates()
    title = random.choice(TITLES)
    dest = random.choice(DESTS)
    short = random.choice(SHORTS)
    # 確保 short_description ≤ 80
    short = short[:80]
    detail = (
        f"Auto gen itinerary for {dest}. Includes food, sights, local transit tips. "
        f"Seed={random.randint(1000, 9999)}"
    )
    return {
        "title": f"{title} - {dest}",
        "destination": dest,
        "start_date": start_date,    # 後端用 MySQL DATE，'YYYY-MM-DD' OK
        "end_date": end_date,
        "short_description": short,
        "detail_description": detail,
    }

class TravelUser(HttpUser):
    """
    流程：
      on_start:
        1) Firebase signUp（或 signIn）→ idToken
        2) POST /api/travellers/ensure 建立/確保旅客
      tasks:
        - POST /api/itineraries 建立隨機行程
        - GET /api/itineraries/by-email/:email （公用）
        - GET /api/itineraries/detail/:id （公用，從前一步取一些 id 測試）
        - GET /api/itineraries/:id/ai （公用，可能會 404 視背景任務）
    """
    wait_time = between(1, 3)

    # 使用者態（每個 Locust user 各自的帳密、token）
    email = None
    password = None
    id_token = None
    auth_headers = None
    last_created_ids = []

    # ---- Firebase Auth ----
    def firebase_signup_or_login(self):
        """
        先 signUp；若已存在則 fallback signInWithPassword
        """
        if not FIREBASE_API_KEY:
            raise RuntimeError("FIREBASE_API_KEY 未設定，請在環境變數提供 Firebase Web API Key")

        base = "https://identitytoolkit.googleapis.com/v1"
        sign_up_url = f"{base}/accounts:signUp?key={FIREBASE_API_KEY}"
        sign_in_url = f"{base}/accounts:signInWithPassword?key={FIREBASE_API_KEY}"
        payload = {
            "email": self.email,
            "password": self.password,
            "returnSecureToken": True
        }

        # 先 signUp
        with self.client.post(sign_up_url, json=payload, name="firebase_signUp", catch_response=True) as resp:
            if resp.status_code == 200:
                data = resp.json()
                self.id_token = data.get("idToken")
                resp.success()
                return

            # 若帳號已存在則改 signIn
            if resp.status_code in (400, 409):
                # 改走 signIn
                with self.client.post(sign_in_url, json=payload, name="firebase_signIn", catch_response=True) as r2:
                    if r2.status_code == 200:
                        data = r2.json()
                        self.id_token = data.get("idToken")
                        r2.success()
                        return
                    else:
                        r2.failure(f"Firebase signIn failed: {r2.status_code} {r2.text}")
                        raise RuntimeError("Firebase login failed")
            else:
                resp.failure(f"Firebase signUp failed: {resp.status_code} {resp.text}")
                raise RuntimeError("Firebase signUp failed")

    def ensure_traveller(self):
        name = f"{NAME_PREFIX}-{random.randint(1000, 9999)}"
        with self.client.post(
            "/api/travellers/ensure",
            json={"name": name},
            headers=self.auth_headers,
            name="/api/travellers/ensure",
            catch_response=True,
        ) as resp:
            if resp.status_code in (200, 201):
                resp.success()
            else:
                resp.failure(f"ensure traveller failed: {resp.status_code} {resp.text}")

    # ---- Locust lifecycle ----
    def on_start(self):
        # 為每個虛擬使用者產生帳密
        self.email = rand_email()
        self.password = rand_password()

        # 1) Firebase 取得 idToken
        self.firebase_signup_or_login()
        self.auth_headers = {
            "Authorization": f"Bearer {self.id_token}",
            "Content-Type": "application/json",
        }

        # 2) 旅客 ensure
        self.ensure_traveller()

    # ---- Tasks ----
    @task(4)
    def create_random_itinerary(self):
        payload = itinerary_payload()
        with self.client.post(
            "/api/itineraries",
            json=payload,
            headers=self.auth_headers,
            name="/api/itineraries (create)",
            catch_response=True,
        ) as resp:
            if resp.status_code == 201:
                data = resp.json()
                itinerary_id = data.get("id")
                if itinerary_id:
                    self.last_created_ids.append(itinerary_id)
                resp.success()
            else:
                resp.failure(f"create itinerary failed: {resp.status_code} {resp.text}")

    @task(1)
    def list_my_itineraries(self):
        # 這個 API 是 public，但 server 目前 SQL 沒用到 email 變數（仍可測吞吐）
        self.client.get(
            f"/api/itineraries/by-email/{self.email}",
            name="/api/itineraries/by-email/:email",
        )

    @task(1)
    def get_some_detail(self):
        if not self.last_created_ids:
            return
        itinerary_id = random.choice(self.last_created_ids)
        self.client.get(
            f"/api/itineraries/detail/{itinerary_id}",
            name="/api/itineraries/detail/:id",
        )

    @task(1)
    def maybe_read_ai_suggestion(self):
        if not self.last_created_ids:
            return
        itinerary_id = random.choice(self.last_created_ids)
        self.client.get(
            f"/api/itineraries/{itinerary_id}/ai",
            name="/api/itineraries/:id/ai",
        )
