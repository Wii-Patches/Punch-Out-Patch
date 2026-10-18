# hook: `sth r0,42(r5)` in the SDK's __parse_cl_data, where the Classic Controller's
# buttons (already inverted to 1 = pressed) are stored into the WPAD status (r5).  The
# function has one such store per Classic report layout (standard and the two
# high-resolution ones); all three are hooked with this same routine.
#
# The Classic's buttons are mapped onto the Wii Remote's own button word (status+0) as a
# remote held sideways.  This is below both WPADRead and KPADRead, so every reader sees
# them: the game's pad manager (WPAD), and the menus, dialogs and HOME Menu (KPAD).
# The left stick acts as the d-pad too.  At every store the stick is already in the
# status (+0x2C X, +0x2E Y, up positive) on a 10-bit scale centred on 512; half a tilt
# (256) counts as a press.
# r6, r7, r9 are free here (r6 is reloaded before its next use, r7 and r9 are dead).
    sth     0, 42(5)                    # displaced instruction
    lhz     7, 0(5)                     # remote buttons
    # --- face / shoulder buttons -------------------------------------------
    andi.   6, 0, 0x0040                # B
    beq     2f
    ori     7, 7, 0x0200                # -> 1
2:  andi.   6, 0, 0x0010                # A
    beq     2f
    ori     7, 7, 0x0100                # -> 2
2:  andi.   6, 0, 0x0020                # Y
    beq     2f
    ori     7, 7, 0x0400                # -> B
2:  andi.   6, 0, 0x0008                # X
    beq     2f
    ori     7, 7, 0x0800                # -> A
2:  andi.   6, 0, 0x0400                # +
    beq     2f
    ori     7, 7, 0x0010                # -> +
2:  andi.   6, 0, 0x1000                # -
    beq     2f
    ori     7, 7, 0x1000                # -> -
2:  andi.   6, 0, 0x0800                # HOME
    beq     2f
    ori     7, 7, 0x8000                # -> HOME
    # --- d-pad ---------------------------------------------------------------
2:  andi.   6, 0, 0x0002                # d-pad left  -> remote UP    (sideways: left)
    beq     2f
    ori     7, 7, 0x0008
2:  andi.   6, 0, 0x8000                # d-pad right -> remote DOWN  (sideways: right)
    beq     2f
    ori     7, 7, 0x0004
2:  andi.   6, 0, 0x4000                # d-pad down  -> remote LEFT  (sideways: down)
    beq     2f
    ori     7, 7, 0x0001
2:  andi.   6, 0, 0x0001                # d-pad up    -> remote RIGHT (sideways: up)
    beq     2f
    ori     7, 7, 0x0002
    # --- left stick as the d-pad --------------------------------------------
2:  lha     9, 0x2C(5)                  # left stick X
    cmpwi   9, 512+256
    blt     2f
    ori     7, 7, 0x0004                # right -> remote DOWN
2:  cmpwi   9, 512-256
    bgt     2f
    ori     7, 7, 0x0008                # left  -> remote UP
2:  lha     9, 0x2E(5)                  # left stick Y
    cmpwi   9, 512+256
    blt     2f
    ori     7, 7, 0x0002                # up    -> remote RIGHT
2:  cmpwi   9, 512-256
    bgt     2f
    ori     7, 7, 0x0001                # down  -> remote LEFT
2:  sth     7, 0(5)
