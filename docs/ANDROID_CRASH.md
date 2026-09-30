# Android launch failure investigation

Previous CI generated an Android shell using project name farmershub_gh and organization com.mycompany, then rewrote Gradle namespace/applicationId to com.mycompany.farmershubghmvp. It did not rewrite or move the generated MainActivity Kotlin class. The generated manifest's relative .MainActivity name resolves against the changed namespace; the compiled class remains in the old package. This is a concrete launcher mismatch that can produce ClassNotFoundException before Dart/Firebase startup runs.

The Android project now pins the package consistently in Gradle, MainActivity and the explicit manifest launcher name. scripts/check_android.py checks the class path/package, manifest, release internet permission and Firebase client registration before building.

A prior device log was not available in the repository. Treat this as a source-proven defect; emulator launch verification is required to establish the repaired APK starts successfully. Firebase auth/invalid-credential is a separate sign-in error and does not establish a native launcher crash.

Two GitHub emulator attempts stalled at first frame after Impeller/Vulkan initialization and the runner shut down before completing checks. The beta uses Flutter's compatibility renderer via EnableImpeller=false to avoid reliance on Vulkan drivers. This is separate from the launcher package correction; runtime verification remains required.
