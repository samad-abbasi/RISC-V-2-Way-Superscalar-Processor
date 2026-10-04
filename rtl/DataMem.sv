
module DataMem2W(
    input  logic        clk,
    // Port 0
    input  logic        WE0,
    input  logic [31:0] A0,
    input  logic [31:0] WD0,
    output logic [31:0] RD0,
    // Port 1
    input  logic        WE1,
    input  logic [31:0] A1,
    input  logic [31:0] WD1,
    output logic [31:0] RD1
);

    // 1 KB byte?addressable memory (as in the original DataMem)
    logic [7:0] memory [1023:0];

    // WRITE Operations: apply writes from port 0 first, then port 1.  In case
    // both ports write to the same byte address, port 1 wins the race.
    always @(posedge clk) begin
        // Port 0 write
        if (WE0) begin
            memory[A0]     <= WD0[7:0];
            memory[A0 + 1] <= WD0[15:8];
            memory[A0 + 2] <= WD0[23:16];
            memory[A0 + 3] <= WD0[31:24];
        end
        // Port 1 write
        if (WE1) begin
            memory[A1]     <= WD1[7:0];
            memory[A1 + 1] <= WD1[15:8];
            memory[A1 + 2] <= WD1[23:16];
            memory[A1 + 3] <= WD1[31:24];
        end
    end

    // READ Operations: combinational reads for each port
    always @(*) begin
        RD0[7:0]   = memory[A0];
        RD0[15:8]  = memory[A0 + 1];
        RD0[23:16] = memory[A0 + 2];
        RD0[31:24] = memory[A0 + 3];

        RD1[7:0]   = memory[A1];
        RD1[15:8]  = memory[A1 + 1];
        RD1[23:16] = memory[A1 + 2];
        RD1[31:24] = memory[A1 + 3];
    end

endmodule