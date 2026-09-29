class l2_base_seq extends uvm_sequence #(l2_core_item);
  `uvm_object_utils(l2_base_seq)
  int unsigned tag_ctr=1;
  function new(string name="l2_base_seq"); super.new(name); endfunction

  task send_read(longint unsigned addr);
    l2_core_item tr=l2_core_item::type_id::create("rd");
    start_item(tr); tr.flush=0; tr.rw=0; tr.addr=addr; tr.data='0; tr.byteen='0; tr.tag=tag_ctr++; finish_item(tr);
  endtask
  task send_write(longint unsigned addr, bit [63:0] data, bit [7:0] be=8'hff);
    l2_core_item tr=l2_core_item::type_id::create("wr");
    start_item(tr); tr.flush=0; tr.rw=1; tr.addr=addr; tr.data=data; tr.byteen=be; tr.tag=tag_ctr++; finish_item(tr);
  endtask
  task send_flush();
    l2_core_item tr=l2_core_item::type_id::create("flush");
    start_item(tr); tr.flush=1; tr.rw=0; tr.addr='0; tr.data='0; tr.byteen='0; tr.tag=tag_ctr++; finish_item(tr);
  endtask
endclass
