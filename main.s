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
    
    @ Arvo ensimmäinen NEXT-palikka
    bl get_random_piece
    str r0, [r9, #0x124]   @ Tallenna ensimmäinen NEXT-palikka
    
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
    ldr r0, [r9, #0x114]
    movw r12, #20
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
    mov r4, #1
    bl write_piece
    bl clear_lines
    bl spawn_piece
    bl render
    b main_loop

skip_gravity:
    movw r0, #0x0000
    movt r0, #0x0004
    ldr r4, [r0]
    
    @ === ROTATION ===
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
    beq update_debounce
    ldr r0, [r9, #0x10C]
    ldr r1, [r9, #0x104]
    add r1, r1, #1
    ldr r2, [r9, #0x108]
    ldr r3, [r9, #0x11C]
    bl check_collision
    cmp r0, #0
    bne update_debounce
    ldr r0, [r9, #0x104]
    add r0, r0, #1
    str r0, [r9, #0x104]

update_debounce:
    ldr r0, [r9, #0x120]
    cmp r0, #0
    beq skip_debounce
    sub r0, r0, #1
    str r0, [r9, #0x120]
skip_debounce:

    bl render
    b main_loop

game_over_loop:
    @ 1. Lue ohjain ENNEN VSYNC-pysäytystä!
    movw r0, #0x0000
    movt r0, #0x0004
    ldr r1, [r0]
    tst r1, #16             @ Onko A-nappi (Space) painettuna?
    bne reset_game          @ Jos on, aloita alusta!
    
    @ 2. Jos ei painettu, piirrä ruutu ja laukaise VSYNC
    bl render
    b game_over_loop        @ Tänne tuskin koskaan päästään, mutta pidetään varmuuden vuoksi


@ ============================================
@ spawn_piece
@ ============================================
spawn_piece:
    push {r4-r7, lr}
    
    ldr r0, [r9, #0x124]   @ Hae next piece
    str r0, [r9, #0x10C]   @ Aseta se nykyiseksi palikaksi
    
    bl get_random_piece    @ Arvo uusi next piece
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
    push {r4-r8, r10-r11, lr}
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
    pop {r4-r8, r10-r11, pc}
cc_hit:
    mov r0, #1
    pop {r4-r8, r10-r11, pc}

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
    str r0, [r9, #0x110]
    
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
    push {r4-r7, r10-r11, lr}
    
    @ Clear VRAM
    mov r0, #0x20
    mov r1, r8
    mov r2, #800
render_clear_vram:
    strb r0, [r1], #1
    subs r2, r2, #1
    bne render_clear_vram
    
    @ Draw walls
    mov r4, #0
    mov r5, #124
render_walls:
    mov r6, r4
    lsl r6, r6, #5
    mov r7, r4
    lsl r7, r7, #3
    add r1, r6, r7
    
    add r0, r8, r1
    add r0, r0, #14
    strb r5, [r0]
    
    add r0, r8, r1
    add r0, r0, #25
    strb r5, [r0]
    
    add r4, r4, #1
    cmp r4, #20
    blt render_walls
    
    @ Draw matrix
    mov r4, #0
render_mat_row:
    mov r5, #0
render_mat_col:
    mov r10, r4
    lsl r10, r10, #3
    mov r11, r4
    lsl r11, r11, #1
    add r0, r10, r11
    add r0, r0, r5
    add r0, r0, r9
    add r0, r0, #0x200
    ldrb r0, [r0]
    cmp r0, #0
    beq render_mat_next
    
    mov r10, r4
    lsl r10, r10, #5
    mov r11, r4
    lsl r11, r11, #3
    add r0, r10, r11
    add r0, r0, r5
    add r0, r0, #15
    add r0, r0, r8
    mov r1, #35
    strb r1, [r0]

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
    @ Draw "NEXT" text at VRAM + 147 (X=27, Y=3) - right side of wall
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
    
    @ Draw next piece shape at X=32, Y=5
    ldr r5, [r9, #0x124]  @ type
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
    mov r11, r0
    lsl r11, r11, #3      @ Y * 8
    add r0, r10, r11      @ Y * 40
    add r0, r0, #32       @ X base (32)
    add r0, r0, r5        @ + col
    add r0, r0, r8        @ + VRAM base
    mov r1, #35           @ '#'
    strb r1, [r0]

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
    
    @ Draw GAME OVER text at VRAM+160
    mov r0, r8
    movw r1, #160
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
    
render_score:
    @ Draw score
    ldr r0, [r9, #0x110]
    mov r1, r8
    movw r2, #110
    add r1, r1, r2
    
    mov r2, #0
render_score_thousands:
    cmp r0, #1000
    blt render_score_hundreds_calc
    sub r0, r0, #1000
    add r2, r2, #1
    b render_score_thousands
    
render_score_hundreds_calc:
    strb r2, [r1]
    
    mov r2, #0
render_score_hundreds:
    cmp r0, #100
    blt render_score_tens_calc
    sub r0, r0, #100
    add r2, r2, #1
    b render_score_hundreds
    
render_score_tens_calc:
    add r2, r2, #48
    strb r2, [r1, #1]
    
    mov r2, #0
render_score_tens:
    cmp r0, #10
    blt render_score_ones
    sub r0, r0, #10
    add r2, r2, #1
    b render_score_tens
    
render_score_ones:
    add r2, r2, #48
    strb r2, [r1, #2]
    add r0, r0, #48
    strb r0, [r1, #3]
    
    ldrb r0, [r1]
    add r0, r0, #48
    strb r0, [r1]
    
    @ VSYNC
    movw r0, #0x0008
    movt r0, #0x0004
    mov r1, #1
    str r1, [r0]
    
    pop {r4-r7, r10-r11, pc}

@ ============================================
@ draw_piece - FIXED: Y < 19
@ ============================================
draw_piece:
    push {r4-r7, lr}
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
    @ FIXED: cmp r0, #19
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
    strb r1, [r4]
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
    
    pop {r4-r7, pc}

@ ============================================
@ get_random_piece: Palauttaa arvon 0-6 (r0)
@ ============================================
get_random_piece:
    movw r1, #0x0004
    movt r1, #0x0004       @ r1 = 0x40004
    ldr r0, [r1]           @ Lue 32-bit random KERRAN
grp_loop:
    and r2, r0, #7         @ Ota 3 alinta bittiä r2:een
    cmp r2, #7             @ Onko se 7?
    bne grp_done           @ Jos 0-6, homma selvä!
    lsr r0, r0, #3         @ Jos oli 7, pudota käytetyt bitit pois (siirrä oikealle)
    cmp r0, #0             @ Loppuiko luku kesken?
    bne grp_loop           @ Jos ei, kokeile uusia bittejä
    mov r2, #0             @ Fallback: jos kaikki bitit olivat 7 (erittäin harvinaista), palauta 0
grp_done:
    mov r0, r2             @ Siirrä tulos r0:aan
    bx lr

@ END
