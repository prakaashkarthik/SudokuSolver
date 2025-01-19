typedef enum {
    IDLE,
    LOAD,
    COMPUTE_POSSIBLE_VALUES,
    SOLVE,
    DONE
} solver_fsm_e;


/* verilator lint_off UNOPTFLAT */
module sudoku (
    input logic clk,
    input logic rst_b,
    input logic [3:0] in_grid [9][9],

    output logic [3:0] solved_grid [9][9]

);

    logic [8:0][8:0][3:0] grid_value;
    solver_fsm_e curr_state, next_state;

    logic [8:0] legal_values_one_hot;
    logic [8:0] rows_one_hot[9];
    logic [8:0] cols_one_hot[9];
    logic [8:0] subgrids_one_hot[9];

    logic done;

    always_ff @(posedge clk or negedge rst_b) begin
        if (~rst_b) begin
            curr_state <= IDLE;
        end else begin
            curr_state <= next_state;
        end
    end

    always_comb begin
        case (curr_state)
            IDLE: begin
                // Next state assignment
                next_state = LOAD; // should probably move to load after input says its ready
            end
            LOAD: begin
                legal_values_one_hot = 9'b1_1111_1111;
                next_state = COMPUTE_POSSIBLE_VALUES;
            end
            COMPUTE_POSSIBLE_VALUES: begin
                next_state = SOLVE;
            end
            SOLVE: begin
                next_state = (done) ? DONE : SOLVE;
            end
            default: next_state = IDLE;
        endcase
    end


    // Assume this can happen in single cycle
    genvar r, c;
    for (r = 0; r < 9; r += 1) begin : g_row_load
        for (c = 0; c < 9; c += 1) begin : g_col_load
            assign grid_value[r][c] = (curr_state == IDLE) ? 4'b0 :
                                      (curr_state == LOAD) ? in_grid[r][c] : grid_value[r][c];
        end
    end

    // Calculate rows one-hot based on grid.value
    generate
        for (r = 0; r < 9; r += 1) begin : g_row_onehot
            logic [8:0][3:0] tmp_row;
            assign tmp_row = {
                grid_value[r][0], grid_value[r][1], grid_value[r][2],
                grid_value[r][3], grid_value[r][4], grid_value[r][5],
                grid_value[r][6], grid_value[r][7], grid_value[r][8]
            };

            values2onehot rows2onehot(
                .values(tmp_row),
                .onehot(rows_one_hot[r])
            );
        end
    endgenerate

    // Calculate columns one-hot based on grid.value
    generate
        for (c = 0; c < 9; c += 1) begin : g_col_onehot
            logic [8:0][3:0] tmp_col;
            assign tmp_col = {
                grid_value[0][c], grid_value[1][c], grid_value[2][c],
                grid_value[3][c], grid_value[4][c], grid_value[5][c],
                grid_value[6][c], grid_value[7][c], grid_value[8][c]
            };

            values2onehot cols2onehot(
                .values(tmp_col),
                .onehot(cols_one_hot[c])
            );
        end
    endgenerate

    // Calculate subgrid one-hot based on grid.value
    generate
        for (r = 0; r < 3; r++) begin : g_subgrid_r_onehot
            for (c = 0; c < 3; c += 1) begin : g_subgrid_c_onehot
                logic [3:0] r_b = r * 3;
                logic [3:0] c_b = c * 3;
                logic [8:0][3:0] tmp_subgrid;
                assign tmp_subgrid = {
                    grid_value[r_b][c_b], grid_value[r_b][c_b+1], grid_value[r_b][c_b+2],
                    grid_value[r_b+1][c_b], grid_value[r_b+1][c_b+1], grid_value[r_b+1][c_b+2],
                    grid_value[r_b+2][c_b], grid_value[r_b+2][c_b+1], grid_value[r_b+2][c_b+2]
                };

                values2onehot subgrid2onehot(
                    .values(tmp_subgrid),
                    .onehot(subgrids_one_hot[r_b+c])
                );
            end
        end
    endgenerate


    // Computing the possible values
    // We do this by OR-ing the values in rows/columns/subgrids and XOR-ing with all_possible_values
    logic [8:0][8:0][8:0] possible_values = '0;
    genvar i;
    generate
        for (r = 0; r < 9; r++) begin : g_compute_value_r
            for (c = 0; c < 9; c++) begin : g_compute_value_c
                logic [3:0] subgrid_idx;
                always_comb begin
                    case (r)
                        0, 1, 2: begin
                            case (c)
                                0, 1, 2: subgrid_idx = 0;
                                3, 4, 5: subgrid_idx = 1;
                                6, 7, 8: subgrid_idx = 2;
                                default: subgrid_idx = 0;
                            endcase
                        end
                        3, 4, 5: begin
                            case (c)
                                0, 1, 2: subgrid_idx = 3;
                                3, 4, 5: subgrid_idx = 4;
                                6, 7, 8: subgrid_idx = 5;
                                default: subgrid_idx = 0;
                            endcase
                        end
                        6, 7, 8: begin
                            case (c)
                                0, 1, 2: subgrid_idx = 6;
                                3, 4, 5: subgrid_idx = 7;
                                6, 7, 8: subgrid_idx = 8;
                                default: subgrid_idx = 0;
                            endcase
                        end
                        default: subgrid_idx = 0;
                    endcase
                end

                assign possible_values[r][c] = (curr_state == COMPUTE_POSSIBLE_VALUES & ~(|in_grid[r][c])) ?
                    legal_values_one_hot ^ (rows_one_hot[r] | cols_one_hot[c] | subgrids_one_hot[subgrid_idx]) : 
                    possible_values[r][c];

            end
        end
    endgenerate

    logic [8:0] possible_vec_0_0 = possible_values[0][0];
    logic [8:0] possible_vec_0_1 = possible_values[0][1];
    logic [8:0] possible_vec_0_2 = possible_values[0][2];
    logic [8:0] possible_vec_0_3 = possible_values[0][3];
    logic [8:0] possible_vec_0_4 = possible_values[0][4];
    logic [8:0] possible_vec_0_5 = possible_values[0][5];
    logic [8:0] possible_vec_0_6 = possible_values[0][6];
    logic [8:0] possible_vec_0_7 = possible_values[0][7];
    logic [8:0] possible_vec_0_8 = possible_values[0][8];

    logic [8:0] possible_vec_1_0 = possible_values[1][0];
    logic [8:0] possible_vec_1_1 = possible_values[1][1];
    logic [8:0] possible_vec_1_2 = possible_values[1][2];
    logic [8:0] possible_vec_1_3 = possible_values[1][3];
    logic [8:0] possible_vec_1_4 = possible_values[1][4];
    logic [8:0] possible_vec_1_5 = possible_values[1][5];
    logic [8:0] possible_vec_1_6 = possible_values[1][6];
    logic [8:0] possible_vec_1_7 = possible_values[1][7];
    logic [8:0] possible_vec_1_8 = possible_values[1][8];

    logic [8:0] possible_vec_2_0 = possible_values[2][0];
    logic [8:0] possible_vec_2_1 = possible_values[2][1];
    logic [8:0] possible_vec_2_2 = possible_values[2][2];
    logic [8:0] possible_vec_2_3 = possible_values[2][3];
    logic [8:0] possible_vec_2_4 = possible_values[2][4];
    logic [8:0] possible_vec_2_5 = possible_values[2][5];
    logic [8:0] possible_vec_2_6 = possible_values[2][6];
    logic [8:0] possible_vec_2_7 = possible_values[2][7];
    logic [8:0] possible_vec_2_8 = possible_values[2][8];

    logic [8:0] possible_vec_3_0 = possible_values[3][0];
    logic [8:0] possible_vec_3_1 = possible_values[3][1];
    logic [8:0] possible_vec_3_2 = possible_values[3][2];
    logic [8:0] possible_vec_3_3 = possible_values[3][3];
    logic [8:0] possible_vec_3_4 = possible_values[3][4];
    logic [8:0] possible_vec_3_5 = possible_values[3][5];
    logic [8:0] possible_vec_3_6 = possible_values[3][6];
    logic [8:0] possible_vec_3_7 = possible_values[3][7];
    logic [8:0] possible_vec_3_8 = possible_values[3][8];

    logic [8:0] possible_vec_4_0 = possible_values[4][0];
    logic [8:0] possible_vec_4_1 = possible_values[4][1];
    logic [8:0] possible_vec_4_2 = possible_values[4][2];
    logic [8:0] possible_vec_4_3 = possible_values[4][3];
    logic [8:0] possible_vec_4_4 = possible_values[4][4];
    logic [8:0] possible_vec_4_5 = possible_values[4][5];
    logic [8:0] possible_vec_4_6 = possible_values[4][6];
    logic [8:0] possible_vec_4_7 = possible_values[4][7];
    logic [8:0] possible_vec_4_8 = possible_values[4][8];

    logic [8:0] possible_vec_5_0 = possible_values[5][0];
    logic [8:0] possible_vec_5_1 = possible_values[5][1];
    logic [8:0] possible_vec_5_2 = possible_values[5][2];
    logic [8:0] possible_vec_5_3 = possible_values[5][3];
    logic [8:0] possible_vec_5_4 = possible_values[5][4];
    logic [8:0] possible_vec_5_5 = possible_values[5][5];
    logic [8:0] possible_vec_5_6 = possible_values[5][6];
    logic [8:0] possible_vec_5_7 = possible_values[5][7];
    logic [8:0] possible_vec_5_8 = possible_values[5][8];

    logic [8:0] possible_vec_6_0 = possible_values[6][0];
    logic [8:0] possible_vec_6_1 = possible_values[6][1];
    logic [8:0] possible_vec_6_2 = possible_values[6][2];
    logic [8:0] possible_vec_6_3 = possible_values[6][3];
    logic [8:0] possible_vec_6_4 = possible_values[6][4];
    logic [8:0] possible_vec_6_5 = possible_values[6][5];
    logic [8:0] possible_vec_6_6 = possible_values[6][6];
    logic [8:0] possible_vec_6_7 = possible_values[6][7];
    logic [8:0] possible_vec_6_8 = possible_values[6][8];

    logic [8:0] possible_vec_7_0 = possible_values[7][0];
    logic [8:0] possible_vec_7_1 = possible_values[7][1];
    logic [8:0] possible_vec_7_2 = possible_values[7][2];
    logic [8:0] possible_vec_7_3 = possible_values[7][3];
    logic [8:0] possible_vec_7_4 = possible_values[7][4];
    logic [8:0] possible_vec_7_5 = possible_values[7][5];
    logic [8:0] possible_vec_7_6 = possible_values[7][6];
    logic [8:0] possible_vec_7_7 = possible_values[7][7];
    logic [8:0] possible_vec_7_8 = possible_values[7][8];

    logic [8:0] possible_vec_8_0 = possible_values[8][0];
    logic [8:0] possible_vec_8_1 = possible_values[8][1];
    logic [8:0] possible_vec_8_2 = possible_values[8][2];
    logic [8:0] possible_vec_8_3 = possible_values[8][3];
    logic [8:0] possible_vec_8_4 = possible_values[8][4];
    logic [8:0] possible_vec_8_5 = possible_values[8][5];
    logic [8:0] possible_vec_8_6 = possible_values[8][6];
    logic [8:0] possible_vec_8_7 = possible_values[8][7];
    logic [8:0] possible_vec_8_8 = possible_values[8][8];

    // Calculate 'done' based on all one-hots being set
    logic [8:0] row_done, col_done, subgrid_done;
    generate
        for (i = 0; i < 9; i++) begin : g_done_collector
            assign row_done[i] = &rows_one_hot[i];
            assign col_done[i] = &cols_one_hot[i];
            assign subgrid_done[i] = &subgrids_one_hot[i];
        end
    endgenerate

    assign done = (&row_done) & (&col_done) & (&subgrid_done);

endmodule

