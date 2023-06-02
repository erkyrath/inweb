# This makefile was automatically written by inweb -makefile
# and is not intended for human editing

INWEBPLATFORM = macosuniv

INFORM6OS = MACOS

GLULXEOS = OS_UNIX

EXEEXTENSION = 

INTEST = intest/Tangled/intest
INWEB = inweb/Tangled/inweb

SDKPATH := $(shell xcrun -show-sdk-path)

CCOPTSX = -DPLATFORM_MACOS=1 -target x86_64-apple-macos10.12 -isysroot $(SDKPATH) $(CFLAGS)
CCOPTSA = -DPLATFORM_MACOS=1 -target arm64-apple-macos11 -isysroot $(SDKPATH) $(CFLAGS)

MANYWARNINGS = -Weverything -Wno-pointer-arith -Wno-unused-macros -Wno-shadow -Wno-cast-align -Wno-variadic-macros -Wno-missing-noreturn -Wno-missing-prototypes -Wno-unused-parameter -Wno-padded -Wno-missing-variable-declarations -Wno-unreachable-code-break -Wno-class-varargs -Wno-format-nonliteral -Wno-cast-qual -Wno-double-promotion -Wno-comma -Wno-strict-prototypes -Wno-extra-semi-stmt -Wno-c11-extensions -Wno-unreachable-code-return -Wno-unused-but-set-variable -Wno-declaration-after-statement -ferror-limit=1000

FEWERWARNINGS = -Wno-implicit-int -Wno-dangling-else -Wno-pointer-sign -Wno-format-extra-args -Wno-tautological-compare -Wno-deprecated-declarations -Wno-logical-op-parentheses -Wno-format -Wno-extra-semi-stmt -Wno-c11-extensions -Wno-unreachable-code-return -Wno-unused-but-set-variable

