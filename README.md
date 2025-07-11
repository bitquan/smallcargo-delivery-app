# SmallCargo - Delivery Management System

A comprehensive Flutter-based delivery management system with real-time tracking, customer/driver/admin dashboards, and advanced features.

## 🚀 Getting Started with GitHub Codespaces

### Option 1: Use this Repository (Recommended)
1. **Fork this repository** to your GitHub account
2. **Open in Codespaces**:
   - Go to your forked repository on GitHub
   - Click the green "Code" button
   - Select "Codespaces" tab
   - Click "Create codespace on main"

### Option 2: Create New Repository
1. **Create a new repository** on GitHub
2. **Upload this code**:
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
   git add .
   git commit -m "Initial commit: Flutter delivery management system"
   git push -u origin main
   ```
3. **Enable Codespaces** in your repository settings

### � Mobile Development Tips
- Codespaces works great on mobile browsers
- Use the GitHub mobile app for quick access
- Consider VS Code mobile app for better experience
- Web version runs perfectly in Codespaces
- **Estimated delivery time** with dynamic updates
- **Professional status indicators** with color coding

#### **🚚 Driver Information Display**
- **Driver details** with avatar and ID
- **Live speed tracking** (mph display)
- **ETA calculations** based on real-time location
- **Online/offline status** indicators

#### **📱 Interactive Features**
- **Call Driver** button with phone integration
- **Center Map** button for easy navigation
- **Zoom controls** and map type selection
- **Responsive design** for all screen sizes

#### **🔄 Real-Time Updates**
- **2-second location refresh** rate
- **Smooth driver movement** simulation
- **Dynamic ETA recalculation**
- **Live polyline route updates**

### **🎮 How to Test the Tracking:**

1. **Launch the app** and log in (use Quick Admin Login)
2. **Navigate to the Tracking tab** (3rd icon in bottom navigation)
3. **Watch the driver move** along the route in real-time
4. **Try the "Center Map" button** to follow the driver
5. **See the ETA update** as the driver progresses
6. **Check the speed display** in the driver info card

---

## Features

- **User Authentication**: Secure sign-in/sign-up with Firebase Auth
- **Order Management**: Create, track, and manage cargo orders
- **Distance-Based Pricing**: Automatic pricing calculation based on pickup/delivery addresses
- **Real-time Tracking**: Live tracking with Google Maps integration
- **Multi-role Support**: Customer, Driver, and Admin roles
- **Responsive Design**: Works on web, mobile, and tablet
- **Firebase Integration**: Firestore database and cloud storage

## Distance-Based Pricing

The app automatically calculates shipping costs based on:
- **Distance**: $1.00 per mile between pickup and delivery addresses
- **Estimated Time**: $0.15 per minute of travel time
- **Base Fee**: $5.00 for any delivery
- **Loading Service**: $10.00 base + $0.25 per pound (weight-based)
- **Unloading Service**: $10.00 base + $0.25 per pound (weight-based)
- **Weight**: $0.50 per pound for all items combined
- **Priority Level**: 
  - Low: 20% discount
  - Medium: Standard rate
  - High: 30% premium
  - Urgent: 80% premium
- **Time of Day**: Peak hours (rush hour) and late hours adjustments

## Multi-Item Support

- **Add Multiple Items**: Users can add multiple items to a single shipment
- **Individual Item Details**: Each item can have its own description, weight, dimensions, and special instructions
- **Photo Support**: Multiple photos can be added for each item (coming soon)
- **Weight-Based Pricing**: Loading and unloading fees are calculated based on total weight
- **Combined Shipping**: All items are shipped together with optimized pricing

The pricing is calculated using Google Maps Distance Matrix API for accurate distance and time estimates.

## Setup

1. **Prerequisites**:
   - Flutter SDK (latest stable)
   - Firebase project setup
   - Google Maps API key

2. **Installation**:
   ```bash
   git clone <repository-url>
   cd small_cargo
   flutter pub get
   ```

3. **Firebase Configuration**:
   - The project is pre-configured with Firebase
   - API keys and configuration are already set up
   - Firebase project ID: `small-cargo-t`

4. **Running the App**:
   ```bash
   # Development
   flutter run -d chrome
   
   # Production build
   flutter build web --release
   
   # Deploy to Firebase
   firebase deploy --only hosting
   ```

## Project Structure

```
lib/
├── config/           # App configuration
├── core/            # Core utilities, themes, constants
├── models/          # Data models (User, Order, etc.)
├── services/        # Firebase services (Auth, Database)
├── screens/         # UI screens
│   ├── auth/        # Authentication screens
│   ├── home/        # Home and dashboard
│   └── ...
├── widgets/         # Reusable widgets
└── main.dart        # App entry point
```

## Configuration

The app is pre-configured with:
- Firebase Project ID: `small-cargo-t`
- Google Maps API Key: `AIzaSyBirnBdv4bAiKjJCu1i_uKam7VmWFzD90o`
- Firebase API Key: `AIzaSyAXrXpxeVG2tUBhgp-1bTr3dOVsHRD7Awk`

## Build & Deploy

```bash
# Clean build
flutter clean
flutter pub get

# Build for web
flutter build web --release

# Deploy to Firebase
firebase deploy --only hosting
```

## Live Demo

The app is deployed at: `https://small-cargo-t.web.app`

## Support

For issues and questions, please check the documentation or create an issue in the repository.
