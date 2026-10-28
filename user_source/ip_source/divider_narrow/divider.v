/************************************************************\
**	Copyright (c) 2012-2026 Anlogic Inc.
**	All Right Reserved.
\************************************************************/
/************************************************************\
**	Gen time	:	Oct 28 2026 19:34:32
**	IpTool version	:	2026.03(193873 2026/03/31)
**	App version	:
**	Ip Version	:	2.0
\************************************************************/
`timescale 1ns / 1ps
module divider_narrow
(
  input                         aclk,
  input                         aresetn,
  input   [39:0]                s_axis_dividend_tdata,
  input                         s_axis_dividend_tvalid,
  input   [31:0]                s_axis_divisor_tdata,
  input                         s_axis_divisor_tvalid,
  output  [71:0]                m_axis_dout_tdata,
  output                        m_axis_dout_tvalid
);

  divider_top_divider
  #(
      .OPERAND_SIGN(0),
      .DIVIDEND_DW(40),
      .DIVISOR_DW(28),
      .DIVIDEND_CEIL_DW(40),
      .DIVISOR_CEIL_DW(32),
      .OUTPUT_DW(72),
      .FLOW_CONTROL(0),
      .OUT_BLOCKING(0),
      .LATENCY(42)
  )divider_top_Inst
  (
      .aclk(aclk),
      .aresetn(aresetn),
      .s_axis_dividend_tdata(s_axis_dividend_tdata),
      .s_axis_dividend_tvalid(s_axis_dividend_tvalid),
      .s_axis_divisor_tdata(s_axis_divisor_tdata),
      .s_axis_divisor_tvalid(s_axis_divisor_tvalid),
      .m_axis_dout_tdata(m_axis_dout_tdata),
      .m_axis_dout_tvalid(m_axis_dout_tvalid)
  );
endmodule
