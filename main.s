@ ============================================
@ Tetris Phase 11 - Fixed score counter
@ ============================================

@ === MEMORY MAP ===
@ 0x10000: ROM (code)
@ 0x20000: RAM base
@ 0x20100: Game state
@ 0x20200: Matrix (10 wide, 20 tall)
@ 0x20300: Tetromino definitions (7 pieces * 4 bytes)
@ 0x30000: VRAM (40x20)
@ 0x40000: MMIO
@ 0x40008: VSYNC port (write 1 when frame ready)

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
    
    @ Initialize Tetromino definitions at 0x20300
    @ I-piece: row 0=0x00, row 1=0x0F, row 2=0x00, row 3=0x00
    add r0, r9, #0x300
    mov r1, #0x00
    strb r1, [r0, #0]
    mov r1, #0x0F
    strb r1, [r0, #1]
    mov r1, #0x00
    strb r1, [r0, #2]
    strb r1, [r0, #3]
    
    @ J-piece: 0x02, 0x02, 0x07, 0x00
    add r0, r9, #0x304
    mov r1, #0x02
    strb r1, [r0, #0]
    strb r1, [r0, #1]
    mov r1, #0x07
    strb r1, [r0, #2]
    mov r1, #0x00
    strb r1, [r0, #3]
    
    @ L-piece: 0x04, 0x04, 0x07, 0x00
    add r0, r9, #0x308
    mov r1, #0x04
    strb r1, [r0, #0]
    strb r1, [r0, #1]
    mov r1, #0x07
    strb r1, [r0, #2]
    mov r1, #0x00
    strb r1, [r0, #3]
    
    @ O-piece: 0x66, 0x66, 0x00, 0x00
    add r0, r9, #0x30C
    mov r1, #0x66
    strb r1, [r0, #0]
    strb r1, [r0, #1]
    mov r1, #0x00
    strb r1, [r0, #2]
    strb r1, [r0, #3]
    
    @ S-piece: 0x03, 0x06, 0x00, 0x00
    add r0, r9, #0x310
    mov r1, #0x03
    strb r1, [r0, #0]
    mov r1, #0x06
    strb r1, [r0, #1]
    mov r1, #0x00
    strb r1, [r0, #2]
    strb r1, [r0, #3]
    
    @ T-piece: 0x02, 0x07, 0x02, 0x00
    add r0, r9, #0x314
    mov r1, #0x02
    strb r1, [r0, #0]
    mov r1, #0x07
    strb r1, [r0, #1]
    mov r1, #0x02
    strb r1, [r0, #2]
    mov r1, #0x00
    strb r1, [r0, #3]
    
    @ Z-piece: 0x06, 0x03, 0x00, 0x00
    add r0, r9, #0x318
    mov r1, #0x06
    strb r1, [r0, #0]
    mov r1, #0x03
    strb r1, [r0, #1]
    mov r1, #0x00
    strb r1, [r0, #2]
    strb r1, [r0, #3]
    
    @ Clear game state
    mov r0, #0
    str r0, [r9, #0x104]
    str r0, [r9, #0x108]
    str r0, [r9, #0x10C]
    str r0, [r9, #0x110]
    str r0, [r9, #0x114]
    str r0, [r9, #0x118]
    
    @ Initialize position
    mov r0, #3
    str r0, [r9, #0x104]
    mov r0, #0
    str r0, [r9, #0x108]
    
    @ Clear Matrix (200 bytes starting at 0x20200)
    add r0, r9, #0x200
    mov r1, #0
    mov r2, #200
init_matrix_loop:
    strb r1, [r0], #1
    subs r2, r2, #1
    bne init_matrix_loop
    
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
    
    @ Check for soft drop (Down button = bit 2)
    movw r0, #0x0000
    movt r0, #0x0004
    ldr r4, [r0]
    tst r4, #2
    beq check_gravity
    
    @ Soft drop: force gravity trigger
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
    
    @ Try to move down
    ldr r0, [r9, #0x10C]
    ldr r1, [r9, #0x104]
    ldr r2, [r9, #0x108]
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
    mov r3, #1
    bl write_piece
    bl clear_lines
    bl spawn_piece
    bl render          @ Call render to write VSYNC!
    b main_loop        @ Go directly to main_loop

skip_gravity:
    movw r0, #0x0000
    movt r0, #0x0004
    ldr r4, [r0]
    
    @ Left
    tst r4, #4
    beq skip_left
    ldr r0, [r9, #0x10C]
    ldr r1, [r9, #0x104]
    sub r1, r1, #1
    ldr r2, [r9, #0x108]
    bl check_collision
    cmp r0, #0
    bne skip_left
    ldr r0, [r9, #0x104]
    sub r0, r0, #1
    str r0, [r9, #0x104]

skip_left:
    tst r4, #8
    beq skip_right
    ldr r0, [r9, #0x10C]
    ldr r1, [r9, #0x104]
    add r1, r1, #1
    ldr r2, [r9, #0x108]
    bl check_collision
    cmp r0, #0
    bne skip_right
    ldr r0, [r9, #0x104]
    add r0, r0, #1
    str r0, [r9, #0x104]

skip_right:
    bl render
skip_input:
    b main_loop

game_over_loop:
    bl render
    bl game_over_handler
    @ Write VSYNC for game over screen
    movw r0, #0x0008
    movt r0, #0x0004
    mov r1, #1
    str r1, [r0]
    b game_over_loop

@ ============================================
@ spawn_piece
@ ============================================
spawn_piece:
    push {r4-r7, lr}
    
    movw r0, #0x0004
    movt r0, #0x0004
    ldr r0, [r0]
    mov r1, #7
    bl modulo
    str r0, [r9, #0x10C]
    
    mov r0, #3
    str r0, [r9, #0x104]
    mov r0, #0
    str r0, [r9, #0x108]
    
    ldr r0, [r9, #0x10C]
    ldr r1, [r9, #0x104]
    ldr r2, [r9, #0x108]
    bl check_collision
    cmp r0, #0
    beq spawn_done
    
    mov r0, #1
    str r0, [r9, #0x118]

spawn_done:
    pop {r4-r7, pc}

@ ============================================
@ check_collision
@ ============================================
check_collision:
    push {r4-r8, r10-r11, lr}
    mov r4, r0
    mov r5, r1
    mov r6, r2
    
    mov r7, r4
    lsl r7, r7, #2
    add r7, r7, r9
    add r7, r7, #0x300
    
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
@ write_piece
@ ============================================
write_piece:
    push {r4-r7, lr}
    mov r4, r0
    mov r5, r1
    mov r6, r2
    mov r7, r3
    
    lsl r0, r4, #2
    add r0, r0, r9
    add r0, r0, #0x300
    
    mov r4, #0
wp_row_loop:
    ldrb r1, [r0, r4]
    cmp r1, #0
    beq wp_next_row
    
    mov r3, #0
    mov r12, #8
wp_col_loop:
    tst r1, r12
    beq wp_next_col
    
    add r2, r6, r4
    add r11, r5, r3
    
    cmp r2, #0
    blt wp_next_col
    cmp r2, #20
    bge wp_next_col
    cmp r11, #0
    blt wp_next_col
    cmp r11, #10
    bge wp_next_col
    
    push {r2}
    mov r10, r2
    lsl r2, r2, #3
    lsl r10, r10, #1
    add r2, r2, r10
    add r2, r2, r11
    add r2, r2, r9
    add r2, r2, #0x200
    strb r7, [r2]
    pop {r2}
    
wp_next_col:
    lsr r12, r12, #1
    add r3, r3, #1
    cmp r3, #4
    blt wp_col_loop
wp_next_row:
    add r4, r4, #1
    cmp r4, #4
    blt wp_row_loop
    
    pop {r4-r7, pc}

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
@ render
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
    mov r3, #35
    bl draw_piece
    
    @ Draw score (4 digits: thousands, hundreds, tens, ones)
    @ Max score = 9999, supports overflow
    ldr r0, [r9, #0x110]
    mov r1, r8
    movw r2, #110
    add r1, r1, r2      @ r1 = VRAM + 110
    
    @ Calculate thousands
    mov r2, #0          @ r2 = thousands
render_score_thousands:
    cmp r0, #1000
    blt render_score_hundreds_calc
    sub r0, r0, #1000
    add r2, r2, #1
    b render_score_thousands
    
render_score_hundreds_calc:
    @ r2 = thousands, r0 = remainder (0-999)
    strb r2, [r1]       @ store thousands (will add 48 later)
    
    @ Calculate hundreds from remainder
    mov r2, #0          @ r2 = hundreds
render_score_hundreds:
    cmp r0, #100
    blt render_score_tens_calc
    sub r0, r0, #100
    add r2, r2, #1
    b render_score_hundreds
    
render_score_tens_calc:
    @ r2 = hundreds, r0 = remainder (0-99)
    add r2, r2, #48     @ convert to ASCII
    strb r2, [r1, #1]   @ store hundreds
    
    @ Calculate tens from remainder
    mov r2, #0          @ r2 = tens
render_score_tens:
    cmp r0, #10
    blt render_score_ones
    sub r0, r0, #10
    add r2, r2, #1
    b render_score_tens
    
render_score_ones:
    @ r2 = tens, r0 = ones
    add r2, r2, #48     @ convert tens to ASCII
    strb r2, [r1, #2]   @ store tens
    add r0, r0, #48     @ convert ones to ASCII
    strb r0, [r1, #3]   @ store ones
    
    @ Now fix thousands - reload and add 48
    ldrb r0, [r1]       @ reload thousands
    add r0, r0, #48     @ convert to ASCII
    strb r0, [r1]       @ store thousands
    
    @ Check for game over and draw GAME OVER text
    ldr r0, [r9, #0x118]
    cmp r0, #1
    bne render_vsync
    
    @ Draw GAME OVER text
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
    
render_vsync:
    @ VSYNC
    movw r0, #0x0008
    movt r0, #0x0004
    mov r1, #1
    str r1, [r0]
    
    pop {r4-r7, r10-r11, pc}

@ ============================================
@ draw_piece
@ ============================================
draw_piece:
    push {r4-r7, lr}
    mov r4, r0
    mov r5, r1
    mov r6, r2
    mov r7, r3
    
    lsl r0, r4, #2
    add r0, r0, r9
    add r0, r0, #0x300
    
    mov r4, #0
dp_row_loop:
    ldrb r1, [r0, r4]
    cmp r1, #0
    beq dp_next_row
    
    mov r3, #0
dp_col_loop:
    mov r2, #3
    sub r2, r2, r3
    mov r12, #1
    lsl r12, r12, r2
    
    tst r1, r12
    beq dp_next_col
    
    add r2, r6, r4
    
    cmp r2, #0
    blt dp_next_col
    cmp r2, #20
    bge dp_next_col
    
    add r12, r5, r3
    cmp r12, #0
    blt dp_next_col
    cmp r12, #10
    bge dp_next_col
    
    push {r1}
    lsl r1, r2, #5
    lsl r2, r2, #3
    add r1, r1, r2
    add r1, r1, r12
    add r1, r1, #15
    add r1, r1, r8
    strb r7, [r1]
    pop {r1}
    
dp_next_col:
    add r3, r3, #1
    cmp r3, #4
    blt dp_col_loop
dp_next_row:
    add r4, r4, #1
    cmp r4, #4
    blt dp_row_loop
    
    pop {r4-r7, pc}

@ ============================================
@ game_over_handler
@ ============================================
game_over_handler:
    push {r4-r7, lr}
    
    mov r0, r8
    movw r1, #160
    add r0, r0, r1
    mov r1, #71
    strb r1, [r0]
    mov r1, #65
    strb r1, [r0, #1]
    mov r1, #77
    strb r1, [r0, #2]
    mov r1, #69
    strb r1, [r0, #3]
    mov r1, #32
    strb r1, [r0, #4]
    mov r1, #79
    strb r1, [r0, #5]
    mov r1, #86
    strb r1, [r0, #6]
    mov r1, #69
    strb r1, [r0, #7]
    mov r1, #82
    strb r1, [r0, #8]
    
    pop {r4-r7, pc}

@ ============================================
@ modulo
@ ============================================
modulo:
    and r0, r0, #7
    cmp r0, #7
    bne modulo_done
    mov r0, #6
modulo_done:
    bx lr

@ END