// Test different locations for emulator
const testLocations = [
  {
    name: "Raipur, Chhattisgarh",
    lat: 21.2787,
    lng: 81.8661
  },
  {
    name: "Delhi, India", 
    lat: 28.6139,
    lng: 77.2090
  },
  {
    name: "Mumbai, India",
    lat: 19.0760,
    lng: 72.8777
  },
  {
    name: "Bangalore, India",
    lat: 12.9716,
    lng: 77.5946
  }
];

console.log("🗺️ Test Locations for Emulator:");
console.log("================================");

testLocations.forEach((loc, index) => {
  console.log(`${index + 1}. ${loc.name}`);
  console.log(`   Lat: ${loc.lat}`);
  console.log(`   Lng: ${loc.lng}`);
  console.log(`   Set in Emulator: Extended Controls > Location`);
  console.log("");
});

console.log("📱 STEPS TO TEST:");
console.log("1. Open Emulator Extended Controls (Ctrl+Shift+K)");
console.log("2. Go to Location tab");
console.log("3. Enter coordinates manually");
console.log("4. Click 'Send Location'");
console.log("5. Watch location update in app!");