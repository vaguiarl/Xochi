# 🧗 Ledge Hanging & Auto-Climb System

## Goal
Recreate the satisfying ledge grab and auto-climb from Xochi 1.0 that made platforming feel smooth and forgiving.

## How It Works

### Detection Phase:
1. **Player is in air** (not on ground)
2. **Moving upward or falling** near a platform edge
3. **Raycast detects** a ledge within grab range
4. **Hands are near the ledge top** (not too high, not too low)

### Grab Phase:
1. **Snap to ledge position** (align Xochi's hands with ledge edge)
2. **Enter "hanging" state** (velocity = 0, can't move horizontally)
3. **Play hanging animation** (Xochi grabs ledge with hands)
4. **Wait for climb trigger** (automatic after 0.3s OR press jump)

### Climb Phase:
1. **Move upward** smoothly over ledge
2. **Position above platform**
3. **Return to normal state**
4. **Can move again**

---

## Implementation in player.gd

### New States:
```gdscript
enum State {
    NORMAL,
    HANGING,
    CLIMBING
}

var current_state: State = State.NORMAL
var ledge_position: Vector2 = Vector2.ZERO
var hang_timer: float = 0.0
```

### Detection (in _physics_process):
```gdscript
func _detect_ledge() -> Dictionary:
    # Only check when in air and moving up or near apex
    if is_on_floor() or velocity.y < -100:
        return {}

    # Raycast forward and up to find ledge
    var direction: float = 1.0 if sprite.flip_h == false else -1.0
    var hand_height: float = -20.0  # Xochi's hand position

    # Check for platform edge at hand level
    var ray_origin := position + Vector2(direction * 20, hand_height)
    var ray_end := ray_origin + Vector2(direction * 15, 0)

    var space_state := get_world_2d().direct_space_state
    var query := PhysicsRayQueryParameters2D.create(ray_origin, ray_end)
    query.collision_mask = COLLISION_LAYER_WORLD | COLLISION_LAYER_PLATFORMS

    var result := space_state.intersect_ray(query)

    if result:
        # Found a ledge!
        return {
            "position": result.position,
            "normal": result.normal
        }

    return {}
```

### Hanging State:
```gdscript
func _enter_hanging_state(ledge_pos: Vector2) -> void:
    current_state = State.HANGING
    ledge_position = ledge_pos
    hang_timer = 0.0

    # Snap to ledge
    position.x = ledge_pos.x - (16.0 if sprite.flip_h == false else -16.0)
    position.y = ledge_pos.y + 10.0

    # Stop all movement
    velocity = Vector2.ZERO

    print("Grabbed ledge!")


func _update_hanging(delta: float) -> void:
    hang_timer += delta

    # Auto-climb after 0.3 seconds OR if jump pressed
    if hang_timer > 0.3 or Input.is_action_just_pressed("jump"):
        _enter_climbing_state()

    # Allow dropping by pressing down
    if Input.is_action_pressed("move_down"):
        current_state = State.NORMAL
        velocity.y = 100  # Small drop velocity
```

### Climbing State:
```gdscript
func _enter_climbing_state() -> void:
    current_state = State.CLIMBING

    # Smooth climb animation using tween
    var target_pos := position + Vector2(0, -40)  # Climb up 40 pixels

    var tween := create_tween()
    tween.tween_property(self, "position", target_pos, 0.3)
    tween.tween_callback(_finish_climb)


func _finish_climb() -> void:
    current_state = State.NORMAL
    velocity = Vector2.ZERO
    print("Climb complete!")
```

---

## Integration Steps

### 1. Add to player.gd:
- New state enum
- Ledge detection in _physics_process
- State machine for NORMAL/HANGING/CLIMBING
- Collision masks for ledge detection

### 2. Adjust movement:
- Only allow movement in NORMAL state
- Block velocity changes during HANGING/CLIMBING
- Override gravity during these states

### 3. Animation (optional):
- Add "hanging" sprite frame (hands on ledge)
- Add "climbing" animation (pulling up)
- Transition smoothly between states

---

## Tuning Parameters

```gdscript
const LEDGE_DETECT_DISTANCE: float = 15.0  # How far ahead to check
const LEDGE_GRAB_HEIGHT: float = 20.0       # Hand reach height
const HANG_DURATION: float = 0.3            # Auto-climb delay
const CLIMB_HEIGHT: float = 40.0            # How far to climb up
const CLIMB_SPEED: float = 0.3              # Climb animation duration
```

---

## Testing Checklist

- [ ] Xochi grabs ledges when jumping near them
- [ ] Auto-climbs after 0.3 seconds
- [ ] Can drop by pressing down while hanging
- [ ] Works on platforms
- [ ] Works on trajineras (moving platforms!)
- [ ] Doesn't grab ledges when already above them
- [ ] Feels smooth and responsive

---

## Next: Implement in Code

Should I:
1. **Add this to player.gd now?** (Full implementation)
2. **Start with basic version?** (Just detection + auto-climb)
3. **Show me the original code first?** (From game.js)

This will make Xochi feel much more forgiving and fun to control! 🧗✨
