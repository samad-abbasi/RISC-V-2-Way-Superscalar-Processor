module Top2W(input logic clk, input logic rst);

    // Fetch -> Decode
    logic [31:0] InstrD0, InstrD1;
    logic [31:0] PCD0, PCD1;
    logic [31:0] PCPlus4D0, PCPlus4D1;
    logic        PredictTakenD;
    logic        ValidD1;

    // Decode -> Execute
    logic        PredictTakenE;
    logic        RegWriteE0, RegWriteE1;
    logic        MemWriteE0, MemWriteE1;
    logic        JumpE0, JumpE1;
    logic        BranchE0, BranchE1;
    logic        ALUSrcE0, ALUSrcE1;
    logic [1:0]  ResultSrcE0, ResultSrcE1;
    logic [2:0]  ALUControlE0, ALUControlE1;
    logic [4:0]  RdE0, RdE1;
    logic [4:0]  Rs1E0, Rs1E1;
    logic [4:0]  Rs2E0, Rs2E1;
    logic [31:0] RD1E0, RD1E1;
    logic [31:0] RD2E0, RD2E1;
    logic [31:0] PCE0, PCE1;
    logic [31:0] PCPlus4E0, PCPlus4E1;
    logic [31:0] ImmExtE0, ImmExtE1;
    logic        ValidE1;

    // Execute -> Memory
    logic        RegWriteM0, RegWriteM1;
    logic        MemWriteM0, MemWriteM1;
    logic [1:0]  ResultSrcM0, ResultSrcM1;
    logic [31:0] ALUResultM0, ALUResultM1;
    logic [31:0] WriteDataM0, WriteDataM1;
    logic [4:0]  RdM0, RdM1;
    logic [31:0] PCPlus4M0, PCPlus4M1;
    // Branch outputs from Execute stage
    logic        PCSrcE;
    logic [31:0] PCTargetE;

    // Memory -> Writeback
    logic        RegWriteW0, RegWriteW1;
    logic [1:0]  ResultSrcW0, ResultSrcW1;
    logic [31:0] ALUResultW0, ALUResultW1;
    logic [31:0] ReadDataW0, ReadDataW1;
    logic [31:0] PCPlus4W0, PCPlus4W1;
    logic [4:0]  RdW0, RdW1;

    // Writeback -> Decode (results written to register file)
    logic [31:0] ResultW0, ResultW1;

    // Hazard signals
    logic [1:0]  ForwardAE0, ForwardBE0;
    logic [1:0]  ForwardAE1, ForwardBE1;
    logic        StallF, StallD, FlushD, FlushE;

    // FETCH STAGE
Fetch2W fetch_inst (
    .clk(clk), .rst(rst), .PCTargetE(PCTargetE), .PCSrcE(PCSrcE),
    .StallF(StallF), .StallD(StallD), .FlushD(FlushD), .BranchE(BranchE0),
    .PCE(PCE0), .InstrD0(InstrD0), .InstrD1(InstrD1), .PCD0(PCD0),
    .PCD1(PCD1), .PCPlus4D0(PCPlus4D0), .PCPlus4D1(PCPlus4D1),
    .PredictTakenD(PredictTakenD), .ValidD1(ValidD1)
);

    // DECODE STAGE
Decode2W decode_inst (
    .clk(clk), .rst(rst), .RegWriteW0(RegWriteW0), .RegWriteW1(RegWriteW1),
    .ResultW0(ResultW0), .ResultW1(ResultW1), .RdW0(RdW0), .RdW1(RdW1),
    .InstrD0(InstrD0), .InstrD1(InstrD1), .PCD0(PCD0), .PCD1(PCD1),
    .PCPlus4D0(PCPlus4D0), .PCPlus4D1(PCPlus4D1), .PredictTakenD(PredictTakenD),
    .ValidD1(ValidD1), .FlushE(FlushE), .PredictTakenE(PredictTakenE),
    .RegWriteE0(RegWriteE0), .RegWriteE1(RegWriteE1), .MemWriteE0(MemWriteE0),
    .MemWriteE1(MemWriteE1), .JumpE0(JumpE0), .JumpE1(JumpE1),
    .BranchE0(BranchE0), .BranchE1(BranchE1), .ALUSrcE0(ALUSrcE0),
    .ALUSrcE1(ALUSrcE1), .ResultSrcE0(ResultSrcE0), .ResultSrcE1(ResultSrcE1),
    .ALUControlE0(ALUControlE0), .ALUControlE1(ALUControlE1), .RdE0(RdE0),
    .RdE1(RdE1), .Rs1E0(Rs1E0), .Rs1E1(Rs1E1), .Rs2E0(Rs2E0),
    .Rs2E1(Rs2E1), .RD1E0(RD1E0), .RD1E1(RD1E1), .RD2E0(RD2E0),
    .RD2E1(RD2E1), .PCE0(PCE0), .PCE1(PCE1), .PCPlus4E0(PCPlus4E0),
    .PCPlus4E1(PCPlus4E1), .ImmExtE0(ImmExtE0), .ImmExtE1(ImmExtE1),
    .ValidE1(ValidE1)
);


    // EXECUTE STAGE
Execute2W execute_inst (
    .clk(clk), .rst(rst), .RegWriteE0(RegWriteE0), .RegWriteE1(RegWriteE1),
    .MemWriteE0(MemWriteE0), .MemWriteE1(MemWriteE1), .JumpE0(JumpE0),
    .JumpE1(JumpE1), .BranchE0(BranchE0), .BranchE1(BranchE1),
    .ALUSrcE0(ALUSrcE0), .ALUSrcE1(ALUSrcE1), .ResultSrcE0(ResultSrcE0),
    .ResultSrcE1(ResultSrcE1), .ALUControlE0(ALUControlE0), .ALUControlE1(ALUControlE1),
    .RD1E0(RD1E0), .RD1E1(RD1E1), .RD2E0(RD2E0), .RD2E1(RD2E1),
    .PCE0(PCE0), .PCE1(PCE1), .PCPlus4E0(PCPlus4E0), .PCPlus4E1(PCPlus4E1),
    .ImmExtE0(ImmExtE0), .ImmExtE1(ImmExtE1), .Rs1E0(Rs1E0), .Rs2E0(Rs2E0),
    .Rs1E1(Rs1E1), .Rs2E1(Rs2E1), .RdE0(RdE0), .RdE1(RdE1),
    .ForwardAE0(ForwardAE0), .ForwardBE0(ForwardBE0), .ForwardAE1(ForwardAE1),
    .ForwardBE1(ForwardBE1), .ALUResultM0(ALUResultM0), .ALUResultM1(ALUResultM1),
    .RegWriteM0(RegWriteM0), .RegWriteM1(RegWriteM1), .RdM0(RdM0),
    .RdM1(RdM1), .ResultW0(ResultW0), .ResultW1(ResultW1),
    .RegWriteW0(RegWriteW0), .RegWriteW1(RegWriteW1), .RdW0(RdW0),
    .RdW1(RdW1), .RegWriteM0_out(RegWriteM0), .RegWriteM1_out(RegWriteM1),
    .MemWriteM0_out(MemWriteM0), .MemWriteM1_out(MemWriteM1),
    .ResultSrcM0_out(ResultSrcM0), .ResultSrcM1_out(ResultSrcM1),
    .ALUResultM0_out(ALUResultM0), .ALUResultM1_out(ALUResultM1),
    .WriteDataM0_out(WriteDataM0), .WriteDataM1_out(WriteDataM1),
    .RdM0_out(RdM0), .RdM1_out(RdM1), .PCPlus4M0(PCPlus4M0),
    .PCPlus4M1(PCPlus4M1), .PCSrcE(PCSrcE), .PCTargetE(PCTargetE)
);

    // MEMORY STAGE
Memory2W memory_inst (
    .clk(clk), .rst(rst), .RegWriteM0(RegWriteM0), .RegWriteM1(RegWriteM1),
    .MemWriteM0(MemWriteM0), .MemWriteM1(MemWriteM1), .ResultSrcM0(ResultSrcM0),
    .ResultSrcM1(ResultSrcM1), .ALUResultM0(ALUResultM0), .ALUResultM1(ALUResultM1),
    .WriteDataM0(WriteDataM0), .WriteDataM1(WriteDataM1), .PCPlus4M0(PCPlus4M0),
    .PCPlus4M1(PCPlus4M1), .RdM0(RdM0), .RdM1(RdM1), .RegWriteW0(RegWriteW0),
    .RegWriteW1(RegWriteW1), .ResultSrcW0(ResultSrcW0), .ResultSrcW1(ResultSrcW1),
    .ALUResultW0(ALUResultW0), .ALUResultW1(ALUResultW1), .ReadDataW0(ReadDataW0),
    .ReadDataW1(ReadDataW1), .PCPlus4W0(PCPlus4W0), .PCPlus4W1(PCPlus4W1),
    .RdW0(RdW0), .RdW1(RdW1)
);

    // WRITEBACK STAGE
WriteBack2W writeback_inst (
    .RegWriteW0(RegWriteW0), .RegWriteW1(RegWriteW1), .ALUResultW0(ALUResultW0),
    .ALUResultW1(ALUResultW1), .ReadDataW0(ReadDataW0), .ReadDataW1(ReadDataW1),
    .PCPlus4W0(PCPlus4W0), .PCPlus4W1(PCPlus4W1), .RdW0(RdW0),
    .RdW1(RdW1), .ResultSrcW0(ResultSrcW0), .ResultSrcW1(ResultSrcW1),
    .ResultW0(ResultW0), .ResultW1(ResultW1)
);

    // HAZARD DETECTION AND FORWARDING
Hazard_Unit2W hazard_inst (
    .Rs1D0(Rs1D0), .Rs2D0(InstrD0[24:20]), .Rs1D1(InstrD1[19:15]), .Rs2D1(InstrD1[24:20]),
    .ValidD1(ValidD1), .Rs1E0(Rs1E0), .Rs2E0(Rs2E0), .Rs1E1(Rs1E1),
    .Rs2E1(Rs2E1), .RdE0(RdE0), .RdE1(RdE1), .ResultSrcE0(ResultSrcE0),
    .ResultSrcE1(ResultSrcE1), .RdM0(RdM0), .RdM1(RdM1), .RegWriteM0(RegWriteM0),
    .RegWriteM1(RegWriteM1), .RdW0(RdW0), .RdW1(RdW1), .RegWriteW0(RegWriteW0),
    .RegWriteW1(RegWriteW1), .BranchE0(BranchE0), .PredictTakenE(PredictTakenE),
    .PCSrcE(PCSrcE), .StallF(StallF), .StallD(StallD), .FlushD(FlushD),
    .FlushE(FlushE), .ForwardAE0(ForwardAE0), .ForwardBE0(ForwardBE0),
    .ForwardAE1(ForwardAE1), .ForwardBE1(ForwardBE1)
);

endmodule