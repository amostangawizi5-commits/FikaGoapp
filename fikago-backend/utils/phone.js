// Keep Tanzanian phone numbers in E.164 format throughout the API.
const normalizeTzPhone = (value) => {
  if (typeof value !== 'string' && typeof value !== 'number') return null;

  let digits = String(value).replace(/\D/g, '');
  if (digits.startsWith('255')) digits = digits.slice(3);
  else if (digits.startsWith('0')) digits = digits.slice(1);

  if (!/^[0-9]{9}$/.test(digits)) return null;
  return `+255${digits}`;
};

const phoneCandidates = (value) => {
  const normalized = normalizeTzPhone(value);
  if (!normalized) return [];
  const national = normalized.slice(4);
  return [normalized, national, `0${national}`];
};

const normalizePhoneFields = (value) => {
  if (Array.isArray(value)) return value.map(normalizePhoneFields);
  if (!value || typeof value !== 'object') return value;

  return Object.fromEntries(Object.entries(value).map(([key, item]) => {
    if (/(^|_)phone(_number)?$/i.test(key) || /phone$/i.test(key)) {
      return [key, normalizeTzPhone(item) || item];
    }
    return [key, normalizePhoneFields(item)];
  }));
};

module.exports = { normalizeTzPhone, phoneCandidates, normalizePhoneFields };
