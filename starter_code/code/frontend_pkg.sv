package frontend_pkg;

  typedef enum logic [1:0] {
    CFI_NONE = 2'd0,
    CFI_BRANCH = 2'd1,
    CFI_JAL = 2'd2,
    CFI_JALR = 2'd3
  } cfi_t;

endpackage
