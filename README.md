
# Published Site
https://quiz-party-11f16.web.app/

# Quiz Party (Flutter + Firebase)

Host creates a quiz -> gets a 6-digit code -> players join, pick a character,
answer live -> animated leaderboard after every question.

## Setup
1. `flutter create .`   (inside this folder, generates android/ios/web/etc.)
2. Create a Firebase project and enable **Cloud Firestore** (start in test mode).
3. `dart pub global activate flutterfire_cli && flutterfire configure`
   (generates `lib/firebase_options.dart`)
4. `flutter pub get && flutter run`
   Run one instance as host, others (phones / emulators / Chrome) as players.

## Firestore rules (demo - tighten for production)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    match /games/{game} {
      allow read, create, update: if true;
      match /players/{p} { allow read, create, update: if true; }
    }
  }
}
```

## Notes
- Scoring: 500-1000 points for a correct answer, faster = more.
- Scoring is computed on the client for simplicity. For competitive/public use,
  move it into a Cloud Function and lock down the rules.
- Add your own characters in `kCharacters` (lib/models.dart).
"# Quizz-Party" 
