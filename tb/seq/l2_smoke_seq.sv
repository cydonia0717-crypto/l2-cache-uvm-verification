class l2_smoke_seq extends l2_base_seq;
  `uvm_object_utils(l2_smoke_seq)
  function new(string name="l2_smoke_seq"); super.new(name); endfunction
  task body();
    send_read(64'h0000_1000);
    send_read(64'h0000_1000);
    send_write(64'h0000_1080,64'h1122_3344_5566_7788);
    send_read(64'h0000_1080);
    send_write(64'h0000_1088,64'hDEAD_BEEF_CAFE_BABE,8'h0f);
    send_read(64'h0000_1088);
  endtask
endclass
