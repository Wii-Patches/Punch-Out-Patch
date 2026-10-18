# hook: right after the core-format WPADRead in the game's pad update (the path a
# plain Wii Remote takes).  r25 = channel, the raw extension type the game probed is
# at 8(r1).
#
# A Classic Controller is made to take this same path (see the retail patch at the
# type check), so the game treats it exactly like a Wii Remote held sideways.  For the
# Classic's data to arrive at all, the remote is switched to the Classic data format (8)
# while one is attached, and back to the core format (2) otherwise; WPADSetDataFormat
# does nothing when the format already matches, so asking every frame is cheap.  The
# buttons themselves are mapped in __parse_cl_data (cc_parse.s).
    stwu    1, -32(1)
    mflr    0
    stw     0, 36(1)
    lwz     5, 40(1)                    # raw extension type
    li      4, 2
    cmpwi   5, 2
    bne     1f
    li      4, 8
1:  mr      3, 25
    lis     12, SETFMT@ha
    addi    12, 12, SETFMT@l
    mtctr   12
    bctrl
    lwz     0, 36(1)
    mtlr    0
    addi    1, 1, 32
    lbz     0, 233(1)                   # displaced instruction
