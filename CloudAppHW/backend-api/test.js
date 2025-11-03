// test_gemini.js
require('dotenv').config();
const { GoogleGenerativeAI } = require('@google/generative-ai');

async function runTest() {
    console.log('--- 開始 Gemini 最小測試 ---');

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
        console.error('❌ 錯誤：找不到 .env 檔案中的 GEMINI_API_KEY');
        return;
    }
    console.log('✅ 成功讀取 GEMINI_API_KEY');

    try {
        const genAI = new GoogleGenerativeAI(apiKey);
        const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' }); // 用一個常見的 model 測試

        console.log('🔄 正在呼叫 Gemini API (generateContent)...');

        const prompt = 'Hello, this is a connectivity test.';
        const result = await model.generateContent(prompt);

        const text = result.response.text();
        console.log('--- 測試結果 ---');
        console.log(text);
        console.log('✅✅✅ 測試成功！Node.js 可以連線。');

    } catch (err) {
        console.error('--- 測試失敗 ---');
        console.error('❌ 捕捉到錯誤：', err); // 把完整的錯誤物件印出來
    }
}

runTest();