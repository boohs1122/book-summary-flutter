---
name: design-review
description: Review and improve BookSummaryApp screen design from the product flow through mobile concepts, Material 3 implementation, and device verification. Use when asked to review or improve this Flutter app's design or a specific screen.
---

# BookSummaryApp design review

Apply this workflow only to BookSummaryApp UI work. A request to "디자인 검토해줘" includes implementing the selected design and checking the rendered screen; a request explicitly limited to ideas or review stops before code changes.

1. Read the target screen, `docs/02_화면흐름.md`, relevant API behavior in `docs/03_API명세.md`, `lib/core/theme/app_theme.dart`, and the app's architecture and coding rules. Keep required actions, loading, empty, error, and dark-mode states. Identify the current design's concrete problems before making a concept.
2. For visual direction, load `../imagegen-frontend-mobile/SKILL.md` and use image generation to make a mobile screen concept. Treat that skill as image-only guidance for this step. Request raw screen content or a light device frame so the result can be compared with an emulator screenshot. Use the existing Material 3 color scheme and product language as constraints; do not treat generated text, icons, or layout as a specification.
3. Compare the concept with the existing Flutter Material 3 theme and the documented flow. Implement the smallest useful change with Flutter widgets and existing packages. Preserve navigation, accessibility, and all required states. Change the shared theme only when the change benefits more than one screen.
4. Run `dart format` on changed Dart files and `flutter analyze`. Use a focused widget test for behavior that can regress. For screen-level work, run the app or a focused `integration_test` on an available emulator or device, capture the rendered screen, and visually compare it with the concept in light and dark mode where relevant. Check readable text, clipping, safe areas, tap targets, and loading/empty/error states. Prefer Flutter's `integration_test`; use native UI tooling only when a native permission dialog or platform view must be exercised.
5. Report what changed, the screen evidence and tests run, and any state or device that could not be checked. Do not claim visual verification from static analysis alone. Do not commit generated concepts or add test dependencies unless they are needed for the requested work.

Follow the repository's existing commit and PR rules for any later publication request.
