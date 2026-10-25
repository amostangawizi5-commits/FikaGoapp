// ============================================================
// FIKAGO - SELCOM PAYMENT SERVICE (Mock)
// TODO: Integrate real Selcom API
// ============================================================

const initiatePayment = async ({ orderId, amount, phone, method }) => {
  try {
    // MOCK: Kwa sasa, tunarudisha transaction ref ya kubuni
    const transactionRef = `SELCOM-${Date.now()}-${Math.floor(Math.random() * 10000)}`;

    console.log('');
    console.log('════════════════════════════════════════════');
    console.log('💳 SELCOM PAYMENT MOCK');
    console.log('════════════════════════════════════════════');
    console.log(`📦 Order: ${orderId}`);
    console.log(`💰 Amount: TZS ${amount}`);
    console.log(`📱 Phone: ${phone}`);
    console.log(`💳 Method: ${method}`);
    console.log(`🔖 Ref: ${transactionRef}`);
    console.log('════════════════════════════════════════════');
    console.log('');

    return {
      success: true,
      transaction_ref: transactionRef,
      status: 'pending',
      message: 'Payment initiated (mock)',
    };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

const verifyPayment = async (transactionRef) => {
  // MOCK: Assume payment always succeeds
  return { success: true, status: 'success', transaction_ref: transactionRef };
};

module.exports = { initiatePayment, verifyPayment };
