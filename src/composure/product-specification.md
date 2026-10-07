# Composure — Product and Engineering Specification

**Status:** Implementation specification\
**Product:** Composure\
**Platforms:** macOS and iOS\
**Primary language:** Swift\
**UI:** SwiftUI\
**Minimum target:** macOS 26+, iOS 26+\
**Primary AI:** Apple Foundation Models, on-device `SystemLanguageModel`\
**Speech:** Apple Speech framework (`SpeechAnalyzer`, `SpeechTranscriber`)\
**Remote meeting capture on macOS:** ScreenCaptureKit\
**Backend:** None\
**Accounts:** None\
**Cloud AI:** None\
**Meeting recording:** None\
**Transcript persistence:** None

> **Product promise:** Composure is a private, on-device behavioral coach for high-stakes conversations. It helps the user respond deliberately at the moments where a small cue can change the outcome.

---

## 1. Product Definition

Composure is not a meeting recorder, transcription product, note taker, or meeting-summary application. It listens only while the user explicitly starts a coaching session, processes speech transiently on the device, recognizes situations where behavioral guidance may be useful, and displays very short cues.

Typical cues:

> **ASK FIRST**\
> Understand the concern before defending the decision.

> **KEEP IT SHORT**\
> Answer the question before adding context.

> **LET THEM FINISH**\
> Hold your response until the speaker is done.

> **BRING IT BACK**\
> Return the discussion to the decision.

The app should normally remain silent. A low cue rate is a feature, not a defect.

---

## 2. Primary Use Cases

### 2.1 Prepare

Available on macOS and iOS.

The user describes an upcoming conversation and optionally provides:

- topic/context;
- desired outcome;
- what may make the conversation difficult;
- whether it is high-stakes or executive-facing.

Composure returns behavioral preparation, not a meeting summary or business recommendation.

Example input:

> I am meeting the CEO, CTO, and VP Engineering. We need to decide whether to delay the launch. I strongly disagree with the CTO's proposal and I want to make my case without turning it into an argument.

Example output structure:

```text
OBJECTIVE
Get agreement on the decision criteria before arguing for an answer.

WATCH FOR
• Responding too quickly to challenges.
• Getting pulled into implementation detail.
• Defending your position before understanding the concern.

QUESTIONS TO ASK
• Which assumption worries you most?
• What risk are you trying to minimize?
• What would change your view?

IF CHALLENGED
Acknowledge the concern, ask one question, then answer briefly.

REMEMBER
Short answer first.
Curiosity before advocacy.
You do not need to win every point.
```

Preparation content is ephemeral by default and is not automatically persisted.

### 2.2 Live Coach — macOS

Two modes:

1. **In-Person** — microphone input only.
2. **Remote Meeting** — meeting application audio plus the user's microphone, captured separately where the OS and audio hardware allow.

Remote mode is provider-independent. Composure must not integrate with Zoom, Teams, Google Meet, Webex, Slack Huddles, or any other meeting provider.

### 2.3 Live Coach — iOS

V1 supports **In-Person** mode only.

The iPhone can be placed on the table and used as a discreet behavioral cue display. Composure should not depend on capturing a Zoom/Teams/Webex call running on the same iPhone.

### 2.4 Practice

Post-V1.

The user can rehearse a difficult conversation with an on-device model playing a skeptical or challenging counterpart. Afterward, Composure may give behavioral feedback.

---

## 3. Non-Goals

Composure must not drift into the meeting-intelligence category.

V1 explicitly excludes:

- meeting recording;
- transcript viewing;
- transcript export;
- meeting notes;
- meeting summaries;
- action-item extraction;
- CRM integration;
- calendar integration;
- meeting bots;
- participant analytics;
- employee monitoring;
- sentiment analysis of other participants;
- emotion recognition;
- lie detection;
- speaker naming/identification;
- psychological profiling;
- EQ scoring;
- cloud inference;
- remote telemetry containing conversation content;
- user accounts;
- login;
- sync;
- subscriptions/payments.

If a future feature requires persistent meeting content, it must be treated as a major product/privacy change rather than an incremental feature.

---

## 4. Product Principles

### 4.1 Privacy before feature breadth

All live meeting audio, derived transcript fragments, semantic classifications, conversation state, and coaching prompts remain on the device.

There is no cloud fallback.

### 4.2 Ephemeral by default

Audio and speech-derived data live only as long as needed to generate coaching.

When the user stops a session, Composure releases references to:

- audio buffers;
- transient transcript fragments;
- rolling conversation context;
- semantic analyses;
- recent cue state;
- session-level meeting preparation context.

Do not claim cryptographic RAM erasure. The accurate claim is:

> Composure does not intentionally record, save, upload, or persist live conversation content.

### 4.3 Behavioral coaching, not participant analysis

Composure should analyze conversation only to decide what action would help the user.

Prefer classifications such as:

- `directQuestion`;
- `challenge`;
- `requestForJustification`;
- `agendaDrift`;
- `decisionPoint`.

Do not infer that another participant is angry, deceptive, incompetent, hostile, or politically motivated.

### 4.4 Glanceable intervention

A live cue should be understood in less than one second.

Target:

- headline: 1–4 words;
- instruction: 5–12 words preferred;
- instruction hard limit: 18 words.

### 4.5 Silence is a feature

Most conversation should result in no cue.

Prefer missing a mediocre coaching opportunity over distracting the user.

### 4.6 Provider independence

Remote meeting capture must happen at the OS audio layer. The application must not depend on meeting-provider APIs, browser extensions, authentication, or bots.

---

## 5. V1 Functional Scope

V1 must include:

1. First-run privacy onboarding.
2. Coaching Profile.
3. Prepare mode on macOS and iOS.
4. macOS In-Person Live Coach.
5. macOS Remote Meeting Live Coach.
6. iOS In-Person Live Coach.
7. Floating macOS cue panel.
8. On-device speech recognition.
9. On-device semantic coaching.
10. Deterministic behavioral detectors.
11. Cue arbitration and rate limiting.
12. Explicit Start/Stop controls.
13. Persistent listening indicator while capture is active.
14. Privacy/readiness diagnostics.
15. Graceful behavior when Apple Intelligence is unavailable.

---

## 6. Repository Structure

Recommended layout:

```text
Composure/
├── Composure.xcodeproj
├── Apps/
│   ├── macOS/
│   │   ├── ComposureMacApp.swift
│   │   ├── Views/
│   │   ├── Audio/
│   │   └── Windowing/
│   └── iOS/
│       ├── ComposureiOSApp.swift
│       ├── Views/
│       └── Audio/
├── Packages/
│   └── ComposureCore/
│       ├── Sources/ComposureCore/
│       │   ├── Coaching/
│       │   ├── Models/
│       │   ├── Transcription/
│       │   ├── Preparation/
│       │   ├── Privacy/
│       │   └── Utilities/
│       └── Tests/
├── Tests/
│   ├── Integration/
│   ├── Privacy/
│   └── Fixtures/
└── Docs/
    ├── ARCHITECTURE.md
    ├── PRIVACY.md
    └── APP_STORE.md
```

Use a shared Swift package for domain logic. Platform-specific capture/window code should remain in the macOS/iOS targets.

---

## 7. System Architecture

```text
Audio Source(s)
      │
      ▼
Transient PCM Stream
      │
      ▼
Speech Transcription
      │
      ▼
Conversation Event Buffer
      │
      ├───────────────┐
      ▼               ▼
Fast Detectors   Semantic Analyzer
      │               │
      └───────┬───────┘
              ▼
        Cue Candidates
              │
              ▼
          Cue Arbiter
              │
              ▼
           Coach Cue
              │
              ▼
              UI
```

The application must be organized so capture, speech, semantic analysis, and cue arbitration can be unit-tested or replaced independently.

---

## 8. Core Interfaces

Illustrative interfaces:

```swift
protocol AudioSource: Sendable {
    var events: AsyncStream<AudioEvent> { get }
    func start() async throws
    func stop() async
}

protocol TranscriptionService: Sendable {
    var events: AsyncStream<TranscriptEvent> { get }
    func start() async throws
    func consume(_ event: AudioEvent) async throws
    func stop() async
}

protocol CoachingModel: Sendable {
    func analyze(_ input: SemanticCoachingInput) async throws -> SemanticAnalysis
}

protocol CoachDetector: Sendable {
    func evaluate(_ context: CoachingContext) async -> [CueCandidate]
}
```

Concrete implementations should include:

- `MicrophoneAudioSource`;
- `ScreenCaptureMeetingAudioSource`;
- `SpeechAnalyzerTranscriptionService`;
- `AppleFoundationCoachingModel`;
- `SpeakingDurationDetector`;
- `InterruptionDetector`;
- `CueArbiter`.

---

## 9. Audio Architecture — In-Person

Supported on macOS and iOS.

```text
Device microphone
      ↓
AVAudioEngine / capture pipeline
      ↓
PCM buffers
      ↓
SpeechAnalyzer + SpeechTranscriber
      ↓
Transient TranscriptEvent stream
```

Hard requirements:

- no `AVAudioFile`;
- no audio file URL;
- no audio written to Documents, Application Support, Caches, or tmp;
- no audio persistence in SwiftData/Core Data;
- all audio exists only as live buffers required for processing.

---

## 10. Audio Architecture — macOS Remote Meeting

Remote mode requires two logical sources:

```text
A. Meeting application/system audio → OTHER
B. Microphone audio                  → USER
```

Use ScreenCaptureKit for meeting audio. Prefer `SCContentSharingPicker` or another Apple-provided content selection flow so the user explicitly chooses what Composure may hear.

Use ScreenCaptureKit audio output types where supported by the deployment target:

- `.audio` for captured application/system audio;
- `.microphone` for microphone audio.

The meeting application must continue to own/use the microphone normally. Composure is an additional consumer and must never hijack or reroute the microphone away from the meeting app.

Compatibility with shared microphone devices, AirPods, Bluetooth headsets, USB microphones, and common meeting applications must be proven by testing before release.

If simultaneous microphone access is unavailable for a specific configuration, Composure must fail clearly or offer a documented degraded mode; it must not silently steal or switch the input device.

---

## 11. Screen Privacy

Composure uses ScreenCaptureKit only to obtain meeting audio.

The app must not:

- register a screen frame output unless technically required;
- analyze pixels;
- perform OCR;
- capture screenshots;
- inspect participant video;
- inspect shared screen content;
- extract participant names from meeting UI;
- store visual buffers.

If the API delivers any visual buffers as an implementation consequence, discard them immediately and do not pass them into application logic.

The privacy explanation must say why macOS presents a screen/system-audio permission even though Composure does not use screen content.

---

## 12. Speech Recognition

Primary implementation:

- `SpeechAnalyzer`;
- `SpeechTranscriber`;
- `AssetInventory`.

Speech assets are system-managed Apple assets. Composure should provide a readiness flow before a sensitive meeting so required speech assets can be downloaded in advance.

English is the first supported language.

Architecture must allow additional locales later.

### 12.1 Separate analyzers for remote mode

Apple's `SpeechAnalyzer` handles one input sequence at a time. Therefore remote meeting mode should use separate analyzer instances for microphone and meeting audio:

```text
Microphone     → SpeechAnalyzer A → USER events
Meeting audio  → SpeechAnalyzer B → OTHER events
```

Timestamp outputs and merge them into one transient conversation event stream.

### 12.2 Partial vs finalized text

Partial/volatile text may be used for responsiveness and lightweight heuristics.

Finalized speech should drive semantic analysis and rolling context.

Do not render raw transcript text in the normal Live Coach UI.

---

## 13. Transcript Events

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

- mic → `.user`;
- meeting/system audio → `.other`.

In-person mode:

- `.unknown` in V1.

Do not pretend to know the speaker when the app cannot know.

---

## 14. In-Person V1 Limitations

Because every speaker enters through one microphone, V1 cannot reliably distinguish the user from others.

Therefore these features should initially be limited to macOS Remote Meeting mode:

- user's continuous speaking time;
- user interruption detection;
- user response latency;
- user/other talk ratio;
- repeated defense by the user.

In-person mode should emphasize semantic coaching:

- question directed at the user;
- challenge;
- request for justification;
- ambiguous question;
- decision point;
- agenda drift;
- speculation risk;
- unnecessary-detail trap.

Speaker enrollment is a post-V1 feature.

---

## 15. Rolling Context

Maintain an in-memory rolling buffer only.

Recommended bounds:

- latest 60–120 seconds of finalized transcript events;
- compact current conversational state;
- at most 20 recent cue records;
- no unbounded arrays.

```swift
struct CoachingContext: Sendable {
    var recentEvents: [TranscriptEvent]
    var meetingGoal: MeetingGoal?
    var profile: CoachingProfile
    var activeMode: CoachingMode
    var recentCues: [RecentCue]
    var conversationalState: ConversationalState
}
```

The rolling transcript is an implementation detail. It is never exposed as a transcript feature.

---

## 16. Conversational State

Use a compact, ephemeral state object rather than maintaining the entire meeting indefinitely.

```swift
struct ConversationalState: Sendable {
    var currentTopic: String?
    var currentDecision: String?
    var unresolvedQuestion: String?
    var phase: ConversationPhase
}

enum ConversationPhase: Sendable {
    case discussion
    case clarification
    case disagreement
    case decision
    case unknown
}
```

Do not attempt to maintain a detailed meeting memory.

---

## 17. On-Device Foundation Model

Primary semantic model:

```swift
SystemLanguageModel.default
```

Use the Apple Foundation Models framework and keep inference on-device.

Before use, check model availability and handle at least:

- available;
- Apple Intelligence not enabled;
- device not eligible;
- model not ready;
- unknown unavailable reason.

V1 must not automatically use Private Cloud Compute or any third-party cloud model.

The app should remain partially useful when the semantic model is unavailable through deterministic detectors and template-based Prepare guidance.

---

## 18. Model Abstraction

Do not couple domain logic directly to `SystemLanguageModel`.

```swift
protocol CoachingModel: Sendable {
    func analyze(_ input: SemanticCoachingInput) async throws -> SemanticAnalysis
}
```

V1 implementation:

```text
AppleFoundationCoachingModel
```

Possible future local implementations:

```text
CoreAILocalCoachingModel
MLXLocalCoachingModel
```

No cloud implementation belongs in V1.

---

## 19. Structured Semantic Output

Use guided/structured generation. Do not parse arbitrary model prose if avoidable.

Illustrative model:

```swift
enum CoachingSituation: String, Codable, Sendable {
    case none
    case directQuestion
    case challenge
    case disagreement
    case requestForJustification
    case ambiguousQuestion
    case decisionPoint
    case agendaDrift
    case speculationRisk
    case detailTrap
    case escalation
}

enum CueType: String, Codable, Sendable {
    case none
    case askFirst
    case clarify
    case answerDirectly
    case shorten
    case wait
    case avoidDefending
    case acknowledge
    case returnToDecision
    case avoidSpeculation
    case slowDown
}

struct SemanticAnalysis: Sendable {
    var shouldCue: Bool
    var situation: CoachingSituation
    var cueType: CueType
    var confidence: Double
    var headline: String
    var instruction: String
}
```

Use the current Foundation Models guided-generation mechanism in the installed SDK (`@Generable`, generation schemas, or its current equivalent).

---

## 20. Semantic Instructions

Stable system instructions should express roughly:

```text
You are a private executive communication coach.

Do not summarize the meeting.
Decide whether the user would benefit from one very short behavioral cue now.
Usually the correct answer is NO CUE.

Focus on actions the user can take.
Do not diagnose emotions, personalities, motives, honesty, or mental states.
Do not take sides in the underlying business argument.
Prefer curiosity, clarity, brevity, listening, and decision focus.
Avoid repeating sensitive meeting content unless needed to make the cue understandable.

Headline: maximum four words.
Instruction: normally twelve words or fewer; hard maximum eighteen.
```

The user's Coaching Profile is part of the input.

---

## 21. Hybrid Coaching Engine

Do not send every speech fragment to an LLM.

Use two layers.

### 21.1 Deterministic detectors

Fast, local, explainable signals:

- user speaking duration;
- overlap/interruption;
- response latency;
- cue cooldown;
- repeated-cue suppression;
- stale-cue rejection.

### 21.2 Semantic model

Used for conversational meaning:

- direct challenge;
- ambiguous question;
- justification request;
- decision point;
- agenda drift;
- speculation risk;
- detail trap;
- whether a cue is useful at all.

This architecture should produce lower latency and fewer distracting cues than constant generative inference.

---

## 22. Semantic Scheduling

Run semantic analysis only when a meaningful finalized speech segment arrives.

Initial guidance:

- no more frequently than roughly every 2–3 seconds;
- prefer a completed sentence or meaningful turn;
- do not analyze isolated filler words;
- cancel/ignore stale requests when newer context supersedes them.

If there is no meaningful intervention:

```text
shouldCue = false
```

---

## 23. Agenda Pulse

If Prepare mode or session setup provides a meeting objective, Composure may compare the current discussion with that objective at low frequency.

Suggested cadence: 30–60 seconds.

Ask a narrow question:

> Has the conversation materially moved away from the stated decision or objective in a way where a user intervention would help?

Do not flag normal subtopics as drift.

---

## 24. Coaching Profile

Personalization should be lightweight and behavioral.

```swift
struct CoachingProfile: Codable, Sendable {
    var respondTooQuickly: Int
    var becomeDefensive: Int
    var overExplain: Int
    var interruptOthers: Int
    var stateOpinionsStrongly: Int
    var allowAgendaDrift: Int
    var speculateTooMuch: Int
    var needMoreCuriosity: Int
    var executiveRestraint: Bool
    var cueFrequency: CueFrequency
    var cueVerbosity: CueVerbosity
}
```

Suggested scale:

```text
0 = not relevant
1 = sometimes
2 = important
3 = major focus
```

Never calculate an EQ score.

Onboarding choices:

```text
[ ] I answer too quickly
[ ] I become defensive when challenged
[ ] I over-explain
[ ] I interrupt
[ ] I state opinions too strongly
[ ] I let discussions drift
[ ] I speculate instead of saying I don't know
[ ] I should ask more questions

[ ] Be especially conservative in executive meetings
```

---

## 25. Session Context

Before Live Coach starts, optionally ask:

```text
What kind of conversation is this?

Normal
High stakes / executive
Difficult conversation
```

Do not infer executive presence from voices, names, titles, or meeting-provider metadata.

If the user runs Prepare immediately before Live Coach, allow the preparation objective to flow into the live session in memory only.

---

## 26. Cue Model

```swift
struct CoachCue: Identifiable, Sendable {
    let id: UUID
    let type: CueType
    let priority: CuePriority
    let headline: String
    let instruction: String
    let createdAt: ContinuousClock.Instant
    let expiresAt: ContinuousClock.Instant
}

enum CuePriority: Int, Sendable {
    case low
    case normal
    case high
    case immediate
}
```

Only the Cue Arbiter can display a cue.

---

## 27. Cue Arbitration

Rules:

1. Only one cue may be visible at once.
2. Suppress semantically equivalent recent cues.
3. Apply minimum spacing between normal cues.
4. Prefer immediate user-behavior cues over general semantic advice.
5. Expire stale cues automatically.
6. Do not queue old advice.
7. Never show advice after the conversational moment has passed.

Initial tunable defaults:

```text
Normal cue duration:       8 seconds
Normal cue cooldown:      20 seconds
Repeat-type suppression:  90 seconds
High-priority cooldown:    8 seconds
Semantic cue target:       0–4 per 10 minutes
```

These constants belong in one configuration structure and require tuning through evaluation.

---

## 28. Cue Examples

### Challenge

```text
ASK FIRST
Understand the concern before defending the design.
```

### High-stakes direct question

```text
ANSWER DIRECTLY
Give the answer first. Add context only if needed.
```

### Ambiguous question

```text
CLARIFY
Find out what decision the question is supporting.
```

### Speculation risk

```text
DON'T GUESS
Separate what you know from what you think.
```

### Agenda drift

```text
BRING IT BACK
Return to the decision this meeting needs.
```

### User speaking too long

```text
LAND THE POINT
Finish the thought and let someone respond.
```

### Interruption

```text
LET THEM FINISH
Hold your response until they are done.
```

Avoid therapy-like or patronizing language such as “calm down,” “relax,” “control yourself,” or “you are being emotional.”

---

## 29. Deterministic Detectors

### 29.1 Speaking duration — remote mode

Initial thresholds:

```text
45 sec  → internal observation
75 sec  → normal shorten candidate
100 sec → high-priority candidate
```

Do not show a cue automatically at every threshold. The Cue Arbiter still decides.

### 29.2 Interruption — remote mode

Detect meaningful overlap between remote speech and the user's mic.

Initial overlap threshold: approximately 700 ms.

Tune this against natural conversational hand-offs and device latency.

### 29.3 Rapid response

Optional V1 detector.

If another participant finishes a challenging question and the user starts almost immediately, generate a candidate only when the profile says rapid responses are a major coaching focus.

Do not coach every quick answer.

---

## 30. Semantic Situations

V1 target taxonomy:

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

These labels are implementation-only and should not become a meeting analytics dashboard.

---

## 31. High-Stakes / Executive Mode

This mode is manually selected.

Bias coaching toward:

- direct answers;
- shorter answers;
- clarifying intent;
- avoiding unsupported speculation;
- acknowledging concerns;
- asking before defending;
- staying focused on the decision.

Bias against:

- technical tangents;
- rebutting minor points;
- long contextual preambles;
- trying to win every disagreement.

This is not a “never disagree with executives” mode. The goal is deliberate, effective communication.

---

## 32. Prepare Mode

Input:

```swift
struct MeetingPreparationInput: Sendable {
    var topic: String
    var desiredOutcome: String?
    var difficulty: String?
    var highStakes: Bool
    var profile: CoachingProfile
}
```

Output:

```swift
struct MeetingPreparation: Sendable {
    var objective: String
    var watchFor: [String]
    var questionsToAsk: [String]
    var ifChallenged: [String]
    var reminders: [String]
}
```

The model must behave as a communication coach, not a generic strategy consultant. Business context is used only to understand the behavioral situation.

Default output sections:

- OBJECTIVE
- WATCH FOR
- QUESTIONS TO ASK
- IF CHALLENGED
- KEEP IN MIND

The output should be concise enough for a phone screen or minimal scrolling.

---

## 33. macOS UX

Main navigation:

```text
Home
Prepare
Live Coach
Settings
```

Live Coach screen:

```text
LIVE COACH

[ In-Person ]
Use this Mac's microphone

[ Remote Meeting ]
Listen to meeting audio and your microphone
```

### 33.1 Floating cue panel

Implement as a SwiftUI-backed non-activating `NSPanel` or equivalent.

Requirements:

- does not steal keyboard focus;
- remains above ordinary meeting windows where platform rules allow;
- movable;
- remembers preferred position;
- compact;
- unobtrusive resting state;
- clear active listening indicator;
- cue changes without activating Composure.

Suggested resting state:

```text
● Composure
Listening
```

Suggested cue state:

```text
ASK FIRST
Understand the concern before explaining.
```

Default position should be near the top center, close enough to the camera to reduce obvious eye movement. User can change it.

---

## 34. iOS UX

Primary iOS functions:

- Prepare;
- In-Person Coach;
- Settings.

Home:

```text
Composure

[ Prepare for a Conversation ]

[ Start In-Person Coach ]

Settings
```

During coaching:

```text
COMPOSURE

● Listening on this device

ASK FIRST
Understand what they need before giving your answer.

[ Stop ]
```

Keep the app foregrounded in V1 and disable automatic screen locking during an active session.

No V1 requirement for background microphone capture.

---

## 35. Persistence

Persist only:

- `CoachingProfile`;
- UI preferences;
- preferred cue location;
- preferred language;
- onboarding completion;
- non-sensitive model/asset readiness metadata if useful.

Use `UserDefaults` / `@AppStorage` where sufficient.

Do not persist:

- audio;
- transcripts;
- preparation text;
- meeting objectives;
- participant names;
- semantic analyses;
- conversation state;
- cue history across sessions.

No database is required in V1.

---

## 36. Logging Policy

Conversation content must never enter logs.

Prohibited destinations:

- `print()`;
- `Logger` / OSLog;
- crash breadcrumbs;
- analytics events;
- debug files;
- exception descriptions that embed transcript text.

Allowed telemetry-like local log event names:

```text
audio.capture.started
audio.capture.stopped
speech.model.ready
coach.analysis.completed
cue.displayed.askFirst
```

Forbidden:

```text
Generated cue for transcript: "Why did you..."
```

Create a logging facade that accepts event identifiers and scalar metadata only, not arbitrary strings from meeting content.

---

## 37. Network Policy

V1 contains no application backend and no cloud AI.

Do not add:

- `URLSession` for product services;
- WebSockets;
- remote APIs;
- remote logging;
- analytics SDKs;
- crash-reporting SDKs.

Apple system frameworks may download required Apple-managed model/speech assets. Composure should make those downloads explicit in readiness/setup flows and should not require network connectivity during a live session once assets are installed.

Where feasible, test whether the macOS app can ship without outgoing-network client entitlements. Do not assume; verify with the target SDK and App Sandbox behavior.

---

## 38. Readiness and Privacy Screen

Settings should include a status section similar to:

```text
PRIVACY & ON-DEVICE STATUS

Speech model          ✓ Ready
Apple Intelligence    ✓ Available
Cloud AI              ✓ Not used
Meeting recording     ✓ Disabled by design
Transcript storage    ✓ Disabled by design
```

Do not claim the device itself is impossible to compromise.

---

## 39. Permissions

Request permissions only when the corresponding feature is invoked.

### macOS In-Person

- microphone;
- speech-recognition permission if required by current SDK behavior.

### macOS Remote

- microphone;
- Screen/System Audio Recording permission required by ScreenCaptureKit;
- speech-recognition permission if required.

Permission explanation:

> macOS requires this permission so Composure can hear audio from the meeting application. Composure does not analyze or save your screen.

### iOS

- microphone when In-Person Coach is first started;
- speech-recognition permission if required by the deployed Speech API path.

Never request contacts, calendar, location, photos, camera, or notifications in V1.

---

## 40. Active Capture Disclosure

Composure must always provide a clear visual indication while microphone or meeting audio analysis is active.

No stealth mode.

No hidden listening.

Always provide Stop.

Onboarding should explain that the user is responsible for complying with applicable organizational policies, participant-notice requirements, and local law.

Composure should not attempt jurisdiction-specific legal advice.

---

## 41. Foundation Model Unavailable

Composure must remain coherent when Apple Intelligence is unavailable.

Prepare mode:

- template/deterministic advice derived from the Coaching Profile.

Live mode:

- deterministic cues remain available where the audio mode allows.

Example UI:

```text
ON-DEVICE AI UNAVAILABLE

Composure can still provide basic timing and conversation cues.
Enable Apple Intelligence for semantic coaching.
```

Never offer automatic cloud fallback.

---

## 42. Failure Handling

AI/model failures during a meeting must fail quietly.

Possible floating status:

```text
Coach temporarily unavailable
```

Continue deterministic detectors.

Do not show technical modal dialogs over the meeting.

Stale semantic requests should be canceled or ignored rather than queued.

---

## 43. Concurrency

Use Swift structured concurrency with strict concurrency checking.

Suggested isolation:

```text
@MainActor  → UI state
actor       → audio coordination
actor       → transcription
actor       → conversation buffer
actor       → semantic analysis
actor       → cue arbitration
```

Use `AsyncStream` / `AsyncSequence` between pipeline stages.

Avoid global mutable state.

---

## 44. Session State Machine

Use one explicit state machine:

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

Do not model session state with unrelated booleans.

Lifecycle:

```text
IDLE
 ↓
Check model/assets
 ↓
Check/request permissions
 ↓
Select audio source if remote
 ↓
Create transient context
 ↓
Start audio stream
 ↓
Start transcriber(s)
 ↓
LISTENING
 ↓
Stop requested
 ↓
Stop capture
 ↓
Finalize/cancel analyzers
 ↓
Release session context
 ↓
Clear cue
 ↓
IDLE
```

---

## 45. Audio Route Changes

Handle explicitly:

- AirPods connected/disconnected;
- wired headset changes;
- USB microphone changes;
- external display audio;
- selected meeting app closed;
- ScreenCaptureKit stream ending;
- sleep/wake;
- microphone permission revoked.

Never silently select a surprising microphone during a sensitive meeting.

---

## 46. Compatibility Matrix

Before release, validate remote mode with at least:

- Microsoft Teams;
- Zoom;
- Google Meet in Safari;
- Google Meet in Chrome;
- Webex.

Audio hardware:

- built-in speaker + mic;
- wired headphones;
- AirPods;
- Bluetooth headset;
- USB microphone;
- external display audio.

Test that:

1. meeting participants hear the user normally;
2. Composure receives mic audio where expected;
3. Composure receives remote audio;
4. no echo/feedback is introduced;
5. Composure does not recursively capture its own cue sounds (there should be no cue sounds by default);
6. no audio file is created.

---

## 47. Performance Targets

Engineering goals, not marketing guarantees:

- cue visible roughly within 2 seconds of an actionable utterance ending;
- no UI hitching during hour-long meetings;
- bounded transcript/context memory;
- semantic model not invoked continuously;
- no unnecessary screen-frame processing;
- acceptable thermals on supported MacBook and iPhone hardware.

---

## 48. Accessibility

Support:

- VoiceOver;
- Dynamic Type on iOS;
- keyboard navigation on macOS;
- reduced motion;
- high contrast;
- adequate cue font size.

Do not use color as the only cue-priority signal.

---

## 49. Visual Design

Composure should feel appropriate in an executive meeting.

Design attributes:

- quiet;
- neutral;
- minimal;
- high contrast;
- large cue typography;
- limited chrome.

Avoid:

- gamification;
- animated avatars;
- cartoon therapist motifs;
- scores;
- streaks;
- confetti;
- aggressive warning colors;
- distracting animation.

Live coaching is visual by default. Do not play sounds. Haptics are off by default on iOS.

---

## 50. Privacy Verification

Create explicit privacy tests.

After a test session, inspect:

- Documents;
- Library;
- Application Support;
- Caches;
- tmp;
- UserDefaults;
- unified logs where practical.

Use known phrases spoken during testing.

Expected: zero persisted matches.

Also inspect application network behavior during a live session after assets have been installed.

Expected: no Composure network request containing conversation content.

---

## 51. Unit and Integration Tests

At minimum:

- CoachingProfile persistence;
- transcript ring-buffer expiration;
- cue cooldown;
- cue repeat suppression;
- cue priority;
- cue expiration;
- stale cue rejection;
- session state transitions;
- semantic-analysis rate limiting;
- transcript event ordering;
- remote user/other event merge;
- session context destruction;
- preparation fallback;
- Foundation Model unavailable path;
- model error path;
- audio route change handling.

Cue Arbiter examples:

```text
Given ASK_FIRST shown 10 seconds ago
When another ASK_FIRST arrives
Then suppress it
```

```text
Given a normal semantic cue is visible
When an immediate interruption cue arrives
Then replace the normal cue
```

```text
Given a candidate is already stale
Then discard it rather than display old advice
```

---

## 52. AI Evaluation Corpus

Create synthetic conversation fixtures. Never use real sensitive meeting transcripts.

Include:

- normal discussion where no cue should appear;
- direct questions;
- hostile/challenging questions;
- healthy disagreement;
- executive questions;
- technical tangents;
- agenda drift;
- unsupported speculation;
- situations where silence is the best result.

Each fixture should specify:

- cue or no cue;
- acceptable cue types;
- unacceptable cue types;
- maximum acceptable verbosity.

Apple periodically changes the system model with OS updates. Treat this corpus as a product regression suite, not disposable test data.

---

## 53. Quality Metrics

Do not instrument real conversation content in V1.

Use controlled evaluation sessions.

Primary metric:

```text
Useful displayed cues / total displayed cues
```

Secondary:

- false-positive cue rate;
- average cues per 10 minutes;
- cue latency;
- repeated cue rate;
- missed obvious opportunities.

A lower cue count with higher usefulness is preferred.

---

## 54. App Store and Policy Positioning

Position Composure as:

- communication;
- productivity;
- executive communication coaching;
- conversation preparation.

Do not market it as:

- mental-health treatment;
- psychological diagnosis;
- emotion detection;
- lie detection;
- employee monitoring;
- surveillance.

Apple's App Review Guidelines require explicit consent and a clear visual and/or audible indication when an app records, logs, or otherwise makes a record of user activity involving microphone, screen, or other user input. Composure should exceed that baseline through explicit Start/Stop and a persistent listening indicator.

---

## 55. App Sandbox and Entitlements

macOS should use App Sandbox.

Grant only required entitlements/capabilities.

Expected areas:

- microphone/audio input;
- ScreenCaptureKit/system capture permissions.

Do not grant broad file-system access.

Investigate whether the app can omit outgoing network entitlements while still allowing Apple-managed system model assets to be provisioned; verify against the shipping SDK rather than assuming.

---

## 56. Security/Privacy Release Checklist

```text
[ ] No audio persistence
[ ] No transcript persistence
[ ] No hidden temporary audio files
[ ] No conversation text in logs
[ ] No third-party analytics
[ ] No crash-report SDK containing user content
[ ] No remote AI
[ ] No account system
[ ] No unexpected application network endpoints
[ ] Capture indicator always visible
[ ] Stop immediately ends application capture
[ ] Permission explanations are accurate
[ ] Privacy policy matches implementation
[ ] Screen pixels are not analyzed or stored
[ ] Synthetic model regression suite passes
```

---

## 57. First-Run Experience

Screen 1:

```text
COMPOSURE
Private coaching for high-stakes conversations.
```

Screen 2:

```text
PRIVATE BY DESIGN

Composure processes conversations on your device.
It does not intentionally record, save, or upload meeting audio or transcripts.
```

Screen 3:

```text
WHEN COMPOSURE IS LISTENING

You'll always see an active listening indicator.
Only use Composure where live audio analysis is consistent with applicable policies and requirements.
```

Screen 4:

```text
HOW SHOULD I COACH YOU?
```

Do not request microphone or ScreenCaptureKit permissions until the relevant feature is actually used.

---

## 58. Settings

V1 settings:

- Coaching Profile;
- cue frequency: Low / Normal / High;
- cue detail: Very Short / Short;
- default session style: Normal / High Stakes;
- preferred language;
- floating panel location (macOS);
- Privacy & On-Device Status;
- reset Coaching Profile;
- About Composure.

There is no meeting-history settings section because meeting history does not exist.

---

## 59. Practice Mode — Post-V1

Potential flow:

```text
User speech
   ↓
On-device transcription
   ↓
Foundation Model role-play
   ↓
Text response
   ↓
Optional behavioral review
```

Example scenarios:

- skeptical executive;
- architecture review;
- angry customer;
- performance discussion;
- budget challenge;
- project delay.

Feedback focuses on behavior, not personality or mental health.

---

## 60. Future Speaker Enrollment

Post-V1 only.

Possible design:

```text
User voluntarily records short local enrollment sample
           ↓
local speaker embedding
           ↓
ME / NOT ME
```

Requirements:

- opt-in;
- local only;
- no identity of other speakers;
- no named diarization;
- simple deletion;
- purpose limited to identifying the user in in-person mode.

---

## 61. Recommended Technology Choices

Unless implementation testing demonstrates a problem:

- Swift;
- SwiftUI;
- Swift 6 concurrency checking;
- Observation framework;
- ScreenCaptureKit;
- Speech framework (`SpeechAnalyzer`, `SpeechTranscriber`, `AssetInventory`);
- Foundation Models;
- AVFoundation/AVAudioEngine where capture plumbing requires it;
- UserDefaults/@AppStorage for non-sensitive preferences;
- App Sandbox on macOS.

Avoid introducing:

- Redux/TCA solely for architecture fashion;
- RxSwift;
- database frameworks;
- networking frameworks;
- dependency-injection frameworks;
- backend scaffolding.

Simple actors, protocols, and SwiftUI state are sufficient.

---

## 62. Coding Guidelines

Use:

- `Sendable` types across actor boundaries;
- initializer-based dependency injection;
- explicit error types;
- small protocols at platform/model boundaries;
- pure decision logic for cue arbitration;
- feature-oriented source layout;
- tests next to core behavior.

Avoid:

- global mutable state;
- unnecessary singletons;
- force unwraps;
- silent `catch {}` blocks;
- massive view models;
- business logic in SwiftUI Views.

---

## 63. Core Domain Types

Initial domain types should include:

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

Core services:

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

---

## 64. Implementation Milestones

### Milestone 0 — Skeleton

- macOS target;
- iOS target;
- shared `ComposureCore` package;
- navigation;
- test targets;
- structured concurrency baseline.

### Milestone 1 — Profile + Prepare

- onboarding;
- Coaching Profile;
- local preference persistence;
- Foundation Models availability;
- Prepare flow;
- structured output;
- deterministic fallback.

### Milestone 2 — In-Person Coach

- microphone capture;
- SpeechAnalyzer pipeline;
- transient transcript;
- semantic analyzer;
- cue arbiter;
- macOS and iOS cue UI.

### Milestone 3 — macOS Remote Meeting

- ScreenCaptureKit selection;
- meeting audio capture;
- microphone capture;
- separate analyzers;
- event merge;
- speaking-duration and interruption detectors.

### Milestone 4 — Coaching Quality

- synthetic evaluation corpus;
- prompt tuning;
- cue suppression tuning;
- high-stakes behavior;
- agenda pulse;
- latency optimization.

### Milestone 5 — Privacy Hardening

- filesystem inspection;
- logging inspection;
- network inspection;
- sandbox/entitlement review;
- lifecycle cleanup verification.

### Milestone 6 — App Store Readiness

- app icons;
- screenshots;
- privacy policy;
- App Privacy answers;
- Review notes;
- permission descriptions;
- accessibility;
- release-device matrix.

---

## 65. Definition of V1 Done

### macOS Remote Meeting

The user can:

1. open Composure;
2. choose Live Coach → Remote Meeting;
3. optionally enable High Stakes;
4. select the meeting content through the Apple system flow;
5. participate normally;
6. receive occasional concise cues;
7. stop Composure;
8. find no recording, transcript, summary, or meeting history.

### iPhone In-Person

The user can:

1. start In-Person Coach;
2. place the phone nearby;
3. participate normally;
4. receive occasional semantic cues;
5. stop the session;
6. have no meeting content persist.

### Prepare

The user can:

1. describe a difficult upcoming conversation;
2. receive concise behavioral preparation;
3. leave the screen;
4. have the preparation content not automatically persist.

---

## 66. Product North Star

When considering a feature, ask:

> Does this help the user respond more deliberately in an important conversation without compromising privacy or distracting them?

The target experience is not:

> “AI understood my meeting.”

It is:

> “At exactly the right moment, Composure reminded me how I wanted to show up.”

---

## 67. Priority Order

If trade-offs are required, optimize in this order:

1. Privacy.
2. Reliability.
3. Low distraction.
4. Coaching usefulness.
5. Latency.
6. Simplicity.
7. Battery/resource use.
8. Visual polish.
9. Feature breadth.

Never trade the first three for feature breadth.

---

## 68. Instructions to the Implementation Agent

Build Composure incrementally.

For each milestone:

1. implement the smallest coherent vertical slice;
2. add tests;
3. verify privacy invariants;
4. run on physical devices;
5. fix observed behavior before proceeding;
6. keep the architecture local-first and backend-free.

If Apple APIs differ from assumptions in this document:

1. prefer the current stable Apple API;
2. preserve the product/privacy requirement;
3. document the discrepancy;
4. choose the simplest supported implementation;
5. do not introduce cloud processing without explicit product approval.

Composure must remain a **private behavioral coach**, not a meeting-content product.

---

## 69. Apple API References

Verify exact API signatures against the SDK installed with the version of Xcode used for implementation.

- SpeechAnalyzer: <https://developer.apple.com/documentation/speech/speechanalyzer>
- Speech framework: <https://developer.apple.com/documentation/speech>
- AssetInventory: <https://developer.apple.com/documentation/speech/assetinventory>
- Foundation Models `SystemLanguageModel`: <https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel>
- Foundation Models updates: <https://developer.apple.com/documentation/updates/foundationmodels>
- ScreenCaptureKit `SCStreamOutputType`: <https://developer.apple.com/documentation/screencapturekit/scstreamoutputtype>
- ScreenCaptureKit updates: <https://developer.apple.com/documentation/updates/screencapturekit>
- App Review Guidelines: <https://developer.apple.com/app-store/review/guidelines/>

**Last specification review:** October 7, 2026.
