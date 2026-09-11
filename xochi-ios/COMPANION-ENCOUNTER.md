# The Crowquistador crossing

Build 4 extends the first playable encounter of the approved Spanish-learning companion concept. It uses the existing native Godot project; no Swift gameplay rewrite or live LLM controls movement.

## Implemented loop

The player sees a short Spanish phrase, can hear its authored pronunciation, and either speaks/types a matching direction or chooses its meaning. Xochi walks or jumps to the chosen destination using actual physics. New hazards stop the plan. Touch can take over at any point; a new instruction replaces an unfinished manual destination, and stale spoken results cannot reclaim control.

The sequence introduces and reuses five intentions across eight steps: come, wait, approach, take the boat, wait for the guard, jump across, wait for a friend, and gather at the bridge. Movement alone does not finish a lesson. Wrong meanings produce gentle feedback without an attack, life loss, or evidence credit. An optional English hint keeps the encounter moving.

The Crowquistador turns to investigate an authored distraction. The first opening lasts six seconds; repeating it produces shorter openings down to 3.8 seconds. There is always another opening. While the microphone prepares/listens or a direction is interpreted, guard simulation freezes and music keeps playing. The opening remains valid for the eventual finalized instruction. This pilot uses predictable enemy states rather than model-generated tactics.

## Evidence and language

The local save distinguishes intentions used, independent meaning choices, exact Spanish spoken/typed practice and separate model-interpreted Spanish practice. Model-inferred language is not treated as exact phrase evidence. English instructions are accepted as rescue, without being counted as Spanish spoken practice. A translation hint or wrong guess marks the current choice assisted. Choosing a meaning by touch is not treated as evidence of speaking ability. A recognized utterance is practice, not proof of pronunciation or long-term recall.

The interface language can be English or Spanish. Listening defaults to Spanish; the pause menu permits English. This avoids promising seamless bilingual recognition in one device recognizer. Speech examples always use the Spanish voice.

## Recovered art and music

The crow is derived from the original Crowquistador, with transparent edges and matching soft 3D materials; the skull is the original `calaca.png`, presented under the user's Calabrija name. Generation prompts and original references are documented under `assets/companion/`.

Music is `music_menu.ogg`, the original World 1/menu selection, matched by embedded Suno generation ID to **Traviesa Axolotla en Xochimilco**. It remains one continuous stream through the encounter and ending. Speech lowers its volume briefly, never rewinds it.

## Deliberately outside this first encounter

This build does not establish a complete language course, long-term adaptation, pronunciation grading, or a new multi-world campaign. It does not yet implement the board's full cover/distraction puzzle, group pathfinding, open-ended conversation or unconstrained commands. A deterministic parser handles authored phrases immediately. Optional Apple Intelligence classifies other single directions into the same finite vocabulary; unsupported or conflicting instructions ask the player to try again or use a choice.

Apple Foundation Models now powers experimental natural guidance as well as legacy cheering. It receives only an utterance, never the lesson answer, and returns constrained intent/language fields, including an explicit reject choice. The scene validates the result before any physical movement. An anchored request filter rejects praise, stories, explanations, negation and sequences before inference; the model is also instructed to reject ambiguity. Inference times out after five seconds, with a six-second adapter watchdog; stale sessions are ignored.

One empty model session is prepared while speaking or typing, then consumed once; no request history is reused. Model availability and locale support are checked at runtime, separately from speech recognition. Pause explains readiness and exposes typed guidance even when microphone permission is denied. Exact phrases and touch remain usable without Apple Intelligence. Microphone capture is opt-in and bounded to one finalized utterance or a 20-second ceiling; the app does not save recordings.

## Next human test

Use this TestFlight encounter with Spanish beginners. Observe whether they understand when Xochi needs a plan, whether touch feels immediate, whether the music makes repetition pleasant, and whether familiar language can be used without the English hint. Revisit the phrases later in a changed layout before making any retention claim.

Physical iPhone checks still need real model interpretation quality and latency, varied accents, on-device voice assets, speaker/music feedback, permission denial, headset routes and interruptions. Automated tests and simulator captures do not establish these properties.

## Apple implementation references

The optional on-device model uses [SystemLanguageModel availability](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel) and [locale support](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/supportslocale%28_%3A%29). [Apple lists compatible devices and setup requirements](https://support.apple.com/en-us/121115); iPhone 12 mini does not support Apple Intelligence. On-device speech recognition is a separate capability and is explicitly required by the native capture request.

## Experimental model validation boundary

The final native request filter passes 15/15 tests. The final single-process Mac probe used five seconds of preparation and a five-second inference deadline: nine non-guidance cases rejected correctly, while all six model-backed cases timed out, including five positive requests. This does **not** establish usable natural-language latency. The bounded fallback works, but Apple Intelligence guidance remains experimental until its actual response quality and speed are verified on a compatible iPhone. See `tests/native_companion_model_probe.py` and `TEST-RESULTS.md`.
