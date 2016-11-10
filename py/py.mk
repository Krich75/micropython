# where py object files go (they have a name prefix to prevent filename clashes)
PY_BUILD = $(BUILD)/py

# where autogenerated header files go
HEADER_BUILD = $(BUILD)/genhdr

# file containing qstr defs for the core Python bit
PY_QSTR_DEFS = $(PY_SRC)/qstrdefs.h

# If qstr autogeneration is not disabled we specify the output header
# for all collected qstrings.
ifneq ($(QSTR_AUTOGEN_DISABLE),1)
QSTR_DEFS_COLLECTED = $(HEADER_BUILD)/qstrdefs.collected.h
endif

# some code is performance bottleneck and compiled with other optimization options
CSUPEROPT = -O3

INC += -I../lib
INC += -I../lib/netutils

ifeq ($(MICROPY_PY_USSL),1)
CFLAGS_MOD += -DMICROPY_PY_USSL=1
ifeq ($(MICROPY_SSL_AXTLS),1)
CFLAGS_MOD += -DMICROPY_SSL_AXTLS=1 -I../lib/axtls/ssl -I../lib/axtls/crypto -I../lib/axtls/config
LDFLAGS_MOD += -Lbuild -laxtls
else ifeq ($(MICROPY_SSL_MBEDTLS),1)
# Can be overriden by ports which have "builtin" mbedTLS
MICROPY_SSL_MBEDTLS_INCLUDE ?= ../lib/mbedtls/include
CFLAGS_MOD += -DMICROPY_SSL_MBEDTLS=1 -I$(MICROPY_SSL_MBEDTLS_INCLUDE)
LDFLAGS_MOD += -L../lib/mbedtls/library -lmbedx509 -lmbedtls -lmbedcrypto
endif
endif

#ifeq ($(MICROPY_PY_LWIP),1)
#CFLAGS_MOD += -DMICROPY_PY_LWIP=1 -I../lib/lwip/src/include -I../lib/lwip/src/include/ipv4 -I../extmod/lwip-include
#endif

ifeq ($(MICROPY_PY_LWIP),1)
LWIP_DIR = lib/lwip/src
INC += -I../lib/lwip/src/include -I../lib/lwip/src/include/ipv4 -I../extmod/lwip-include
CFLAGS_MOD += -DMICROPY_PY_LWIP=1
SRC_MOD += extmod/modlwip.c lib/netutils/netutils.c
SRC_MOD += $(addprefix $(LWIP_DIR)/,\
	core/def.c \
	core/dns.c \
	core/init.c \
	core/mem.c \
	core/memp.c \
	core/netif.c \
	core/pbuf.c \
	core/raw.c \
	core/stats.c \
	core/sys.c \
	core/tcp.c \
	core/tcp_in.c \
	core/tcp_out.c \
	core/timers.c \
	core/udp.c \
	core/ipv4/autoip.c \
	core/ipv4/icmp.c \
	core/ipv4/igmp.c \
	core/ipv4/inet.c \
	core/ipv4/inet_chksum.c \
	core/ipv4/ip_addr.c \
	core/ipv4/ip.c \
	core/ipv4/ip_frag.c \
	)
ifeq ($(MICROPY_PY_LWIP_SLIP),1)
CFLAGS_MOD += -DMICROPY_PY_LWIP_SLIP=1
SRC_MOD += $(LWIP_DIR)/netif/slipif.c
endif
endif

ifeq ($(MICROPY_PY_BTREE),1)
BTREE_DIR = lib/berkeley-db-1.xx
CFLAGS_MOD += -D__DBINTERFACE_PRIVATE=1 -Dmpool_error=printf -Dabort=abort_ -Dvirt_fd_t=mp_obj_t "-DVIRT_FD_T_HEADER=<py/obj.h>"
INC += -I../$(BTREE_DIR)/PORT/include
SRC_MOD += extmod/modbtree.c
SRC_MOD += $(addprefix $(BTREE_DIR)/,\
btree/bt_close.c \
btree/bt_conv.c \
btree/bt_debug.c \
btree/bt_delete.c \
btree/bt_get.c \
btree/bt_open.c \
btree/bt_overflow.c \
btree/bt_page.c \
btree/bt_put.c \
btree/bt_search.c \
btree/bt_seq.c \
btree/bt_split.c \
btree/bt_utils.c \
mpool/mpool.c \
	)
CFLAGS_MOD += -DMICROPY_PY_BTREE=1
# we need to suppress certain warnings to get berkeley-db to compile cleanly
$(BUILD)/$(BTREE_DIR)/%.o: CFLAGS += -Wno-old-style-definition -Wno-sign-compare -Wno-unused-parameter
endif

# py object files
PY_O_BASENAME = \
	mpstate.o \
	nlrsetjmp.o \
	malloc.o \
	gc.o \
	qstr.o \
	vstr.o \
	mpprint.o \
	unicode.o \
	mpz.o \
	lexer.o \
	lexerstr.o \
	lexerunix.o \
	parse.o \
	scope.o \
	compile.o \
	emitcommon.o \
	emitbc.o \
	asmx64.o \
	emitnx64.o \
	asmx86.o \
	emitnx86.o \
	asmthumb.o \
	emitnthumb.o \
	emitinlinethumb.o \
	asmarm.o \
	emitnarm.o \
	formatfloat.o \
	parsenumbase.o \
	parsenum.o \
	emitglue.o \
	runtime.o \
	runtime_utils.o \
	nativeglue.o \
	stackctrl.o \
	argcheck.o \
	warning.o \
	map.o \
	obj.o \
	objarray.o \
	objattrtuple.o \
	objbool.o \
	objboundmeth.o \
	objcell.o \
	objclosure.o \
	objcomplex.o \
	objdict.o \
	objenumerate.o \
	objexcept.o \
	objfilter.o \
	objfloat.o \
	objfun.o \
	objgenerator.o \
	objgetitemiter.o \
	objint.o \
	objint_longlong.o \
	objint_mpz.o \
	objlist.o \
	objmap.o \
	objmodule.o \
	objobject.o \
	objpolyiter.o \
	objproperty.o \
	objnone.o \
	objnamedtuple.o \
	objrange.o \
	objreversed.o \
	objset.o \
	objsingleton.o \
	objslice.o \
	objstr.o \
	objstrunicode.o \
	objstringio.o \
	objtuple.o \
	objtype.o \
	objzip.o \
	opmethods.o \
	sequence.o \
	stream.o \
	binary.o \
	builtinimport.o \
	builtinevex.o \
	modarray.o \
	modbuiltins.o \
	modcollections.o \
	modgc.o \
	modio.o \
	modmath.o \
	modcmath.o \
	modmicropython.o \
	modstruct.o \
	modsys.o \
	moduerrno.o \
	modthread.o \
	vm.o \
	bc.o \
	showbc.o \
	repl.o \
	smallint.o \
	frozenmod.o \
	../extmod/moductypes.o \
	../extmod/modujson.o \
	../extmod/modure.o \
	../extmod/moduzlib.o \
	../extmod/moduheapq.o \
	../extmod/moduhashlib.o \
	../extmod/modubinascii.o \
	../extmod/virtpin.o \
	../extmod/machine_mem.o \
	../extmod/machine_pinbase.o \
	../extmod/machine_pulse.o \
	../extmod/machine_i2c.o \
	../extmod/machine_spi.o \
	../extmod/modussl_axtls.o \
	../extmod/modussl_mbedtls.o \
	../extmod/modurandom.o \
	../extmod/modwebsocket.o \
	../extmod/modwebrepl.o \
	../extmod/modframebuf.o \
	../extmod/fsusermount.o \
	../extmod/vfs_fat.o \
	../extmod/vfs_fat_ffconf.o \
	../extmod/vfs_fat_diskio.o \
	../extmod/vfs_fat_file.o \
	../extmod/vfs_fat_lexer.o \
	../extmod/vfs_fat_misc.o \
	../extmod/utime_mphal.o \
	../extmod/uos_dupterm.o \
	../lib/embed/abort_.o \
	../lib/utils/printf.o \

# prepend the build destination prefix to the py object files
PY_O = $(addprefix $(PY_BUILD)/, $(PY_O_BASENAME))

# object file for frozen files
ifneq ($(FROZEN_DIR),)
PY_O += $(BUILD)/$(BUILD)/frozen.o
endif

# object file for frozen bytecode (frozen .mpy files)
ifneq ($(FROZEN_MPY_DIR),)
PY_O += $(BUILD)/$(BUILD)/frozen_mpy.o
endif

# Sources that may contain qstrings
SRC_QSTR_IGNORE = nlr% emitnx% emitnthumb% emitnarm%
SRC_QSTR = $(SRC_MOD) $(addprefix py/,$(filter-out $(SRC_QSTR_IGNORE),$(PY_O_BASENAME:.o=.c)) emitnative.c)

# Anything that depends on FORCE will be considered out-of-date
FORCE:
.PHONY: FORCE

$(HEADER_BUILD)/mpversion.h: FORCE | $(HEADER_BUILD)
	$(Q)$(PYTHON) $(PY_SRC)/makeversionhdr.py $@

# mpconfigport.mk is optional, but changes to it may drastically change
# overall config, so they need to be caught
MPCONFIGPORT_MK = $(wildcard mpconfigport.mk)

# qstr data
# Adding an order only dependency on $(HEADER_BUILD) causes $(HEADER_BUILD) to get
# created before we run the script to generate the .h
# Note: we need to protect the qstr names from the preprocessor, so we wrap
# the lines in "" and then unwrap after the preprocessor is finished.
$(HEADER_BUILD)/qstrdefs.generated.h: $(PY_QSTR_DEFS) $(QSTR_DEFS) $(QSTR_DEFS_COLLECTED) $(PY_SRC)/makeqstrdata.py mpconfigport.h $(MPCONFIGPORT_MK) $(PY_SRC)/mpconfig.h | $(HEADER_BUILD)
	$(ECHO) "GEN $@"
	$(Q)cat $(PY_QSTR_DEFS) $(QSTR_DEFS) $(QSTR_DEFS_COLLECTED) | $(SED) 's/^Q(.*)/"&"/' | $(CPP) $(CFLAGS) - | sed 's/^"\(Q(.*)\)"/\1/' > $(HEADER_BUILD)/qstrdefs.preprocessed.h
	$(Q)$(PYTHON) $(PY_SRC)/makeqstrdata.py $(HEADER_BUILD)/qstrdefs.preprocessed.h > $@

# emitters

$(PY_BUILD)/emitnx64.o: CFLAGS += -DN_X64
$(PY_BUILD)/emitnx64.o: py/emitnative.c
	$(call compile_c)

$(PY_BUILD)/emitnx86.o: CFLAGS += -DN_X86
$(PY_BUILD)/emitnx86.o: py/emitnative.c
	$(call compile_c)

$(PY_BUILD)/emitnthumb.o: CFLAGS += -DN_THUMB
$(PY_BUILD)/emitnthumb.o: py/emitnative.c
	$(call compile_c)

$(PY_BUILD)/emitnarm.o: CFLAGS += -DN_ARM
$(PY_BUILD)/emitnarm.o: py/emitnative.c
	$(call compile_c)

# optimising gc for speed; 5ms down to 4ms on pybv2
$(PY_BUILD)/gc.o: CFLAGS += $(CSUPEROPT)

# optimising vm for speed, adds only a small amount to code size but makes a huge difference to speed (20% faster)
$(PY_BUILD)/vm.o: CFLAGS += $(CSUPEROPT)
# Optimizing vm.o for modern deeply pipelined CPUs with branch predictors
# may require disabling tail jump optimization. This will make sure that
# each opcode has its own dispatching jump which will improve branch
# branch predictor efficiency.
# http://article.gmane.org/gmane.comp.lang.lua.general/75426
# http://hg.python.org/cpython/file/b127046831e2/Python/ceval.c#l828
# http://www.emulators.com/docs/nx25_nostradamus.htm
#-fno-crossjumping
