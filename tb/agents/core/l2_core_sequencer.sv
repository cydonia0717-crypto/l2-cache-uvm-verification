class l2_core_sequencer extends uvm_sequencer #(l2_core_item);
  `uvm_component_utils(l2_core_sequencer)
  virtual l2_core_if vif;
  int unsigned port_id;
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
endclass
