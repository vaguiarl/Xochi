# The Trajinera Rescue — build 5

## Why the encounter changed

Build 4 drew babies without rescue behavior, left crow perception disconnected, and required a pending lesson answer before an arrival could advance. Build 5 moves progress into real rescue events. `companion.tscn` now starts `rescue_main.gd`; the earlier lesson root remains as a UI/voice base and historical prototype.

## The journey

The welcoming quay has a nearby baby, a lantern and “Ven.” Guide or direct movement earns the same visible greeting and 1/3 counter. La Lupita connects the quay and garden with a readable eight-second route (two seconds at each end, two seconds in each direction). Guidance walks to the boarding point and waits for a dwell before jumping.

Rabbitbrije waits in the guarded garden. Reed refuges block perception; the crow patrols, warns for 0.75 seconds, chases at 255 px/s, searches after 1.5 seconds of lost sight, and returns. Calabrija investigates a bell on “Mira allá”; repeated bell directions shorten distraction from four to a minimum three seconds. Catching requires pursuit contact. Rescuing Rabbitbrije earns another checkpoint.

Frida carries the other baby. A chinampa offers an intermediate landing; an ordinary double-jump can make a more direct transfer. Guidance targets the moving boat's stable identity and follows its actual position. Deck collision carries Xochi. Art/canopies are decorative, with reduced opacity near the player and a clearly marked deck. La Lupita, Frida and Esperanza retain stable names and original boat illustrations.

The final bridge repeats cover and distraction. Two babies and Rabbitbrije must be rescued before departure. An early arrival identifies a remaining friend; guidance supports return crossings. All three companions visibly follow, with an arcing catch-up motion over gaps rather than separate escort collision. Esperanza departs for 3.2 seconds before showing the ending.

## Input, language and persistence

Select a visible marker, then Guide. Touch has immediate control; a normal upward swipe plus another gives a double-jump. Open-playfield taps keep the existing optional hyper-jump. UI and marker taps never become world taps.

Core authored directions are Ven, Espera, Al bote, Salta, Al puente and Mira allá, with English equivalents and exact boat names. Native recognizer vocabulary includes the names and distraction phrase. Apple Intelligence remains the existing optional experimental fallback; it does not plan physics or drive the crow. Typed and spoken exact commands share the deterministic action path. Safe planning pauses boats and crow together while leaving the song playing. Exposed chase locations do not open speech planning.

The rescue sidecar (`learning-save-path.rescue`, version 1) stores earned friend IDs and an allowlisted lantern checkpoint, independently of old lesson completion and language evidence. It uses temporary-file replacement. Manual arrivals record no language evidence; touch with displayed support is assisted. Retrying takes 0.48 seconds, resets nearby boat/patrol timing and preserves earned friends and the song. New journeys resume an unfinished rescue; completed journeys restart fresh.

## Validation and remaining tuning

Three independent routes cover actual screen-touch Guide buttons, direct touch movement/double-jumps, and exact Spanish/English command delivery. None of those completion routes teleports the player or forces a rescue. Separate state fixtures test warnings, pursuit, cover, distraction, catches, cancellation and retry persistence.

The expert guided route takes about 38 simulated seconds. The proposed four-to-six-minute first-play target is not established by automation; novice comprehension, challenge, music/speech balance and enjoyment need the next TestFlight session. Full native speech recognition and on-device model quality remain physical-device checks. The iPhone simulator verifies layout and actual opening touch-to-rescue behavior.

Original Calabrija/Crowquistador art, weapon-free Xochi, Rabbitbrije and the original repository's trajinera assets are reused. No new generated raster assets or music were substituted.
