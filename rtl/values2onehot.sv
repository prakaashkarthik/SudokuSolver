module values2onehot (
    input logic [8:0][3:0] values,
    output logic [8:0] onehot
    // output logic all_set
);

    genvar i;
    generate
        for (i = 0; i < 9; i++) begin : g_onehot_vec
            always_comb begin
                logic [3:0] idx;
                idx = (|values[i]) ? values[i] - 1 : '1; // '1 is invalid index
                case (idx)
                    0 : onehot[0] = 1;
                    1 : onehot[1] = 1;
                    2 : onehot[2] = 1;
                    3 : onehot[3] = 1;
                    4 : onehot[4] = 1;
                    5 : onehot[5] = 1;
                    6 : onehot[6] = 1;
                    7 : onehot[7] = 1;
                    8 : onehot[8] = 1;
                    default : onehot[idx] = 0;
                endcase
            end
        end
    endgenerate

    // assign all_set = &onehot;
endmodule
