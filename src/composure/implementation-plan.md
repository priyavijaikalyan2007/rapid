# Composure — Implementation Plan

This plan is designed to be handed directly to Codex or another implementation agent.

The implementation should proceed milestone-by-milestone. Do not begin post-V1 work until V1 acceptance and privacy criteria are met.

Read first:

1. `SPEC.md` — normative requirements.
2. `COMPOSURE_PRODUCT_ENGINEERING_SPEC.md` — detailed rationale and design.
3. This file — build order and acceptance gates.

---

## 0. Working Rules for the Implementation Agent

For every milestone:

1. make the smallest coherent vertical slice;
2. compile both platform targets whenever shared code changes;
3. add tests before moving on;
4. run relevant paths on physical devices;
5. verify the privacy invariants;
6. document SDK/API discrepancies;
7. avoid adding dependencies unless there is a demonstrated need.

Do not introduce:

- backend services;
- accounts;
- cloud AI;
- analytics;
- crash SDKs;
- meeting history;
- transcript persistence;
- recording;
- provider-specific integrations.

If an Apple API behaves differently from the design assumption, preserve the privacy/product invariant and choose the simplest supported implementation.

---

# Phase 0 — Repository and Build Baseline

## Goal

Create a clean multi-platform project with shared domain code and tests before implementing audio or AI.

## Tasks

### P0-001 — Create project

Create:

```text
Composure/
├── Composure.xcodeproj
├── Apps/
│   ├── macOS/
│   └── iOS/
├── Packages/
│   └── ComposureCore/
├── Tests/
└── Docs/
```

Targets:

- Composure macOS app;
- Composure iOS app;
- ComposureCore Swift package;
- unit test target(s).

### P0-002 — Deployment configuration

Initial targets:

- macOS 26+;
- iOS 26+.

Enable Swift 6 strict concurrency checking.

### P0-003 — Base application shell

Implement platform home screens and placeholder navigation:

macOS:

```text
Home
Prepare
Live Coach
Settings
```

iOS:

```text
Prepare
Live
Settings
```

### P0-004 — Domain skeleton

Add types:

```text
CoachingProfile
CoachingMode
SessionKind
MeetingGoal
TranscriptEvent
SpeakerRole
ConversationalState
CoachingContext
CoachingSituation
CueType
CuePriority
CueCandidate
CoachCue
SemanticAnalysis
CoachSessionState
SessionError
```

### P0-005 — Service protocols

Add:

```text
AudioSource
TranscriptionService
ConversationBuffer
CoachingModel
CoachDetector
SemanticCoach
CueArbiter
CoachSession
PreparationService
ReadinessService
```

### P0-006 — Logging facade

Create a safe logging abstraction now, before transcript strings exist.

Design it to accept:

- event identifier enum;
- safe scalar metadata.

Do not accept arbitrary strings as an event body.

## Tests

- both apps compile;
- shared package compiles;
- domain types are `Sendable` where appropriate;
- logging API cannot accidentally accept transcript text in ordinary use.

## Exit Gate

Both apps launch on physical devices and contain no networking, audio, AI, database, or third-party dependencies.

---

# Phase 1 — Coaching Profile and Privacy Onboarding

## Goal

Ship a useful shell and establish the privacy contract before live capture exists.

## Tasks

### P1-001 — First-run onboarding

Implement screens:

1. Composure introduction.
2. Private by design.
3. Active-listening disclosure.
4. Coaching Profile setup.

Do not request microphone/system-capture permissions during onboarding.

### P1-002 — Coaching Profile

Implement profile fields using a small integer scale:

```text
respondTooQuickly
becomeDefensive
overExplain
interruptOthers
stateOpinionsStrongly
allowAgendaDrift
speculateTooMuch
needMoreCuriosity
executiveRestraint
cueFrequency
cueVerbosity
```

### P1-003 — Persistence

Persist only the profile and UI preferences via `UserDefaults` / `@AppStorage`.

### P1-004 — Settings

Implement:

- Coaching Profile editor;
- cue frequency;
- cue detail;
- default session style;
- preferred language;
- reset profile;
- privacy/status placeholder.

## Tests

- profile round-trip persistence;
- reset behavior;
- no sensitive content model exists in persistence layer;
- onboarding state persists.

## Exit Gate

A fresh install can complete onboarding, configure coaching preferences, quit, relaunch, and retain only those preferences.

---

# Phase 2 — Foundation Models Readiness and Prepare Mode

## Goal

Deliver the first genuinely useful feature without requiring audio permissions.

## Tasks

### P2-001 — Foundation Models wrapper

Implement `AppleFoundationCoachingModel` behind `CoachingModel`.

Check `SystemLanguageModel.default.availability` and map to application readiness states:

```text
available
appleIntelligenceNotEnabled
deviceNotEligible
modelNotReady
otherUnavailable
```

### P2-002 — Model session policy

Create stable semantic instructions that enforce:

- communication coaching only;
- no personality/emotion diagnosis;
- concise output;
- no generic business-consulting drift;
- no cloud fallback.

### P2-003 — Prepare schema

Implement:

```swift
struct MeetingPreparationInput
struct MeetingPreparation
```

Use guided/structured generation supported by the installed SDK.

### P2-004 — Prepare UI

Inputs:

- What is this conversation about?
- What outcome do you want? (optional)
- What could make this difficult? (optional)
- High-stakes/executive toggle.

Output:

- OBJECTIVE
- WATCH FOR
- QUESTIONS TO ASK
- IF CHALLENGED
- KEEP IN MIND

### P2-005 — Deterministic fallback

When the Foundation Model is unavailable, generate useful template advice from the Coaching Profile.

Example mapping:

```text
respondTooQuickly > 1
→ “Pause before answering a challenge.”

needMoreCuriosity > 1
→ “Ask what concern the question is trying to resolve.”
```

### P2-006 — Ephemeral preparation state

Do not persist user input or generated preparation.

Leaving the preparation flow may keep state while the view is alive, but relaunching the app must not recover it.

## Tests

- model availability mapping;
- structured output decoding;
- output length constraints;
- deterministic fallback;
- no preparation persistence;
- profile affects generated/fallback advice.

## Manual evaluation

Create at least 20 synthetic preparation scenarios and inspect:

- behavioral relevance;
- brevity;
- no business-consulting drift;
- no patronizing/therapy language.

## Exit Gate

Prepare works on both macOS and iOS with Foundation Models available and unavailable.

---

# Phase 3 — Speech Asset Readiness

## Goal

Make speech dependencies explicit and ready before live sessions.

## Tasks

### P3-001 — Speech locale support

English first.

Use `SpeechTranscriber` supported-locale APIs from the shipping SDK.

### P3-002 — AssetInventory integration

Create the transcriber configuration and use `AssetInventory` to:

- inspect status;
- obtain installation request;
- download/install missing assets;
- expose progress/status where APIs allow.

### P3-003 — Readiness service

Implement a unified `ReadinessService` that reports:

```text
speech asset ready?
foundation model available?
microphone permission state?
remote capture permission state? (macOS)
```

### P3-004 — Privacy & On-Device Status UI

Display:

```text
Speech model          Ready / Needs Setup
Apple Intelligence    Available / Unavailable
Cloud AI              Not used
Meeting recording     Disabled by design
Transcript storage    Disabled by design
```

## Tests

- readiness state mapping;
- no active meeting required for speech asset setup;
- offline behavior after assets are installed.

## Exit Gate

A user can make the device “meeting ready” before entering a sensitive conversation.

---

# Phase 4 — Shared In-Person Audio Capture

## Goal

Capture live microphone audio on macOS and iOS without writing audio to disk.

## Tasks

### P4-001 — MicrophoneAudioSource

Implement a streaming `AudioSource` using AVFoundation/AVAudioEngine or the current preferred Apple capture path.

Output PCM buffers as transient `AudioEvent`s.

### P4-002 — Permission flow

Request microphone permission only when In-Person Coach is started.

Request speech-recognition permission only if required by the chosen Speech API behavior.

### P4-003 — No-file guarantee

Search the implementation for accidental use of:

```text
AVAudioFile
write(to:)
SCRecordingOutput
file URLs for session audio
```

None should exist in live capture code.

### P4-004 — Route handling

Handle:

- built-in mic;
- wired mic;
- AirPods/Bluetooth changes;
- USB mic on macOS;
- interruption/route-change callbacks.

Do not silently select an unexpected device during an active session when the API allows explicit detection.

## Tests

- start/stop lifecycle;
- repeated sessions;
- permission denied;
- route changes;
- no audio file is created.

## Exit Gate

Both platforms can stream microphone buffers for at least 60 minutes without persistence or unbounded memory growth.

---

# Phase 5 — Live Speech Transcription

## Goal

Convert streaming audio into ephemeral transcript events.

## Tasks

### P5-001 — SpeechAnalyzerTranscriptionService

Implement a transcriber using:

- `SpeechAnalyzer`;
- `SpeechTranscriber`;
- asynchronous analyzer input sequence;
- `AnalyzerInputConverter` or current SDK equivalent.

### P5-002 — TranscriptEvent output

Emit transient events:

```swift
TranscriptEvent(
    timestamp: ...,
    speaker: .unknown,
    text: ...,
    isFinal: ...
)
```

### P5-003 — ConversationBuffer

Implement bounded in-memory ring buffer:

- max age: configurable; default 120 seconds;
- prune on insert and periodically;
- no disk persistence.

### P5-004 — Session cleanup

On Stop:

- stop capture;
- finish/cancel analyzer;
- finish async streams;
- clear rolling context;
- release transcriber/session references.

### P5-005 — No transcript UI

Do not build transcript display except optional developer-only diagnostic views behind compile-time DEBUG flags. DEBUG views must never persist text.

## Tests

- event order;
- buffer age expiration;
- analyzer lifecycle;
- rapid stop/start;
- error recovery;
- session cleanup.

## Privacy test

Speak unique phrases, stop, then search writable app locations and logs.

Expected: zero matches.

## Exit Gate

In-person speech can be transcribed for coaching without creating a transcript product or persistence path.

---

# Phase 6 — Cue Engine and Deterministic Arbitration

## Goal

Build the behavioral output layer before adding semantic AI.

## Tasks

### P6-001 — CueCandidate and CoachCue

Implement domain models and priorities.

### P6-002 — CueArbiter actor

Rules:

- one visible cue;
- expiration;
- cooldown;
- same-type suppression;
- stale candidate rejection;
- priority replacement;
- no historical queue.

Initial configurable values:

```text
normal duration:         8s
normal cooldown:        20s
same type suppression:  90s
high-priority cooldown:  8s
```

### P6-003 — macOS cue surface

Implement non-activating floating panel.

Resting state:

```text
● Composure — Listening
```

Cue state:

```text
ASK FIRST
Understand the concern before explaining.
```

### P6-004 — iOS cue surface

Foreground live coaching screen with large glanceable typography.

Disable idle timer during the session.

### P6-005 — Cue language validator

Enforce:

- headline <= 4 words where practical;
- instruction <= 18 words hard limit;
- no multiline paragraphs;
- prohibited patronizing phrases rejected/rewritten.

## Tests

- cooldown;
- replacement;
- duplicate suppression;
- stale rejection;
- expiry;
- word-count enforcement.

## Exit Gate

Synthetic cue candidates produce stable, unobtrusive UI behavior on both platforms.

---

# Phase 7 — In-Person Semantic Coaching

## Goal

Turn transient speech into useful semantic cues without speaker identification.

## Tasks

### P7-001 — Semantic input builder

Construct bounded inputs from:

- recent finalized events;
- current Coaching Profile;
- session style;
- optional meeting objective;
- recent cue types.

### P7-002 — Structured semantic output

Use guided generation for fields equivalent to:

```text
shouldCue
situation
cueType
confidence
headline
instruction
```

### P7-003 — Semantic scheduler

Requirements:

- wait for meaningful finalized speech;
- rate limit to roughly >=2–3 seconds between opportunities;
- cancel/ignore stale requests;
- do not analyze filler-only segments.

### P7-004 — Situation taxonomy

Implement support for:

```text
NO_ACTION
DIRECT_QUESTION
CHALLENGE
DISAGREEMENT
JUSTIFICATION_REQUEST
AMBIGUOUS_QUESTION
DECISION_POINT
AGENDA_DRIFT
SPECULATION_RISK
DETAIL_TRAP
ESCALATION
```

### P7-005 — Bias toward silence

Model instructions and post-processing must prefer no cue unless the intervention is useful.

### P7-006 — Agenda pulse

When a meeting objective exists, optionally run a separate lower-frequency comparison at 30–60 second intervals.

## Tests

Use synthetic fixtures, not real sensitive transcripts.

Assert:

- appropriate cue type;
- acceptable no-cue decisions;
- maximum verbosity;
- no participant psychological diagnosis.

## Exit Gate

In-person mode produces occasional useful cues with a low false-positive rate in controlled conversations.

---

# Phase 8 — macOS Remote Meeting Capture

## Goal

Capture meeting audio and microphone separately without provider integrations.

## Tasks

### P8-001 — ScreenCaptureKit source selection

Use the current stable ScreenCaptureKit sharing/content picker flow.

The user explicitly selects the meeting app/window/content source.

### P8-002 — Meeting audio stream

Register/process ScreenCaptureKit `.audio` output.

### P8-003 — Microphone stream

Use ScreenCaptureKit `.microphone` output where appropriate for the shipping SDK, or another Apple-supported simultaneous microphone path if testing proves more reliable.

Do not reroute the mic away from the meeting app.

### P8-004 — Screen privacy

Do not register a screen output consumer unless unavoidable.

No screen buffer may enter product logic, logs, storage, OCR, or the model.

### P8-005 — Separate speech analyzers

Implement:

```text
meeting audio → SpeechAnalyzer OTHER
microphone    → SpeechAnalyzer USER
```

Because one analyzer handles one input sequence.

### P8-006 — Event merge

Merge user/other finalized and partial events into a timestamp-ordered transient stream.

### P8-007 — Current-process audio exclusion

Where the SDK supports it and behavior is correct, exclude Composure's own application audio from capture.

Live cues should not play sounds in V1 anyway.

### P8-008 — Remote-specific deterministic detectors

Add:

- speaking duration;
- overlap/interruption;
- optional rapid response.

Initial speaking thresholds:

```text
45s internal observation
75s shorten candidate
100s high-priority candidate
```

Initial meaningful overlap threshold: ~700ms, tunable.

## Compatibility work

Test combinations of:

Meeting apps:

- Teams;
- Zoom;
- Meet/Safari;
- Meet/Chrome;
- Webex.

Hardware:

- built-in;
- wired;
- AirPods;
- Bluetooth headset;
- USB mic;
- external display audio.

Record results in `Docs/REMOTE_AUDIO_COMPATIBILITY.md`.

## Exit Gate

At least the supported compatibility matrix passes without breaking the user's ability to participate in the meeting and without writing audio to disk.

---

# Phase 9 — High-Stakes Mode and Personalization

## Goal

Make the same conversation produce different coaching based on the user's stated needs.

## Tasks

### P9-001 — High-stakes policy

Bias toward:

- concise/direct answers;
- clarifying intent;
- avoiding speculation;
- asking before defending;
- acknowledging concerns;
- decision focus.

### P9-002 — Profile weighting

Use profile values to adjust candidate scoring.

Examples:

```text
overExplain high
→ lower threshold for LAND THE POINT

needMoreCuriosity high
→ increase ASK FIRST / CLARIFY preference

respondTooQuickly high
→ allow rapid-response detector candidates
```

### P9-003 — Session setup

Allow:

```text
Normal
High stakes / executive
Difficult conversation
```

No automatic executive detection.

## Tests

Same synthetic input + different profiles should produce meaningfully different cue preference while staying within product rules.

## Exit Gate

Customization is visible in behavior without becoming complicated or diagnostic.

---

# Phase 10 — Model Evaluation and Prompt Hardening

## Goal

Treat coaching quality as a testable subsystem.

## Tasks

### P10-001 — Synthetic corpus

Create `Tests/ModelEvaluation/` with synthetic conversations.

Each fixture includes:

```text
input/context
profile
session style
expected cue/no cue
acceptable cue types
unacceptable cue types
max verbosity
```

### P10-002 — Required cases

Include at least:

- 20 no-cue ordinary discussions;
- 10 direct questions;
- 10 challenges;
- 10 disagreements;
- 10 justification requests;
- 10 agenda-drift examples;
- 10 speculation-risk examples;
- 10 detail traps;
- 10 high-stakes executive questions;
- 10 cases where the user should simply listen.

### P10-003 — Regression runner

Build a developer evaluation runner that can execute the corpus against the current system model and summarize:

- cue rate;
- no-cue rate;
- cue type agreement;
- instruction word count;
- prohibited-language failures.

Do not persist real meeting content; the corpus is synthetic source-controlled test data.

### P10-004 — OS model regression

Run the corpus when:

- adopting a new major macOS/iOS SDK;
- Apple changes the Foundation Model version;
- prompts change materially.

## Quality target

Optimize for precision over recall.

The app should be quiet.

## Exit Gate

No major regression in cue relevance, verbosity, or false positives across the corpus.

---

# Phase 11 — Privacy Hardening

## Goal

Prove the product promise technically.

## Tasks

### P11-001 — Filesystem inspection

Run controlled sessions containing unique marker phrases.

After Stop and app termination, search:

- Documents;
- Library;
- Application Support;
- Caches;
- tmp;
- preferences.

Expected: zero marker phrase matches.

### P11-002 — Log inspection

Search unified application logs and debug outputs for marker phrases.

Expected: zero matches.

### P11-003 — Network inspection

With required assets already installed:

1. launch Composure;
2. start live coaching;
3. speak marker phrases;
4. inspect application network connections;
5. stop session.

Expected: no application-controlled request containing conversation content.

### P11-004 — Screen privacy verification

Remote mode must demonstrate:

- no screenshots;
- no OCR;
- no screen-frame model input;
- no pixel persistence.

### P11-005 — Memory bounds

Verify:

- transcript ring buffer bounded;
- recent cue list bounded;
- no long-session growth proportional to meeting duration.

### P11-006 — Entitlement review

Audit:

- App Sandbox;
- microphone permission;
- screen/system capture permissions;
- outgoing network entitlement necessity.

### P11-007 — Privacy documentation

Create/update `Docs/PRIVACY.md` with implementation facts, not marketing claims.

## Exit Gate

Privacy verification checklist passes and findings are documented.

---

# Phase 12 — Reliability and Performance

## Goal

Make Composure safe to leave running through long meetings.

## Tasks

### P12-001 — Long-duration tests

Run 60-, 90-, and 120-minute sessions.

Observe:

- memory;
- CPU;
- battery/thermals;
- cue latency;
- analyzer stability.

### P12-002 — Audio failure recovery

Test:

- meeting app closes;
- selected source disappears;
- AirPods disconnect;
- mic permission revoked;
- Mac sleeps/wakes;
- model request errors.

### P12-003 — Semantic failure isolation

Foundation Model failure must not kill capture or deterministic detectors.

### P12-004 — UI focus behavior

Verify floating panel does not steal focus from:

- Teams;
- Zoom;
- Safari;
- Chrome;
- Webex.

## Exit Gate

No known crash, unbounded memory growth, or focus-stealing issue in the supported matrix.

---

# Phase 13 — Accessibility and Visual Polish

## Tasks

### P13-001 — Accessibility

Verify:

- VoiceOver;
- keyboard navigation;
- Dynamic Type;
- increased contrast;
- reduced motion;
- cue comprehension without color.

### P13-002 — macOS panel polish

Implement:

- remembered position;
- readable typography;
- compact listening state;
- smooth but restrained cue transitions.

### P13-003 — iOS polish

Ensure:

- one-handed Start/Stop;
- large cue text;
- clear listening state;
- no accidental screen lock during session.

### P13-004 — No disruptive output

No cue sound by default.

No haptics by default.

## Exit Gate

UI is appropriate for a serious executive meeting and usable with accessibility features.

---

# Phase 14 — App Store Readiness

## Tasks

### P14-001 — App metadata

Prepare:

- final app icon;
- product screenshots;
- subtitle/description;
- support URL;
- privacy policy URL.

### P14-002 — Permission strings

Write accurate microphone and ScreenCaptureKit/system capture usage descriptions.

### P14-003 — App Privacy answers

Answers must match implementation. Do not claim data collection that does not occur; do not omit any data collection that does occur.

### P14-004 — App Review notes

Explain:

- why system/screen capture permission is requested on macOS;
- that Composure processes meeting audio locally;
- that it does not record or store audio/transcripts;
- how the persistent listening indicator works;
- how reviewers can exercise Prepare, In-Person, and Remote modes.

### P14-005 — Final release checklist

```text
[ ] No audio persistence
[ ] No transcript persistence
[ ] No conversation content in logs
[ ] No third-party analytics
[ ] No cloud AI
[ ] No backend
[ ] No account system
[ ] No unexpected network endpoints
[ ] Capture indicator always present
[ ] Stop ends capture immediately
[ ] Permission descriptions accurate
[ ] Screen pixels unused
[ ] Privacy corpus/inspection passes
[ ] Model evaluation corpus passes
[ ] Compatibility matrix documented
[ ] Accessibility review passes
```

## Exit Gate

Release candidate is suitable for App Store submission.

---

# Phase 15 — Post-V1 Backlog

Do not begin until V1 has shipped or the product owner explicitly reprioritizes.

## Practice Mode

- text-first role-play;
- optional spoken interaction;
- behavioral feedback;
- all on-device.

## Local Speaker Enrollment

- user-only voice enrollment;
- ME / NOT ME classification;
- no identification of others;
- opt-in;
- local storage only;
- easy deletion.

## Alternative Local Models

Possible future Foundation Models-compatible local implementations:

- Core AI local language model;
- MLX local model.

Must preserve offline/local privacy semantics.

## Additional Languages

Add after validating:

- SpeechTranscriber availability/assets;
- Foundation Model language support;
- coaching prompt quality.

---

# Recommended Issue Breakdown

If Codex is working from tickets, create the following top-level epics:

```text
EPIC-001 Project Skeleton
EPIC-002 Privacy Onboarding & Profile
EPIC-003 Prepare Mode
EPIC-004 Speech Readiness
EPIC-005 In-Person Audio
EPIC-006 Transcription Pipeline
EPIC-007 Cue Engine
EPIC-008 Semantic Coaching
EPIC-009 macOS Remote Capture
EPIC-010 Personalization & High-Stakes Mode
EPIC-011 Model Evaluation
EPIC-012 Privacy Hardening
EPIC-013 Reliability & Performance
EPIC-014 Accessibility & Polish
EPIC-015 App Store Release
```

Each epic must have an explicit acceptance test and privacy impact review.

---

# Definition of V1 Complete

V1 is complete only when all of the following are true:

1. Prepare works on macOS and iOS.
2. In-Person Live Coach works on macOS and iOS.
3. Remote Meeting Live Coach works on macOS for the documented compatibility matrix.
4. Semantic coaching remains on-device.
5. No cloud fallback exists.
6. No live audio is written to files.
7. No live transcript is persisted.
8. No meeting history exists.
9. Controlled privacy tests find no conversation marker phrases after sessions.
10. Cue behavior is rate-limited and quiet.
11. The synthetic model regression suite passes.
12. Accessibility and App Store review readiness are complete.

---

# Final Instruction to Codex

Do not optimize Composure for how much of a meeting it can understand.

Optimize it for how rarely it needs to interrupt the user — and how valuable the interruption is when it does.

The core product is the momentary behavioral cue, not the transcript underneath it.
