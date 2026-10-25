// ============================================================
// FIKAGO - GOOGLE MAPS SERVICE
// Calculate distance na duration kati ya points 2
// ============================================================
const axios = require('axios');

const GOOGLE_API_KEY = process.env.GOOGLE_MAPS_API_KEY;
const DISTANCE_MATRIX_URL = 'https://maps.googleapis.com/maps/api/distancematrix/json';

const calculateDistance = async (origin, destination) => {
  try {
    // Kama API key haipo, tumia fallback (haversine)
    if (!GOOGLE_API_KEY || GOOGLE_API_KEY === 'your_google_maps_key_here') {
      return calculateHaversine(origin, destination);
    }

    const response = await axios.get(DISTANCE_MATRIX_URL, {
      params: {
        origins: `${origin.lat},${origin.lng}`,
        destinations: `${destination.lat},${destination.lng}`,
        mode: 'driving',
        units: 'metric',
        key: GOOGLE_API_KEY,
      },
    });

    const data = response.data;

    if (data.status !== 'OK') {
      return calculateHaversine(origin, destination);
    }

    const element = data.rows[0].elements[0];

    if (element.status !== 'OK') {
      return calculateHaversine(origin, destination);
    }

    return {
      distance_meters: element.distance.value,
      distance_km: parseFloat((element.distance.value / 1000).toFixed(2)),
      distance_text: element.distance.text,
      duration_seconds: element.duration.value,
      duration_min: Math.ceil(element.duration.value / 60),
      duration_text: element.duration.text,
    };
  } catch (error) {
    console.error('Google Maps error:', error.message);
    return calculateHaversine(origin, destination);
  }
};

// Fallback: Haversine formula
const calculateHaversine = (origin, destination) => {
  const R = 6371;
  const dLat = (destination.lat - origin.lat) * Math.PI / 180;
  const dLon = (destination.lng - origin.lng) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(origin.lat * Math.PI / 180) *
      Math.cos(destination.lat * Math.PI / 180) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c;

  return {
    distance_km: parseFloat(distance.toFixed(2)),
    distance_text: `${distance.toFixed(2)} km`,
    duration_min: Math.ceil(distance * 3), // Assume 20 km/h average
    duration_text: `~${Math.ceil(distance * 3)} min`,
  };
};

// Calculate delivery fee based on distance
const calculateDeliveryFee = (distanceKm) => {
  let fee = 0;

  if (distanceKm <= 2) {
    fee = 2000;
  } else if (distanceKm <= 5) {
    fee = 2000 + (distanceKm - 2) * 500;
  } else if (distanceKm <= 10) {
    fee = 3500 + (distanceKm - 5) * 400;
  } else {
    fee = 5500 + (distanceKm - 10) * 300;
  }

  return Math.round(fee / 100) * 100;
};

module.exports = { calculateDistance, calculateDeliveryFee };
