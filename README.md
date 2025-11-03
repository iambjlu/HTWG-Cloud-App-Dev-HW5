
# HTWG-Cloud-App-HW5

We want to improve the application and use infrastructure as code to deploy the application to the cloud VM.
Create a load test which triggers scaling behaviour of your application. Test the Scenarios "Periodic Workload" and "Once-in-a-lifetime Workload".
Document the load balacing parameters, the test execution and the server load in a test protocol.

* Create terraform project for automated deployment
* Check terraform files into version control
* Create script to fill application with initial data
* Create load test scripts for the following scenarios
* Periodic workload
* Once-in-a-lifetime Workload
* Create test report summarizing your findings

---

# Cloud Foundations Mid-term Milestone

### Functional Requirements:
The application provides a WebUI and REST API for the following User-Stories:
* As a traveller I can register to the site and create a profile.
* As a traveller I can create a travel plan which shows transport and accomodation for a trip such that
I can view it later.
* As a traveller I can view my travel plan such that I have an overview over my travel arrangement.
* As a traveller I can add locations to a travel plan.
* As a traveller I can upload a profile image to my account.
* As a guest or traveller I can search for itineraries of other travellers.
* As a traveller I can like and comment the trip of another traveller
Acceptance criteria for the user stories can be found in the exercises 1-4.
### Technical Requirements :
* The application runs on a standard cloud platform.
* Deployment of application to IaaS is automated based on terraform
* Deployment of application to PaaS is automated based on terraform
* There are performance testing scripts and a test report proofing the limits of the application for IaaS
and PaaS
* The application implements a multi-user service with authentication and authorization.
using a standard identity server.

<hr />


# HTWG-Cloud-App-HW5

我們希望改進這個應用程式，並使用「基礎設施即程式碼（Infrastructure as Code）」的方式，將應用程式部署到雲端虛擬機（VM）上。  
請建立負載測試（load test），以觸發應用程式的自動擴展行為（scaling behavior）。  
測試兩種情境：「**週期性工作負載（Periodic Workload）**」與「**一次性高峰負載（Once-in-a-lifetime Workload）**」。  
請在測試報告中紀錄負載平衡參數（load balancing parameters）、測試執行情形，以及伺服器負載情況。

---

## 任務要求

* 建立一個 Terraform 專案，用於自動化部署。  
* 將 Terraform 檔案提交至版本控制系統（Version Control）。  
* 撰寫腳本，用於在應用程式中填入初始資料。  
* 為以下情境建立負載測試腳本：  
  * 週期性工作負載（Periodic Workload）  
  * 一次性高峰負載（Once-in-a-lifetime Workload）  
* 撰寫測試報告，總結測試結果與觀察。


---

# Cloud Foundations Mid-term Milestone

### Functional Requirements

本應用程式提供一個 Web UI 與 REST API，以支援以下使用者故事（User Stories）：

- 作為一名旅客（Traveller），我可以註冊帳號並建立個人資料。
- 作為一名旅客，我可以建立旅遊計畫（Travel Plan），其中包含交通與住宿資訊，方便日後查看。
- 作為一名旅客，我可以檢視我的旅遊計畫，以便掌握整體行程安排。
- 作為一名旅客，我可以在旅遊計畫中新增地點。
- 作為一名旅客，我可以上傳個人頭像至我的帳戶。
- 作為訪客（Guest）或旅客，我可以搜尋其他旅客的行程。
- 作為一名旅客，我可以對其他旅客的行程按讚或留言。

各使用者故事的驗收準則（Acceptance Criteria）可參見作業練習 1–4。

---

### Technical Requirements

- 應用程式需可運行於標準雲端平台上。  
- 應用程式部署至 IaaS（基礎設施即服務）需透過 **Terraform** 自動化完成。  
- 應用程式部署至 PaaS（平台即服務）亦需透過 **Terraform** 自動化完成。  
- 需具備效能測試腳本與測試報告，以驗證應用程式在 IaaS 與 PaaS 環境下的性能極限。  
- 應用程式需實作多使用者服務，並具備認證（Authentication）與授權（Authorization）功能，  
  使用標準的身份伺服器（Identity Server）進行管理。
