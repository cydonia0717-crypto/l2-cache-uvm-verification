class l2_outstanding_seq extends l2_base_seq;
  `uvm_object_utils(l2_outstanding_seq)
  int unsigned count=9;
  longint unsigned base=64'h0001_0000;
  longint unsigned stride=64;
  function new(string name="l2_outstanding_seq"); super.new(name); endfunction
  task body();
    for (int i=0;i<count;i++) send_read(base + i*stride);
  endtask
endclass
