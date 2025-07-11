# SmallCargo Delivery App - Setup Guide

## 🚀 Complete Setup Instructions for Your Computer

### Prerequisites
Before setting up the project, ensure you have:

1. **Flutter SDK** (3.32.6 or later)
   ```bash
   flutter --version
   ```

2. **Git** installed
   ```bash
   git --version
   ```

3. **VS Code** with Flutter/Dart extensions
   - Flutter extension
   - Dart extension

4. **Web Browser** (Chrome recommended for development)

### 📦 Getting the Project

#### Option 1: Clone from GitHub (Recommended)
```bash
# Clone the repository
git clone https://github.com/bitquan/smallcargo-delivery-app.git
cd smallcargo-delivery-app

# Install dependencies
flutter pub get

# Run the app
flutter run -d chrome
```

#### Option 2: Download ZIP
1. Download the project ZIP file
2. Extract to your desired location
3. Open terminal in the project folder
4. Run setup commands:
   ```bash
   flutter pub get
   flutter run -d chrome
   ```

### 🛠️ Project Structure

```
smallcargo-delivery-app/
├── lib/
│   ├── core/
│   │   ├── design_system/          # Golden gradient design system
│   │   └── constants/              # App constants and themes
│   ├── models/                     # Data models (Order, User, PackageItem)
│   ├── screens/                    # All app screens
│   │   ├── admin/                  # Admin dashboard with pricing controls
│   │   ├── auth/                   # Authentication screens
│   │   ├── customer/               # Customer-specific screens
│   │   ├── driver/                 # Driver-specific screens
│   │   ├── orders/                 # Order management screens
│   │   └── tracking/               # Real-time tracking screens
│   ├── services/                   # Business logic services
│   │   ├── pricing_service.dart    # Advanced pricing calculations
│   │   ├── auth_service.dart       # Authentication service
│   │   ├── database_service.dart   # Database operations
│   │   └── location_service.dart   # GPS and location services
│   └── widgets/                    # Reusable UI components
├── assets/                         # Images, icons, and other assets
├── web/                           # Web-specific files
└── firebase configuration files
```

### 🎯 Key Features Implemented

#### ✅ Complete Business Logic
- **PricingService**: Sophisticated pricing with US units (miles/pounds)
- **Real-time Calculations**: Distance-based pricing with priority multipliers
- **Admin Controls**: Full pricing management from admin dashboard
- **Service Options**: Insurance, tracking, express delivery, fragile handling

#### ✅ Professional UI/UX
- **AppDesignSystem**: Golden gradient theme throughout
- **Responsive Design**: Works on web, mobile, and desktop
- **Animated Components**: Smooth transitions and loading states
- **Form Validation**: Comprehensive input validation

#### ✅ Screen Connectivity
- **Create Order**: Real-time pricing with PricingService integration
- **Admin Dashboard**: 6-tab interface with pricing management
- **Tracking Screen**: Google Maps integration with animations
- **User Management**: Complete authentication flow

### 🔧 Configuration Files

#### pubspec.yaml
All dependencies are properly configured:
- Flutter SDK: 3.32.6
- Provider for state management
- Firebase for backend services
- Google Maps for tracking
- Image handling packages

#### Firebase Setup
Firebase is configured but you'll need to:
1. Create your own Firebase project at https://console.firebase.google.com
2. Replace the firebase configuration files with your own
3. Enable Authentication, Firestore, and Storage

### 🚦 Running the App

#### Development Mode
```bash
# Web (recommended for development)
flutter run -d chrome

# Desktop (if you have desktop support)
flutter run -d windows  # or macos/linux

# Mobile (with emulator or physical device)
flutter run -d android  # or ios
```

#### Production Build
```bash
# Web build
flutter build web

# The built files will be in build/web/
```

### 📱 App Navigation

#### User Roles
1. **Customer**: Create orders, track packages, manage profile
2. **Driver**: View assigned orders, update delivery status
3. **Admin**: Manage pricing, view analytics, user management

#### Key Screens
- **Home**: Dashboard with quick actions
- **Create Order**: 4-step wizard with real-time pricing
- **Track Order**: Google Maps integration with live updates
- **Admin Dashboard**: Complete control panel with pricing management

### 💰 Pricing System

#### Current Configuration (US Units)
- **Base Fee**: $5.00
- **Per Mile**: $4.00
- **Per Pound**: $0.50
- **Priority Multipliers**: Low (1.0x), Medium (1.2x), High (1.5x), Urgent (2.0x)
- **Service Fees**: Insurance ($3), Tracking ($2), Express ($10), Fragile ($5)

#### Distance Categories
- **Local**: ≤6 miles (1.0x multiplier)
- **Regional**: ≤30 miles (1.1x multiplier)
- **Long Distance**: ≤125 miles (1.25x multiplier)
- **Interstate**: >125 miles (1.5x multiplier)

### 🎨 Design System

#### Colors
- **Primary Gold**: #FFD700 (Golden)
- **Secondary**: #FFA500 (Orange)
- **Background**: Dark gradients for modern look
- **Cards**: White with subtle shadows

#### Typography
- **Headlines**: Bold, modern fonts
- **Body**: Clean, readable text
- **Buttons**: Consistent styling with gradients

### 🔐 Authentication

#### Supported Methods
- Email/Password
- Google Sign-in (configurable)
- Anonymous access for testing

#### User Management
- Role-based access control
- Profile management
- Secure authentication flow

### 🗺️ Maps Integration

#### Google Maps Features
- Real-time tracking
- Route optimization
- Custom markers
- Distance calculation
- Turn-by-turn directions

### 🧪 Testing

#### Run Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/
```

### 🚀 Deployment Options

#### Web Deployment
1. **Firebase Hosting** (recommended)
   ```bash
   flutter build web
   firebase deploy
   ```

2. **GitHub Pages**
   ```bash
   flutter build web --base-href "/smallcargo-delivery-app/"
   ```

3. **Netlify/Vercel**
   - Upload build/web/ folder

#### Mobile Deployment
1. **Google Play Store**
   ```bash
   flutter build apk --release
   ```

2. **Apple App Store**
   ```bash
   flutter build ios --release
   ```

### 📞 Support

#### Common Issues
1. **Flutter version**: Ensure you're using Flutter 3.32.6+
2. **Dependencies**: Run `flutter pub get` if packages are missing
3. **Platform support**: Web is fully supported, mobile requires additional setup

#### Development Tips
- Use VS Code with Flutter extension for best experience
- Enable hot reload for faster development
- Use Chrome DevTools for debugging web version
- Test on multiple screen sizes

### 🔄 Updates and Maintenance

#### Keeping Up to Date
```bash
# Update Flutter
flutter upgrade

# Update dependencies
flutter pub upgrade

# Clean build if needed
flutter clean
flutter pub get
```

#### Version Control
- All changes are committed to Git
- Use branches for feature development
- Regular commits with descriptive messages

---

## 🎉 Ready to Go!

Your SmallCargo Delivery App is now fully set up with:
- ✅ Complete business logic implementation
- ✅ Professional UI/UX with golden gradient design
- ✅ Real-time pricing calculations
- ✅ Admin dashboard with pricing controls
- ✅ Google Maps integration
- ✅ Comprehensive form validation
- ✅ Role-based authentication
- ✅ Responsive design for all platforms

The app is production-ready and can be deployed to web, mobile, or desktop platforms!
