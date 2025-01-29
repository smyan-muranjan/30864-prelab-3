`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_ahb_lite_satellite ();

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst;

    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    task reset_dut;
    begin
        n_rst = 0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        @(posedge clk);
        @(posedge clk);
    end
    endtask

    // bus model signals
    logic enqueue_transaction_en;
    logic transaction_write;
    logic transaction_fake;
    logic [3:0] transaction_addr;
    logic [15:0] transaction_data;
    logic transaction_error;
    logic [2:0] transaction_size;

    logic model_reset;
    logic enable_transactions;
    integer current_transaction_num;
    logic current_transaction_error;

    logic hsel;
    logic [1:0] htrans;
    logic [3:0] haddr;
    logic [2:0] hsize;
    logic hwrite;
    logic [15:0] hwdata;
    logic [15:0] hrdata;
    logic hresp;

    ahb_lite_model BFM (.clk(clk),
        // Testing setup signals
        .enqueue_transaction(enqueue_transaction_en),
        .transaction_write(transaction_write),
        .transaction_fake(transaction_fake),
        .transaction_addr(transaction_addr),
        .transaction_data(transaction_data),
        .transaction_error(transaction_error),
        .transaction_size(transaction_size),
        // Testing controls
        .model_reset(model_reset),
        .enable_transactions(enable_transactions),
        .current_transaction_num(current_transaction_num),
        .current_transaction_error(current_transaction_error),
        // AHB-Lite-Satellite Side
        .hsel(hsel),
        .htrans(htrans),
        .haddr(haddr),
        .hsize(hsize),
        .hwrite(hwrite),
        .hwdata(hwdata),
        .hrdata(hrdata),
        .hresp(hresp)
    );
    logic clear_coeff, modwait, err, data_ready, new_coefficient_set;
    logic [1:0] coefficient_num;
    logic [15:0] fir_out, sample_data;
    ahb_lite_satellite DUT (
        .clk(clk), .n_rst(n_rst), .clear_coeff(clear_coeff), .modwait(modwait), 
        .err(err), .hsel(hsel), .hsize(hsize[0]), .hwrite(hwrite),
        .coefficient_num(coefficient_num), .htrans(htrans), .haddr(haddr),
        .hwdata(hwdata), .fir_out(fir_out), .data_ready(data_ready), .new_coefficient_set(new_coefficient_set), 
        .hresp(hresp), .sample_data(sample_data), .fir_coefficient(fir_coefficient), .hrdata(hrdata)
    );
    // bus model tasks
    task reset_model;
    begin
        model_reset = 1'b1;
        #(0.1);
        model_reset = 1'b0;
    end
    endtask
    
    task enqueue_transaction;
        input logic for_dut;
        input logic write_mode;
        input logic [3:0] address;
        input logic [15:0] data;
        input logic expected_error;
        input logic size;
    begin
        // Make sure enqueue flag is low (will need a 0->1 pulse later)
        enqueue_transaction_en = 1'b0;
        #(0.1ns);
    
        // Setup info about transaction
        transaction_fake  = ~for_dut;
        transaction_write = write_mode;
        transaction_addr  = address;
        transaction_data  = data;
        transaction_error = expected_error;
        transaction_size  = {2'b00,size};
    
        // Pulse the enqueue flag
        enqueue_transaction_en = 1'b1;
        #(0.1ns);
        enqueue_transaction_en = 1'b0;
    end
    endtask
    
    task execute_transactions;
        input integer num_transactions;
        integer wait_var;
    begin
        // Activate the bus model
        enable_transactions = 1'b1;
        @(posedge clk);
    
        // Process the transactions (all but last one overlap 1 out of 2 cycles
        for(wait_var = 0; wait_var < num_transactions; wait_var++) begin
            @(posedge clk);
        end
    
        // Run out the last one (currently in data phase)
        @(posedge clk);
    
        // Turn off the bus model
        @(negedge clk);
        enable_transactions = 1'b0;
    end
    endtask

    initial begin
        n_rst = 1;

        model_reset = 1'b0;
        enable_transactions = 1'b0;
        enqueue_transaction_en = 1'b0;
        transaction_write = 1'b0;
        transaction_fake = 1'b0;
        transaction_addr = '0;
        transaction_data = '0;
        transaction_error = 1'b0;
        transaction_size = 3'd0;

        fir_out = 16'b0110011001100110;
        coefficient_num = 2'd0;
        clear_coeff = 0;
        modwait = 0;
        err = 0;

        reset_model;
        reset_dut;
        // update f0 coefficient.
        enqueue_transaction(
            .for_dut(1'b1),
            .write_mode(1'b1),
            .address(4'd6),
            .data(16'b1000000000000000),
            .expected_error(1'b0),
            .size(1'b1)
        );

        // update f1 coefficient.
        enqueue_transaction(
            .for_dut(1'b1),
            .write_mode(1'b1),
            .address(4'd9),
            .data(16'b0000000000100000),
            .expected_error(1'b0),
            .size(1'b0)
        );

        // check f0 coefficient.
        enqueue_transaction(
            .for_dut(1'b1),
            .write_mode(1'b0),
            .address(4'd6),
            .data(16'b1000000000000000),
            .expected_error(1'b0),
            .size(1'b1)
        );

        // check f1 coefficient.
        enqueue_transaction(
            .for_dut(1'b1),
            .write_mode(1'b0),
            .address(4'd9),
            .data(16'b000000001000000),
            .expected_error(1'b0),
            .size(1'b0)
        );

        // check f0 coefficient.
        enqueue_transaction(
            .for_dut(1'b1),
            .write_mode(1'b0),
            .address(4'd6),
            .data(16'b1000000000000000),
            .expected_error(1'b0),
            .size(1'b1)
        );

        // check f1 coefficient.
        enqueue_transaction(
            .for_dut(1'b1),
            .write_mode(1'b0),
            .address(4'd9),
            .data(16'b000000001000000),
            .expected_error(1'b0),
            .size(1'b0)
        );

        // update sample.
        enqueue_transaction(
            .for_dut(1'b1),
            .write_mode(1'b1),
            .address(4'd4),
            .data(16'b1010101010101010),
            .expected_error(1'b0),
            .size(1'b1)
        );

        // check sample
        enqueue_transaction(
            .for_dut(1'b1),
            .write_mode(1'b0),
            .address(4'd4),
            .data(16'b1010101010101010),
            .expected_error(1'b0),
            .size(1'b1)
        );
        enqueue_transaction(
            .for_dut(1'b1),
            .write_mode(1'b0),
            .address(4'd4),
            .data(16'b1010101010101010),
            .expected_error(1'b0),
            .size(1'b1)
        );

        // check result
        enqueue_transaction(
            .for_dut(1'b1),
            .write_mode(1'b0),
            .address(4'd2),
            .data(16'b0110011001100110),
            .expected_error(1'b0),
            .size(1'b1)
        );

        // trying to write to result register
        enqueue_transaction(
            .for_dut(1'b1),
            .write_mode(1'b1),
            .address(4'd2),
            .data(16'b0110011001100110),
            .expected_error(1'b1),
            .size(1'b1)
        );

        // trying to read invalid memory
        enqueue_transaction(
            .for_dut(1'b1),
            .write_mode(1'b0),
            .address(4'hF),
            .data(16'b1010101010101010),
            .expected_error(1'b0),
            .size(1'b0)
        );
        // 2 byte read of invalid memory
        enqueue_transaction(
            .for_dut(1'b1),
            .write_mode(1'b0),
            .address(4'h5),
            .data(16'b1010101010101010),
            .expected_error(1'b0),
            .size(1'b1)
        );
        execute_transactions(13);
        $finish;
    end
endmodule

/* verilator coverage_on */

