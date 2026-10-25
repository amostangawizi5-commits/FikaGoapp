// ============================================================
// FIKAGO - SMS SERVICE (Mock for now)
// ============================================================

const sendSMS = async (phoneNumber, message) => {
  try {
    console.log('');
    console.log('════════════════════════════════════════════');
    console.log('📱 SMS MOCK');
    console.log('════════════════════════════════════════════');
    console.log(`📞 Kwa: ${phoneNumber}`);
    console.log(`💬 Ujumbe: ${message}`);
    console.log('════════════════════════════════════════════');
    console.log('');
    return { success: true };
  } catch (error) {
    console.error('❌ SMS Error:', error.message);
    return { success: false, error: error.message };
  }
};

module.exports = { sendSMS };
