module pathAndError #(parameter k, m, n, l, E )
(clk, reset, load, restart, ready, encoded, historyTable,errorTable,backTrackingTable, nextStates , outputStates, 
decoded, error);

// inputs -------------------------------------------------------------------------

input reset;
input clk; // The clock signal.
input load; // i took the load so we dont enter while loading
input restart; // i took the load so we dont enter while loading



// outputs -------------------------------------------------------------------------
output reg [0:0] ready ;
output reg [E:0] error;
output reg [l*k-1: 0] decoded;


// history table where we save our predecessor
output reg [(l+1)*(m-k)-1 : 0] historyTable [0 : 2**(m-k)-1];

// The maximum number of errors in an example is L*n so we should represent the error in clog2(L*n)+1 bits
// E= clog2(L*n) 
output reg [(E+1)*(l+1) -1: 0] errorTable [0 : 2**(m-k)-1];

// only one stage to get the best error before putting data in memory 
// reg [(E+1)*(1) -1: 0] errorDetection [0 : 2**(m-k)-1];

//       [5:0] -> 6 bits
//       [11:6] -> 6 bits
//       [17:12] -> 6 bits
////////////////////////
output reg [k*(l+1)-1 : 0] backTrackingTable [0 : 2**(m-k)-1];



// memory parameters ---------------------------------
input [(2**k)*(m-k)-1 : 0] nextStates [0 : 2**(m-k)-1];
//------------------------------------------------
//2m-2k-1 --> m-k-2 | m-k-1 -->        0
//if input = 0      | if input = 1
//------------------------------------------------
input [(2**k)*n - 1 : 0] outputStates [0 : 2**(m-k)-1];

//------------------------------------------------
// decodeing stage
reg [(m-k)-1 : 0] previousState;
reg [(m-k)-1 : 0] nextState;

//------------------------------------------------


integer myNextState;
reg [n-1:0] noOfErrors; 
integer j,i,states;

input [n-1 :0] encoded;


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
        historyTable[0][(l+1)*(m-k)-1 -: (m-k)] <= 0;
        errorTable[0][(l+1)*(E+1)-1 -: (E+1)] <= 0;
        ready = 0 ;
        i = 0 ;
        states = 0 ;
    end else if (clk && load==0 && ready==0) begin
        
        if(i<l) begin
            // for loop of the whole states
            
            for (states = 0; states <2**(m-k) ;states = states+1 ) begin
                // if(states < 2**(m-k)) begin
                j = 0;
                if (historyTable[states][(l+1 -i)*(m-k) -1] === 1'bz) begin
                    // cant start from here
                    j = 2**k; 
                end
                // no of outgoings from my states
                while(j<2**k) begin
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
                            ones = errorTable[states][(E+1)*(l+1 -i) -1 -:(E+1)] + ones;
                        end

                        if (errorTable[myNextState][(E+1)*(l+1 -i-1) -1] === 1'bz) begin // no prev state came
                            
                            historyTable[myNextState][(l+1 -i-1)*(m-k)-1 -: (m-k)] = states;
                            // accumulate prev error to ones
                            errorTable[myNextState][(E+1)*(l+1 -i-1) -1 -:(E+1)] = ones;

                            backTrackingTable[myNextState][k*(l+1 -i-1) -1  -: k ] = j ; 
                        end else begin // collison occured
                            if(errorTable[myNextState][(E+1)*(l+1 -i-1) -1 -:(E+1)] > ones) begin
                                errorTable[myNextState][(E+1)*(l+1 -i-1) -1 -:(E+1)] = ones; 
                                historyTable[myNextState][(l+1 -i-1)*(m-k)-1 -: (m-k)] = states;
                                backTrackingTable[myNextState][k*(l+1 -i-1) -1 -: k ] = j ; 
                            end 


                        end
                end
					 j=j+1;
            end
            // increment level
            i = i+1;
        end
	if (i == l) begin
                previousState  = 0;
                error = errorTable[previousState][(E+1)*(1) -1 -:(E+1)];
                for (i = 0; i < l; i = i+1) begin
                    nextState = historyTable[previousState][(i+1)*(m-k)-1 -: (m-k)];
                    decoded[(i+1)*k -1 -: k] = backTrackingTable[previousState][k*(i+1) -1 -: k ];
                    previousState = historyTable[previousState][(i+1)*(m-k)-1 -: (m-k)];
                end
                ready = 1;
        end
        
    end 


end

endmodule