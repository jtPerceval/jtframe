/*  This file is part of JTFRAME.
    JTFRAME program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTFRAME program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTFRAME.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 7-3-2019 */

module jtframe_led(
    input        rst,
    input        clk,
    input        LVBL,
    input        downloading,
    input        osd_shown,
    input [3:0]  gfx_en,
    input [1:0]  game_led,
    output reg   led
);

wire  sys_led, enlarged;
reg   last_LVBL, cen_VB;

assign sys_led = ~( downloading | osd_shown | (|(~gfx_en)));

always @(posedge clk) begin
    last_LVBL <= LVBL;
    cen_VB    <= !LVBL && last_LVBL;
end

// Make the minimum pulse length equal to 16 frames = 0.26s
jtframe_enlarger #(.W(4)) u_enlarger(
    .rst        ( rst               ),
    .clk        ( clk               ),
    .cen        ( cen_VB            ),
    .pulse_in   ( game_led[0]       ),
    .pulse_out  ( enlarged          )
);

///////////////// LED is on while
// downloading, PLL lock lost, OSD is shown or in reset state
always @(posedge clk, posedge rst) begin
    if( rst ) begin
        led <= 0;
    end else begin
        led <= ~enlarged & (sys_led | game_led[1]);
    end
end

endmodule