# hook: `add r7,r24,r27` after the KPADRead in the core path (r25 = channel).  The pad's
# buttons go into the KPAD status, and the GameCube pad's C-stick steers the pointer (see
# ptr_core.s).  SICnINBUFL (0xCD006408 + 12*chan) holds the C-stick in [31:24] (X) and
# [23:16] (Y), 128 +/- ~100 around the centre.
    add     7, 24, 27                   # displaced instruction
    # The menus and dialogs read the KPAD buttons, not the WPAD word the pad buttons were
    # merged into (gc_buttons.s, already copied to 8(r7) this frame).  Merge them into the
    # KPAD status too: hold |= buttons, and trig/release against last frame's hold (0x38(r7)).
    # r3 already holds the KPAD hold (loaded just before this hook) and is stored next.
    lhz     9, 8(7)                     # this frame's remote + pad buttons
    andi.   9, 9, 0x9F1F
    lwz     10, 0xF0(1)                 # KPAD hold
    or      3, 10, 9
    lwz     11, 0x38(7)                 # last frame's hold
    andc    12, 3, 11                   # trig
    andc    11, 11, 3                   # release
    stw     3, 0xF0(1)
    stw     12, 0xF4(1)
    stw     11, 0xF8(1)
    cmplwi  25, 3
    bgt     8f
    mulli   5, 25, 12
    lis     6, 0xCD00
    add     6, 6, 5
    lwz     8, 0x6404(6)                # INBUFH: did a pad answer?
    cmpwi   8, 0
    blt     8f
    andis.  9, 8, 0x0080
    beq     8f
    lwz     8, 0x6408(6)                # INBUFL
    rlwinm  9, 8, 8, 24, 31             # C-stick X
    rlwinm  10, 8, 16, 24, 31           # C-stick Y
    addi    9, 9, -128
    addi    10, 10, -128
    stwu    1, -16(1)
    lis     5, 0x4330                   # int -> float with the 2^52 + 2^31 trick
    stw     5, 8(1)
    lis     11, 0x8000
    stw     11, 12(1)
    lfd     3, 8(1)                     # magic
    xoris   9, 9, 0x8000
    stw     9, 12(1)
    lfd     1, 8(1)
    xoris   10, 10, 0x8000
    stw     10, 12(1)
    lfd     2, 8(1)
    addi    1, 1, 16
    fsub    1, 1, 3
    fsub    2, 2, 3
    lis     5, 0x3c23                   # 1/100: the stick spans about +-100
    ori     5, 5, 0xd70a
    stwu    1, -16(1)
    stw     5, 8(1)
    lfs     4, 8(1)
    addi    1, 1, 16
    fmuls   1, 1, 4
    fmuls   2, 2, 4
# f1 = stick X (+ right), f2 = stick Y (+ up), already read by the caller.  The KPAD
# status the game just read is at 0xF0(r1): pos at +0x20/+0x24, dpd_valid_fg at +0x5E.
# r7 = the game's per-channel copy of the previous frame (pos at +0x58/+0x5C).
#
# The stick owns the pointer: while it is held the pointer moves from where it was, and
# with the stick at rest the pointer stays put.  The remote's own IR pointer is ignored,
# because a remote lying in view of the sensor bar would otherwise snap the pointer back
# to where it is aimed the moment the stick is released, and nothing could be clicked.
    stwu    1, -32(1)
    lis     5, 0x3e4c                   # dead zone 0.2
    ori     5, 5, 0xcccd
    stw     5, 8(1)
    lfs     3, 8(1)
    lis     5, 0x3d23                   # speed 0.04 per frame at full tilt
    ori     5, 5, 0xd70a
    stw     5, 8(1)
    lfs     4, 8(1)
    lis     5, 0x3f80                   # 1.0
    stw     5, 8(1)
    lfs     5, 8(1)
    fsubs   10, 5, 5                    # 0.0
    fneg    6, 5                        # -1.0
    fabs    7, 1
    fabs    8, 2
    fsubs   7, 7, 3
    fsubs   8, 8, 3
    fsel    1, 7, 1, 10                 # |x| > dead zone ? x : 0
    fsel    2, 8, 2, 10
    lfs     11, 0x58(7)                 # previous pointer
    lfs     12, 0x5c(7)
    fcmpu   0, 1, 10
    bne     3f
    fcmpu   0, 2, 10
    bne     3f
    stfs    11, 0x20+0xf0+32(1)         # stick at rest: the pointer stays where it was
    stfs    12, 0x24+0xf0+32(1)
    b       4f
3:  fmadds  11, 1, 4, 11                # x += stickX * speed
    fnmsubs 12, 2, 4, 12                # y -= stickY * speed  (pointer y grows downward)
    fsubs   13, 5, 11                   # clamp to [-1, 1]
    fsel    11, 13, 11, 5
    fsubs   13, 11, 6
    fsel    11, 13, 11, 6
    fsubs   13, 5, 12
    fsel    12, 13, 12, 5
    fsubs   13, 12, 6
    fsel    12, 13, 12, 6
    stfs    11, 0x20+0xf0+32(1)
    stfs    12, 0x24+0xf0+32(1)
4:  li      0, 1
    stb     0, 0x5e+0xf0+32(1)
9:  addi    1, 1, 32
8:
