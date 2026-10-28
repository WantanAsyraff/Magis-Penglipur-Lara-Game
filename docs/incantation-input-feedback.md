# Incantation input feedback

The input route remains `_unhandled_input → _process_incantation_inputs → _add_sequence → IncantationResolver.push → _cast_resolved`. `_add_sequence` verifies casting stance, local authority, alive state, pause, stun/silence, dialogue, phone and quest-offer interception, and `IncantationResolver.accepts(direction)`.

After `push()` accepts the direction and before spell execution, Player emits `incantation_direction_accepted(direction: String)`. Its child `effects/incantation-input-particles.tscn` listens to this signal. Recognition and rendering remain separate from the cast queue and execution restrictions. Valid prefixes, exact completions, longer continuations and CHAINED restarts emit once. Mana/cooldown rejection of the completed spell does not retract accepted-input feedback. No prediction or invalid direction emits this signal.

The reusable CPUParticles2D emitter has six soft, muted blue-violet particles, a 0.3 second lifetime, modest upward/outward velocity and an origin beside the player's upper body/hand. Each accepted input restarts the same six-particle burst. Rapid inputs replace the preceding burst instead of accumulating nodes or particles. There is no sound, shake, flash or additional overlay.

CPU particles support the project's GL Compatibility renderer and Web target. Godot's manual GPU emission API is unavailable on Compatibility; see the [official GPUParticles2D reference](https://docs.godotengine.org/en/stable/classes/class_gpuparticles2d.html#class-gpuparticles2d-method-emit-particle). An actual-renderer close-up is included so the deliberately small burst can be inspected.

The existing next-direction assistant, incantations, shared-prefix trie, buffering, spell timings and queue logic are unchanged. Strike → Resonate → Shatterwave remains independently executable in sequence. See [verification](combat-save-v1-verification.md).
