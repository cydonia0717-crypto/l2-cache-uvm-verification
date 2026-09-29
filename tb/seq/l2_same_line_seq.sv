class l2_same_line_seq extends l2_base_seq;
  `uvm_object_utils(l2_same_line_seq)
  longint unsigned base=64'h0002_0000;
  int unsigned word=0;
  function new(string name="l2_same_line_seq"); super.new(name); endfunction
  task body(); send_read(base + word*8); endtask
endclass
