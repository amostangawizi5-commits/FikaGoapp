// ============================================================
// FIKAGO - ORDER NUMBER GENERATOR
// Format: FK-YYYYMMDD-XXXX (e.g., FK-20260115-0001)
// ============================================================

const generateOrderNumber = async (pool) => {
  const today = new Date();
  const dateStr = today.toISOString().slice(0, 10).replace(/-/g, '');
  
  // Pata idadi ya orders za leo
  const result = await pool.query(
    `SELECT COUNT(*) FROM orders WHERE order_number LIKE $1`,
    [`FK-${dateStr}-%`]
  );
  
  const count = parseInt(result.rows[0].count) + 1;
  const paddedCount = String(count).padStart(4, '0');
  
  return `FK-${dateStr}-${paddedCount}`;
};

module.exports = { generateOrderNumber };
