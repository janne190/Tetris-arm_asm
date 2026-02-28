@ ============================================
@ Tetris Phase 15 - Fully Procedural Rotation
@ ============================================
@ Features:
@ - 14-byte base shape table (7 pieces x 2 bytes)
@ - Branchless 3x3 and 4x4 CW rotation algorithms
@ - Uniform random piece distribution via magic multiplier
@ - Centered pieces to prevent orbiting during rotation
@ ============================================

@ === MEMORY MAP ===
@ 0x10000: ROM (code)
@ 0x20000: RAM base
@ 0x20100: Game state
@ 0x20200: Matrix (10 wide, 20 tall)
@ 0x20300: Tetromino base shapes (7 pieces * 2 bytes = 14 bytes)
@ 0x30000: VRAM (40x20)
@ 0x40000: MMIO
@ 0x40008: VSYNC port

@ === GAME STATE ===
@ [r9, #0x100] = initialized
@ [r9, #0x104] = piece_x
@ [r9, #0x108] = piece_y
@ [r9, #0x10C] = piece_type (0-6)
@ [r9, #0x110] = score
@ [r9, #0x114] = gravity counter
@ [r9, #0x118] = game over flag
@ [r9, #0x11C] = current_rotation (0-3)
@ [r9, #0x120] = rotation debounce
@ [r9, #0x124] = next piece type
@ [r9, #0x128] = high score
@ [r9, #0x12C] = hard drop debounce
@ [r9, #0x134] = PRNG state (xorshift32)

@ === PIECE TYPES ===
@ 0 = I-piece (4x4 grid)
@ 1 = J-piece (3x3 grid)
@ 2 = L-piece (3x3 grid)
@ 3 = O-piece (2x2, NO ROTATION)
@ 4 = S-piece (3x3 grid)
@ 5 = T-piece (3x3 grid)
@ 6 = Z-piece (3x3 grid)

@ === ENTRY POINT ===
_start:
    @ Initialize stack pointer to 0x28000
    movw sp, #0x8000
    movt sp, #0x0002
    
    @ r8 = VRAM base (0x30000)
    movw r8, #0x0000
    movt r8, #0x0003
    
    @ r9 = RAM base (0x20000)
    movw r9, #0x0000
    movt r9, #0x0002
    
    @ Check if already initialized
    ldr r0, [r9, #0x100]
    cmp r0, #0
    bne main_loop
    
    @ Mark as initialized
    mov r0, #1
    str r0, [r9, #0x100]
    
    @ ========================================
    @ Initialize Tetromino BASE SHAPES at 0x20300
    @ 14 bytes total (7 pieces * 2 bytes each)
    @ All pieces CENTERED in their grids
    @ ========================================
    
    @ r0 = base address 0x20300
    add r0, r9, #0x300
    
    @ I-piece (4x4): 0x00F0 - horizontal line in row 1 (centered)
    @ Bit layout: row1 = bits 4-7 = 1111
    mov r1, #0xF0
    strb r1, [r0, #0]
    mov r1, #0x00
    strb r1, [r0, #1]
    
    @ J-piece (3x3): 0x0039 - centered
    @ Row 0: 100 (bit 0), Row 1: 111 (bits 3,4,5)
    @ Shape = 1 + 8 + 16 + 32 = 57 = 0x39
    mov r1, #0x39
    strb r1, [r0, #2]
    mov r1, #0x00
    strb r1, [r0, #3]
    
    @ L-piece (3x3): 0x003C - centered
    @ Row 0: 001 (bit 2), Row 1: 111 (bits 3,4,5)
    @ Shape = 4 + 8 + 16 + 32 = 60 = 0x3C
    mov r1, #0x3C
    strb r1, [r0, #4]
    mov r1, #0x00
    strb r1, [r0, #5]
    
    @ O-piece (2x2): 0x0036 - does NOT rotate
    @ Row 0: 011 (bits 1,2), Row 1: 011 (bits 4,5)
    @ Shape = 2 + 4 + 16 + 32 = 54 = 0x36
    mov r1, #0x36
    strb r1, [r0, #6]
    mov r1, #0x00
    strb r1, [r0, #7]
    
    @ S-piece (3x3): 0x001E - centered
    @ Row 0: 011 (bits 1,2), Row 1: 110 (bits 3,4)
    @ Shape = 2 + 4 + 8 + 16 = 30 = 0x1E
    mov r1, #0x1E
    strb r1, [r0, #8]
    mov r1, #0x00
    strb r1, [r0, #9]
    
    @ T-piece (3x3): 0x003A - centered
    @ Row 0: 010 (bit 1), Row 1: 111 (bits 3,4,5)
    @ Shape = 2 + 8 + 16 + 32 = 58 = 0x3A
    mov r1, #0x3A
    strb r1, [r0, #10]
    mov r1, #0x00
    strb r1, [r0, #11]
    
    @ Z-piece (3x3): 0x0033 - centered
    @ Row 0: 110 (bits 0,1), Row 1: 011 (bits 4,5)
    @ Shape = 1 + 2 + 16 + 32 = 51 = 0x33
    mov r1, #0x33
    strb r1, [r0, #12]
    mov r1, #0x00
    strb r1, [r0, #13]
    
    @ Fall through to reset_game

@ ============================================
@ reset_game - Initialize/Reset game state
@ ============================================
reset_game:
    @ Clear game state variables
    mov r0, #0
    str r0, [r9, #0x104]    @ piece_x
    str r0, [r9, #0x108]    @ piece_y
    str r0, [r9, #0x10C]    @ piece_type
    str r0, [r9, #0x110]    @ score
    str r0, [r9, #0x114]    @ gravity counter
    str r0, [r9, #0x118]    @ game over flag
    str r0, [r9, #0x11C]    @ rotation
    str r0, [r9, #0x120]    @ rotation debounce
    
    @ Fix: Set hard drop debounce to prevent instant drop on restart
    mov r0, #1
    str r0, [r9, #0x12C]    @ hard drop debounce = 1 (wait for key release)
    
    @ Initialize spawn position
    mov r0, #3
    str r0, [r9, #0x104]    @ piece_x = 3
    mov r0, #0
    str r0, [r9, #0x108]    @ piece_y = 0
    
    @ Clear Matrix (200 bytes at 0x20200)
    add r0, r9, #0x200
    mov r1, #0
    mov r2, #200
reset_matrix_loop:
    strb r1, [r0], #1
    subs r2, r2, #1
    bne reset_matrix_loop
    
    @ Initialize PRNG seed from hardware RNG with zero guard
    movw r0, #0x0004
    movt r0, #0x0004       @ r0 = 0x40004 (hardware RNG)
    ldr r0, [r0]           @ r0 = hardware random value
    cmp r0, #0
    moveq r0, #1           @ Replace 0 with non-zero seed (xorshift requirement)
    str r0, [r9, #0x134]   @ Store PRNG seed
    
    @ Draw first NEXT piece
    bl get_random_piece
    str r0, [r9, #0x124]   @ Store first NEXT piece
    
    @ Spawn first piece
    bl spawn_piece

@ ============================================
@ main_loop - Main game loop
@ ============================================
main_loop:
    @ Check for game over
    ldr r0, [r9, #0x118]
    cmp r0, #1
    beq game_over_loop
    
    @ === NORMAL GAME LOOP ===
    @ Increment gravity counter
    ldr r0, [r9, #0x114]
    add r0, r0, #1
    str r0, [r9, #0x114]
    
    @ Check for soft drop (Down button = bit 1)
    movw r0, #0x0000
    movt r0, #0x0004
    ldr r4, [r0]
    tst r4, #2
    beq check_gravity
    
    @ Soft drop: force gravity
    mov r0, #100
    str r0, [r9, #0x114]
    b do_gravity
    
check_gravity:
    @ Calculate gravity threshold based on level
    ldr r0, [r9, #0x114]   @ r0 = gravity counter
    ldr r1, [r9, #0x110]   @ r1 = score
    lsr r1, r1, #9         @ r1 = level (score / 512)
    mov r12, #20
    sub r12, r12, r1       @ r12 = 20 - level
    cmp r12, #2            @ Minimum threshold is 2
    bge apply_thresh
    mov r12, #2
apply_thresh:
    cmp r0, r12
    blt skip_gravity
    
do_gravity:
    @ Reset gravity counter
    mov r0, #0
    str r0, [r9, #0x114]
    
    @ Check collision one row down
    ldr r0, [r9, #0x10C]   @ type
    ldr r1, [r9, #0x104]   @ x
    ldr r2, [r9, #0x108]   @ y
    ldr r3, [r9, #0x11C]   @ rotation
    add r2, r2, #1         @ y + 1
    bl check_collision
    cmp r0, #0
    bne do_lock            @ Collision = lock piece
    
    @ No collision: move down
    ldr r0, [r9, #0x108]
    add r0, r0, #1
    str r0, [r9, #0x108]
    b skip_gravity

do_lock:
    @ Lock piece to matrix
    ldr r0, [r9, #0x10C]   @ type
    ldr r1, [r9, #0x104]   @ x
    ldr r2, [r9, #0x108]   @ y
    ldr r3, [r9, #0x11C]   @ rotation
    ldr r4, [r9, #0x10C]
    add r4, r4, #1         @ value = type + 1 (1-7)
    bl write_piece
    bl clear_lines
    bl spawn_piece
    bl render
    b main_loop

skip_gravity:
    @ Read controller state
    movw r0, #0x0000
    movt r0, #0x0004
    ldr r4, [r0]           @ r4 = controller state
    
    @ === HARD DROP CHECK (Space = bit 4) ===
    tst r4, #16
    beq clear_hd_debounce
    
    @ Check hard drop debounce
    ldr r0, [r9, #0x12C]
    cmp r0, #0
    bne skip_debounce
    
    @ Set debounce active
    mov r0, #1
    str r0, [r9, #0x12C]
    
hd_loop:
    @ Try to move down
    ldr r0, [r9, #0x10C]   @ type
    ldr r1, [r9, #0x104]   @ x
    ldr r2, [r9, #0x108]   @ y
    ldr r3, [r9, #0x11C]   @ rotation
    add r2, r2, #1         @ y + 1
    bl check_collision
    cmp r0, #0
    bne hd_hit
    
    @ No collision: move down and add points
    ldr r2, [r9, #0x108]
    add r2, r2, #1
    str r2, [r9, #0x108]
    
    ldr r0, [r9, #0x110]
    add r0, r0, #2         @ 2 points per cell
    str r0, [r9, #0x110]
    b hd_loop
    
hd_hit:
    @ Update high score if needed
    ldr r0, [r9, #0x110]
    ldr r1, [r9, #0x128]
    cmp r0, r1
    ble hd_no_hi_update
    str r0, [r9, #0x128]
hd_no_hi_update:
    b do_lock
    
clear_hd_debounce:
    mov r0, #0
    str r0, [r9, #0x12C]

skip_debounce:
    @ === ROTATION CHECK (Up = bit 0) ===
    @ Rotates CLOCKWISE
    tst r4, #1
    beq check_left
    
    @ Check rotation debounce
    ldr r0, [r9, #0x120]
    cmp r0, #0
    bne check_left
    
    @ Set debounce
    mov r0, #10
    str r0, [r9, #0x120]
    
    @ Calculate new rotation: (current + 1) AND 3
    ldr r0, [r9, #0x11C]
    add r0, r0, #1
    and r0, r0, #3
    
    @ Check collision with new rotation
    mov r3, r0             @ r3 = new rotation
    mov r5, r0             @ r5 = save new rotation
    ldr r0, [r9, #0x10C]   @ type
    ldr r1, [r9, #0x104]   @ x
    ldr r2, [r9, #0x108]   @ y
    bl check_collision
    cmp r0, #0
    bne check_left         @ Collision = can't rotate
    
    @ Apply rotation
    str r5, [r9, #0x11C]
    b skip_debounce

check_left:
    @ Left movement (Left = bit 2)
    tst r4, #4
    beq check_right
    ldr r0, [r9, #0x10C]
    ldr r1, [r9, #0x104]
    sub r1, r1, #1
    ldr r2, [r9, #0x108]
    ldr r3, [r9, #0x11C]
    bl check_collision
    cmp r0, #0
    bne check_right
    ldr r0, [r9, #0x104]
    sub r0, r0, #1
    str r0, [r9, #0x104]

check_right:
    @ Right movement (Right = bit 3)
    tst r4, #8
    beq update_rot_debounce
    ldr r0, [r9, #0x10C]
    ldr r1, [r9, #0x104]
    add r1, r1, #1
    ldr r2, [r9, #0x108]
    ldr r3, [r9, #0x11C]
    bl check_collision
    cmp r0, #0
    bne update_rot_debounce
    ldr r0, [r9, #0x104]
    add r0, r0, #1
    str r0, [r9, #0x104]

update_rot_debounce:
    @ Decrement rotation debounce
    ldr r0, [r9, #0x120]
    cmp r0, #0
    beq skip_rot_debounce
    sub r0, r0, #1
    str r0, [r9, #0x120]
skip_rot_debounce:

    bl render
    b main_loop

@ ============================================
@ game_over_loop - Wait for restart
@ ============================================
game_over_loop:
    movw r0, #0x0000
    movt r0, #0x0004
    ldr r1, [r0]
    
    @ Check Space button (bit 4)
    tst r1, #16
    beq go_clear_debounce
    
    @ Check debounce
    ldr r2, [r9, #0x12C]
    cmp r2, #0
    bne go_skip_input
    
    @ Restart game
    b reset_game
    
go_clear_debounce:
    mov r2, #0
    str r2, [r9, #0x12C]
    
go_skip_input:
    bl render
    b game_over_loop


@ ============================================
@ spawn_piece - Spawn next piece
@ ============================================
spawn_piece:
    push {r4-r7, lr}
    
    @ Get next piece type
    ldr r0, [r9, #0x124]
    
    @ Bounds check: clamp to 0-6
    cmp r0, #6
    bls sp_type_ok
    mov r0, #0
sp_type_ok:
    str r0, [r9, #0x10C]   @ Set current piece
    
    @ Generate new next piece
    bl get_random_piece
    
    @ Bounds check
    cmp r0, #6
    bls sp_next_ok
    mov r0, #0
sp_next_ok:
    str r0, [r9, #0x124]
    
    @ Reset rotation
    mov r0, #0
    str r0, [r9, #0x11C]
    
    @ Reset position
    mov r0, #3
    str r0, [r9, #0x104]
    mov r0, #0
    str r0, [r9, #0x108]
    
    @ Check if spawn position is blocked (game over)
    ldr r0, [r9, #0x10C]
    ldr r1, [r9, #0x104]
    ldr r2, [r9, #0x108]
    ldr r3, [r9, #0x11C]
    bl check_collision
    cmp r0, #0
    beq spawn_done
    
    @ Game over
    mov r0, #1
    str r0, [r9, #0x118]

spawn_done:
    pop {r4-r7, pc}

@ ============================================
@ get_piece_shape - Get rotated piece shape
@ Input: r0 = piece type (0-6), r1 = rotation (0-3)
@ Output: r0 = shape bitmask
@ 
@ Piece types:
@   0 = I-piece (4x4 grid)
@   3 = O-piece (no rotation)
@   1,2,4,5,6 = 3x3 grid pieces
@ ============================================
get_piece_shape:
    push {r1-r4, lr}
    
    @ Save piece type for grid size decision
    mov r3, r0             @ r3 = piece type
    
    @ Load base shape from table (piece_type * 2)
    lsl r2, r0, #1         @ r2 = type * 2
    add r2, r2, r9
    add r2, r2, #0x300     @ r2 = address of base shape
    ldrh r0, [r2]          @ r0 = 16-bit base shape
    
    @ If rotation == 0, return base shape
    cmp r1, #0
    beq gps_done
    
    @ O-piece (type 3) does NOT rotate
    cmp r3, #3
    beq gps_done
    
    @ Fix: Symmetric pieces (I=0, S=4, Z=6) use Nintendo toggle method
    @ Force rotation to 0 or 1 to prevent bounding box wobble
    cmp r3, #0              @ I-piece?
    beq gps_toggle
    cmp r3, #4              @ S-piece?
    beq gps_toggle
    cmp r3, #6              @ Z-piece?
    beq gps_toggle
    b gps_normal_rotate
    
gps_toggle:
    @ Clamp rotation to 0 or 1 (toggle between two states)
    and r1, r1, #1
    
gps_normal_rotate:
    @ If rotation is 0, skip rotation loop entirely
    cmp r1, #0
    beq gps_done
    
    @ Determine rotation function based on piece type
    cmp r3, #0
    bne gps_3x3
    
    @ I-piece uses 4x4 rotation
gps_4x4_loop:
    push {r1}
    bl rotate_4x4_CW90
    pop {r1}
    subs r1, r1, #1
    bne gps_4x4_loop
    b gps_done
    
gps_3x3:
    @ All other pieces use 3x3 rotation
gps_3x3_loop:
    push {r1}
    bl rotate_3x3_CW90
    pop {r1}
    subs r1, r1, #1
    bne gps_3x3_loop
    
gps_done:
    pop {r1-r4, pc}

@ ============================================
@ rotate_4x4_CW90
@ Rotate a 4x4 bit-matrix in r0 by 90 degrees CW.
@ Bit packing: bit_index = row*4 + col (row=0 top, col=0 left, LSB=top-left)
@ Registers: r0=in/out (low 16 bits) r1=scratch(t) r2=scratch(mask)
@ Method: Hacker's Delight Ch.7 delta-swap butterfly
@ Formula: rotate_CW = transpose(flip_rows(M))
@ Verified: ALL 2^16 = 65536 inputs -- PASS
@ Count: 35 instructions (0 branches, 0 multiplies, 0 LDR-pseudo)
@ ============================================
rotate_4x4_CW90:
    @ -- Phase 1: flip rows (2 delta-swaps) -------------------------
    @ delta_swap(r0, mask=0x000F, delta=12) -- 4 bit-pair(s)
    lsr r1, r0, #12
    eor r1, r1, r0
    movw r2, #0x000F
    and r1, r1, r2
    eor r0, r0, r1
    lsl r1, r1, #12
    eor r0, r0, r1

    @ delta_swap(r0, mask=0x00F0, delta=4) -- 4 bit-pair(s)
    lsr r1, r0, #4
    eor r1, r1, r0
    movw r2, #0x00F0
    and r1, r1, r2
    eor r0, r0, r1
    lsl r1, r1, #4
    eor r0, r0, r1

    @ -- Phase 2: transpose (3 delta-swaps) -------------------------
    @ delta_swap(r0, mask=0x0842, delta=3) -- 3 bit-pair(s)
    lsr r1, r0, #3
    eor r1, r1, r0
    movw r2, #0x0842
    and r1, r1, r2
    eor r0, r0, r1
    lsl r1, r1, #3
    eor r0, r0, r1

    @ delta_swap(r0, mask=0x0084, delta=6) -- 2 bit-pair(s)
    lsr r1, r0, #6
    eor r1, r1, r0
    movw r2, #0x0084
    and r1, r1, r2
    eor r0, r0, r1
    lsl r1, r1, #6
    eor r0, r0, r1

    @ delta_swap(r0, mask=0x0008, delta=9) -- 1 bit-pair(s)
    lsr r1, r0, #9
    eor r1, r1, r0
    movw r2, #0x0008
    and r1, r1, r2
    eor r0, r0, r1
    lsl r1, r1, #9
    eor r0, r0, r1

    bx lr

@ ============================================
@ rotate_3x3_CW90
@ Rotate a 3x3 bit-matrix in r0 by 90 degrees CW.
@ Bit packing: bit_index = row*3 + col (row=0 top, col=0 left, LSB=top-left)
@ Registers: r0=in/out (low 9 bits) r1=scratch(t) r2=scratch(mask)
@ Method: Hacker's Delight Ch.7 delta-swap butterfly
@ Formula: rotate_CW = transpose(flip_rows(M))
@ Verified: ALL 2^9 = 512 inputs -- PASS
@ Count: 21 instructions (0 branches, 0 multiplies, 0 LDR-pseudo)
@ ============================================
rotate_3x3_CW90:
    @ -- Phase 1: flip rows (1 delta-swap) --------------------------
    @ delta_swap(r0, mask=0x0007, delta=6) -- 3 bit-pair(s)
    lsr r1, r0, #6
    eor r1, r1, r0
    movw r2, #0x0007
    and r1, r1, r2
    eor r0, r0, r1
    lsl r1, r1, #6
    eor r0, r0, r1

    @ -- Phase 2: transpose (2 delta-swaps) -------------------------
    @ delta_swap(r0, mask=0x0022, delta=2) -- 2 bit-pair(s)
    lsr r1, r0, #2
    eor r1, r1, r0
    movw r2, #0x0022
    and r1, r1, r2
    eor r0, r0, r1
    lsl r1, r1, #2
    eor r0, r0, r1

    @ delta_swap(r0, mask=0x0004, delta=4) -- 1 bit-pair(s)
    lsr r1, r0, #4
    eor r1, r1, r0
    movw r2, #0x0004
    and r1, r1, r2
    eor r0, r0, r1
    lsl r1, r1, #4
    eor r0, r0, r1

    bx lr

@ ============================================
@ check_collision - Check if piece collides
@ Input: r0 = type, r1 = x, r2 = y, r3 = rotation
@ Output: r0 = 0 (no collision) or 1 (collision)
@ ============================================
check_collision:
    push {r4-r7, r10-r12, lr}
    mov r4, r0              @ r4 = piece type
    mov r5, r1              @ r5 = x
    mov r6, r2              @ r6 = y
    mov r7, r3              @ r7 = rotation
    
    @ Determine grid size (N) based on piece type
    @ I-piece (type 0) = 4x4, all others = 3x3
    @ Use r12 for grid size (NOT r8!)
    mov r12, #3             @ Default N = 3
    cmp r4, #0
    bne cc_get_shape
    mov r12, #4             @ I-piece: N = 4
    
cc_get_shape:
    @ Get rotated shape
    mov r0, r4
    mov r1, r7
    bl get_piece_shape
    mov r7, r0              @ r7 = shape
    
    @ r12 = N (grid size: 3 or 4)
    mov r4, #0              @ r4 = row (0 to N-1)
    
cc_row_loop:
    mov r10, #0             @ r10 = col (0 to N-1)
    
    @ Calculate row mask: (shape >> (row * N)) & mask
    mov r0, r7
    mov r1, r4
    mul r1, r1, r12         @ r1 = row * N
    lsr r0, r0, r1          @ r0 = shape >> (row * N)
    
    @ Create row mask based on N
    cmp r12, #4
    bne cc_row_mask_3
    and r0, r0, #0xF        @ 4-bit mask
    b cc_row_mask_done
cc_row_mask_3:
    and r0, r0, #0x7        @ 3-bit mask
cc_row_mask_done:
    
    cmp r0, #0
    beq cc_next_row
    
cc_col_loop:
    @ Check if bit at col is set
    @ Bit position = col (matches rotation packing: bit_index = row*N + col)
    mov r11, #1
    lsl r11, r11, r10       @ r11 = 1 << col
    
    tst r0, r11
    beq cc_next_col
    
    @ Calculate board position
    add r1, r6, r4          @ board_y = y + row
    add r2, r5, r10         @ board_x = x + col
    
    @ Bounds check
    cmp r1, #19
    bge cc_hit
    cmp r1, #0
    blt cc_next_col
    cmp r2, #0
    blt cc_hit
    cmp r2, #10
    bge cc_hit
    
    @ Check matrix at (board_y, board_x)
    @ matrix_index = board_y * 10 + board_x
    push {r4, r10, r12}     @ Save row, col, grid_size
    mov r10, r1
    lsl r10, r10, #3        @ board_y * 8
    mov r11, r1
    lsl r11, r11, #1        @ board_y * 2
    add r3, r10, r11        @ board_y * 10
    add r3, r3, r2          @ + board_x
    
    add r3, r3, r9
    add r3, r3, #0x200
    ldrb r3, [r3]
    cmp r3, #0
    pop {r4, r10, r12}      @ Restore row, col, grid_size
    bne cc_hit
    
cc_next_col:
    add r10, r10, #1
    cmp r10, r12
    blt cc_col_loop
    
cc_next_row:
    add r4, r4, #1
    cmp r4, r12
    blt cc_row_loop
    
    @ No collision
    mov r0, #0
    pop {r4-r7, r10-r12, pc}
    
cc_hit:
    mov r0, #1
    pop {r4-r7, r10-r12, pc}

@ ============================================
@ write_piece - Write piece to matrix
@ Input: r0 = type, r1 = x, r2 = y, r3 = rotation, r4 = value
@ ============================================
write_piece:
    push {r4-r7, r10-r12, lr}
    mov r5, r0              @ r5 = piece type
    mov r6, r1              @ r6 = x
    mov r7, r2              @ r7 = y
    mov r10, r3             @ r10 = rotation
    str r4, [sp, #-4]!      @ Push value to write on stack
    
    @ Determine grid size (use r12, NOT r8!)
    mov r12, #3
    cmp r5, #0
    bne wp_get_shape
    mov r12, #4
    
wp_get_shape:
    @ Get rotated shape
    mov r0, r5
    mov r1, r10
    bl get_piece_shape
    mov r10, r0             @ r10 = shape
    
    mov r5, #0              @ r5 = row
    
wp_row_loop:
    @ Calculate row mask
    mov r0, r10
    mov r1, r5
    mul r1, r1, r12         @ row * grid_size
    lsr r0, r0, r1
    
    cmp r12, #4
    bne wp_row_mask_3
    and r0, r0, #0xF
    b wp_row_mask_done
wp_row_mask_3:
    and r0, r0, #0x7
wp_row_mask_done:
    
    cmp r0, #0
    beq wp_next_row
    
    push {r5, r12}          @ Save row and grid_size
    mov r6, #0              @ r6 = col
    
wp_col_loop:
    @ Bit position = col (matches rotation packing)
    mov r2, #1
    lsl r2, r2, r6          @ r2 = 1 << col
    
    tst r0, r2
    beq wp_next_col
    
    @ Calculate board position
    ldr r1, [r9, #0x104]    @ reload x
    ldr r2, [sp, #0]        @ r2 = row from stack (sp+0 after push {r5, r12})
    add r2, r7, r2          @ board_y = y + row
    add r1, r1, r6          @ board_x = x + col
    
    cmp r2, #0
    blt wp_next_col
    cmp r2, #19
    bge wp_next_col
    cmp r1, #0
    blt wp_next_col
    cmp r1, #10
    bge wp_next_col
    
    push {r0}
    lsl r3, r2, #3          @ board_y * 8
    lsl r4, r2, #1          @ board_y * 2
    add r3, r3, r4          @ board_y * 10
    add r3, r3, r1          @ + board_x
    add r3, r3, r9
    add r3, r3, #0x200
    ldr r4, [sp, #12]       @ Get value from stack (offset: pushed r0 + row + grid_size)
    strb r4, [r3]
    pop {r0}
    
wp_next_col:
    add r6, r6, #1
    cmp r6, r12             @ col < grid_size
    blt wp_col_loop
    pop {r5, r12}           @ Restore row and grid_size
    
wp_next_row:
    add r5, r5, #1
    cmp r5, r12             @ row < grid_size
    blt wp_row_loop
    
    add sp, sp, #4          @ Pop value from stack
    pop {r4-r7, r10-r12, pc}

@ ============================================
@ clear_lines - Clear completed lines
@ ============================================
clear_lines:
    push {r4-r8, r10-r11, lr}
    
    mov r4, #19             @ Start from bottom row

cl_row_loop:
    @ Calculate row address
    mov r10, r4
    lsl r10, r10, #3
    mov r11, r4
    lsl r11, r11, #1
    add r5, r10, r11
    add r5, r5, r9
    add r5, r5, #0x200
    
    @ Count filled cells
    mov r6, #0
    mov r7, #0

cl_count_loop:
    ldrb r0, [r5, r7]
    cmp r0, #0
    beq cl_not_filled
    add r6, r6, #1
cl_not_filled:
    add r7, r7, #1
    cmp r7, #10
    blt cl_count_loop
    
    @ Check if line complete
    cmp r6, #10
    bne cl_next_row
    
    @ Add score
    ldr r0, [r9, #0x110]
    add r0, r0, #100
    
    @ Max score check (999999)
    movw r1, #0x423F
    movt r1, #0x000F
    cmp r0, r1
    ble skip_max_out
    mov r0, r1
skip_max_out:
    str r0, [r9, #0x110]
    
    @ Update high score
    ldr r1, [r9, #0x128]
    cmp r0, r1
    ble skip_hi_update
    str r0, [r9, #0x128]
skip_hi_update:
    
    @ Shift rows down
    mov r6, r4

cl_shift_loop:
    cmp r6, #0
    ble cl_clear_top
    
    @ Get current row address
    mov r10, r6
    lsl r10, r10, #3
    mov r11, r6
    lsl r11, r11, #1
    add r5, r10, r11
    add r5, r5, r9
    add r5, r5, #0x200
    
    @ Get row above address
    sub r12, r6, #1
    mov r10, r12
    lsl r10, r10, #3
    mov r11, r12
    lsl r11, r11, #1
    add r7, r10, r11
    add r7, r7, r9
    add r7, r7, #0x200
    
    @ Copy row
    mov r0, #0
cl_copy_loop:
    ldrb r1, [r7, r0]
    strb r1, [r5, r0]
    add r0, r0, #1
    cmp r0, #10
    blt cl_copy_loop
    
    sub r6, r6, #1
    b cl_shift_loop

cl_clear_top:
    @ Clear top row
    add r0, r9, #0x200
    mov r1, #0
    mov r2, #0
cl_clear_loop:
    strb r1, [r0, r2]
    add r2, r2, #1
    cmp r2, #10
    blt cl_clear_loop
    
    b cl_row_loop

cl_next_row:
    subs r4, r4, #1
    bge cl_row_loop
    
    pop {r4-r8, r10-r11, pc}

@ ============================================
@ render - Draw game to VRAM
@ ============================================
render:
    push {r4-r7, r10-r12, lr}
    
    @ Clear VRAM (800 bytes)
    mov r0, #0x20           @ Space character
    mov r1, r8
    mov r2, #800
render_clear_vram:
    strb r0, [r1], #1
    subs r2, r2, #1
    bne render_clear_vram
    
    @ Clear CRAM (800 bytes at 0x30800)
    mov r0, #0x00
    mov r1, r8
    add r1, r1, #0x800
    mov r2, #800
render_clear_cram:
    strb r0, [r1], #1
    subs r2, r2, #1
    bne render_clear_cram
    
    @ Draw walls (gray = color 7)
    mov r4, #0
    mov r5, #124            @ '|' character
    mov r10, #7
render_walls:
    mov r6, r4
    lsl r6, r6, #5
    mov r7, r4
    lsl r7, r7, #3
    add r1, r6, r7          @ Y * 40
    
    @ Left wall
    add r0, r8, r1
    add r0, r0, #14
    strb r5, [r0]
    add r0, r0, #0x800
    strb r10, [r0]
    sub r0, r0, #0x800
    
    @ Right wall
    add r0, r8, r1
    add r0, r0, #25
    strb r5, [r0]
    add r0, r0, #0x800
    strb r10, [r0]
    
    add r4, r4, #1
    cmp r4, #20
    blt render_walls
    
    @ Draw matrix with colors
    mov r4, #0
render_mat_row:
    mov r5, #0
render_mat_col:
    @ Get matrix cell
    mov r6, r4
    lsl r6, r6, #3
    mov r7, r4
    lsl r7, r7, #1
    add r0, r6, r7
    add r0, r0, r5
    add r0, r0, r9
    add r0, r0, #0x200
    ldrb r11, [r0]
    cmp r11, #0
    beq render_mat_next
    
    @ Calculate VRAM address
    mov r6, r4
    lsl r6, r6, #5
    mov r7, r4
    lsl r7, r7, #3
    add r0, r6, r7
    add r0, r0, r5
    add r0, r0, #15
    add r0, r0, r8
    
    @ Draw character
    mov r1, #35             @ '#'
    strb r1, [r0]
    
    @ Draw color
    add r0, r0, #0x800
    strb r11, [r0]

render_mat_next:
    add r5, r5, #1
    cmp r5, #10
    blt render_mat_col
    add r4, r4, #1
    cmp r4, #20
    blt render_mat_row
    
    @ Draw floor
    mov r0, r8
    add r0, r0, #768        @ Row 19 * 40 = 760, + 15 offset = 775
    add r0, r0, #7
    mov r1, #45             @ '-'
    strb r1, [r0]
    strb r1, [r0, #1]
    strb r1, [r0, #2]
    strb r1, [r0, #3]
    strb r1, [r0, #4]
    strb r1, [r0, #5]
    strb r1, [r0, #6]
    strb r1, [r0, #7]
    strb r1, [r0, #8]
    strb r1, [r0, #9]
    
    @ Draw current piece
    ldr r0, [r9, #0x10C]
    ldr r1, [r9, #0x104]
    ldr r2, [r9, #0x108]
    ldr r3, [r9, #0x11C]
    mov r4, #35
    bl draw_piece
    
    @ === DRAW NEXT PIECE ===
    @ "NEXT" label at Y=3, X=27
    mov r0, r8
    add r0, r0, #147        @ 3 * 40 + 27
    mov r1, #78             @ 'N'
    strb r1, [r0]
    mov r1, #69             @ 'E'
    strb r1, [r0, #1]
    mov r1, #88             @ 'X'
    strb r1, [r0, #2]
    mov r1, #84             @ 'T'
    strb r1, [r0, #3]
    mov r1, #3              @ Yellow
    add r0, r0, #0x800
    strb r1, [r0]
    strb r1, [r0, #1]
    strb r1, [r0, #2]
    strb r1, [r0, #3]
    
    @ Draw next piece preview
    ldr r5, [r9, #0x124]    @ next piece type
    add r11, r5, #1         @ color
    
    @ Get shape (rotation 0)
    mov r0, r5
    mov r1, #0
    bl get_piece_shape
    mov r12, r0             @ r12 = shape
    
    @ Determine grid size for next piece (use r2, NOT r8!)
    mov r2, #3              @ r2 = grid size (default 3)
    cmp r5, #0
    bne np_draw
    mov r2, #4              @ I-piece: grid size 4
    
np_draw:
    mov r3, #0              @ row
np_row_loop:
    @ Calculate row mask
    mov r0, r12
    mov r1, r3
    mul r1, r1, r2          @ row * grid_size
    lsr r0, r0, r1
    
    cmp r2, #4
    bne np_row_mask_3
    and r4, r0, #0xF
    b np_row_mask_done
np_row_mask_3:
    and r4, r0, #0x7
np_row_mask_done:
    
    cmp r4, #0
    beq np_next_row
    
    push {r2, r3}           @ Save grid size and row
    mov r5, #0              @ col
np_col_loop:
    @ Bit position = col (matches rotation packing)
    mov r1, #1
    lsl r1, r1, r5          @ r1 = 1 << col
    tst r4, r1
    beq np_next_col
    
    @ Calculate VRAM address: Y = row+5, X = col+32
    @ offset = (row+5)*40 + 32 + col
    ldr r0, [sp, #4]        @ r0 = row (from stack)
    add r0, r0, #5          @ row + 5
    lsl r1, r0, #5          @ (row+5) * 32
    lsl r0, r0, #3          @ (row+5) * 8
    add r0, r0, r1          @ (row+5) * 40
    add r0, r0, #32         @ + X base
    add r0, r0, r5          @ + col
    add r0, r0, r8          @ + VRAM base
    mov r1, #35
    strb r1, [r0]
    
    @ Draw color
    add r0, r0, #0x800
    strb r11, [r0]

np_next_col:
    add r5, r5, #1
    cmp r5, r2              @ col < grid_size
    blt np_col_loop
    pop {r2, r3}            @ Restore grid size and row
    
np_next_row:
    add r3, r3, #1
    cmp r3, r2              @ row < grid_size
    blt np_row_loop
    
    @ === GAME OVER TEXT ===
    ldr r0, [r9, #0x118]
    cmp r0, #1
    bne render_score
    
    @ Draw "GAME OVER" at Y=10, X=15
    mov r0, r8
    movw r1, #415           @ 10*40 + 15
    add r0, r0, r1
    mov r1, #71             @ 'G'
    strb r1, [r0]
    mov r1, #65             @ 'A'
    strb r1, [r0, #1]
    mov r1, #77             @ 'M'
    strb r1, [r0, #2]
    mov r1, #69             @ 'E'
    strb r1, [r0, #3]
    mov r1, #32             @ ' '
    strb r1, [r0, #4]
    mov r1, #79             @ 'O'
    strb r1, [r0, #5]
    mov r1, #86             @ 'V'
    strb r1, [r0, #6]
    mov r1, #69             @ 'E'
    strb r1, [r0, #7]
    mov r1, #82             @ 'R'
    strb r1, [r0, #8]
    mov r1, #1              @ Red
    add r0, r0, #0x800
    strb r1, [r0]
    strb r1, [r0, #1]
    strb r1, [r0, #2]
    strb r1, [r0, #3]
    strb r1, [r0, #4]
    strb r1, [r0, #5]
    strb r1, [r0, #6]
    strb r1, [r0, #7]
    strb r1, [r0, #8]
    
render_score:
    @ "HI" label
    mov r0, r8
    add r0, r0, #27
    mov r1, #72             @ 'H'
    strb r1, [r0]
    mov r1, #73             @ 'I'
    strb r1, [r0, #1]
    mov r1, #3              @ Yellow
    add r0, r0, #0x800
    strb r1, [r0]
    strb r1, [r0, #1]
    
    @ High score
    ldr r0, [r9, #0x128]
    mov r1, r8
    add r1, r1, #33
    bl print_number
    
    @ "SCORE" label
    mov r0, r8
    add r0, r0, #67         @ 1*40 + 27
    mov r1, #83             @ 'S'
    strb r1, [r0]
    mov r1, #67             @ 'C'
    strb r1, [r0, #1]
    mov r1, #79             @ 'O'
    strb r1, [r0, #2]
    mov r1, #82             @ 'R'
    strb r1, [r0, #3]
    mov r1, #69             @ 'E'
    strb r1, [r0, #4]
    mov r1, #3
    add r0, r0, #0x800
    strb r1, [r0]
    strb r1, [r0, #1]
    strb r1, [r0, #2]
    strb r1, [r0, #3]
    strb r1, [r0, #4]
    
    @ Current score
    ldr r0, [r9, #0x110]
    mov r1, r8
    add r1, r1, #73         @ 1*40 + 33
    bl print_number
    
    @ "LV" label
    mov r0, r8
    add r0, r0, #107        @ 2*40 + 27
    mov r1, #76             @ 'L'
    strb r1, [r0]
    mov r1, #86             @ 'V'
    strb r1, [r0, #1]
    mov r1, #3
    add r0, r0, #0x800
    strb r1, [r0]
    strb r1, [r0, #1]
    
    @ Level
    ldr r0, [r9, #0x110]
    lsr r0, r0, #9          @ Level = Score / 512
    mov r1, r8
    add r1, r1, #113        @ 2*40 + 33
    bl print_number
    
    @ TETRIS logo (vertical)
    mov r6, r8
    add r7, r8, #0x800
    
    @ T - Y=4
    mov r0, #84
    mov r1, #1              @ Red
    mov r2, #166            @ 4*40+6
    strb r0, [r6, r2]
    strb r1, [r7, r2]
    
    @ E - Y=6
    mov r0, #69
    mov r1, #3              @ Yellow
    mov r2, #246            @ 6*40+6
    strb r0, [r6, r2]
    strb r1, [r7, r2]
    
    @ T - Y=8
    mov r0, #84
    mov r1, #2              @ Green
    mov r2, #326            @ 8*40+6
    strb r0, [r6, r2]
    strb r1, [r7, r2]
    
    @ R - Y=10
    mov r0, #82
    mov r1, #6              @ Cyan
    mov r2, #406            @ 10*40+6
    strb r0, [r6, r2]
    strb r1, [r7, r2]
    
    @ I - Y=12
    mov r0, #73
    mov r1, #4              @ Blue
    mov r2, #486            @ 12*40+6
    strb r0, [r6, r2]
    strb r1, [r7, r2]
    
    @ S - Y=14
    mov r0, #83
    mov r1, #5              @ Magenta
    mov r2, #566            @ 14*40+6
    strb r0, [r6, r2]
    strb r1, [r7, r2]
    
    @ VSYNC
    movw r0, #0x0008
    movt r0, #0x0004
    mov r1, #1
    str r1, [r0]
    
    pop {r4-r7, r10-r12, pc}

@ ============================================
@ draw_piece - Draw piece to VRAM
@ Input: r0 = type, r1 = x, r2 = y, r3 = rotation, r4 = char
@ ============================================
draw_piece:
    push {r4-r7, r10-r12, lr}
    
    @ Bounds check
    cmp r0, #6
    movhi r0, #0
    
    mov r5, r0              @ r5 = piece type
    mov r6, r1              @ r6 = x
    mov r7, r2              @ r7 = y
    mov r10, r3             @ r10 = rotation
    mov r11, r4             @ r11 = char
    
    @ Calculate color
    add r4, r5, #1
    push {r4}
    
    @ Determine grid size (use r12, NOT r8!)
    mov r12, #3
    cmp r5, #0
    bne dp_get_shape
    mov r12, #4
    
dp_get_shape:
    @ Get shape
    mov r0, r5
    mov r1, r10
    bl get_piece_shape
    mov r10, r0             @ r10 = shape
    
    pop {r4}                @ r4 = color
    mov r5, #0              @ r5 = row
    
dp_row_loop:
    @ Calculate row mask
    mov r0, r10
    mov r1, r5
    mul r1, r1, r12         @ row * grid_size
    lsr r0, r0, r1
    
    cmp r12, #4
    bne dp_row_mask_3
    and r0, r0, #0xF
    b dp_row_mask_done
dp_row_mask_3:
    and r0, r0, #0x7
dp_row_mask_done:
    
    cmp r0, #0
    beq dp_next_row
    
    push {r5, r12}          @ Save row and grid_size
    mov r6, #0              @ r6 = col
    
dp_col_loop:
    @ Bit position = col (matches rotation packing)
    mov r2, #1
    lsl r2, r2, r6          @ r2 = 1 << col
    
    tst r0, r2
    beq dp_next_col
    
    ldr r1, [r9, #0x104]    @ reload x
    ldr r2, [sp, #0]        @ r2 = row from stack (sp+0 after push {r5, r12})
    add r2, r7, r2          @ board_y = y + row
    
    cmp r2, #0
    blt dp_next_col
    cmp r2, #19
    bge dp_next_col
    
    add r1, r1, r6          @ board_x = x + col
    cmp r1, #0
    blt dp_next_col
    cmp r1, #10
    bge dp_next_col
    
    push {r0}
    lsl r0, r2, #5          @ board_y * 32
    lsl r3, r2, #3          @ board_y * 8
    add r0, r0, r3          @ board_y * 40
    add r0, r0, r1          @ + board_x
    add r0, r0, #15         @ + VRAM X offset
    add r0, r0, r8          @ + VRAM base
    strb r11, [r0]
    
    add r0, r0, #0x800
    strb r4, [r0]
    pop {r0}
    
dp_next_col:
    add r6, r6, #1
    cmp r6, r12             @ col < grid_size
    blt dp_col_loop
    pop {r5, r12}           @ Restore row and grid_size
    
dp_next_row:
    add r5, r5, #1
    cmp r5, r12             @ row < grid_size
    blt dp_row_loop
    
    pop {r4-r7, r10-r12, pc}

@ ============================================
@ get_random_piece - Branchless uniform PRNG
@ Returns: r0 = piece type (0-6) with uniform 1/7 probability
@ Uses Xorshift32 PRNG + magic multiplier division by 7
@ ============================================
get_random_piece:
    @ Load PRNG state
    ldr r0, [r9, #0x134]
    
    @ Xorshift32 Form B: explicit LSL/LSR before each EOR
    @ Triple (13, 17, 5) - Marsaglia's validated constants
    lsl r1, r0, #13
    eor r0, r0, r1          @ r0 ^= r0 << 13
    lsr r1, r0, #17
    eor r0, r0, r1          @ r0 ^= r0 >> 17
    lsl r1, r0, #5
    eor r0, r0, r1          @ r0 ^= r0 << 5
    
    @ Store updated state
    str r0, [r9, #0x134]
    
    @ -----------------------------------------------------------------------
    @ UNIFORM MODULO 7 using magic multiplier
    @ Magic = 0x24924925, shift = 2, is_add = True (Warren fixup)
    @ Formula: result = (t1 + (n-t1)>>1) >> 2 where t1 = mulhi(n, magic)
    @ -----------------------------------------------------------------------
    @ r0 = n (input), r1 = magic, r2 = t1 (mulhi), r3 = temp
    push {r4}
    mov r4, r0              @ Save n in r4
    
    @ Load magic constant
    movw r1, #0x4925
    movt r1, #0x2492        @ r1 = 0x24924925
    
    @ Unsigned multiply long: r2 = high 32 bits of (n * magic)
    umull r3, r2, r4, r1    @ r2 = t1 = mulhi(n, magic)
    
    @ Warren fixup: temp = (n - t1) >> 1
    sub r3, r4, r2          @ r3 = n - t1
    lsr r3, r3, #1          @ r3 = (n - t1) >> 1
    
    @ result = (t1 + temp) >> 2
    add r2, r2, r3          @ r2 = t1 + temp
    lsr r2, r2, #2          @ r2 = quotient = n // 7
    
    @ Compute modulo: remainder = n - (quotient * 7)
    mov r3, #7
    mul r3, r2, r3          @ r3 = quotient * 7
    sub r0, r4, r3          @ r0 = n - (quotient * 7) = n % 7
    
    pop {r4}
    bx lr

@ ============================================
@ print_number - Print 6-digit number
@ Input: r0 = number, r1 = VRAM address
@ ============================================
print_number:
    push {r2-r7, r12, lr}
    
    @ Build divisor table on stack
    mov r2, #1
    push {r2}
    mov r2, #10
    push {r2}
    mov r2, #100
    push {r2}
    movw r2, #1000
    push {r2}
    movw r2, #10000
    push {r2}
    movw r2, #0x86A0
    movt r2, #0x0001        @ 100000
    push {r2}
    
    @ Initialize loop
    mov r4, r0              @ number
    mov r5, #6              @ digit count
    mov r6, r1              @ VRAM address
    mov r7, sp              @ divisor pointer
    mov r12, #0             @ leading zero flag

pn_loop:
    ldr r2, [r7], #4
    mov r3, #0

pn_div:
    cmp r4, r2
    blt pn_digit_done
    sub r4, r4, r2
    add r3, r3, #1
    b pn_div

pn_digit_done:
    @ Leading zero handling
    cmp r3, #0
    bne pn_non_zero
    cmp r12, #0
    bne pn_write_digit
    cmp r5, #1
    beq pn_write_digit
    
    mov r3, #32             @ Space
    b pn_store

pn_non_zero:
    mov r12, #1

pn_write_digit:
    add r3, r3, #48         @ ASCII '0'

pn_store:
    strb r3, [r6]
    mov r2, #6              @ Cyan
    movw r3, #0x800
    add r3, r6, r3
    strb r2, [r3]
    add r6, r6, #1
    subs r5, r5, #1
    bne pn_loop
    
    @ Clean up stack
    add sp, sp, #24
    pop {r2-r7, r12, pc}

@ END