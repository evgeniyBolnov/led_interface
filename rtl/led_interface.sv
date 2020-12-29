module led_interface #(
  parameter clock_freq      = 50_000_000,
  parameter blink_period_ms = 100       ,
  parameter pause_before_ms = 1_000     ,
  parameter pause_after_ms  = 1_000     ,
  parameter bits_count      = 8
) (
  input                   clk          ,
  input                   reset        ,
  input  [bits_count-1:0] parallel_code,
  output                  serial_code
);

  localparam pause_before = pause_before_ms * ( clock_freq / 1000 );
  localparam pause_after  = pause_after_ms  * ( clock_freq / 1000 );
  localparam blink_period = blink_period_ms * ( clock_freq / 1000 );

  logic [bits_count-1:0] code_meta      ;
  logic [bits_count-1:0] code_latch     ;
  logic [bits_count-1:0] current_code   ;
  logic [           2:0] state_counter  ;
  logic [           7:0] bit_counter    ;
  logic [          31:0] before_timer   ;
  logic [          31:0] after_timer    ;
  logic [          31:0] blink_timer    ;
  logic                  serial_code_reg;

  assign serial_code = serial_code_reg;

  always_ff @( posedge clk or posedge reset )
    begin
      if ( reset )
        begin
          code_meta     <= '0;
          code_latch    <= '0;
          current_code  <= '0;
          before_timer  <= '0;
          after_timer   <= '0;
          blink_timer   <= '0;
          state_counter <= '0;
          bit_counter   <= bits_count - 1'b1;
        end
      else
        begin
          if ( ( pause_before > 0 ) && ( before_timer < pause_before - 1'b1 ) )
            before_timer <= before_timer + 1'b1;
          else
            begin
              if ( ( bit_counter > 0 ) || ( state_counter < 7 ) )
                begin
                  if ( blink_timer < blink_period - 1'b1 )
                    blink_timer <= blink_timer + 1'b1;
                  else
                    begin
                      if ( state_counter < 7 )
                        state_counter <= state_counter + 1'b1;
                      else
                        begin
                          state_counter <= 0;
                          bit_counter   <= bit_counter - 1'b1;
                        end
                      blink_timer <= 0;
                    end
                end
              else
                begin
                  if ( ( pause_after > 0 ) && ( after_timer < pause_after - 1'b1 ) )
                    after_timer <= after_timer + 1'b1;
                  else
                    begin
                      before_timer  <= '0;
                      after_timer   <= '0;
                      state_counter <= '0;
                      bit_counter   <= bits_count - 1'b1;
                      current_code  <= code_latch;
                    end
                end
            end
          { code_latch, code_meta } <= { code_meta, parallel_code };
        end
    end

  always_ff @(posedge clk or posedge reset)
    begin
      if ( reset )
        serial_code_reg <= '0;
      else
        case( state_counter )
          3, 4, 5 : serial_code_reg <= current_code[bit_counter];
          2       : serial_code_reg <= 1'b1;
          default : serial_code_reg <= '0;
        endcase
    end

endmodule
