## Firebase Auth Emulator Network Issues - Solutions

### Issue:
```
E/RecaptchaCallWrapper: Initial task failed for action RecaptchaAction(action=signInWithPassword)
with exception - A network error (such as timeout, interrupted connection or unreachable host) has occurred.
```

### Possible Solutions:

1. **Use Real Device**: 
   - Network issues are more common in emulator
   - Try testing on real Android device

2. **Check Emulator Internet**:
   ```bash
   # In emulator, open browser and check if internet works
   # Sometimes emulator DNS settings cause issues
   ```

3. **Firebase Auth Emulator** (Advanced):
   ```bash
   # Install Firebase CLI and run local auth emulator
   npm install -g firebase-tools
   firebase emulators:start --only auth
   ```

4. **Disable App Verification** (Temporary):
   - Go to Firebase Console > Authentication > Settings
   - Temporarily disable "App verification" for testing

5. **Update Firebase Dependencies**:
   ```yaml
   firebase_auth: ^4.16.0  # or latest
   firebase_core: ^2.32.0  # or latest
   ```

### Current Workaround:
- Test with real device for production-like experience
- Or use Firebase Auth emulator for local development