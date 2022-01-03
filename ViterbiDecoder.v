module ViterbiDecoder#(parameter n =2,parameter k=1,parameter m=4, parameter L=7)(
	clk,
	reset,
	restart,
	load,
	encoded,
	state_address,
	input_address,
	next_state_data,
	output_data,
	enable,
	decoded,
	error,
	ready
);


function integer clog2;
input integer value;
begin
value = value-1;
for (clog2=0; value>0; clog2=clog2+1) value = value>>1;
end
endfunction

parameter E = clog2(L*n);

// inputs
input clk; // The clock signal.
input reset; // The asynchronous reset signal (reset the whole decoder).
input restart; // This signal tells the decoder to discard its result and start processing a new stream of encoded bits.
input enable; // This signal can be used to pause the processing if equal zero.
input [0:n-1] encoded; // The encoded bits for this clock cycle
input load; // This signal tells the decoder to read an entry to the Next State Table and the Output table
input [0:m-k-1] state_address; // The address of the state in the tables into which we want to write (the row according to the tables in the project description)
input [0:k-1] input_address; // The address of the input in the tables into which we want to write (the column according to the tables in the project description)
input [0:m-k-1] next_state_data; // The next state to write into the Next State Table
input [0:n-1] output_data; // The output to write into the Output Table
//////////////////////////////////////////

// outputs
// output wire [0:k*L-1] decoded; // The result of the decoding process.
// output wire [E:0] error; // The number of errors found in the most likely sequence
// output wire ready; // Whether the decoder finished processing and the output is ready



// reg [2*m-2*k-1 : 0] nextStates [0 : 2**(m-k) -1];
// reg [2*n - 1 : 0] outputStates [0 : 2**(m-k) -1];

// memory #(k, m, n ) m1 (clk, load, reset, state_address, input_address, next_state_data, output_data, nextStates, outputStates);
// memory 
//------------------------------------------------------------------------------
reg [(2**k)*(m-k)-1 : 0] nextStates [0 : 2**(m-k)-1];
//------------------------------------------------
//2m-2k-1 --> m-k-2 | m-k-1 -->        0
//if input = 0      | if input = 1
//------------------------------------------------

reg [(2**k)*n - 1 : 0] outputStates [0 : 2**(m-k)-1];
//------------------------------------------------
//2n-1 --> n-2      | n-1 -->        0
//if input = 0      | if input = 1
//------------------------------------------------


integer row;
integer memoryIndex;


always @(posedge clk, reset) begin
    if (reset == 1'b1) begin
        // looping on whole memory to reset it
        for (memoryIndex=0; memoryIndex < 2**(m-k); memoryIndex=memoryIndex+1) begin
            nextStates[memoryIndex] <= 0; //reset array
            outputStates[memoryIndex] <= 0; //reset array
        end
    end else if(clk && load == 1'b1)begin
        // state_address '000' mean row 0 in our memory so convert to integer =0
        row = state_address;
        memoryIndex = input_address;
        // input_address : 00 -> memoryIndex = 0
        nextStates[row][(2**k -memoryIndex)*(m-k) - 1 -: (m-k) ] = next_state_data; 
        outputStates[row][(2**k -memoryIndex)*n - 1  -: n ] = output_data;    
    end
end




//------------------------------------------------------------------------------

reg [0:L*n -1] example;
// reg [(L+1)*(m-k)-1 : 0] historyTable [0 : 2**(m-k)-1];
// reg [(E+1)*(L+1) -1: 0] errorTable [0 : 2**(m-k)-1];
// reg [k*(L+1)-1 : 0] backTrackingTable [0 : 2**(m-k)-1];


// pathAndError #(k, m, n, L, E ) tables (clk, reset, load, restart, ready, encoded, historyTable,
                                    // errorTable, backTrackingTable, nextStates, outputStates, decoded, error);


// pathAndError
output reg [0:0] ready ;
output reg [E:0] error;
output reg [L*k-1: 0] decoded;


// history table where we save our predecessor
reg [(L+1)*(m-k)-1 : 0] historyTable [0 : 2**(m-k)-1];

// The maximum number of errors in an example is L*n so we should represent the error in clog2(L*n)+1 bits
// E= clog2(L*n) 
reg [(E+1)*(L+1) -1: 0] errorTable [0 : 2**(m-k)-1];

// only one stage to get the best error before putting data in memory 
// reg [(E+1)*(1) -1: 0] errorDetection [0 : 2**(m-k)-1];

//       [5:0] -> 6 bits
//       [11:6] -> 6 bits
//       [17:12] -> 6 bits
////////////////////////
reg [k*(L+1)-1 : 0] backTrackingTable [0 : 2**(m-k)-1];



// memory parameters ---------------------------------
// input [(2**k)*(m-k)-1 : 0] nextStates [0 : 2**(m-k)-1];
//------------------------------------------------
//2m-2k-1 --> m-k-2 | m-k-1 -->        0
//if input = 0      | if input = 1
//------------------------------------------------
// input [(2**k)*n - 1 : 0] outputStates [0 : 2**(m-k)-1];

//------------------------------------------------
// decodeing stage
reg [(m-k)-1 : 0] previousState;
reg [(m-k)-1 : 0] nextState;

//------------------------------------------------


integer myNextState;
reg [n-1:0] noOfErrors; 
integer j,i,states;


integer ones;
integer exCount ;

always @(posedge clk, reset) begin

	//Reseting or resarting module
	if(reset || restart) begin
        // looping on whole memory to reset it
        for (j=0; j < 2**(m-k); j=j+1) begin
            historyTable[j] <= 'bz; //reset array
            errorTable[j] <= 'bz; //reset array
            // errorDetection[j] <= 'bz; //reset array
        end
        // initializing that i'll start from 0
        historyTable[0][(L+1)*(m-k)-1 -: (m-k)] <= 0;
        errorTable[0][(L+1)*(E+1)-1 -: (E+1)] <= 0;
        ready = 0 ;
        i = 0 ;
        states = 0 ;
    end else if (clk && load==0 && ready==0) begin
        
        if(i<L) begin
            // for loop of the whole states
            
            for (states = 0; states <2**(m-k) ;states = states+1 ) begin
                // if(states < 2**(m-k)) begin
                j = 0;
                if (historyTable[states][(L+1 -i)*(m-k) -1] === 1'bz) begin
                    // cant start from here
                    j = 2**k; 
                end
                // no of outgoings from my states
                while(j < 2**k) begin
                    ones = 0;
                    // getting index of my next state in integer to axes table        
                    myNextState = nextStates[states][(2**k -j)*(m-k) - 1 -: (m-k) ];
                    noOfErrors = encoded ^ outputStates[states][(2**k -j)*n - 1  -: n ];
                    // example [0:l*n -1]
                    // [0:1] , [2:3]
                    // first iter : i=0 -> [0+:2] ->[1:0] xxxxx
                    //a_vect[ 0 +: 8] // == a_vect[ 7 : 0]
                    //a_vect[15 -: 8] // == a_vect[15 : 8]
                    // check collision
                    // getting no of 1s
                    for(exCount=0;exCount<n;exCount=exCount+1)   //check for all the bits.
                        if(noOfErrors[exCount] == 1'b1)    //check if the bit is '1'
                            ones = ones + 1;    //if its one, increment the count.
                    // saving history no matter error
                    if (i!=0) begin
                        ones = errorTable[states][(E+1)*(L+1 -i) -1 -:(E+1)] + ones;
                    end
                    if (errorTable[myNextState][(E+1)*(L+1 -i-1) -1] === 1'bz) begin // no prev state came
                        
                        historyTable[myNextState][(L+1 -i-1)*(m-k)-1 -: (m-k)] = states;
                        // accumulate prev error to ones
                        errorTable[myNextState][(E+1)*(L+1 -i-1) -1 -:(E+1)] = ones;
                        backTrackingTable[myNextState][k*(L+1 -i-1) -1  -: k ] = j ; 
                    end else begin // collison occured
                        if(errorTable[myNextState][(E+1)*(L+1 -i-1) -1 -:(E+1)] > ones) begin
                            errorTable[myNextState][(E+1)*(L+1 -i-1) -1 -:(E+1)] = ones; 
                            historyTable[myNextState][(L+1 -i-1)*(m-k)-1 -: (m-k)] = states;
                            backTrackingTable[myNextState][k*(L+1 -i-1) -1 -: k ] = j ; 
                        end 
                    end
					j=j+1;
                end
            end
            // increment level
            i = i+1;
        end
	if (i == L) begin
                previousState  = 0;
                error = errorTable[previousState][(E+1)*(1) -1 -:(E+1)];
                for (i = 0; i < L; i = i+1) begin
                    nextState = historyTable[previousState][(i+1)*(m-k)-1 -: (m-k)];
                    decoded[(i+1)*k -1 -: k] = backTrackingTable[previousState][k*(i+1) -1 -: k ];
                    previousState = historyTable[previousState][(i+1)*(m-k)-1 -: (m-k)];
                end
                ready = 1;
        end
        
    end 


end


endmodule
