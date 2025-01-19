module tb_top (
    input logic clk,
    input logic rst_b
);

    logic [3:0] in_grid [9][9] = '{
        '{2, 9, 0,   0, 0, 0,   8, 7, 1},
        '{7, 4, 3,   0, 0, 0,   0, 5, 0},
        '{5, 8, 0,   0, 0, 0,   0, 4, 9},

        '{0, 0, 5,   4, 7, 0,   1, 3, 0},
        '{0, 7, 0,   0, 0, 2,   0, 0, 0},
        '{0, 2, 9,    0, 0, 0,   0, 0, 4},

        '{6, 0, 0,   9, 0, 3,   4, 0, 7},
        '{4, 3, 2,    6, 8, 0,    0, 0, 0},
        '{9, 0, 0,   2, 5, 0,   6, 0, 3}
    };

    logic [3:0] solved_grid[9][9];


    sudoku sudoku_solver (
        .clk(clk),
        .rst_b(rst_b),
        .in_grid(in_grid),
        .solved_grid(solved_grid)
    );

endmodule
