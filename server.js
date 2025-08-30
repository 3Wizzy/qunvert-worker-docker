const app = require('./src/app')
const { baseWebhookURL } = require('./src/config')
require('dotenv').config()

// Start the server
const port = process.env.PORT || 3000

// Check if BASE_WEBHOOK_URL environment variable is available
if (!baseWebhookURL) {
  console.error('BASE_WEBHOOK_URL environment variable is not available. Exiting...')
  process.exit(1) // Terminate the application with an error code
}

  //SELF REGISTER
const registerWorker = async () => {
  console.log('\n2️⃣ Registering worker with manager...');
  try {
    const axios = require('axios');
    const body = {
      workerId: process.env.WORKER_ID,
      url: `${process.env.WORKER_URL}`,
      maxSessions: parseInt(process.env.MAX_SESSIONS) || 10
    }
    console.log('Registering worker with manager...', body)
    await axios.post(`${process.env.WHATSAPP_MANAGER_URL}/workers/register`, body, { timeout: 10000 });
    console.log('✅ Worker registered successfully!');
  } catch (error) {
      console.log('⚠️ Worker registration will retry automatically:', error);
  }
}


registerWorker()


app.listen(port, () => {
  console.log(`Server running on port ${port}`)
})
