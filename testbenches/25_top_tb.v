`timescale 1ns/1ps

// Verilog-2005 simulation only. Matched to the supplied updated ChipInventor top.
// Top ports: clk, rst (active high), pc_o.
// IMEM window: 0x00400000 to 0x007FFFFF; DMEM: 7 words (28 bytes).
// Full official firmware is embedded; 44 in-scope instruction types.
module testbench();

    reg clk_i = 0;
    reg rst_i = 1;

    wire [31:0] pc_o;
    top ai45 (
        .clk(clk_i),
        .rst(rst_i),
        .pc_o(pc_o)
    );

    // Simulation probes, not top-level ports.
    wire [31:0] debug_pc_o = pc_o;
    wire [31:0] debug_writeback_o = ai45.blk4028_5.write_data_i;
    wire debug_register_write_o = ai45.blk4028_5.write_enable_i;
    wire [4:0] debug_rd_o = ai45.blk4028_5.rd_address_i;

    always #5 clk_i = ~clk_i;

    // Update these references if ChipInventor renames the instances.
    wire [3:0] state = ai45.blk4026_79.state;
    wire [31:0] debug_x4_o = ai45.blk4028_5.registers[4];
    wire [31:0] instruction = ai45.blk4029_3.data_o;

    wire [31:0] bus_address = ai45.blk4016_92.address_i;
    wire [31:0] bus_data = ai45.blk4016_92.write_data_i;
    wire [3:0] bus_mask = ai45.blk4016_92.byte_write_i;
    wire bus_read = ai45.blk4016_92.read_enable_i;
    wire bus_write = ai45.blk4016_92.write_enable_i;
    wire branch_taken = ai45.blk4032_14.taken_o;

    // Reference architectural state.
    reg [31:0] r [0:31];
    reg [31:0] ram [0:6];

    reg [31:0] pc, insn, a, b, imm;
    reg [31:0] expected, next_pc, addr, store_data;
    reg [31:0] raw_word;

    reg [3:0] lanes;
    reg [4:0] rd;
    reg [6:0] op, f7;
    reg [2:0] f3;

    reg writes, is_load, is_store, is_branch, taken;
    reg [15:0] crc;
    reg signed [63:0] sa, sb, product;

    reg [8*10-1:0] mnemonic;
    reg [8*10-1:0] names [0:43];
    integer coverage [0:43];

    integer i, j, k, nbytes, bits, idx;
    integer cycles, run_number, retired, total_checks;
    integer register_checks, memory_checks, covered;
    integer stage;
    reg [8*32-1:0] stage_names [0:8];
    reg done;

    // Reference firmware image. No external hex file required.
    function [31:0] rom_word;
        input [29:0] word_address;
        begin
            case (word_address)
                30'h00100000: rom_word=32'h123452B7;
                30'h00100001: rom_word=32'h12345337;
                30'h00100002: rom_word=32'h3E629463;
                30'h00100003: rom_word=32'h00001297;
                30'h00100004: rom_word=32'h3E028063;
                30'h00100005: rom_word=32'h00A00293;
                30'h00100006: rom_word=32'hFFD28313;
                30'h00100007: rom_word=32'h00700393;
                30'h00100008: rom_word=32'h3C731863;
                30'h00100009: rom_word=32'h006283B3;
                30'h0010000A: rom_word=32'h01100E13;
                30'h0010000B: rom_word=32'h3DC39263;
                30'h0010000C: rom_word=32'h405E03B3;
                30'h0010000D: rom_word=32'h3A639E63;
                30'h0010000E: rom_word=32'h0FF00293;
                30'h0010000F: rom_word=32'h0F02C313;
                30'h00100010: rom_word=32'h00F00393;
                30'h00100011: rom_word=32'h3A731663;
                30'h00100012: rom_word=32'h7002E313;
                30'h00100013: rom_word=32'h7FF00393;
                30'h00100014: rom_word=32'h3A731063;
                30'h00100015: rom_word=32'h0F02F313;
                30'h00100016: rom_word=32'h0F000393;
                30'h00100017: rom_word=32'h38731A63;
                30'h00100018: rom_word=32'h0AA00293;
                30'h00100019: rom_word=32'h05500313;
                30'h0010001A: rom_word=32'h0062C3B3;
                30'h0010001B: rom_word=32'h0FF00E13;
                30'h0010001C: rom_word=32'h39C39063;
                30'h0010001D: rom_word=32'h0062E3B3;
                30'h0010001E: rom_word=32'h37C39C63;
                30'h0010001F: rom_word=32'h0062F3B3;
                30'h00100020: rom_word=32'h36039863;
                30'h00100021: rom_word=32'h00100293;
                30'h00100022: rom_word=32'h00429313;
                30'h00100023: rom_word=32'h01000393;
                30'h00100024: rom_word=32'h36731063;
                30'h00100025: rom_word=32'h0023D313;
                30'h00100026: rom_word=32'h00400E13;
                30'h00100027: rom_word=32'h35C31A63;
                30'h00100028: rom_word=32'hFF000293;
                30'h00100029: rom_word=32'h4022D313;
                30'h0010002A: rom_word=32'hFFC00393;
                30'h0010002B: rom_word=32'h34731263;
                30'h0010002C: rom_word=32'h00100293;
                30'h0010002D: rom_word=32'h00400313;
                30'h0010002E: rom_word=32'h006293B3;
                30'h0010002F: rom_word=32'h01000E13;
                30'h00100030: rom_word=32'h33C39863;
                30'h00100031: rom_word=32'h00200313;
                30'h00100032: rom_word=32'h006E53B3;
                30'h00100033: rom_word=32'h00400E93;
                30'h00100034: rom_word=32'h33D39063;
                30'h00100035: rom_word=32'hFF000293;
                30'h00100036: rom_word=32'h4062D3B3;
                30'h00100037: rom_word=32'hFFC00E93;
                30'h00100038: rom_word=32'h31D39863;
                30'h00100039: rom_word=32'h00A00293;
                30'h0010003A: rom_word=32'h0142A313;
                30'h0010003B: rom_word=32'h00100393;
                30'h0010003C: rom_word=32'h30731063;
                30'h0010003D: rom_word=32'hFF600293;
                30'h0010003E: rom_word=32'h0142B313;
                30'h0010003F: rom_word=32'h2E031A63;
                30'h00100040: rom_word=32'h00A00293;
                30'h00100041: rom_word=32'h01400313;
                30'h00100042: rom_word=32'h0062A3B3;
                30'h00100043: rom_word=32'h00100E13;
                30'h00100044: rom_word=32'h2FC39063;
                30'h00100045: rom_word=32'h005333B3;
                30'h00100046: rom_word=32'h2C039C63;
                30'h00100047: rom_word=32'h0FC10417;
                30'h00100048: rom_word=32'hEE440413;
                30'h00100049: rom_word=32'h12345337;
                30'h0010004A: rom_word=32'h67830313;
                30'h0010004B: rom_word=32'h00642023;
                30'h0010004C: rom_word=32'h0000B3B7;
                30'h0010004D: rom_word=32'hABB38393;
                30'h0010004E: rom_word=32'h00741223;
                30'h0010004F: rom_word=32'h0CC00E13;
                30'h00100050: rom_word=32'h01C40423;
                30'h00100051: rom_word=32'h00042E83;
                30'h00100052: rom_word=32'h2A6E9463;
                30'h00100053: rom_word=32'h00441F03;
                30'h00100054: rom_word=32'hFFFFBFB7;
                30'h00100055: rom_word=32'hABBF8F93;
                30'h00100056: rom_word=32'h29FF1C63;
                30'h00100057: rom_word=32'h00445F03;
                30'h00100058: rom_word=32'h0000BFB7;
                30'h00100059: rom_word=32'hABBF8F93;
                30'h0010005A: rom_word=32'h29FF1463;
                30'h0010005B: rom_word=32'h00840F03;
                30'h0010005C: rom_word=32'hFCC00F93;
                30'h0010005D: rom_word=32'h27FF1E63;
                30'h0010005E: rom_word=32'h00844F03;
                30'h0010005F: rom_word=32'h0CC00F93;
                30'h00100060: rom_word=32'h27FF1863;
                30'h00100061: rom_word=32'h00500293;
                30'h00100062: rom_word=32'h00A00313;
                30'h00100063: rom_word=32'h00500393;
                30'h00100064: rom_word=32'hFF600E13;
                30'h00100065: rom_word=32'hFF600E93;
                30'h00100066: rom_word=32'h00728463;
                30'h00100067: rom_word=32'h2540006F;
                30'h00100068: rom_word=32'h01DE0463;
                30'h00100069: rom_word=32'h24C0006F;
                30'h0010006A: rom_word=32'h00629463;
                30'h0010006B: rom_word=32'h2440006F;
                30'h0010006C: rom_word=32'h01C29463;
                30'h0010006D: rom_word=32'h23C0006F;
                30'h0010006E: rom_word=32'h0062C463;
                30'h0010006F: rom_word=32'h2340006F;
                30'h00100070: rom_word=32'h005E4463;
                30'h00100071: rom_word=32'h22C0006F;
                30'h00100072: rom_word=32'h00535463;
                30'h00100073: rom_word=32'h2240006F;
                30'h00100074: rom_word=32'h01C2D463;
                30'h00100075: rom_word=32'h21C0006F;
                30'h00100076: rom_word=32'h0062E463;
                30'h00100077: rom_word=32'h2140006F;
                30'h00100078: rom_word=32'h01C2E463;
                30'h00100079: rom_word=32'h20C0006F;
                30'h0010007A: rom_word=32'h00537463;
                30'h0010007B: rom_word=32'h2040006F;
                30'h0010007C: rom_word=32'h005E7463;
                30'h0010007D: rom_word=32'h1FC0006F;
                30'h0010007E: rom_word=32'h00800F6F;
                30'h0010007F: rom_word=32'h1F40006F;
                30'h00100080: rom_word=32'h00000F97;
                30'h00100081: rom_word=32'h010F8F93;
                30'h00100082: rom_word=32'h000F8067;
                30'h00100083: rom_word=32'h1E40006F;
                30'h00100084: rom_word=32'h00100013;
                30'h00100085: rom_word=32'h1C001E63;
                30'h00100086: rom_word=32'hDEADC2B7;
                30'h00100087: rom_word=32'hEEF28293;
                30'h00100088: rom_word=32'h00028313;
                30'h00100089: rom_word=32'h00030393;
                30'h0010008A: rom_word=32'h00038F93;
                30'h0010008B: rom_word=32'hDEADC2B7;
                30'h0010008C: rom_word=32'hEEF28293;
                30'h0010008D: rom_word=32'h1A5F9E63;
                30'h0010008E: rom_word=32'h000185B7;
                30'h0010008F: rom_word=32'h6A058593;
                30'h00100090: rom_word=32'h00200613;
                30'h00100091: rom_word=32'hEE6B36B7;
                30'h00100092: rom_word=32'h80068693;
                30'h00100093: rom_word=32'h000312B7;
                30'h00100094: rom_word=32'hD4028293;
                30'h00100095: rom_word=32'hDCD65337;
                30'h00100096: rom_word=32'hFFF00393;
                30'h00100097: rom_word=32'h00100E13;
                30'h00100098: rom_word=32'h02C58533;
                30'h00100099: rom_word=32'h18551663;
                30'h0010009A: rom_word=32'h02C68533;
                30'h0010009B: rom_word=32'h18651263;
                30'h0010009C: rom_word=32'h02C59533;
                30'h0010009D: rom_word=32'h16051E63;
                30'h0010009E: rom_word=32'h02C69533;
                30'h0010009F: rom_word=32'h16751A63;
                30'h001000A0: rom_word=32'h02C6B533;
                30'h001000A1: rom_word=32'h17C51663;
                30'h001000A2: rom_word=32'h02C6A533;
                30'h001000A3: rom_word=32'h16751263;
                30'h001000A4: rom_word=32'h02D62533;
                30'h001000A5: rom_word=32'h15C51E63;
                30'h001000A6: rom_word=32'h000028B7;
                30'h001000A7: rom_word=32'hE8288893;
                30'h001000A8: rom_word=32'h00010437;
                30'h001000A9: rom_word=32'hFFF40413;
                30'h001000AA: rom_word=32'h01200493;
                30'h001000AB: rom_word=32'h03400913;
                30'h001000AC: rom_word=32'h05600993;
                30'h001000AD: rom_word=32'h07800A13;
                30'h001000AE: rom_word=32'h09000A93;
                30'h001000AF: rom_word=32'h0AB00B13;
                30'h001000B0: rom_word=32'h0CD00B93;
                30'h001000B1: rom_word=32'h0EF00C13;
                30'h001000B2: rom_word=32'h80848433;
                30'h001000B3: rom_word=32'h80890433;
                30'h001000B4: rom_word=32'h80898433;
                30'h001000B5: rom_word=32'h808A0433;
                30'h001000B6: rom_word=32'h808A8433;
                30'h001000B7: rom_word=32'h808B0433;
                30'h001000B8: rom_word=32'h808B8433;
                30'h001000B9: rom_word=32'h808C0433;
                30'h001000BA: rom_word=32'h11141463;
                30'h001000BB: rom_word=32'h000102B7;
                30'h001000BC: rom_word=32'hFFF28293;
                30'h001000BD: rom_word=32'h00001337;
                30'h001000BE: rom_word=32'h23430313;
                30'h001000BF: rom_word=32'h000053B7;
                30'h001000C0: rom_word=32'h67838393;
                30'h001000C1: rom_word=32'h00009E37;
                30'h001000C2: rom_word=32'h0ABE0E13;
                30'h001000C3: rom_word=32'h0000DEB7;
                30'h001000C4: rom_word=32'hDEFE8E93;
                30'h001000C5: rom_word=32'h805312B3;
                30'h001000C6: rom_word=32'h805392B3;
                30'h001000C7: rom_word=32'h805E12B3;
                30'h001000C8: rom_word=32'h805E92B3;
                30'h001000C9: rom_word=32'h0D129663;
                30'h001000CA: rom_word=32'h00010537;
                30'h001000CB: rom_word=32'hFFF50513;
                30'h001000CC: rom_word=32'h123455B7;
                30'h001000CD: rom_word=32'h67858593;
                30'h001000CE: rom_word=32'h90ABD637;
                30'h001000CF: rom_word=32'hDEF60613;
                30'h001000D0: rom_word=32'h80A5A533;
                30'h001000D1: rom_word=32'h80A62533;
                30'h001000D2: rom_word=32'h0B151463;
                30'h001000D3: rom_word=32'h00000297;
                30'h001000D4: rom_word=32'h0AC28293;
                30'h001000D5: rom_word=32'h0002A303;
                30'h001000D6: rom_word=32'h0042A383;
                30'h001000D7: rom_word=32'h00010537;
                30'h001000D8: rom_word=32'hFFF50513;
                30'h001000D9: rom_word=32'h80A32533;
                30'h001000DA: rom_word=32'h80A3A533;
                30'h001000DB: rom_word=32'h000028B7;
                30'h001000DC: rom_word=32'hE8288893;
                30'h001000DD: rom_word=32'h07151E63;
                30'h001000DE: rom_word=32'h01400293;
                30'h001000DF: rom_word=32'h00A00313;
                30'h001000E0: rom_word=32'h006283B3;
                30'h001000E1: rom_word=32'h40628E33;
                30'h001000E2: rom_word=32'h03C38EB3;
                30'h001000E3: rom_word=32'h12C00F13;
                30'h001000E4: rom_word=32'h07EE9063;
                30'h001000E5: rom_word=32'h00000297;
                30'h001000E6: rom_word=32'h06C28293;
                30'h001000E7: rom_word=32'h0FC10317;
                30'h001000E8: rom_word=32'hC7430313;
                30'h001000E9: rom_word=32'h00300393;
                30'h001000EA: rom_word=32'h0002AE03;
                30'h001000EB: rom_word=32'h01C32023;
                30'h001000EC: rom_word=32'h00428293;
                30'h001000ED: rom_word=32'h00430313;
                30'h001000EE: rom_word=32'hFFF38393;
                30'h001000EF: rom_word=32'hFE0396E3;
                30'h001000F0: rom_word=32'h0FC10317;
                30'h001000F1: rom_word=32'hC5030313;
                30'h001000F2: rom_word=32'h00032E03;
                30'h001000F3: rom_word=32'h11111EB7;
                30'h001000F4: rom_word=32'h111E8E93;
                30'h001000F5: rom_word=32'h01DE1E63;
                30'h001000F6: rom_word=32'h00832E03;
                30'h001000F7: rom_word=32'h33333EB7;
                30'h001000F8: rom_word=32'h333E8E93;
                30'h001000F9: rom_word=32'h01DE1663;
                30'h001000FA: rom_word=32'h00000213;
                30'h001000FB: rom_word=32'h0000006F;
                30'h001000FC: rom_word=32'hFFF00213;
                30'h001000FD: rom_word=32'h0000006F;
                30'h001000FE: rom_word=32'h12345678;
                30'h001000FF: rom_word=32'h90ABCDEF;
                30'h00100100: rom_word=32'h11111111;
                30'h00100101: rom_word=32'h22222222;
                30'h00100102: rom_word=32'h33333333;
                default: rom_word=32'h00000013;
            endcase
        end
    endfunction

    function [31:0] memory_word;
        input [31:0] address;
        begin
            if (address >= 32'h00400000 &&
                address < 32'h00800000)
                memory_word = rom_word(address[31:2]);
            else if (address >= 32'h10010000 &&
                     address < 32'h1001001C)
                memory_word = ram[(address-32'h10010000)>>2];
            else
                memory_word = 0;
        end
    endfunction

    task compare;
        input [8*18-1:0] field;
        input [31:0] actual, want;
        begin
            $display(
                "run=%0d PC=%h %-10s %-18s expected=%h actual=%h %0s",
                run_number, pc, mnemonic, field, want, actual,
                (actual === want) ? "PASS" : "FAIL"
            );

            if (actual !== want)
                $finish;

            total_checks = total_checks + 1;
        end
    endtask

    // Predict results from reference registers and reference memory.
    task predict;
        begin
            insn = rom_word(pc[31:2]);
            op = insn[6:0];
            f3 = insn[14:12];
            f7 = insn[31:25];
            rd = insn[11:7];

            a = r[insn[19:15]];
            b = r[insn[24:20]];
            imm = {{20{insn[31]}}, insn[31:20]};

            next_pc = pc + 4;
            expected = 0;
            writes = 0;
            is_load = 0;
            is_store = 0;
            is_branch = 0;
            taken = 0;
            addr = 0;
            store_data = 0;
            lanes = 0;
            idx = -1;

            case (op)
                7'h37: begin
                    idx = 0;
                    writes = 1;
                    expected = {insn[31:12], 12'b0};
                end

                7'h17: begin
                    idx = 1;
                    writes = 1;
                    expected = pc + {insn[31:12], 12'b0};
                end

                7'h6F: begin
                    idx = 2;
                    writes = 1;
                    expected = pc + 4;
                    imm = {
                        {11{insn[31]}}, insn[31],
                        insn[19:12], insn[20],
                        insn[30:21], 1'b0
                    };
                    next_pc = pc + imm;
                end

                7'h67: begin
                    idx = 3;
                    writes = 1;
                    expected = pc + 4;
                    next_pc = (a + imm) & 32'hFFFFFFFE;
                end

                7'h63: begin
                    is_branch = 1;
                    imm = {
                        {19{insn[31]}}, insn[31], insn[7],
                        insn[30:25], insn[11:8], 1'b0
                    };

                    case (f3)
                        0: begin idx=4; taken=(a==b); end
                        1: begin idx=5; taken=(a!=b); end
                        4: begin
                            idx=6;
                            taken=($signed(a)<$signed(b));
                        end
                        5: begin
                            idx=7;
                            taken=($signed(a)>=$signed(b));
                        end
                        6: begin idx=8; taken=(a<b); end
                        7: begin idx=9; taken=(a>=b); end
                    endcase

                    if (taken)
                        next_pc = pc + imm;
                end

                7'h03: begin
                    writes = 1;
                    is_load = 1;
                    addr = a + imm;
                    raw_word = memory_word(addr) >> (8*addr[1:0]);

                    case (f3)
                        0: begin
                            idx=10;
                            expected={
                                {24{raw_word[7]}}, raw_word[7:0]
                            };
                        end
                        1: begin
                            idx=11;
                            expected={
                                {16{raw_word[15]}}, raw_word[15:0]
                            };
                        end
                        2: begin idx=12; expected=raw_word; end
                        4: begin
                            idx=13;
                            expected={24'b0, raw_word[7:0]};
                        end
                        5: begin
                            idx=14;
                            expected={16'b0, raw_word[15:0]};
                        end
                    endcase
                end

                7'h23: begin
                    is_store = 1;
                    imm = {
                        {20{insn[31]}},
                        insn[31:25], insn[11:7]
                    };
                    addr = a + imm;
                    nbytes = 1 << f3;
                    idx = 15 + f3;
                    lanes = ((1 << nbytes)-1) << addr[1:0];
                    store_data = b << (8*addr[1:0]);
                end

                7'h13: begin
                    writes = 1;
                    case (f3)
                        0: begin idx=18; expected=a+imm; end
                        2: begin
                            idx=19;
                            expected=($signed(a)<$signed(imm));
                        end
                        3: begin idx=20; expected=(a<imm); end
                        4: begin idx=21; expected=a^imm; end
                        6: begin idx=22; expected=a|imm; end
                        7: begin idx=23; expected=a&imm; end
                        1: begin
                            idx=24;
                            expected=a<<insn[24:20];
                        end
                        5: begin
                            if (insn[30]) begin
                                idx=26;
                                expected=$signed(a)>>>insn[24:20];
                            end
                            else begin
                                idx=25;
                                expected=a>>insn[24:20];
                            end
                        end
                    endcase
                end

                7'h33: begin
                    writes = 1;

                    if (f7 == 1) begin
                        idx = 37 + f3;

                        // Independent signed high-half calculation.
                        sa = {32'b0, a};
                        sb = {32'b0, b};

                        if (f3 == 1 || f3 == 2)
                            sa = {{32{a[31]}}, a};

                        if (f3 == 1)
                            sb = {{32{b[31]}}, b};

                        product = sa * sb;

                        expected = (f3 == 0)
                                 ? product[31:0]
                                 : product[63:32];
                    end
                    else if (f7 == 7'h40) begin
                        idx = 41 + f3;
                        bits = 8 << f3;
                        crc = b[15:0];

                        // CRC calculation uses no function.
                        for (k=bits-1; k>=0; k=k-1) begin
                            if (crc[15] ^ a[k])
                                crc = (crc << 1) ^ 16'h1021;
                            else
                                crc = crc << 1;
                        end

                        expected = {16'b0, crc};
                    end
                    else begin
                        case (f3)
                            0: begin
                                if (insn[30]) begin
                                    idx=28;
                                    expected=a-b;
                                end
                                else begin
                                    idx=27;
                                    expected=a+b;
                                end
                            end
                            1: begin idx=29; expected=a<<b[4:0]; end
                            2: begin
                                idx=30;
                                expected=($signed(a)<$signed(b));
                            end
                            3: begin idx=31; expected=(a<b); end
                            4: begin idx=32; expected=a^b; end
                            5: begin
                                if (insn[30]) begin
                                    idx=34;
                                    expected=$signed(a)>>>b[4:0];
                                end
                                else begin
                                    idx=33;
                                    expected=a>>b[4:0];
                                end
                            end
                            6: begin idx=35; expected=a|b; end
                            7: begin idx=36; expected=a&b; end
                        endcase
                    end
                end

            endcase

            if (idx < 0 || idx > 43) begin
                $display(
                    "FAIL: unsupported reference instruction %h at %h",
                    insn, pc
                );
                $finish;
            end

            mnemonic = names[idx];
            compare("instruction", instruction, insn);

            if (is_branch)
                compare(
                    "branch taken",
                    {31'b0, branch_taken},
                    {31'b0, taken}
                );
        end
    endtask

    task run_test;
        begin
            @(negedge clk_i);
            rst_i = 1;

            for (i=0; i<32; i=i+1)
                r[i] = 0;

            pc = 32'h00400000;
            cycles = 0;
            retired = 0;
            done = 0;
            stage = 0;
            mnemonic = "RESET";

            repeat (3) begin
                @(posedge clk_i);
                #1;
                compare("PC", debug_pc_o, pc);
                compare(
                    "write enable",
                    {31'b0, debug_register_write_o},
                    0
                );
            end

            @(negedge clk_i);
            rst_i = 0;

            while (!done && cycles < 5000) begin
                @(posedge clk_i);
                cycles = cycles + 1;

                // EXECUTE: calculate expected architectural results.
                if (state === 4'd2)
                    predict;

                // MEM_REQUEST: check the actual memory transaction.
                if (state === 4'd3) begin
                    compare("memory address", bus_address, addr);
                    compare(
                        "memory read",
                        {31'b0, bus_read},
                        {31'b0, is_load}
                    );
                    compare(
                        "memory write",
                        {31'b0, bus_write},
                        {31'b0, is_store}
                    );

                    if (is_store) begin
                        compare("store data", bus_data, store_data);
                        compare(
                            "byte mask",
                            {28'b0, bus_mask},
                            {28'b0, lanes}
                        );

                        if (addr >= 32'h10010000 &&
                            addr < 32'h1001001C) begin
                            for (j=0; j<4; j=j+1)
                                if (lanes[j])
                                    ram[(addr-32'h10010000)>>2]
                                       [j*8 +: 8] =
                                        store_data[j*8 +: 8];
                        end
                    end
                end

                // WRITEBACK: sample before the DUT's register update.
                if (state === 4'd5) begin
                    compare("next PC", debug_pc_o, next_pc);
                    compare(
                        "register write",
                        {31'b0, debug_register_write_o},
                        {31'b0, writes}
                    );

                    if (writes) begin
                        compare(
                            "destination rd",
                            {27'b0, debug_rd_o},
                            {27'b0, rd}
                        );
                        compare(
                            "writeback data",
                            debug_writeback_o,
                            expected
                        );

                        if (rd != 0)
                            r[rd] = expected;
                    end

                    coverage[idx] = coverage[idx] + 1;
                    retired = retired + 1;

                    // Check actual register contents after the update.
                    #1;
                    for (j=0; j<32; j=j+1) begin
                        register_checks = register_checks + 1;
                        if (ai45.blk4028_5.registers[j] !== r[j]) begin
                            $display(
                                "FAIL: register x%0d expected=%h actual=%h",
                                j, r[j], ai45.blk4028_5.registers[j]
                            );
                            $finish;
                        end
                    end

                    // Report a block only after its final check retires successfully.
                    if ((stage==0 && pc==32'h00400118 && next_pc==32'h0040011C) ||
                        (stage==1 && pc==32'h00400180 && next_pc==32'h00400184) ||
                        (stage==2 && pc==32'h00400208 && next_pc==32'h00400210) ||
                        (stage==3 && pc==32'h00400234 && next_pc==32'h00400238) ||
                        (stage==4 && pc==32'h00400294 && next_pc==32'h00400298) ||
                        (stage==5 && pc==32'h00400348 && next_pc==32'h0040034C) ||
                        (stage==6 && pc==32'h00400374 && next_pc==32'h00400378) ||
                        (stage==7 && pc==32'h00400390 && next_pc==32'h00400394) ||
                        (stage==8 && pc==32'h004003E4 && next_pc==32'h004003E8)) begin
                        $display("STAGE PASS run=%0d %0s", run_number, stage_names[stage]);
                        stage = stage + 1;
                    end

                    // Complete one iteration of the success loop.
                    if (pc == 32'h004003EC && r[4] === 32'b0)
                        done = 1;

                    if (pc == 32'h004003F4) begin
                        $display("FAIL: firmware error loop");
                        $finish;
                    end

                    pc = next_pc;
                end

                if (state === 4'd6) begin
                    $display(
                        "FAIL: unexpected HALT; firmware did not finish"
                    );
                    $finish;
                end
            end

            if (!done) begin
                $display("FAIL: timeout");
                $finish;
            end

            if (stage != 9) begin
                $display("FAIL: only %0d of 9 firmware stages completed", stage);
                $finish;
            end
            compare("final x4", debug_x4_o, 32'b0);
            // Check every reference RAM byte with a known value.
            for (i=0; i<7; i=i+1) begin
                for (j=0; j<4; j=j+1) begin
                    if ((^ram[i][j*8 +: 8]) !== 1'bx)
                        memory_checks = memory_checks + 1;
                    if ((^ram[i][j*8 +: 8]) !== 1'bx &&
                        ai45.blk4016_92.dmem_inst.memory[i]
                            [j*8 +: 8] !== ram[i][j*8 +: 8]) begin

                        $display(
                            "FAIL: RAM word=%0d lane=%0d expected=%h actual=%h",
                            i, j, ram[i][j*8 +: 8],
                            ai45.blk4016_92.dmem_inst.memory[i]
                                [j*8 +: 8]
                        );
                        $finish;
                    end
                end
            end

            $display(
                "PASS RUN %0d: %0d completed instructions, %0d cycles",
                run_number, retired, cycles
            );
        end
    endtask

    initial begin
        total_checks = 0;
        register_checks = 0; memory_checks = 0;
        stage_names[0] = "_rv32i_alu_test";
        stage_names[1] = "_rv32i_lsu_test";
        stage_names[2] = "_rv32i_ctrl_test";
        stage_names[3] = "_rv32i_reg_test";
        stage_names[4] = "_rvbl2_mult_test";
        stage_names[5] = "_rvbl2_crc_test";
        stage_names[6] = "_rvbl2_crc_mem_test";
        stage_names[7] = "_rvbl2_arith_integ_test";
        stage_names[8] = "_rvbl2_mem_transfer_test";

        names[0]  = "LUI";
        names[1]  = "AUIPC";
        names[2]  = "JAL";
        names[3]  = "JALR";
        names[4]  = "BEQ";
        names[5]  = "BNE";
        names[6]  = "BLT";
        names[7]  = "BGE";
        names[8]  = "BLTU";
        names[9]  = "BGEU";
        names[10] = "LB";
        names[11] = "LH";
        names[12] = "LW";
        names[13] = "LBU";
        names[14] = "LHU";
        names[15] = "SB";
        names[16] = "SH";
        names[17] = "SW";
        names[18] = "ADDI";
        names[19] = "SLTI";
        names[20] = "SLTIU";
        names[21] = "XORI";
        names[22] = "ORI";
        names[23] = "ANDI";
        names[24] = "SLLI";
        names[25] = "SRLI";
        names[26] = "SRAI";
        names[27] = "ADD";
        names[28] = "SUB";
        names[29] = "SLL";
        names[30] = "SLT";
        names[31] = "SLTU";
        names[32] = "XOR";
        names[33] = "SRL";
        names[34] = "SRA";
        names[35] = "OR";
        names[36] = "AND";
        names[37] = "MUL";
        names[38] = "MULH";
        names[39] = "MULHSU";
        names[40] = "MULHU";
        names[41] = "CRCB";
        names[42] = "CRCH";
        names[43] = "CRCW";

        for (i=0; i<44; i=i+1)
            coverage[i] = 0;

        // Reference RAM starts unknown and is retained across reset.
        for (run_number=1; run_number<=2; run_number=run_number+1)
            run_test;

        covered = 0;
        for (i=0; i<44; i=i+1)
            if (coverage[i] > 0) covered = covered + 1;
        if (covered != 44) begin
            $display("FAIL: instruction coverage %0d/44", covered);
            $finish;
        end
        $display("INSTRUCTION COVERAGE (both firmware runs; system/synchronization excluded)");

        for (i=0; i<44; i=i+1)
            $display(
                "%-10s executed=%0d %0s",
                names[i], coverage[i],
                coverage[i] ? "TESTED" : "NOT EXERCISED"
            );

        $display(
            "PASS: all executed instructions matched; %0d field comparisons",
            total_checks
        );
        $display("SUMMARY: 44/44 instruction types; 9/9 stages per run; %0d register checks; %0d memory-byte checks", register_checks, memory_checks);
        $finish;
    end

    initial begin
        #120000;
        $display("FAIL: global timeout");
        $finish;
    end

    initial begin
        $dumpfile("waves/top_firmware.vcd");
        $dumpvars(1, testbench);
    end

endmodule