@ ============================================
@ Tetris Phase 13 - All Critical Fixes
@ ============================================

@ === MEMORY MAP ===
@ 0x10000: ROM (code)
@ 0x20000: RAM base
@ 0x20100: Game state
@ 0x20200: Matrix (10 wide, 20 tall)
@ 0x20300: Tetromino definitions (7 pieces * 4 rotations * 4 bytes = 112 bytes)
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
@ [r9, #0x134] = PRNG state (xorshift32)

@ === ENTRY POINT ===
_start:
    movw sp, #0x8000
    movt sp, #0x0002
    
    movw r8, #0x0000
    movt r8, #0x0003
    
    movw r9, #0x0000
    movt r9, #0x0002
    
    @ Check if initialized
    ldr r0, [r9, #0x100]
    cmp r0, #0
    bne main_loop
    
    @ Initialize
    mov r0, #1
    str r0, [r9, #0x100]
    
    @ ========================================
    @ Initialize Tetromino definitions at 0x20300
    @ CORRECTED LUT DATA
    @ ========================================
    
    @ === I-PIECE (0x300) ===
    add r0, r9, #0x300
    @ Rot 0: 0x0F,0x00,0x00,0x00
    mov r1, #0x0F
    strb r1, [r0, #0]
    mov r1, #0x00
    strb r1, [r0, #1]
    strb r1, [r0, #2]
    strb r1, [r0, #3]
    @ Rot 1: 0x02,0x02,0x02,0x02
    mov r1, #0x02
    strb r1, [r0, #4]
    strb r1, [r0, #5]
    strb r1, [r0, #6]
    strb r1, [r0, #7]
    @ Rot 2: 0x00,0x00,0x0F,0x00
    mov r1, #0x00
    strb r1, [r0, #8]
    strb r1, [r0, #9]
    mov r1, #0x0F
    strb r1, [r0, #10]
    mov r1, #0x00
    strb r1, [r0, #11]
    @ Rot 3: 0x04,0x04,0x04,0x04
    mov r1, #0x04
    strb r1, [r0, #12]
    strb r1, [r0, #13]
    strb r1, [r0, #14]
    strb r1, [r0, #15]
    
    @ === J-PIECE (0x310) ===
    add r0, r9, #0x310
    @ Rot 0: 0x04,0x07,0x00,0x00
    mov r1, #0x04
    strb r1, [r0, #0]
    mov r1, #0x07
    strb r1, [r0, #1]
    mov r1, #0x00
    strb r1, [r0, #2]
    strb r1, [r0, #3]
    @ Rot 1: 0x03,0x02,0x02,0x00
    mov r1, #0x03
    strb r1, [r0, #4]
    mov r1, #0x02
    strb r1, [r0, #5]
    strb r1, [r0, #6]
    mov r1, #0x00
    strb r1, [r0, #7]
    @ Rot 2: 0x00,0x07,0x01,0x00
    mov r1, #0x00
    strb r1, [r0, #8]
    mov r1, #0x07
    strb r1, [r0, #9]
    mov r1, #0x01
    strb r1, [r0, #10]
    mov r1, #0x00
    strb r1, [r0, #11]
    @ Rot 3: 0x02,0x02,0x06,0x00
    mov r1, #0x02
    strb r1, [r0, #12]
    strb r1, [r0, #13]
    mov r1, #0x06
    strb r1, [r0, #14]
    mov r1, #0x00
    strb r1, [r0, #15]
    
    @ === L-PIECE (0x320) ===
    add r0, r9, #0x320
    @ Rot 0: 0x01,0x07,0x00,0x00
    mov r1, #0x01
    strb r1, [r0, #0]
    mov r1, #0x07
    strb r1, [r0, #1]
    mov r1, #0x00
    strb r1, [r0, #2]
    strb r1, [r0, #3]
    @ Rot 1: 0x02,0x02,0x03,0x00
    mov r1, #0x02
    strb r1, [r0, #4]
    strb r1, [r0, #5]
    mov r1, #0x03
    strb r1, [r0, #6]
    mov r1, #0x00
    strb r1, [r0, #7]
    @ Rot 2: 0x00,0x07,0x04,0x00
    mov r1, #0x00
    strb r1, [r0, #8]
    mov r1, #0x07
    strb r1, [r0, #9]
    mov r1, #0x04
    strb r1, [r0, #10]
    mov r1, #0x00
    strb r1, [r0, #11]
    @ Rot 3: 0x06,0x02,0x02,0x00
    mov r1, #0x06
    strb r1, [r0, #12]
    mov r1, #0x02
    strb r1, [r0, #13]
    strb r1, [r0, #14]
    mov r1, #0x00
    strb r1, [r0, #15]
    
    @ === O-PIECE (0x330) - Same for all rotations ===
    add r0, r9, #0x330
    @ Rot 0: 0x06,0x06,0x00,0x00
    mov r1, #0x06
    strb r1, [r0, #0]
    strb r1, [r0, #1]
    mov r1, #0x00
    strb r1, [r0, #2]
    strb r1, [r0, #3]
    @ Rot 1: same
    mov r1, #0x06
    strb r1, [r0, #4]
    strb r1, [r0, #5]
    mov r1, #0x00
    strb r1, [r0, #6]
    strb r1, [r0, #7]
    @ Rot 2: same
    mov r1, #0x06
    strb r1, [r0, #8]
    strb r1, [r0, #9]
    mov r1, #0x00
    strb r1, [r0, #10]
    strb r1, [r0, #11]
    @ Rot 3: same
    mov r1, #0x06
    strb r1, [r0, #12]
    strb r1, [r0, #13]
    mov r1, #0x00
    strb r1, [r0, #14]
    strb r1, [r0, #15]
    
    @ === S-PIECE (0x340) ===
    add r0, r9, #0x340
    @ Rot 0: 0x03,0x06,0x00,0x00
    mov r1, #0x03
    strb r1, [r0, #0]
    mov r1, #0x06
    strb r1, [r0, #1]
    mov r1, #0x00
    strb r1, [r0, #2]
    strb r1, [r0, #3]
    @ Rot 1: 0x04,0x06,0x02,0x00
    mov r1, #0x04
    strb r1, [r0, #4]
    mov r1, #0x06
    strb r1, [r0, #5]
    mov r1, #0x02
    strb r1, [r0, #6]
    mov r1, #0x00
    strb r1, [r0, #7]
    @ Rot 2: 0x00,0x03,0x06,0x00
    mov r1, #0x00
    strb r1, [r0, #8]
    mov r1, #0x03
    strb r1, [r0, #9]
    mov r1, #0x06
    strb r1, [r0, #10]
    mov r1, #0x00
    strb r1, [r0, #11]
    @ Rot 3: 0x02,0x03,0x01,0x00
    mov r1, #0x02
    strb r1, [r0, #12]
    mov r1, #0x03
    strb r1, [r0, #13]
    mov r1, #0x01
    strb r1, [r0, #14]
    mov r1, #0x00
    strb r1, [r0, #15]
    @ === T-PIECE (0x350) ===
    add r0, r9, #0x350
    @ Rot 0: 0x02,0x07,0x00,0x00
    mov r1, #0x02
    strb r1, [r0, #0]
    mov r1, #0x07
    strb r1, [r0, #1]
    mov r1, #0x00
    strb r1, [r0, #2]
    strb r1, [r0, #3]
    @ Rot 1: 0x02, 0x03, 0x02, 0x00
    mov r1, #0x02
    strb r1, [r0, #4]
    mov r1, #0x03
    strb r1, [r0, #5]
    mov r1, #0x02
    strb r1, [r0, #6]
    mov r1, #0x00
    strb r1, [r0, #7]
    @ Rot 2: 0x00,0x07,0x02,0x00
    mov r1, #0x00
    strb r1, [r0, #8]
    mov r1, #0x07
    strb r1, [r0, #9]
    mov r1, #0x02
    strb r1, [r0, #10]
    mov r1, #0x00
    strb r1, [r0, #11]
    @ Rot 3: 0x02, 0x06, 0x02, 0x00
    mov r1, #0x02
    strb r1, [r0, #12]
    mov r1, #0x06
    strb r1, [r0, #13]
    mov r1, #0x02
    strb r1, [r0, #14]
    mov r1, #0x00
    strb r1, [r0, #15]

    @ === Z-PIECE (0x360) ===
    add r0, r9, #0x360
    @ Rot 0: 0x06,0x03,0x00,0x00
    mov r1, #0x06
    strb r1, [r0, #0]
    mov r1, #0x03
    strb r1, [r0, #1]
    mov r1, #0x00
    strb r1, [r0, #2]
    strb r1, [r0, #3]
    @ Rot 1: 0x02,0x06,0x04,0x00
    mov r1, #0x02
    strb r1, [r0, #4]
    mov r1, #0x06
    strb r1, [r0, #5]
    mov r1, #0x04
    strb r1, [r0, #6]
    mov r1, #0x00
    strb r1, [r0, #7]
    @ Rot 2: 0x00,0x06,0x03,0x00
    mov r1, #0x00
    strb r1, [r0, #8]
    mov r1, #0x06
    strb r1, [r0, #9]
    mov r1, #0x03
    strb r1, [r0, #10]
    mov r1, #0x00
    strb r1, [r0, #11]
    @ Rot 3: 0x01,0x03,0x02,0x00
    mov r1, #0x01
    strb r1, [r0, #12]
    mov r1, #0x03
    strb r1, [r0, #13]
    mov r1, #0x02
    strb r1, [r0, #14]
    mov r1, #0x00
    strb r1, [r0, #15]
    
    @ Clear game state
reset_game:
    mov r0, #0
    str r0, [r9, #0x104]
    str r0, [r9, #0x108]
    str r0, [r9, #0x10C]
    str r0, [r9, #0x110]
    str r0, [r9, #0x114]
    str r0, [r9, #0x118]
    str r0, [r9, #0x11C]
    str r0, [r9, #0x120]
    
    @ Initialize position
    mov r0, #3
    str r0, [r9, #0x104]
    mov r0, #0
    str r0, [r9, #0x108]
    
    @ Clear Matrix (200 bytes)
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
    
    @ Arvo ensimmainen NEXT-palikka
    bl get_random_piece
    str r0, [r9, #0x124]   @ Tallenna ensimmainen NEXT-palikka
    
    @ Spawn first piece
    bl spawn_piece

main_loop:
    ldr r0, [r9, #0x118]
    cmp r0, #1
    beq game_over_loop
    
    @ === NORMAL GAME LOOP ===
    ldr r0, [r9, #0x114]
    add r0, r0, #1
    str r0, [r9, #0x114]
    
    @ Check for soft drop
    movw r0, #0x0000
    movt r0, #0x0004
    ldr r4, [r0]
    tst r4, #2
    beq check_gravity
    
    mov r0, #100
    str r0, [r9, #0x114]
    b do_gravity
    
check_gravity:
    ldr r0, [r9, #0x114]  @ r0 = gravity counter
    ldr r1, [r9, #0x110]  @ r1 = score
    lsr r1, r1, #9        @ r1 = level (score jaettuna n. 512:lla)
    mov r12, #20
    sub r12, r12, r1      @ r12 = 20 - level
    cmp r12, #2           @ Rajoita maksiminopeus (minimi kynnys on 2)
    bge apply_thresh
    mov r12, #2
apply_thresh:
    cmp r0, r12
    blt skip_gravity
    
do_gravity:
    mov r0, #0
    str r0, [r9, #0x114]
    
    ldr r0, [r9, #0x10C]
    ldr r1, [r9, #0x104]
    ldr r2, [r9, #0x108]
    ldr r3, [r9, #0x11C]
    add r2, r2, #1
    bl check_collision
    cmp r0, #0
    bne do_lock
    
    ldr r0, [r9, #0x108]
    add r0, r0, #1
    str r0, [r9, #0x108]
    b skip_gravity

do_lock:
    ldr r0, [r9, #0x10C]
    ldr r1, [r9, #0x104]
    ldr r2, [r9, #0x108]
    ldr r3, [r9, #0x11C]
    ldr r4, [r9, #0x10C]
    add r4, r4, #1        @ type + 1 (0 = empty, 1-7 = pieces)
    bl write_piece
    bl clear_lines
    bl spawn_piece
    bl render
    b main_loop

skip_gravity:
    movw r0, #0x0000
    movt r0, #0x0004
    ldr r4, [r0]            @ r4 = controller state
    
    @ === HARD DROP CHECK (Space = bit 4) ===
    tst r4, #16
    beq clear_hd_debounce   @ If space NOT pressed, clear debounce and check rotation
    
    @ If space IS pressed, check debounce
    ldr r0, [r9, #0x12C]
    cmp r0, #0
    bne skip_debounce       @ If debounce active, ignore input
    
    @ Set debounce active
    mov r0, #1
    str r0, [r9, #0x12C]
    
hd_loop:
    ldr r0, [r9, #0x10C]    @ type
    ldr r1, [r9, #0x104]    @ x
    ldr r2, [r9, #0x108]    @ y
    ldr r3, [r9, #0x11C]    @ rot
    add r2, r2, #1          @ try Y + 1
    bl check_collision
    cmp r0, #0
    bne hd_hit              @ If collision, lock it
    
    @ No collision: Update Y and add 2 points
    ldr r2, [r9, #0x108]
    add r2, r2, #1
    str r2, [r9, #0x108]
    
    ldr r0, [r9, #0x110]
    add r0, r0, #2          @ 2 points per hard drop cell!
    str r0, [r9, #0x110]
    b hd_loop
    
hd_hit:
    @ Update High Score if needed (hard drop points were added)
    ldr r0, [r9, #0x110]    @ Current score
    ldr r1, [r9, #0x128]    @ High score
    cmp r0, r1
    ble hd_no_hi_update
    str r0, [r9, #0x128]    @ Update high score
hd_no_hi_update:
    b do_lock               @ Lock instantly
clear_hd_debounce:
    mov r0, #0
    str r0, [r9, #0x12C]

skip_debounce:
    @ === ROTATION CHECK (Up = bit 0) ===
    tst r4, #1
    beq check_left
    
    ldr r0, [r9, #0x120]
    cmp r0, #0
    bne check_left
    
    mov r0, #10
    str r0, [r9, #0x120]
    
    @ Calculate new rotation: (current + 1) AND 3
    ldr r0, [r9, #0x11C]
    add r0, r0, #1
    and r0, r0, #3
    
    @ Aseta argumentit OIKEIN check_collision -funktiolle
    mov r3, r0           @ r3 = uusi rotaatio
    mov r5, r0           @ tallenna uusi rotaatio r5:een talteen
    ldr r0, [r9, #0x10C] @ r0 = type
    ldr r1, [r9, #0x104] @ r1 = x
    ldr r2, [r9, #0x108] @ r2 = y
    bl check_collision
    cmp r0, #0
    bne check_left
    
    str r5, [r9, #0x11C]
    b skip_debounce

check_left:
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
    ldr r0, [r9, #0x120]
    cmp r0, #0
    beq skip_rot_debounce
    sub r0, r0, #1
    str r0, [r9, #0x120]
skip_rot_debounce:

    bl render
    b main_loop

game_over_loop:
    movw r0, #0x0000
    movt r0, #0x0004
    ldr r1, [r0]
    
    tst r1, #16             @ Is Space pressed?
    beq go_clear_debounce   @ If NOT pressed, clear the flag
    
    @ If Space IS pressed, check if it was already held down
    ldr r2, [r9, #0x12C]
    cmp r2, #0
    bne go_skip_input       @ If flag is 1 (held down from before), ignore!
    
    @ If flag is 0 and Space is pressed -> Restart!
    b reset_game
    
go_clear_debounce:
    mov r2, #0
    str r2, [r9, #0x12C]    @ Player released Space, safe to restart next press
    
go_skip_input:
    bl render
    b game_over_loop


@ ============================================
@ spawn_piece
@ ============================================
spawn_piece:
    push {r4-r7, lr}
    
    ldr r0, [r9, #0x124]   @ Hae next piece
    
    @ BOUNDS CHECK: Clamp piece type to 0-6 (defensive fix for garbage in memory)
    cmp r0, #6
    bls sp_type_ok
    mov r0, #0             @ Clamp garbage to 0
sp_type_ok:
    str r0, [r9, #0x10C]   @ Aseta se nykyiseksi palikaksi
    
    bl get_random_piece    @ Arvo uusi next piece
    
    @ BOUNDS CHECK: Clamp new next piece to 0-6
    cmp r0, #6
    bls sp_next_ok
    mov r0, #0
sp_next_ok:
    str r0, [r9, #0x124]   @ Tallenna se odottamaan
    
    @ Reset rotation to 0
    mov r0, #0
    str r0, [r9, #0x11C]
    
    mov r0, #3
    str r0, [r9, #0x104]
    mov r0, #0
    str r0, [r9, #0x108]
    
    ldr r0, [r9, #0x10C]
    ldr r1, [r9, #0x104]
    ldr r2, [r9, #0x108]
    ldr r3, [r9, #0x11C]
    bl check_collision
    cmp r0, #0
    beq spawn_done
    
    mov r0, #1
    str r0, [r9, #0x118]

spawn_done:
    pop {r4-r7, pc}

@ ============================================
@ check_collision - FIXED: Y < 19 (not 20)
@ ============================================
check_collision:
    push {r4-r8, r10-r12, lr}
    mov r4, r0
    mov r5, r1
    mov r6, r2
    mov r7, r3
    
    lsl r0, r4, #4
    lsl r1, r7, #2
    add r0, r0, r1
    add r0, r0, r9
    add r7, r0, #0x300
    
    mov r4, #0
cc_row_loop:
    ldrb r0, [r7, r4]
    cmp r0, #0
    beq cc_next_row
    
    mov r8, #0
    mov r12, #8
cc_col_loop:
    tst r0, r12
    beq cc_next_col
    
    add r1, r6, r4
    add r2, r5, r8
    
    @ FIXED: cmp r1, #19 (not 20)
    cmp r1, #19
    bge cc_hit
    cmp r1, #0
    blt cc_next_col
    cmp r2, #0
    blt cc_hit
    cmp r2, #10
    bge cc_hit
    
    mov r10, r1
    lsl r10, r10, #3
    mov r11, r1
    lsl r11, r11, #1
    add r3, r10, r11
    add r3, r3, r2
    
    add r3, r3, r9
    add r3, r3, #0x200
    ldrb r3, [r3]
    cmp r3, #0
    bne cc_hit
    
cc_next_col:
    lsr r12, r12, #1
    add r8, r8, #1
    cmp r8, #4
    blt cc_col_loop
cc_next_row:
    add r4, r4, #1
    cmp r4, #4
    blt cc_row_loop
    
    mov r0, #0
    pop {r4-r8, r10-r12, pc}
cc_hit:
    mov r0, #1
    pop {r4-r8, r10-r12, pc}

@ ============================================
@ write_piece - FIXED: Y < 19
@ ============================================
write_piece:
    push {r4-r7, r10-r11, lr}
    mov r5, r0
    mov r6, r1
    mov r7, r2
    mov r0, r3
    mov r1, r4
    
    lsl r2, r5, #4
    lsl r3, r0, #2
    add r2, r2, r3
    add r2, r2, r9
    add r2, r2, #0x300
    
    mov r3, #0
wp_row_loop:
    ldrb r4, [r2, r3]
    cmp r4, #0
    beq wp_next_row
    
    push {r3}
    mov r5, #0
    mov r12, #8
wp_col_loop:
    tst r4, r12
    beq wp_next_col
    
    add r0, r7, r3
    add r11, r6, r5
    
    cmp r0, #0
    blt wp_next_col
    @ FIXED: cmp r0, #19
    cmp r0, #19
    bge wp_next_col
    cmp r11, #0
    blt wp_next_col
    cmp r11, #10
    bge wp_next_col
    
    push {r0}
    mov r10, r0
    lsl r0, r0, #3
    lsl r10, r10, #1
    add r0, r0, r10
    add r0, r0, r11
    add r0, r0, r9
    add r0, r0, #0x200
    strb r1, [r0]
    pop {r0}
    
wp_next_col:
    lsr r12, r12, #1
    add r5, r5, #1
    cmp r5, #4
    blt wp_col_loop
    pop {r3}
    
wp_next_row:
    add r3, r3, #1
    cmp r3, #4
    blt wp_row_loop
    
    pop {r4-r7, r10-r11, pc}

@ ============================================
@ clear_lines
@ ============================================
clear_lines:
    push {r4-r8, r10-r11, lr}
    
    mov r4, #19

cl_row_loop:
    mov r10, r4
    lsl r10, r10, #3
    mov r11, r4
    lsl r11, r11, #1
    add r5, r10, r11
    add r5, r5, r9
    add r5, r5, #0x200
    
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
    
    cmp r6, #10
    bne cl_next_row
    
    ldr r0, [r9, #0x110]
    add r0, r0, #100
    
    @ Max-out check (999999)
    movw r1, #0x423F
    movt r1, #0x000F       @ r1 = 999999
    cmp r0, r1
    ble skip_max_out
    mov r0, r1             @ Jos yli, lukitse maksimiin
skip_max_out:
    str r0, [r9, #0x110]
    
    @ Paivita High Score tarvittaessa
    ldr r1, [r9, #0x128]
    cmp r0, r1
    ble skip_hi_update
    str r0, [r9, #0x128]
skip_hi_update:
    
    mov r6, r4

cl_shift_loop:
    cmp r6, #0
    ble cl_clear_top
    
    mov r10, r6
    lsl r10, r10, #3
    mov r11, r6
    lsl r11, r11, #1
    add r5, r10, r11
    add r5, r5, r9
    add r5, r5, #0x200
    
    sub r12, r6, #1
    mov r10, r12
    lsl r10, r10, #3
    mov r11, r12
    lsl r11, r11, #1
    add r7, r10, r11
    add r7, r7, r9
    add r7, r7, #0x200
    
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
@ render - FIXED: Game Over in render
@ ============================================
render:
    push {r4-r7, r10-r12, lr}
    
    @ Clear VRAM (800 bytes)
    mov r0, #0x20
    mov r1, r8
    mov r2, #800
render_clear_vram:
    strb r0, [r1], #1
    subs r2, r2, #1
    bne render_clear_vram
    
    @ Clear CRAM (800 bytes at 0x30800)
    @ Use r1 as pointer, calculate CRAM base properly
    mov r0, #0x00
    mov r1, r8
    add r1, r1, #0x200    @ 0x30200
    add r1, r1, #0x200    @ 0x30400
    add r1, r1, #0x200    @ 0x30600
    add r1, r1, #0x200    @ 0x30800 = CRAM base
    mov r2, #800
render_clear_cram:
    strb r0, [r1], #1
    subs r2, r2, #1
    bne render_clear_cram
    
    @ Draw walls (gray = color 7)
    mov r4, #0
    mov r5, #124
    mov r10, #7           @ Gray color
render_walls:
    mov r6, r4
    lsl r6, r6, #5
    mov r7, r4
    lsl r7, r7, #3
    add r1, r6, r7
    
    @ Left wall - VRAM
    add r0, r8, r1
    add r0, r0, #14
    strb r5, [r0]
    @ Left wall - CRAM (VRAM + 0x800)
    add r0, r0, #0x800
    strb r10, [r0]
    sub r0, r0, #0x800
    
    @ Right wall - VRAM
    add r0, r8, r1
    add r0, r0, #25
    strb r5, [r0]
    @ Right wall - CRAM
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
    mov r6, r4
    lsl r6, r6, #3
    mov r7, r4
    lsl r7, r7, #1
    add r0, r6, r7
    add r0, r0, r5
    add r0, r0, r9
    add r0, r0, #0x200
    ldrb r11, [r0]             @ r11 = piece type (0-7)
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
    mov r1, #35
    strb r1, [r0]
    
    @ Draw color in CRAM (VRAM + 0x800)
    add r0, r0, #0x800
    strb r11, [r0]             @ Color = piece type (1-7)

render_mat_next:
    add r5, r5, #1
    cmp r5, #10
    blt render_mat_col
    add r4, r4, #1
    cmp r4, #20
    blt render_mat_row
    
    @ Draw floor
    mov r0, r8
    add r0, r0, #512
    add r0, r0, #256
    sub r0, r0, #8
    add r0, r0, #15
    mov r1, #45
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
    @ Draw "NEXT" text at VRAM + 147 (X=27, Y=3) - Yellow color
    @ VRAM address = Y * 40 + X = 3 * 40 + 27 = 147
    mov r0, r8
    add r0, r0, #147
    mov r1, #78     @ 'N'
    strb r1, [r0]
    mov r1, #69     @ 'E'
    strb r1, [r0, #1]
    mov r1, #88     @ 'X'
    strb r1, [r0, #2]
    mov r1, #84     @ 'T'
    strb r1, [r0, #3]
    @ CRAM colors for NEXT
    mov r1, #3      @ Yellow
    add r0, r0, #0x800
    strb r1, [r0]
    strb r1, [r0, #1]
    strb r1, [r0, #2]
    strb r1, [r0, #3]
    
    @ Draw next piece shape at X=32, Y=5 with color
    ldr r5, [r9, #0x124]  @ type
    add r11, r5, #1       @ r11 = color (type + 1)
    lsl r2, r5, #4        @ type * 16
    add r2, r2, r9
    add r2, r2, #0x300    @ r2 = LUT address
    mov r3, #0            @ row
np_row_loop:
    ldrb r4, [r2, r3]
    cmp r4, #0
    beq np_next_row
    
    mov r5, #0            @ col
np_col_loop:
    mov r0, #3
    sub r0, r0, r5
    mov r12, #1
    lsl r12, r12, r0
    tst r4, r12
    beq np_next_col
    
    @ Calculate VRAM address: Y = row+5, X = col+32
    add r0, r3, #5
    mov r10, r0
    lsl r10, r10, #5      @ Y * 32
    mov r1, r0
    lsl r1, r1, #3        @ Y * 8
    add r0, r10, r1       @ Y * 40
    add r0, r0, #32       @ X base (32)
    add r0, r0, r5        @ + col
    add r0, r0, r8        @ + VRAM base
    mov r1, #35           @ '#'
    strb r1, [r0]         @ Draw character
    
    @ Draw color to CRAM
    add r0, r0, #0x800
    strb r11, [r0]        @ Draw color

np_next_col:
    add r5, r5, #1
    cmp r5, #4
    blt np_col_loop
np_next_row:
    add r3, r3, #1
    cmp r3, #4
    blt np_row_loop
    
    @ === CHECK GAME OVER AND DRAW TEXT ===
    ldr r0, [r9, #0x118]
    cmp r0, #1
    bne render_score
    
    @ Draw GAME OVER text at center of play field
    @ Y=10, X=15 -> offset = 10*40 + 15 = 415
    mov r0, r8
    movw r1, #415
    add r0, r0, r1
    mov r1, #71     @ 'G'
    strb r1, [r0]
    mov r1, #65     @ 'A'
    strb r1, [r0, #1]
    mov r1, #77     @ 'M'
    strb r1, [r0, #2]
    mov r1, #69     @ 'E'
    strb r1, [r0, #3]
    mov r1, #32     @ ' '
    strb r1, [r0, #4]
    mov r1, #79     @ 'O'
    strb r1, [r0, #5]
    mov r1, #86     @ 'V'
    strb r1, [r0, #6]
    mov r1, #69     @ 'E'
    strb r1, [r0, #7]
    mov r1, #82     @ 'R'
    strb r1, [r0, #8]
    @ Draw red color for GAME OVER
    mov r1, #1      @ Red color
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
    @ Draw "HI" label (Y=0, X=27 -> offset 27) - Yellow color
    mov r0, r8
    add r0, r0, #27
    mov r1, #72     @ 'H'
    strb r1, [r0]
    mov r1, #73     @ 'I'
    strb r1, [r0, #1]
    @ CRAM colors for HI
    mov r1, #3      @ Yellow
    add r0, r0, #0x800
    strb r1, [r0]
    strb r1, [r0, #1]
    
    @ Draw High Score (Y=0, X=33 -> offset 33)
    ldr r0, [r9, #0x128]
    mov r1, r8
    add r1, r1, #33
    bl print_number
    
    @ Draw "SCORE" label (Y=1, X=27 -> offset 67) - Yellow color
    mov r0, r8
    add r0, r0, #67
    mov r1, #83     @ 'S'
    strb r1, [r0]
    mov r1, #67     @ 'C'
    strb r1, [r0, #1]
    mov r1, #79     @ 'O'
    strb r1, [r0, #2]
    mov r1, #82     @ 'R'
    strb r1, [r0, #3]
    mov r1, #69     @ 'E'
    strb r1, [r0, #4]
    @ CRAM colors for SCORE
    mov r1, #3      @ Yellow
    add r0, r0, #0x800
    strb r1, [r0]
    strb r1, [r0, #1]
    strb r1, [r0, #2]
    strb r1, [r0, #3]
    strb r1, [r0, #4]
    
    @ Draw Current Score (Y=1, X=33 -> offset 73)
    ldr r0, [r9, #0x110]
    mov r1, r8
    add r1, r1, #73
    bl print_number
    
    @ Draw "LV" label (Y=2, X=27 -> offset 107) - Yellow color
    mov r0, r8
    add r0, r0, #107
    mov r1, #76     @ 'L'
    strb r1, [r0]
    mov r1, #86     @ 'V'
    strb r1, [r0, #1]
    @ CRAM colors for LV
    mov r1, #3      @ Yellow
    add r0, r0, #0x800
    strb r1, [r0]
    strb r1, [r0, #1]
    
    @ Draw Level (Y=2, X=33 -> offset 113)
    ldr r0, [r9, #0x110]
    lsr r0, r0, #9        @ Level = Score / 512
    mov r1, r8
    add r1, r1, #113
    bl print_number
    
    @ Draw vertical TETRIS logo (Colors: 1=Red, 3=Yellow, 2=Green, 6=Cyan, 4=Blue, 5=Magenta)
    @ T at Y=4, E at Y=6, T at Y=8, R at Y=10, I at Y=12, S at Y=14 (X=6)
    mov r6, r8             @ r6 = VRAM base
    add r7, r8, #0x800     @ r7 = CRAM base
    
    @ T - Y=4, X=6 -> offset = 4*40+6 = 166
    mov r0, #84            @ 'T'
    mov r1, #1             @ Red
    mov r2, #4
    lsl r2, r2, #5         @ 4*32 = 128
    mov r3, #4
    lsl r3, r3, #3         @ 4*8 = 32
    add r2, r2, r3         @ 128+32 = 160
    add r2, r2, #6         @ 160+6 = 166
    strb r0, [r6, r2]
    strb r1, [r7, r2]
    
    @ E - Y=6, X=6 -> offset = 6*40+6 = 246
    mov r0, #69            @ 'E'
    mov r1, #3             @ Yellow
    mov r2, #6
    lsl r2, r2, #5         @ 6*32 = 192
    mov r3, #6
    lsl r3, r3, #3         @ 6*8 = 48
    add r2, r2, r3         @ 192+48 = 240
    add r2, r2, #6         @ 240+6 = 246
    strb r0, [r6, r2]
    strb r1, [r7, r2]
    
    @ T - Y=8, X=6 -> offset = 8*40+6 = 326
    mov r0, #84            @ 'T'
    mov r1, #2             @ Green
    mov r2, #8
    lsl r2, r2, #5         @ 8*32 = 256
    mov r3, #8
    lsl r3, r3, #3         @ 8*8 = 64
    add r2, r2, r3         @ 256+64 = 320
    add r2, r2, #6         @ 320+6 = 326
    strb r0, [r6, r2]
    strb r1, [r7, r2]
    
    @ R - Y=10, X=6 -> offset = 10*40+6 = 406
    mov r0, #82            @ 'R'
    mov r1, #6             @ Cyan
    mov r2, #10
    lsl r2, r2, #5         @ 10*32 = 320
    mov r3, #10
    lsl r3, r3, #3         @ 10*8 = 80
    add r2, r2, r3         @ 320+80 = 400
    add r2, r2, #6         @ 400+6 = 406
    strb r0, [r6, r2]
    strb r1, [r7, r2]
    
    @ I - Y=12, X=6 -> offset = 12*40+6 = 486
    mov r0, #73            @ 'I'
    mov r1, #4             @ Blue
    mov r2, #12
    lsl r2, r2, #5         @ 12*32 = 384
    mov r3, #12
    lsl r3, r3, #3         @ 12*8 = 96
    add r2, r2, r3         @ 384+96 = 480
    add r2, r2, #6         @ 480+6 = 486
    strb r0, [r6, r2]
    strb r1, [r7, r2]
    
    @ S - Y=14, X=6 -> offset = 14*40+6 = 566
    mov r0, #83            @ 'S'
    mov r1, #5             @ Magenta
    mov r2, #14
    lsl r2, r2, #5         @ 14*32 = 448
    mov r3, #14
    lsl r3, r3, #3         @ 14*8 = 112
    add r2, r2, r3         @ 448+112 = 560
    add r2, r2, #6         @ 560+6 = 566
    strb r0, [r6, r2]
    strb r1, [r7, r2]
    
    @ VSYNC
    movw r0, #0x0008
    movt r0, #0x0004
    mov r1, #1
    str r1, [r0]
    
    pop {r4-r7, r10-r12, pc}

@ ============================================
@ draw_piece - FIXED: Y < 19, WITH COLORS
@ ============================================
draw_piece:
    push {r4-r7, r10-r11, lr}
    
    @ Bounds check: if piece type > 6, clamp to 0 (BRANCHLESS!)
    @ Uses MOVHI (move if higher, unsigned) - more reliable than branch
    cmp r0, #6
    movhi r0, #0            @ If r0 > 6 (unsigned), clamp to 0
    
    mov r5, r0              @ r5 = piece type (now guaranteed 0-6)
    mov r6, r1              @ r6 = x
    mov r7, r2              @ r7 = y
    mov r0, r3              @ r0 = rotation
    mov r1, r4              @ r1 = char to draw
    
    @ Calculate piece color (type + 1)
    add r11, r5, #1         @ r11 = color (type + 1)
    
    lsl r2, r5, #4
    lsl r3, r0, #2
    add r2, r2, r3
    add r2, r2, r9
    add r2, r2, #0x300
    
    mov r3, #0
dp_row_loop:
    ldrb r4, [r2, r3]
    cmp r4, #0
    beq dp_next_row
    
    push {r3}
    mov r5, #0
dp_col_loop:
    mov r0, #3
    sub r0, r0, r5
    mov r12, #1
    lsl r12, r12, r0
    
    tst r4, r12
    beq dp_next_col
    
    add r0, r7, r3
    
    cmp r0, #0
    blt dp_next_col
    cmp r0, #19
    bge dp_next_col
    
    add r12, r6, r5
    cmp r12, #0
    blt dp_next_col
    cmp r12, #10
    bge dp_next_col
    
    push {r4}
    lsl r4, r0, #5
    lsl r0, r0, #3
    add r4, r4, r0
    add r4, r4, r12
    add r4, r4, #15
    add r4, r4, r8
    strb r1, [r4]          @ Draw character to VRAM
    
    @ Draw color to CRAM
    add r4, r4, #0x800
    strb r11, [r4]         @ Draw color
    pop {r4}
    
dp_next_col:
    add r5, r5, #1
    cmp r5, #4
    blt dp_col_loop
    pop {r3}
    
dp_next_row:
    add r3, r3, #1
    cmp r3, #4
    blt dp_row_loop
    
    pop {r4-r7, r10-r11, pc}

@ ============================================
@ get_random_piece: Branchless Xorshift32 PRNG
@ Returns value 0-6 in r0
@ Uses Xorshift32 Form B (explicit shifts, [SAFE])
@ Uses AND 7 with fixup for modulo 7 (slight bias acceptable for game)
@ ============================================
get_random_piece:
    @ Load PRNG state
    ldr r0, [r9, #0x134]
    
    @ Xorshift32 Form B: explicit LSL/LSR before each EOR
    @ Triple (13, 17, 5) - Marsaglia's validated constants
    @ [SAFE] - fully .clinerules compliant
    lsl r1, r0, #13
    eor r0, r0, r1          @ r0 ^= r0 << 13
    lsr r1, r0, #17
    eor r0, r0, r1          @ r0 ^= r0 >> 17
    lsl r1, r0, #5
    eor r0, r0, r1          @ r0 ^= r0 << 5
    
    @ Store updated state
    str r0, [r9, #0x134]
    
    @ -----------------------------------------------------------------------
    @ MODULO 7: r0 = r0 % 7
    @ Use AND 7 to get 0-7, then fix 7 -> 6
    @ Slight bias (6 is 2x more likely) but acceptable for Tetris
    @ -----------------------------------------------------------------------
    and r0, r0, #7          @ r0 = n & 7 (gives 0-7)
    cmp r0, #7
    subge r0, r0, #1        @ If r0 >= 7, subtract 1 (7 -> 6)
    
    bx lr

@ ============================================
@ print_number: Prints 6-digit number, right-aligned
@ r0 = number to print, r1 = VRAM start address
@ ============================================
print_number:
    push {r2-r7, r12, lr}  @ r8 is global VRAM base - DO NOT push/pop!
    
    @ 1. Build divisor table on stack (6 values = 24 bytes)
    @ Stack grows down, so push smallest FIRST to read largest first
    mov r2, #1
    push {r2}              @ 1 (will be at highest address, read last)
    mov r2, #10
    push {r2}              @ 10
    mov r2, #100
    push {r2}              @ 100
    movw r2, #1000
    push {r2}              @ 1000
    movw r2, #10000
    push {r2}              @ 10000
    movw r2, #0x86A0
    movt r2, #0x0001
    push {r2}              @ 100000 (will be at lowest address, read first)
    
    @ 2. Alustetaan silmukka
    mov r4, r0             @ r4 = Tulostettava luku
    mov r5, #6             @ r5 = Kuusi numeroa tulostettavana
    mov r6, r1             @ r6 = VRAM osoite
    mov r7, sp             @ r7 = Osoitin pinoon (jakajiin)
    mov r12, #0            @ r12 = Etunolla-lippu (0 = etsii ekaa numeroa, 1 = eka numero nahty)

pn_loop:
    ldr r2, [r7], #4       @ Load divisor
    mov r3, #0             @ r3 = Current digit value (0-9)

pn_div:
    cmp r4, r2
    blt pn_digit_done
    sub r4, r4, r2
    add r3, r3, #1
    b pn_div

pn_digit_done:
    @ Leading zero handling (spaces)
    cmp r3, #0
    bne pn_non_zero        @ If >0, normal print
    cmp r12, #0
    bne pn_write_digit     @ If first digit seen, zero is real digit
    cmp r5, #1
    beq pn_write_digit     @ If LAST digit (ones), always print '0'

    @ Leading zero -> print space!
    mov r3, #32            @ ASCII 32 = Space
    b pn_store

pn_non_zero:
    mov r12, #1            @ Flag up: first digit seen!

pn_write_digit:
    add r3, r3, #48        @ ASCII '0' = 48

pn_store:
    strb r3, [r6]          @ Store to VRAM
    @ Write cyan color to CRAM (use r2 as temp, not r12!)
    mov r2, #6             @ Cyan color
    movw r3, #0x800
    add r3, r6, r3         @ CRAM address
    strb r2, [r3]          @ Write color
    add r6, r6, #1         @ Move to next position
    subs r5, r5, #1        @ Vahenna counteria
    bne pn_loop            @ Jatka kunnes 6 merkkia

    @ 3. Clean up stack (6 values * 4 bytes = 24 bytes)
    add sp, sp, #24
    pop {r2-r7, r12, pc}

@ END
