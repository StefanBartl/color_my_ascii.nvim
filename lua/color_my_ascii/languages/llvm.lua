---@module 'color_my_ascii.languages.llvm'
--- LLVM IR language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  -- LLVM IR keywords and instructions
  words = {
    -- Types
    'void', 'i1', 'i8', 'i16', 'i32', 'i64', 'i128',
    'half', 'float', 'double', 'fp128', 'x86_fp80', 'ppc_fp128',
    'ptr', 'label', 'token', 'metadata',
    -- Type qualifiers
    'type', 'opaque',
    -- Linkage types
    'private', 'internal', 'external', 'linkonce', 'weak',
    'common', 'appending', 'extern_weak', 'linkonce_odr', 'weak_odr',
    -- Visibility
    'default', 'hidden', 'protected',
    -- Calling conventions
    'ccc', 'fastcc', 'coldcc', 'cc',
    -- Function attributes
    'define', 'declare', 'nounwind', 'readonly', 'readnone',
    'noreturn', 'nocapture', 'noinline', 'alwaysinline',
    'optsize', 'ssp', 'sspreq',
    -- Instructions - Terminators
    'ret', 'br', 'switch', 'indirectbr', 'invoke',
    'resume', 'unreachable',
    -- Instructions - Binary operations
    'add', 'fadd', 'sub', 'fsub', 'mul', 'fmul',
    'udiv', 'sdiv', 'fdiv', 'urem', 'srem', 'frem',
    -- Instructions - Bitwise operations
    'shl', 'lshr', 'ashr', 'and', 'or', 'xor',
    -- Instructions - Memory access
    'alloca', 'load', 'store', 'getelementptr',
    'fence', 'cmpxchg', 'atomicrmw',
    -- Instructions - Conversion
    'trunc', 'zext', 'sext', 'fptrunc', 'fpext',
    'fptoui', 'fptosi', 'uitofp', 'sitofp',
    'ptrtoint', 'inttoptr', 'bitcast', 'addrspacecast',
    -- Instructions - Comparison
    'icmp', 'fcmp', 'eq', 'ne', 'ugt', 'uge', 'ult', 'ule',
    'sgt', 'sge', 'slt', 'sle',
    'oeq', 'ogt', 'oge', 'olt', 'ole', 'one', 'ord',
    'ueq', 'ugt', 'uge', 'ult', 'ule', 'une', 'uno',
    -- Instructions - Other
    'phi', 'select', 'call', 'va_arg', 'landingpad',
    'extractvalue', 'insertvalue', 'extractelement', 'insertelement',
    'shufflevector',
    -- Keywords
    'global', 'constant', 'null', 'undef', 'true', 'false',
    'to', 'align', 'entry', 'label',
    -- Attributes
    'zeroext', 'signext', 'inreg', 'byval', 'sret',
    'noalias', 'nest', 'returned',
  },

  -- Keywords unique to LLVM IR
  unique_words = {
    'getelementptr', 'phi', 'alloca',
    'icmp', 'fcmp', 'zext', 'sext',
    'trunc', 'ptrtoint', 'inttoptr',
    'i1', 'i128', 'metadata', 'undef',
    'extractvalue', 'insertvalue',
    'landingpad', 'invoke', 'resume',
  },

  hl = 'Function',
}
