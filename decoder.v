// module decoder #(parameter k, m, n, l, E )
// (clk, finishedTables,historyTable,errorTable,backTrackingTable,decoded);

// input finishedTables;
// input clk; // The clock signal.
// // history table where we save our predecessor
// input [(l+1)*(m-k)-1 : 0] historyTable [0 : 2**(m-k)-1];

// // The maximum number of errors in an example is L*n so we should represent the error in clog2(L*n)+1 bits
// // E= clog2(L*n) 
// input [(E+1)*(l+1) -1: 0] errorTable [0 : 2**(m-k)-1];
// //       [5:0] -> 6 bits
// //       [11:6] -> 6 bits
// //       [17:12] -> 6 bits
// ////////////////////////
// input [k*(l+1)-1 : 0] backTrackingTable [0 : 2**(m-k)-1];


// reg [(m-k)-1 : 0] previousState;
// reg [(m-k)-1 : 0] nextState;


// output reg [l*k-1: 0] decoded;


// integer i ;

// always @(posedge finishedTables) begin
//     previousState  = 0;
//     for (i = 0; i < l; i = i+1) begin
//         nextState=historyTable[previousState][(i+1)*(m-k)-1 -: (m-k)];
//         decoded[(i+1)*k -1 -: k] = backTrackingTable[previousState][k*(i+1) -1 -: k ];
//         previousState = historyTable[previousState][(i+1)*(m-k)-1 -: (m-k)];
//     end
// end

// endmodule