# Composure — Normative Implementation Specification

This file is the **authoritative implementation contract** for Composure V1. If other project documents disagree with this file, this file wins unless the product owner explicitly changes the requirement.

For rationale and expanded design guidance, see `COMPOSURE_PRODUCT_ENGINEERING_SPEC.md`.

---

## 1. Product

**Name:** Composure\
**Platforms:** macOS, iOS\
**Implementation:** Native Swift / SwiftUI\
**Backend:** None\
**Account/login:** None\
**Cloud AI:** None\
**Meeting recording:** None\
**Persistent transcripts:** None

Composure is an on-device behavioral coach for high-stakes conversations. It gives short, situational cues such as `ASK FIRST`, `KEEP IT SHORT`, `LET THEM FINISH`, or `BRING IT BACK`.

It is not a meeting notes product.

---

## 2. Hard Invariants

The following are non-negotiable V1 requirements.

### PRIV-001 — No live-content upload

The app MUST NOT upload live audio, transcript text, derived meeting state, model prompts containing meeting content, or generated meeting-specific cues to any application-controlled server.

### PRIV-002 — No audio recording

The app MUST NOT create audio recordings or audio files from live sessions.

### PRIV-003 — No transcript persistence

The app MUST NOT save live transcript text to disk, databases, preferences, logs, analytics, crash breadcrumbs, or cloud storage.

### PRIV-004 — Ephemeral session state

Live audio buffers, transcript events, semantic analyses, conversation state, and session cue history MUST be memory-only and MUST be released when the session stops.

### PRIV-005 — No stealth mode

The app MUST show a persistent visible listening/capture indicator whenever it is processing microphone or meeting audio.

### PRIV-006 — Explicit start/stop

Audio processing MUST begin only after an explicit user action and MUST stop immediately when the user presses Stop or the capture source terminates.

### PRIV-007 — No screen analysis

The macOS remote-meeting implementation MUST NOT analyze, OCR, save, or otherwise process screen pixels for product functionality.

### NET-001 — No backend

V1 MUST NOT contain an application backend, remote API, remote logging service, analytics SDK, or third-party cloud model.

Apple-managed system model/speech asset downloads are allowed.

### MODEL-001 — Local semantic model

Semantic coaching MUST use an on-device model. The initial implementation MUST use Apple Foundation Models `SystemLanguageModel` when available.

### MODEL-002 — No cloud fallback

If the semantic model is unavailable, the app MUST degrade to deterministic/template behavior. It MUST NOT silently route to cloud AI.

### PROD-001 — No meeting-history product

V1 MUST NOT expose meeting history, transcripts, recordings, notes, summaries, participant analytics, or action items.

---

## 3. Supported V1 Modes

### MODE-001 — Prepare

MUST be available on macOS and iOS.

Inputs:

- conversation topic/context;
- desired outcome (optional);
- difficulty/concern (optional);
- high-stakes toggle;
- Coaching Profile.

Output MUST be structured as concise behavioral preparation, using these conceptual sections:

- Objective;
- Watch For;
- Questions to Ask;
- If Challenged;
- Keep in Mind.

Preparation content MUST NOT automatically persist.

### MODE-002 — macOS In-Person

MUST capture microphone audio and provide live semantic coaching.

V1 MUST treat speaker identity as unknown in this mode.

### MODE-003 — macOS Remote Meeting

MUST capture:

- meeting/system/application audio;
- user's microphone audio where supported.

The sources SHOULD remain logically separate so the app can identify `USER` versus `OTHER` speech without speaker recognition.

Provider integrations are forbidden in V1.

### MODE-004 — iOS In-Person

MUST capture the iPhone microphone and provide live coaching while Composure is foregrounded.

V1 does NOT need to support coaching a remote meeting running on the same iPhone.

### MODE-005 — Practice

OUT OF SCOPE for V1.

---

## 4. Platform Technology

### TECH-001

Use Swift and SwiftUI.

### TECH-002

Use Swift structured concurrency and enable strict concurrency checking.

### TECH-003

Use Apple Speech framework with `SpeechAnalyzer` and `SpeechTranscriber` for V1 transcription where supported.

### TECH-004

Use `AssetInventory` to determine/install required Apple speech assets before live use.

### TECH-005

Use Foundation Models `SystemLanguageModel` for semantic analysis.

### TECH-006

Use ScreenCaptureKit for macOS remote meeting audio.

### TECH-007

Use App Sandbox on macOS.

### TECH-008

Do not add a database in V1.

### TECH-009

Use `UserDefaults` / `@AppStorage` only for non-sensitive persistent preferences.

---

## 5. Architectural Boundaries

The following components MUST be separable by protocols or narrow concrete interfaces:

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

Suggested repository shape:

```text
Composure/
├── Apps/macOS/
├── Apps/iOS/
├── Packages/ComposureCore/
├── Tests/
└── Docs/
```

Shared behavioral logic MUST live in `ComposureCore`. Platform audio/windowing code SHOULD remain in platform targets.

---

## 6. Audio Requirements

### AUDIO-001 — Streaming only

Live audio MUST be processed as streaming PCM buffers.

### AUDIO-002 — No files

The live pipeline MUST NOT instantiate file-recording paths such as `AVAudioFile` or `SCRecordingOutput` for session content.

### AUDIO-003 — Remote source separation

In macOS Remote Meeting mode, meeting audio and microphone audio SHOULD be separate streams.

### AUDIO-004 — No microphone hijack

Composure MUST NOT reroute, monopolize, or steal the microphone from the meeting application.

### AUDIO-005 — Route changes

The app MUST handle common route/device changes without silent surprising device selection.

### AUDIO-006 — Compatibility validation

Before release, remote capture MUST be tested with:

- Teams;
- Zoom;
- Google Meet / Safari;
- Google Meet / Chrome;
- Webex.

And at least:

- built-in mic/speaker;
- wired headset;
- AirPods;
- Bluetooth headset;
- USB microphone;
- external display audio.

---

## 7. Speech Requirements

### SPEECH-001 — Analyzer ownership

Each live audio sequence MUST have an appropriate SpeechAnalyzer lifecycle.

### SPEECH-002 — Two-sequence remote mode

Because a SpeechAnalyzer handles one input sequence at a time, remote mode SHOULD use distinct analyzers for user microphone and meeting audio.

### SPEECH-003 — Asset readiness

Required speech assets MUST be checked before the session starts. The app SHOULD provide a setup/readiness action so downloads happen before sensitive meetings.

### SPEECH-004 — Bounded context

Finalized transcript events MUST be kept in a bounded in-memory rolling window. Initial target: 60–120 seconds.

### SPEECH-005 — No transcript UI

Live Coach MUST NOT display a transcript.

---

## 8. Conversation Event Model

The core event model SHOULD express at minimum:

```swift
enum SpeakerRole: Sendable {
    case user
    case other
    case unknown
}

struct TranscriptEvent: Sendable, Identifiable {
    let id: UUID
    let timestamp: ContinuousClock.Instant
    let speaker: SpeakerRole
    let text: String
    let isFinal: Bool
}
```

Remote mode:

- mic → `user`;
- captured meeting audio → `other`.

In-person mode:

- `unknown`.

---

## 9. Coaching Profile

The app MUST provide lightweight user customization.

At minimum, profile dimensions SHOULD include:

- responds too quickly;
- becomes defensive when challenged;
- over-explains;
- interrupts;
- states opinions too strongly;
- lets discussions drift;
- speculates instead of saying “I don't know”;
- needs more curiosity/questions;
- executive/high-stakes restraint preference.

Use a small integer importance scale.

The app MUST NOT calculate or show an EQ score.

---

## 10. Coaching Engine

### COACH-001 — Hybrid architecture

The coaching engine MUST combine deterministic detectors and semantic analysis.

### COACH-002 — Deterministic detectors

V1 SHOULD include:

- speaking duration in Remote Meeting mode;
- interruption/overlap in Remote Meeting mode;
- cue cooldown;
- repeat suppression;
- stale-cue rejection.

### COACH-003 — Semantic situations

The semantic analyzer SHOULD support:

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

### COACH-004 — Usually no cue

Prompts, heuristics, and arbitration MUST explicitly bias toward `NO_ACTION` when a cue would not materially help.

### COACH-005 — Behavioral, not diagnostic

The app MUST NOT infer participant emotions, personality, honesty, competence, or mental state in order to coach the user.

---

## 11. Cue Contract

A cue MUST have:

```text
headline
instruction
priority
createdAt
expiresAt
```

Headline:

- target 1–4 words.

Instruction:

- preferred 5–12 words;
- hard maximum 18 words.

The UI MUST show at most one cue at a time.

Recommended initial arbitration values:

```text
Normal display:             8 seconds
Normal cooldown:           20 seconds
Same-type suppression:     90 seconds
High-priority cooldown:     8 seconds
Semantic cue target:        0–4 / 10 minutes
```

These values MUST be centralized and tunable.

---

## 12. Cue Language

Preferred examples:

```text
ASK FIRST
Understand the concern before defending the decision.
```

```text
ANSWER DIRECTLY
Give the answer first. Add context only if needed.
```

```text
DON'T GUESS
Separate what you know from what you think.
```

```text
LET THEM FINISH
Hold your response until they are done.
```

Avoid language such as:

- Calm down.
- Relax.
- Control yourself.
- You're being emotional.
- Don't get angry.
- You're overreacting.

---

## 13. Semantic Model Contract

The model MUST receive instructions that establish:

1. it is an executive communication coach;
2. it is not summarizing the meeting;
3. most moments require no cue;
4. it should return an action for the user, not an assessment of others;
5. it must not take sides in the underlying business argument;
6. it must prefer clarity, curiosity, brevity, listening, and decision focus;
7. output length is tightly bounded.

The implementation SHOULD use guided/structured generation rather than unconstrained prose parsing.

`SystemLanguageModel.availability` MUST be checked before semantic use.

---

## 14. Semantic Scheduling

Semantic analysis MUST be rate-limited.

Initial target:

- at most one analysis opportunity every ~2–3 seconds;
- normally wait for a meaningful finalized segment;
- ignore filler-only fragments;
- discard/cancel stale analysis results.

Agenda drift analysis, when meeting objectives exist, SHOULD run much less frequently (approximately every 30–60 seconds).

---

## 15. Session State

Use an explicit state machine, not unrelated booleans.

```swift
enum CoachSessionState: Sendable {
    case idle
    case checkingReadiness
    case requestingPermissions
    case selectingAudioSource
    case starting
    case listening
    case stopping
    case failed(SessionError)
}
```

Stopping a session MUST:

1. stop capture;
2. finish/cancel speech analyzers;
3. cancel semantic tasks;
4. clear displayed cue;
5. release rolling transcript/context;
6. return to idle.

---

## 16. macOS UI

MUST include:

- Home;
- Prepare;
- Live Coach;
- Settings.

The floating cue surface SHOULD be a non-activating `NSPanel` or equivalent.

It MUST NOT steal keyboard focus from the meeting.

It SHOULD remain unobtrusive when no cue is active.

Default panel position SHOULD be near the top center but user-adjustable.

---

## 17. iOS UI

V1 MUST include:

- Prepare;
- In-Person Coach;
- Settings.

Live coaching MUST work with the app foregrounded.

V1 does not require background microphone capture.

The app SHOULD disable idle screen locking during an active session.

---

## 18. Persistence Contract

Allowed persistent fields:

- Coaching Profile;
- cue preferences;
- preferred locale;
- onboarding state;
- macOS panel position;
- non-sensitive readiness metadata.

Forbidden persistent fields:

- audio;
- transcript text;
- meeting context;
- preparation text;
- participant names;
- semantic analysis;
- meeting-specific cue history.

No database is needed.

---

## 19. Logging Contract

Application logging MUST accept only bounded non-content event identifiers and non-sensitive scalar metadata.

No API should allow arbitrary transcript strings to flow into the log subsystem.

Examples allowed:

```text
session.started
speech.assets.ready
cue.displayed.askFirst
session.stopped
```

Conversation text is forbidden.

---

## 20. Permissions and Disclosure

Permissions MUST be requested just-in-time.

The app MUST explain why macOS Screen/System Audio permission is needed:

> Composure uses this permission to hear audio from the meeting application. It does not analyze or save your screen.

During active capture, the app MUST show a visible listening indication and provide Stop.

The onboarding/privacy text MUST tell users to comply with their organization's policies and applicable participant-notice/legal requirements.

---

## 21. Degraded Behavior

If Foundation Models are unavailable:

- Prepare → template/deterministic fallback;
- Remote Live → deterministic detectors continue;
- In-Person semantic coaching → clearly unavailable or limited.

The app MUST NOT suggest cloud fallback.

AI failures during a meeting SHOULD fail quietly without modal interruption.

---

## 22. Test Requirements

V1 is not releasable until it has automated or repeatable tests for:

- session state transitions;
- cue cooldown/repeat suppression;
- cue priority replacement;
- stale cue rejection;
- transcript buffer expiration;
- semantic rate limiting;
- remote event merge/order;
- Foundation Models unavailable path;
- preparation fallback;
- session cleanup.

Privacy verification MUST include searching the app's writable directories and logs for known test phrases after a session.

Expected result: zero persisted matches.

---

## 23. AI Regression Corpus

Maintain synthetic conversation fixtures covering:

- no-cue normal discussion;
- direct question;
- challenge;
- disagreement;
- justification request;
- executive question;
- agenda drift;
- speculation risk;
- detail trap;
- correct silence.

Each fixture MUST define acceptable and unacceptable cue behavior.

Run the corpus when changing prompts and before adopting a new major OS/system-model version.

---

## 24. V1 Exit Criteria

### macOS Remote

A user can start remote coaching, select a meeting source, participate normally, receive occasional cues, stop coaching, and find no recording/transcript/history.

### macOS/iOS In-Person

A user can start microphone coaching, receive occasional semantic cues, stop, and leave no meeting-content persistence.

### Prepare

A user can prepare for a difficult conversation and receive concise behavioral guidance without that content being automatically stored.

### Privacy

Controlled filesystem/log/network inspection confirms the app does not intentionally persist or transmit conversation content.

---

## 25. Implementation Priority

When requirements conflict, choose in this order:

1. Privacy.
2. Reliability.
3. Low distraction.
4. Coaching usefulness.
5. Latency.
6. Simplicity.
7. Resource efficiency.
8. Visual polish.
9. Feature breadth.

---

## 26. Official Apple References

- <https://developer.apple.com/documentation/speech/speechanalyzer>
- <https://developer.apple.com/documentation/speech/assetinventory>
- <https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel>
- <https://developer.apple.com/documentation/updates/foundationmodels>
- <https://developer.apple.com/documentation/screencapturekit/scstreamoutputtype>
- <https://developer.apple.com/documentation/updates/screencapturekit>
- <https://developer.apple.com/app-store/review/guidelines/>

**Reviewed:** October 7, 2026.
