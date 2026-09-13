# 🎬 Flutter Movie & Series Discovery App

<p align="center">
  A Flutter movie and television discovery and recommendation application built to demonstrate media discovery, local-first persistence, and cloud synchronization.
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-Dart-02569B?logo=flutter&logoColor=white">
  <img alt="Firebase" src="https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?logo=firebase&logoColor=black">
  <img alt="TMDB" src="https://img.shields.io/badge/TMDB-REST%20API-01B4E4?logo=themoviedatabase&logoColor=white">
  <img alt="Platform" src="https://img.shields.io/badge/Primary%20Platform-Android-3DDC84?logo=android&logoColor=white">
  <img alt="Status" src="https://img.shields.io/badge/Status-Restored%20Prototype-F0A43C">
</p>

---

## ✨ Features

- **Guest Mode with Account Migration**
- **Google Account Sync**
- **Trending Discovery**
- **Mood-Based Recommendations**
- **Category & Genre Browsing**
- **Movie & TV Filtering**
- **Local Watchlist**
- **Google Sign-In**
- **Cloud Firestore Synchronization**
- **User Profile**
- **Dark Mode**

---

## 📱 App Showcase

<p align="center">
  <img
    src="assets/q-select-showcase.gif"
    alt="Q Select App Showcase"
    width="850"
  />
</p>

<p align="center">
  <sub>
    🎬 Animated showcase of Q Select — discovery, recommendations,
    filtering, preferences, profile, and watchlist experience.
  </sub>
</p>

<br>

<details>
<summary><b>🖼️ View All Screenshots</b></summary>

<br>

<table>
  <tr>
    <td align="center" width="50%">
      <img src="assets/home.jpeg" width="240" alt="Q Select Home and Recommendations Screen"/>
      <br><br>
      <b>🏠 Home & Recommendations</b>
      <br>
      <sub>Mood discovery, trending content, and recommendations</sub>
    </td>
    <td align="center" width="50%">
      <img src="assets/filters.jpeg" width="240" alt="Q Select Filter Options Screen"/>
      <br><br>
      <b>🔎 Filter Options</b>
      <br>
      <sub>Genre, rating, and discovery filtering</sub>
    </td>
  </tr>

  <tr>
    <td align="center" width="50%">
      <img src="assets/content-type.jpeg" width="240" alt="Q Select Content Type Selection"/>
      <br><br>
      <b>🎭 Content Preferences</b>
      <br>
      <sub>Movie and TV content-type selection</sub>
    </td>
    <td align="center" width="50%">
      <img src="assets/profile.jpeg" width="240" alt="Q Select User Profile and Watchlist Screen"/>
      <br><br>
      <b>👤 Profile & Watchlist</b>
      <br>
      <sub>Account settings, dark mode, and saved titles</sub>
    </td>
  </tr>
</table>

</details>

<br>

> [!NOTE]
> The profile screenshot has the account email visually redacted for public portfolio use.

---
---

## 🧰 Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart SDK `^3.8.1`)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Networking**: [http](https://pub.dev/packages/http)
- **Remote API**: [The Movie Database (TMDB) REST API](https://developer.themoviedb.org/)
- **Backend & Auth**:
  - [Firebase Auth](https://pub.dev/packages/firebase_auth)
  - [Cloud Firestore](https://pub.dev/packages/cloud_firestore)
  - [Google Sign-In](https://pub.dev/packages/google_sign_in)
- **Local Persistence**:
  - [sqflite](https://pub.dev/packages/sqflite) (SQLite database)
  - [shared_preferences](https://pub.dev/packages/shared_preferences)

---

## 🚧 Project Status

This repository is a ** learning and prototype project**.

---

## 🎞️ TMDB Setup

TMDB API credentials are **not committed** to this repository. You must obtain your own free API key from [The Movie Database](https://www.themoviedb.org/documentation/api).

The application reads TMDB credentials at compile time using Dart environment variables (`--dart-define`).

### Required Variables
```markdown
| Variable | Description |
|---|---|
| `TMDB_API_KEY` | Your TMDB v3 API Key |
| `TMDB_READ_ACCESS_TOKEN` | Optional TMDB v4 Read Access Token (Bearer Token) |

```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (`3.8.1` or newer)
- Android Studio / Android SDK

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/q_select.git
   cd q_select
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Set up your TMDB credentials and Firebase project as described above.

---

## ⚠️ Known Limitations

- **Android Focus**: Configured and validated primarily for Android.
- **Client-Side API Integration**: TMDB calls are made directly from the client; a production-ready application would typically proxy these calls through a backend server.

---

## 👨‍💻 Author

**Ahmad Ali**
