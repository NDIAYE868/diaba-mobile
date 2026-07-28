# Diaba Mobile — Application Flutter

Application mobile de la marketplace sénégalaise **Diaba** pour Android et iOS.

## 📱 Fonctionnalités

| Feature | Description |
|---------|-------------|
| 🏪 **Boutique** | Grille produits, recherche, filtres catégories, tri, carrousel promos |
| 📦 **Détail produit** | Galerie images, rating, stock, description, favoris |
| 🛒 **Panier** | Ajout, suppression, quantité, total FCFA |
| ✅ **Checkout** | Adresse, dépôt, paiement avant/après |
| 📋 **Commandes** | Historique avec suivi statut |
| ❤️ **Favoris** | Liste des produits favoris |
| 👤 **Profil** | Infos, stats, thème, déconnexion |
| 🔐 **Auth** | Login, inscription, reset password (JWT) |

## 🏗️ Architecture

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # MaterialApp + Router
├── core/
│   ├── constants/               # AppConfig, AppColors
│   ├── theme/                   # AppTheme (light/dark)
│   ├── network/                 # DioClient + JWT interceptor
│   ├── storage/                 # TokenStorage (secure)
│   ├── router/                  # GoRouter
│   └── providers/               # ThemeProvider
├── features/
│   ├── auth/                    # Login, Register, ForgotPassword
│   ├── shop/                    # ShopScreen, ProductCard, PromoCarousel
│   ├── product/                 # ProductDetailScreen
│   ├── cart/                    # CartScreen, CartProvider
│   ├── checkout/                # CheckoutScreen (stepper)
│   ├── orders/                  # OrdersScreen
│   ├── favorites/               # FavoritesScreen, FavoritesProvider
│   └── profile/                 # ProfileScreen
└── shared/
    ├── models/                  # Product, Category, Order, User, Cart
    ├── widgets/                 # MainScaffold, AppTextField, AppButton, AppLogo
    └── utils/                   # PriceFormatter
```

## 🛠️ Stack Technique

- **Flutter** 3.x + Dart
- **State Management** : Riverpod
- **Navigation** : GoRouter (ShellRoute, routes protégées)
- **HTTP** : Dio + intercepteur JWT auto-refresh
- **Stockage tokens** : flutter_secure_storage
- **Images** : cached_network_image
- **UI** : Material 3, Google Fonts Poppins
- **Animations** : shimmer, smooth_page_indicator, carousel_slider

## ⚙️ Installation

### Prérequis
- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0
- Android Studio / Xcode (pour iOS)

### 1. Installer Flutter
```bash
# Windows (via Chocolatey)
choco install flutter

# ou télécharger depuis https://docs.flutter.dev/get-started/install
```

### 2. Cloner et installer
```bash
cd c:\dev\diaba\mobile-flutter
flutter pub get
```

### 3. Configurer l'URL API
Éditer `lib/core/constants/app_config.dart` :
```dart
// Développement (Android Emulator)
static const String apiBaseUrl = 'http://10.0.2.2:8000';

// Développement (iOS Simulator)
// static const String apiBaseUrl = 'http://127.0.0.1:8000';

// Appareil physique (remplacer par votre IP locale)
// static const String apiBaseUrl = 'http://192.168.1.X:8000';

// Production
// static const String apiBaseUrl = 'https://api.diaba.sn';
```

### 4. Lancer l'application
```bash
# Lister les appareils disponibles
flutter devices

# Lancer sur un émulateur/appareil
flutter run

# Lancer en release (pour test performance)
flutter run --release
```

### 5. Build
```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (Mac requis)
flutter build ios --release
```

## 🎨 Design

- **Couleurs** : Vert sénégalais `#1B6B3A` + Orange `#E07B2D` + Or `#D4AF37`
- **Typographie** : Poppins (Google Fonts)
- **Mode sombre** : Complet avec couleurs adaptées
- **Material 3** : Design system moderne

## 🌐 API Endpoints utilisés

| Endpoint | Description |
|----------|-------------|
| `POST /api/auth/jwt/create/` | Connexion |
| `POST /api/auth/users/` | Inscription |
| `GET /api/auth/users/me/` | Utilisateur courant |
| `POST /api/auth/jwt/refresh/` | Refresh token |
| `GET /api/products/` | Liste produits |
| `GET /api/products/{slug}/` | Détail produit |
| `GET /api/products/categories/` | Catégories |
| `GET /api/orders/my-orders/` | Mes commandes |
| `POST /api/orders/place/` | Passer une commande |
| `GET /api/shipping/depots/` | Liste des dépôts |

## 🐳 Integration Docker & Environnement

L'application mobile intègre un support Docker complet pour le déploiement Web et la connexion aux conteneurs du backend Django :

### 1. Lancer l'application mobile en conteneur Docker (Web)
```bash
cd c:\dev\diaba\mobile-flutter
docker compose up --build -d
```
L'application sera accessible sur `http://localhost:8080`.

### 2. Connexion aux services Docker du Backend (`diaba-deployment-cd`)
Dans `docker-compose.dev.yml` du projet backend :
- **Android Emulator** : pointe vers `http://10.0.2.2:8000` (adresse loopback d'Android Studio vers l'hôte).
- **iOS Simulator / Navigateur Web** : pointe vers `http://localhost:8000`.
- **Appareil Physique (Android/iOS)** : pointe vers `http://<IP_VOTRE_PC>:8000` (assurez-vous que le PC et le téléphone sont sur le même réseau Wi-Fi).

---

## 📋 TODO (V2)

- [ ] Recherche par image (camera + ML)
- [ ] Notifications push (Firebase FCM)
- [ ] Auth Google/Facebook (OAuth)
- [ ] Avis et notation produits
- [ ] Mode hors-ligne (cache)
- [ ] Localisation Sénégal (communes/dépôts)
