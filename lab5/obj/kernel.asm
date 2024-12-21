
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c020b2b7          	lui	t0,0xc020b
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200016:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200018:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc020001c:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200020:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200024:	c020b137          	lui	sp,0xc020b

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	addi	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:
void grade_backtrace(void);

int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	000a7517          	auipc	a0,0xa7
ffffffffc0200036:	33e50513          	addi	a0,a0,830 # ffffffffc02a7370 <buf>
ffffffffc020003a:	000b3617          	auipc	a2,0xb3
ffffffffc020003e:	89260613          	addi	a2,a2,-1902 # ffffffffc02b28cc <end>
kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	164060ef          	jal	ra,ffffffffc02061ae <memset>
    cons_init();                // init the console
ffffffffc020004e:	580000ef          	jal	ra,ffffffffc02005ce <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200052:	00006597          	auipc	a1,0x6
ffffffffc0200056:	58e58593          	addi	a1,a1,1422 # ffffffffc02065e0 <etext+0x4>
ffffffffc020005a:	00006517          	auipc	a0,0x6
ffffffffc020005e:	5a650513          	addi	a0,a0,1446 # ffffffffc0206600 <etext+0x24>
ffffffffc0200062:	06a000ef          	jal	ra,ffffffffc02000cc <cprintf>

    print_kerninfo();
ffffffffc0200066:	24e000ef          	jal	ra,ffffffffc02002b4 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006a:	68c010ef          	jal	ra,ffffffffc02016f6 <pmm_init>

    pic_init();                 // init interrupt controller
ffffffffc020006e:	5d2000ef          	jal	ra,ffffffffc0200640 <pic_init>
    idt_init();                 // init interrupt descriptor table
ffffffffc0200072:	5dc000ef          	jal	ra,ffffffffc020064e <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc0200076:	499020ef          	jal	ra,ffffffffc0202d0e <vmm_init>
    proc_init();                // init process table
ffffffffc020007a:	51b050ef          	jal	ra,ffffffffc0205d94 <proc_init>
    
    ide_init();                 // init ide devices
ffffffffc020007e:	4a8000ef          	jal	ra,ffffffffc0200526 <ide_init>
    swap_init();                // init swap
ffffffffc0200082:	76c030ef          	jal	ra,ffffffffc02037ee <swap_init>

    clock_init();               // init clock interrupt
ffffffffc0200086:	4f6000ef          	jal	ra,ffffffffc020057c <clock_init>
    intr_enable();              // enable irq interrupt
ffffffffc020008a:	5b8000ef          	jal	ra,ffffffffc0200642 <intr_enable>
    
    cpu_idle();                 // run idle process
ffffffffc020008e:	69f050ef          	jal	ra,ffffffffc0205f2c <cpu_idle>

ffffffffc0200092 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200092:	1141                	addi	sp,sp,-16
ffffffffc0200094:	e022                	sd	s0,0(sp)
ffffffffc0200096:	e406                	sd	ra,8(sp)
ffffffffc0200098:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020009a:	536000ef          	jal	ra,ffffffffc02005d0 <cons_putc>
    (*cnt) ++;
ffffffffc020009e:	401c                	lw	a5,0(s0)
}
ffffffffc02000a0:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000a2:	2785                	addiw	a5,a5,1
ffffffffc02000a4:	c01c                	sw	a5,0(s0)
}
ffffffffc02000a6:	6402                	ld	s0,0(sp)
ffffffffc02000a8:	0141                	addi	sp,sp,16
ffffffffc02000aa:	8082                	ret

ffffffffc02000ac <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000ac:	1101                	addi	sp,sp,-32
ffffffffc02000ae:	862a                	mv	a2,a0
ffffffffc02000b0:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000b2:	00000517          	auipc	a0,0x0
ffffffffc02000b6:	fe050513          	addi	a0,a0,-32 # ffffffffc0200092 <cputch>
ffffffffc02000ba:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000bc:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000be:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c0:	184060ef          	jal	ra,ffffffffc0206244 <vprintfmt>
    return cnt;
}
ffffffffc02000c4:	60e2                	ld	ra,24(sp)
ffffffffc02000c6:	4532                	lw	a0,12(sp)
ffffffffc02000c8:	6105                	addi	sp,sp,32
ffffffffc02000ca:	8082                	ret

ffffffffc02000cc <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000cc:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000ce:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000d2:	8e2a                	mv	t3,a0
ffffffffc02000d4:	f42e                	sd	a1,40(sp)
ffffffffc02000d6:	f832                	sd	a2,48(sp)
ffffffffc02000d8:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000da:	00000517          	auipc	a0,0x0
ffffffffc02000de:	fb850513          	addi	a0,a0,-72 # ffffffffc0200092 <cputch>
ffffffffc02000e2:	004c                	addi	a1,sp,4
ffffffffc02000e4:	869a                	mv	a3,t1
ffffffffc02000e6:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000e8:	ec06                	sd	ra,24(sp)
ffffffffc02000ea:	e0ba                	sd	a4,64(sp)
ffffffffc02000ec:	e4be                	sd	a5,72(sp)
ffffffffc02000ee:	e8c2                	sd	a6,80(sp)
ffffffffc02000f0:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000f2:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000f4:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000f6:	14e060ef          	jal	ra,ffffffffc0206244 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000fa:	60e2                	ld	ra,24(sp)
ffffffffc02000fc:	4512                	lw	a0,4(sp)
ffffffffc02000fe:	6125                	addi	sp,sp,96
ffffffffc0200100:	8082                	ret

ffffffffc0200102 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc0200102:	a1f9                	j	ffffffffc02005d0 <cons_putc>

ffffffffc0200104 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200104:	1101                	addi	sp,sp,-32
ffffffffc0200106:	e822                	sd	s0,16(sp)
ffffffffc0200108:	ec06                	sd	ra,24(sp)
ffffffffc020010a:	e426                	sd	s1,8(sp)
ffffffffc020010c:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020010e:	00054503          	lbu	a0,0(a0)
ffffffffc0200112:	c51d                	beqz	a0,ffffffffc0200140 <cputs+0x3c>
ffffffffc0200114:	0405                	addi	s0,s0,1
ffffffffc0200116:	4485                	li	s1,1
ffffffffc0200118:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc020011a:	4b6000ef          	jal	ra,ffffffffc02005d0 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020011e:	00044503          	lbu	a0,0(s0)
ffffffffc0200122:	008487bb          	addw	a5,s1,s0
ffffffffc0200126:	0405                	addi	s0,s0,1
ffffffffc0200128:	f96d                	bnez	a0,ffffffffc020011a <cputs+0x16>
    (*cnt) ++;
ffffffffc020012a:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020012e:	4529                	li	a0,10
ffffffffc0200130:	4a0000ef          	jal	ra,ffffffffc02005d0 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200134:	60e2                	ld	ra,24(sp)
ffffffffc0200136:	8522                	mv	a0,s0
ffffffffc0200138:	6442                	ld	s0,16(sp)
ffffffffc020013a:	64a2                	ld	s1,8(sp)
ffffffffc020013c:	6105                	addi	sp,sp,32
ffffffffc020013e:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200140:	4405                	li	s0,1
ffffffffc0200142:	b7f5                	j	ffffffffc020012e <cputs+0x2a>

ffffffffc0200144 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200144:	1141                	addi	sp,sp,-16
ffffffffc0200146:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200148:	4bc000ef          	jal	ra,ffffffffc0200604 <cons_getc>
ffffffffc020014c:	dd75                	beqz	a0,ffffffffc0200148 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020014e:	60a2                	ld	ra,8(sp)
ffffffffc0200150:	0141                	addi	sp,sp,16
ffffffffc0200152:	8082                	ret

ffffffffc0200154 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0200154:	715d                	addi	sp,sp,-80
ffffffffc0200156:	e486                	sd	ra,72(sp)
ffffffffc0200158:	e0a6                	sd	s1,64(sp)
ffffffffc020015a:	fc4a                	sd	s2,56(sp)
ffffffffc020015c:	f84e                	sd	s3,48(sp)
ffffffffc020015e:	f452                	sd	s4,40(sp)
ffffffffc0200160:	f056                	sd	s5,32(sp)
ffffffffc0200162:	ec5a                	sd	s6,24(sp)
ffffffffc0200164:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0200166:	c901                	beqz	a0,ffffffffc0200176 <readline+0x22>
ffffffffc0200168:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc020016a:	00006517          	auipc	a0,0x6
ffffffffc020016e:	49e50513          	addi	a0,a0,1182 # ffffffffc0206608 <etext+0x2c>
ffffffffc0200172:	f5bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
readline(const char *prompt) {
ffffffffc0200176:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200178:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc020017a:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc020017c:	4aa9                	li	s5,10
ffffffffc020017e:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0200180:	000a7b97          	auipc	s7,0xa7
ffffffffc0200184:	1f0b8b93          	addi	s7,s7,496 # ffffffffc02a7370 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200188:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc020018c:	fb9ff0ef          	jal	ra,ffffffffc0200144 <getchar>
        if (c < 0) {
ffffffffc0200190:	00054a63          	bltz	a0,ffffffffc02001a4 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200194:	00a95a63          	bge	s2,a0,ffffffffc02001a8 <readline+0x54>
ffffffffc0200198:	029a5263          	bge	s4,s1,ffffffffc02001bc <readline+0x68>
        c = getchar();
ffffffffc020019c:	fa9ff0ef          	jal	ra,ffffffffc0200144 <getchar>
        if (c < 0) {
ffffffffc02001a0:	fe055ae3          	bgez	a0,ffffffffc0200194 <readline+0x40>
            return NULL;
ffffffffc02001a4:	4501                	li	a0,0
ffffffffc02001a6:	a091                	j	ffffffffc02001ea <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02001a8:	03351463          	bne	a0,s3,ffffffffc02001d0 <readline+0x7c>
ffffffffc02001ac:	e8a9                	bnez	s1,ffffffffc02001fe <readline+0xaa>
        c = getchar();
ffffffffc02001ae:	f97ff0ef          	jal	ra,ffffffffc0200144 <getchar>
        if (c < 0) {
ffffffffc02001b2:	fe0549e3          	bltz	a0,ffffffffc02001a4 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02001b6:	fea959e3          	bge	s2,a0,ffffffffc02001a8 <readline+0x54>
ffffffffc02001ba:	4481                	li	s1,0
            cputchar(c);
ffffffffc02001bc:	e42a                	sd	a0,8(sp)
ffffffffc02001be:	f45ff0ef          	jal	ra,ffffffffc0200102 <cputchar>
            buf[i ++] = c;
ffffffffc02001c2:	6522                	ld	a0,8(sp)
ffffffffc02001c4:	009b87b3          	add	a5,s7,s1
ffffffffc02001c8:	2485                	addiw	s1,s1,1
ffffffffc02001ca:	00a78023          	sb	a0,0(a5)
ffffffffc02001ce:	bf7d                	j	ffffffffc020018c <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc02001d0:	01550463          	beq	a0,s5,ffffffffc02001d8 <readline+0x84>
ffffffffc02001d4:	fb651ce3          	bne	a0,s6,ffffffffc020018c <readline+0x38>
            cputchar(c);
ffffffffc02001d8:	f2bff0ef          	jal	ra,ffffffffc0200102 <cputchar>
            buf[i] = '\0';
ffffffffc02001dc:	000a7517          	auipc	a0,0xa7
ffffffffc02001e0:	19450513          	addi	a0,a0,404 # ffffffffc02a7370 <buf>
ffffffffc02001e4:	94aa                	add	s1,s1,a0
ffffffffc02001e6:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02001ea:	60a6                	ld	ra,72(sp)
ffffffffc02001ec:	6486                	ld	s1,64(sp)
ffffffffc02001ee:	7962                	ld	s2,56(sp)
ffffffffc02001f0:	79c2                	ld	s3,48(sp)
ffffffffc02001f2:	7a22                	ld	s4,40(sp)
ffffffffc02001f4:	7a82                	ld	s5,32(sp)
ffffffffc02001f6:	6b62                	ld	s6,24(sp)
ffffffffc02001f8:	6bc2                	ld	s7,16(sp)
ffffffffc02001fa:	6161                	addi	sp,sp,80
ffffffffc02001fc:	8082                	ret
            cputchar(c);
ffffffffc02001fe:	4521                	li	a0,8
ffffffffc0200200:	f03ff0ef          	jal	ra,ffffffffc0200102 <cputchar>
            i --;
ffffffffc0200204:	34fd                	addiw	s1,s1,-1
ffffffffc0200206:	b759                	j	ffffffffc020018c <readline+0x38>

ffffffffc0200208 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200208:	000b2317          	auipc	t1,0xb2
ffffffffc020020c:	63030313          	addi	t1,t1,1584 # ffffffffc02b2838 <is_panic>
ffffffffc0200210:	00033e03          	ld	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200214:	715d                	addi	sp,sp,-80
ffffffffc0200216:	ec06                	sd	ra,24(sp)
ffffffffc0200218:	e822                	sd	s0,16(sp)
ffffffffc020021a:	f436                	sd	a3,40(sp)
ffffffffc020021c:	f83a                	sd	a4,48(sp)
ffffffffc020021e:	fc3e                	sd	a5,56(sp)
ffffffffc0200220:	e0c2                	sd	a6,64(sp)
ffffffffc0200222:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200224:	020e1a63          	bnez	t3,ffffffffc0200258 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200228:	4785                	li	a5,1
ffffffffc020022a:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc020022e:	8432                	mv	s0,a2
ffffffffc0200230:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200232:	862e                	mv	a2,a1
ffffffffc0200234:	85aa                	mv	a1,a0
ffffffffc0200236:	00006517          	auipc	a0,0x6
ffffffffc020023a:	3da50513          	addi	a0,a0,986 # ffffffffc0206610 <etext+0x34>
    va_start(ap, fmt);
ffffffffc020023e:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200240:	e8dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200244:	65a2                	ld	a1,8(sp)
ffffffffc0200246:	8522                	mv	a0,s0
ffffffffc0200248:	e65ff0ef          	jal	ra,ffffffffc02000ac <vcprintf>
    cprintf("\n");
ffffffffc020024c:	00007517          	auipc	a0,0x7
ffffffffc0200250:	1ac50513          	addi	a0,a0,428 # ffffffffc02073f8 <commands+0xb70>
ffffffffc0200254:	e79ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200258:	4501                	li	a0,0
ffffffffc020025a:	4581                	li	a1,0
ffffffffc020025c:	4601                	li	a2,0
ffffffffc020025e:	48a1                	li	a7,8
ffffffffc0200260:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc0200264:	3e4000ef          	jal	ra,ffffffffc0200648 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200268:	4501                	li	a0,0
ffffffffc020026a:	174000ef          	jal	ra,ffffffffc02003de <kmonitor>
    while (1) {
ffffffffc020026e:	bfed                	j	ffffffffc0200268 <__panic+0x60>

ffffffffc0200270 <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200270:	715d                	addi	sp,sp,-80
ffffffffc0200272:	832e                	mv	t1,a1
ffffffffc0200274:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200276:	85aa                	mv	a1,a0
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200278:	8432                	mv	s0,a2
ffffffffc020027a:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020027c:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc020027e:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200280:	00006517          	auipc	a0,0x6
ffffffffc0200284:	3b050513          	addi	a0,a0,944 # ffffffffc0206630 <etext+0x54>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200288:	ec06                	sd	ra,24(sp)
ffffffffc020028a:	f436                	sd	a3,40(sp)
ffffffffc020028c:	f83a                	sd	a4,48(sp)
ffffffffc020028e:	e0c2                	sd	a6,64(sp)
ffffffffc0200290:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200292:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200294:	e39ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200298:	65a2                	ld	a1,8(sp)
ffffffffc020029a:	8522                	mv	a0,s0
ffffffffc020029c:	e11ff0ef          	jal	ra,ffffffffc02000ac <vcprintf>
    cprintf("\n");
ffffffffc02002a0:	00007517          	auipc	a0,0x7
ffffffffc02002a4:	15850513          	addi	a0,a0,344 # ffffffffc02073f8 <commands+0xb70>
ffffffffc02002a8:	e25ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    va_end(ap);
}
ffffffffc02002ac:	60e2                	ld	ra,24(sp)
ffffffffc02002ae:	6442                	ld	s0,16(sp)
ffffffffc02002b0:	6161                	addi	sp,sp,80
ffffffffc02002b2:	8082                	ret

ffffffffc02002b4 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc02002b4:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02002b6:	00006517          	auipc	a0,0x6
ffffffffc02002ba:	39a50513          	addi	a0,a0,922 # ffffffffc0206650 <etext+0x74>
void print_kerninfo(void) {
ffffffffc02002be:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02002c0:	e0dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02002c4:	00000597          	auipc	a1,0x0
ffffffffc02002c8:	d6e58593          	addi	a1,a1,-658 # ffffffffc0200032 <kern_init>
ffffffffc02002cc:	00006517          	auipc	a0,0x6
ffffffffc02002d0:	3a450513          	addi	a0,a0,932 # ffffffffc0206670 <etext+0x94>
ffffffffc02002d4:	df9ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc02002d8:	00006597          	auipc	a1,0x6
ffffffffc02002dc:	30458593          	addi	a1,a1,772 # ffffffffc02065dc <etext>
ffffffffc02002e0:	00006517          	auipc	a0,0x6
ffffffffc02002e4:	3b050513          	addi	a0,a0,944 # ffffffffc0206690 <etext+0xb4>
ffffffffc02002e8:	de5ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc02002ec:	000a7597          	auipc	a1,0xa7
ffffffffc02002f0:	08458593          	addi	a1,a1,132 # ffffffffc02a7370 <buf>
ffffffffc02002f4:	00006517          	auipc	a0,0x6
ffffffffc02002f8:	3bc50513          	addi	a0,a0,956 # ffffffffc02066b0 <etext+0xd4>
ffffffffc02002fc:	dd1ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200300:	000b2597          	auipc	a1,0xb2
ffffffffc0200304:	5cc58593          	addi	a1,a1,1484 # ffffffffc02b28cc <end>
ffffffffc0200308:	00006517          	auipc	a0,0x6
ffffffffc020030c:	3c850513          	addi	a0,a0,968 # ffffffffc02066d0 <etext+0xf4>
ffffffffc0200310:	dbdff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200314:	000b3597          	auipc	a1,0xb3
ffffffffc0200318:	9b758593          	addi	a1,a1,-1609 # ffffffffc02b2ccb <end+0x3ff>
ffffffffc020031c:	00000797          	auipc	a5,0x0
ffffffffc0200320:	d1678793          	addi	a5,a5,-746 # ffffffffc0200032 <kern_init>
ffffffffc0200324:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200328:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020032c:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020032e:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200332:	95be                	add	a1,a1,a5
ffffffffc0200334:	85a9                	srai	a1,a1,0xa
ffffffffc0200336:	00006517          	auipc	a0,0x6
ffffffffc020033a:	3ba50513          	addi	a0,a0,954 # ffffffffc02066f0 <etext+0x114>
}
ffffffffc020033e:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200340:	b371                	j	ffffffffc02000cc <cprintf>

ffffffffc0200342 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200342:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200344:	00006617          	auipc	a2,0x6
ffffffffc0200348:	3dc60613          	addi	a2,a2,988 # ffffffffc0206720 <etext+0x144>
ffffffffc020034c:	04d00593          	li	a1,77
ffffffffc0200350:	00006517          	auipc	a0,0x6
ffffffffc0200354:	3e850513          	addi	a0,a0,1000 # ffffffffc0206738 <etext+0x15c>
void print_stackframe(void) {
ffffffffc0200358:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020035a:	eafff0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc020035e <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020035e:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200360:	00006617          	auipc	a2,0x6
ffffffffc0200364:	3f060613          	addi	a2,a2,1008 # ffffffffc0206750 <etext+0x174>
ffffffffc0200368:	00006597          	auipc	a1,0x6
ffffffffc020036c:	40858593          	addi	a1,a1,1032 # ffffffffc0206770 <etext+0x194>
ffffffffc0200370:	00006517          	auipc	a0,0x6
ffffffffc0200374:	40850513          	addi	a0,a0,1032 # ffffffffc0206778 <etext+0x19c>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200378:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020037a:	d53ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc020037e:	00006617          	auipc	a2,0x6
ffffffffc0200382:	40a60613          	addi	a2,a2,1034 # ffffffffc0206788 <etext+0x1ac>
ffffffffc0200386:	00006597          	auipc	a1,0x6
ffffffffc020038a:	42a58593          	addi	a1,a1,1066 # ffffffffc02067b0 <etext+0x1d4>
ffffffffc020038e:	00006517          	auipc	a0,0x6
ffffffffc0200392:	3ea50513          	addi	a0,a0,1002 # ffffffffc0206778 <etext+0x19c>
ffffffffc0200396:	d37ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc020039a:	00006617          	auipc	a2,0x6
ffffffffc020039e:	42660613          	addi	a2,a2,1062 # ffffffffc02067c0 <etext+0x1e4>
ffffffffc02003a2:	00006597          	auipc	a1,0x6
ffffffffc02003a6:	43e58593          	addi	a1,a1,1086 # ffffffffc02067e0 <etext+0x204>
ffffffffc02003aa:	00006517          	auipc	a0,0x6
ffffffffc02003ae:	3ce50513          	addi	a0,a0,974 # ffffffffc0206778 <etext+0x19c>
ffffffffc02003b2:	d1bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    }
    return 0;
}
ffffffffc02003b6:	60a2                	ld	ra,8(sp)
ffffffffc02003b8:	4501                	li	a0,0
ffffffffc02003ba:	0141                	addi	sp,sp,16
ffffffffc02003bc:	8082                	ret

ffffffffc02003be <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02003be:	1141                	addi	sp,sp,-16
ffffffffc02003c0:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02003c2:	ef3ff0ef          	jal	ra,ffffffffc02002b4 <print_kerninfo>
    return 0;
}
ffffffffc02003c6:	60a2                	ld	ra,8(sp)
ffffffffc02003c8:	4501                	li	a0,0
ffffffffc02003ca:	0141                	addi	sp,sp,16
ffffffffc02003cc:	8082                	ret

ffffffffc02003ce <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02003ce:	1141                	addi	sp,sp,-16
ffffffffc02003d0:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02003d2:	f71ff0ef          	jal	ra,ffffffffc0200342 <print_stackframe>
    return 0;
}
ffffffffc02003d6:	60a2                	ld	ra,8(sp)
ffffffffc02003d8:	4501                	li	a0,0
ffffffffc02003da:	0141                	addi	sp,sp,16
ffffffffc02003dc:	8082                	ret

ffffffffc02003de <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02003de:	7115                	addi	sp,sp,-224
ffffffffc02003e0:	ed5e                	sd	s7,152(sp)
ffffffffc02003e2:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02003e4:	00006517          	auipc	a0,0x6
ffffffffc02003e8:	40c50513          	addi	a0,a0,1036 # ffffffffc02067f0 <etext+0x214>
kmonitor(struct trapframe *tf) {
ffffffffc02003ec:	ed86                	sd	ra,216(sp)
ffffffffc02003ee:	e9a2                	sd	s0,208(sp)
ffffffffc02003f0:	e5a6                	sd	s1,200(sp)
ffffffffc02003f2:	e1ca                	sd	s2,192(sp)
ffffffffc02003f4:	fd4e                	sd	s3,184(sp)
ffffffffc02003f6:	f952                	sd	s4,176(sp)
ffffffffc02003f8:	f556                	sd	s5,168(sp)
ffffffffc02003fa:	f15a                	sd	s6,160(sp)
ffffffffc02003fc:	e962                	sd	s8,144(sp)
ffffffffc02003fe:	e566                	sd	s9,136(sp)
ffffffffc0200400:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200402:	ccbff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200406:	00006517          	auipc	a0,0x6
ffffffffc020040a:	41250513          	addi	a0,a0,1042 # ffffffffc0206818 <etext+0x23c>
ffffffffc020040e:	cbfff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    if (tf != NULL) {
ffffffffc0200412:	000b8563          	beqz	s7,ffffffffc020041c <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200416:	855e                	mv	a0,s7
ffffffffc0200418:	41e000ef          	jal	ra,ffffffffc0200836 <print_trapframe>
ffffffffc020041c:	00006c17          	auipc	s8,0x6
ffffffffc0200420:	46cc0c13          	addi	s8,s8,1132 # ffffffffc0206888 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200424:	00006917          	auipc	s2,0x6
ffffffffc0200428:	41c90913          	addi	s2,s2,1052 # ffffffffc0206840 <etext+0x264>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020042c:	00006497          	auipc	s1,0x6
ffffffffc0200430:	41c48493          	addi	s1,s1,1052 # ffffffffc0206848 <etext+0x26c>
        if (argc == MAXARGS - 1) {
ffffffffc0200434:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200436:	00006b17          	auipc	s6,0x6
ffffffffc020043a:	41ab0b13          	addi	s6,s6,1050 # ffffffffc0206850 <etext+0x274>
        argv[argc ++] = buf;
ffffffffc020043e:	00006a17          	auipc	s4,0x6
ffffffffc0200442:	332a0a13          	addi	s4,s4,818 # ffffffffc0206770 <etext+0x194>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200446:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200448:	854a                	mv	a0,s2
ffffffffc020044a:	d0bff0ef          	jal	ra,ffffffffc0200154 <readline>
ffffffffc020044e:	842a                	mv	s0,a0
ffffffffc0200450:	dd65                	beqz	a0,ffffffffc0200448 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200452:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200456:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200458:	e1bd                	bnez	a1,ffffffffc02004be <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc020045a:	fe0c87e3          	beqz	s9,ffffffffc0200448 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020045e:	6582                	ld	a1,0(sp)
ffffffffc0200460:	00006d17          	auipc	s10,0x6
ffffffffc0200464:	428d0d13          	addi	s10,s10,1064 # ffffffffc0206888 <commands>
        argv[argc ++] = buf;
ffffffffc0200468:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020046a:	4401                	li	s0,0
ffffffffc020046c:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020046e:	50d050ef          	jal	ra,ffffffffc020617a <strcmp>
ffffffffc0200472:	c919                	beqz	a0,ffffffffc0200488 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200474:	2405                	addiw	s0,s0,1
ffffffffc0200476:	0b540063          	beq	s0,s5,ffffffffc0200516 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020047a:	000d3503          	ld	a0,0(s10)
ffffffffc020047e:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200480:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200482:	4f9050ef          	jal	ra,ffffffffc020617a <strcmp>
ffffffffc0200486:	f57d                	bnez	a0,ffffffffc0200474 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200488:	00141793          	slli	a5,s0,0x1
ffffffffc020048c:	97a2                	add	a5,a5,s0
ffffffffc020048e:	078e                	slli	a5,a5,0x3
ffffffffc0200490:	97e2                	add	a5,a5,s8
ffffffffc0200492:	6b9c                	ld	a5,16(a5)
ffffffffc0200494:	865e                	mv	a2,s7
ffffffffc0200496:	002c                	addi	a1,sp,8
ffffffffc0200498:	fffc851b          	addiw	a0,s9,-1
ffffffffc020049c:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020049e:	fa0555e3          	bgez	a0,ffffffffc0200448 <kmonitor+0x6a>
}
ffffffffc02004a2:	60ee                	ld	ra,216(sp)
ffffffffc02004a4:	644e                	ld	s0,208(sp)
ffffffffc02004a6:	64ae                	ld	s1,200(sp)
ffffffffc02004a8:	690e                	ld	s2,192(sp)
ffffffffc02004aa:	79ea                	ld	s3,184(sp)
ffffffffc02004ac:	7a4a                	ld	s4,176(sp)
ffffffffc02004ae:	7aaa                	ld	s5,168(sp)
ffffffffc02004b0:	7b0a                	ld	s6,160(sp)
ffffffffc02004b2:	6bea                	ld	s7,152(sp)
ffffffffc02004b4:	6c4a                	ld	s8,144(sp)
ffffffffc02004b6:	6caa                	ld	s9,136(sp)
ffffffffc02004b8:	6d0a                	ld	s10,128(sp)
ffffffffc02004ba:	612d                	addi	sp,sp,224
ffffffffc02004bc:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02004be:	8526                	mv	a0,s1
ffffffffc02004c0:	4d9050ef          	jal	ra,ffffffffc0206198 <strchr>
ffffffffc02004c4:	c901                	beqz	a0,ffffffffc02004d4 <kmonitor+0xf6>
ffffffffc02004c6:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02004ca:	00040023          	sb	zero,0(s0)
ffffffffc02004ce:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02004d0:	d5c9                	beqz	a1,ffffffffc020045a <kmonitor+0x7c>
ffffffffc02004d2:	b7f5                	j	ffffffffc02004be <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc02004d4:	00044783          	lbu	a5,0(s0)
ffffffffc02004d8:	d3c9                	beqz	a5,ffffffffc020045a <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc02004da:	033c8963          	beq	s9,s3,ffffffffc020050c <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc02004de:	003c9793          	slli	a5,s9,0x3
ffffffffc02004e2:	0118                	addi	a4,sp,128
ffffffffc02004e4:	97ba                	add	a5,a5,a4
ffffffffc02004e6:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02004ea:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02004ee:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02004f0:	e591                	bnez	a1,ffffffffc02004fc <kmonitor+0x11e>
ffffffffc02004f2:	b7b5                	j	ffffffffc020045e <kmonitor+0x80>
ffffffffc02004f4:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02004f8:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02004fa:	d1a5                	beqz	a1,ffffffffc020045a <kmonitor+0x7c>
ffffffffc02004fc:	8526                	mv	a0,s1
ffffffffc02004fe:	49b050ef          	jal	ra,ffffffffc0206198 <strchr>
ffffffffc0200502:	d96d                	beqz	a0,ffffffffc02004f4 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200504:	00044583          	lbu	a1,0(s0)
ffffffffc0200508:	d9a9                	beqz	a1,ffffffffc020045a <kmonitor+0x7c>
ffffffffc020050a:	bf55                	j	ffffffffc02004be <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020050c:	45c1                	li	a1,16
ffffffffc020050e:	855a                	mv	a0,s6
ffffffffc0200510:	bbdff0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0200514:	b7e9                	j	ffffffffc02004de <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200516:	6582                	ld	a1,0(sp)
ffffffffc0200518:	00006517          	auipc	a0,0x6
ffffffffc020051c:	35850513          	addi	a0,a0,856 # ffffffffc0206870 <etext+0x294>
ffffffffc0200520:	badff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    return 0;
ffffffffc0200524:	b715                	j	ffffffffc0200448 <kmonitor+0x6a>

ffffffffc0200526 <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc0200526:	8082                	ret

ffffffffc0200528 <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc0200528:	00253513          	sltiu	a0,a0,2
ffffffffc020052c:	8082                	ret

ffffffffc020052e <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc020052e:	03800513          	li	a0,56
ffffffffc0200532:	8082                	ret

ffffffffc0200534 <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200534:	000a7797          	auipc	a5,0xa7
ffffffffc0200538:	23c78793          	addi	a5,a5,572 # ffffffffc02a7770 <ide>
    int iobase = secno * SECTSIZE;
ffffffffc020053c:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc0200540:	1141                	addi	sp,sp,-16
ffffffffc0200542:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200544:	95be                	add	a1,a1,a5
ffffffffc0200546:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc020054a:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc020054c:	475050ef          	jal	ra,ffffffffc02061c0 <memcpy>
    return 0;
}
ffffffffc0200550:	60a2                	ld	ra,8(sp)
ffffffffc0200552:	4501                	li	a0,0
ffffffffc0200554:	0141                	addi	sp,sp,16
ffffffffc0200556:	8082                	ret

ffffffffc0200558 <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
    int iobase = secno * SECTSIZE;
ffffffffc0200558:	0095979b          	slliw	a5,a1,0x9
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc020055c:	000a7517          	auipc	a0,0xa7
ffffffffc0200560:	21450513          	addi	a0,a0,532 # ffffffffc02a7770 <ide>
                   size_t nsecs) {
ffffffffc0200564:	1141                	addi	sp,sp,-16
ffffffffc0200566:	85b2                	mv	a1,a2
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200568:	953e                	add	a0,a0,a5
ffffffffc020056a:	00969613          	slli	a2,a3,0x9
                   size_t nsecs) {
ffffffffc020056e:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200570:	451050ef          	jal	ra,ffffffffc02061c0 <memcpy>
    return 0;
}
ffffffffc0200574:	60a2                	ld	ra,8(sp)
ffffffffc0200576:	4501                	li	a0,0
ffffffffc0200578:	0141                	addi	sp,sp,16
ffffffffc020057a:	8082                	ret

ffffffffc020057c <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc020057c:	67e1                	lui	a5,0x18
ffffffffc020057e:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xd578>
ffffffffc0200582:	000b2717          	auipc	a4,0xb2
ffffffffc0200586:	2cf73323          	sd	a5,710(a4) # ffffffffc02b2848 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020058a:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020058e:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200590:	953e                	add	a0,a0,a5
ffffffffc0200592:	4601                	li	a2,0
ffffffffc0200594:	4881                	li	a7,0
ffffffffc0200596:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc020059a:	02000793          	li	a5,32
ffffffffc020059e:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02005a2:	00006517          	auipc	a0,0x6
ffffffffc02005a6:	32e50513          	addi	a0,a0,814 # ffffffffc02068d0 <commands+0x48>
    ticks = 0;
ffffffffc02005aa:	000b2797          	auipc	a5,0xb2
ffffffffc02005ae:	2807bb23          	sd	zero,662(a5) # ffffffffc02b2840 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02005b2:	be29                	j	ffffffffc02000cc <cprintf>

ffffffffc02005b4 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02005b4:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02005b8:	000b2797          	auipc	a5,0xb2
ffffffffc02005bc:	2907b783          	ld	a5,656(a5) # ffffffffc02b2848 <timebase>
ffffffffc02005c0:	953e                	add	a0,a0,a5
ffffffffc02005c2:	4581                	li	a1,0
ffffffffc02005c4:	4601                	li	a2,0
ffffffffc02005c6:	4881                	li	a7,0
ffffffffc02005c8:	00000073          	ecall
ffffffffc02005cc:	8082                	ret

ffffffffc02005ce <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <cons_putc>:
#include <sched.h>
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02005d0:	100027f3          	csrr	a5,sstatus
ffffffffc02005d4:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc02005d6:	0ff57513          	zext.b	a0,a0
ffffffffc02005da:	e799                	bnez	a5,ffffffffc02005e8 <cons_putc+0x18>
ffffffffc02005dc:	4581                	li	a1,0
ffffffffc02005de:	4601                	li	a2,0
ffffffffc02005e0:	4885                	li	a7,1
ffffffffc02005e2:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc02005e6:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005e8:	1101                	addi	sp,sp,-32
ffffffffc02005ea:	ec06                	sd	ra,24(sp)
ffffffffc02005ec:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005ee:	05a000ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc02005f2:	6522                	ld	a0,8(sp)
ffffffffc02005f4:	4581                	li	a1,0
ffffffffc02005f6:	4601                	li	a2,0
ffffffffc02005f8:	4885                	li	a7,1
ffffffffc02005fa:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005fe:	60e2                	ld	ra,24(sp)
ffffffffc0200600:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200602:	a081                	j	ffffffffc0200642 <intr_enable>

ffffffffc0200604 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200604:	100027f3          	csrr	a5,sstatus
ffffffffc0200608:	8b89                	andi	a5,a5,2
ffffffffc020060a:	eb89                	bnez	a5,ffffffffc020061c <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc020060c:	4501                	li	a0,0
ffffffffc020060e:	4581                	li	a1,0
ffffffffc0200610:	4601                	li	a2,0
ffffffffc0200612:	4889                	li	a7,2
ffffffffc0200614:	00000073          	ecall
ffffffffc0200618:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc020061a:	8082                	ret
int cons_getc(void) {
ffffffffc020061c:	1101                	addi	sp,sp,-32
ffffffffc020061e:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200620:	028000ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc0200624:	4501                	li	a0,0
ffffffffc0200626:	4581                	li	a1,0
ffffffffc0200628:	4601                	li	a2,0
ffffffffc020062a:	4889                	li	a7,2
ffffffffc020062c:	00000073          	ecall
ffffffffc0200630:	2501                	sext.w	a0,a0
ffffffffc0200632:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200634:	00e000ef          	jal	ra,ffffffffc0200642 <intr_enable>
}
ffffffffc0200638:	60e2                	ld	ra,24(sp)
ffffffffc020063a:	6522                	ld	a0,8(sp)
ffffffffc020063c:	6105                	addi	sp,sp,32
ffffffffc020063e:	8082                	ret

ffffffffc0200640 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200640:	8082                	ret

ffffffffc0200642 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200642:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200646:	8082                	ret

ffffffffc0200648 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200648:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020064c:	8082                	ret

ffffffffc020064e <idt_init>:
void
idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020064e:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200652:	00000797          	auipc	a5,0x0
ffffffffc0200656:	65a78793          	addi	a5,a5,1626 # ffffffffc0200cac <__alltraps>
ffffffffc020065a:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020065e:	000407b7          	lui	a5,0x40
ffffffffc0200662:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200666:	8082                	ret

ffffffffc0200668 <print_regs>:
    cprintf("  tval 0x%08x\n", tf->tval);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs* gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200668:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs* gpr) {
ffffffffc020066a:	1141                	addi	sp,sp,-16
ffffffffc020066c:	e022                	sd	s0,0(sp)
ffffffffc020066e:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200670:	00006517          	auipc	a0,0x6
ffffffffc0200674:	28050513          	addi	a0,a0,640 # ffffffffc02068f0 <commands+0x68>
void print_regs(struct pushregs* gpr) {
ffffffffc0200678:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020067a:	a53ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020067e:	640c                	ld	a1,8(s0)
ffffffffc0200680:	00006517          	auipc	a0,0x6
ffffffffc0200684:	28850513          	addi	a0,a0,648 # ffffffffc0206908 <commands+0x80>
ffffffffc0200688:	a45ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020068c:	680c                	ld	a1,16(s0)
ffffffffc020068e:	00006517          	auipc	a0,0x6
ffffffffc0200692:	29250513          	addi	a0,a0,658 # ffffffffc0206920 <commands+0x98>
ffffffffc0200696:	a37ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020069a:	6c0c                	ld	a1,24(s0)
ffffffffc020069c:	00006517          	auipc	a0,0x6
ffffffffc02006a0:	29c50513          	addi	a0,a0,668 # ffffffffc0206938 <commands+0xb0>
ffffffffc02006a4:	a29ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02006a8:	700c                	ld	a1,32(s0)
ffffffffc02006aa:	00006517          	auipc	a0,0x6
ffffffffc02006ae:	2a650513          	addi	a0,a0,678 # ffffffffc0206950 <commands+0xc8>
ffffffffc02006b2:	a1bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02006b6:	740c                	ld	a1,40(s0)
ffffffffc02006b8:	00006517          	auipc	a0,0x6
ffffffffc02006bc:	2b050513          	addi	a0,a0,688 # ffffffffc0206968 <commands+0xe0>
ffffffffc02006c0:	a0dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02006c4:	780c                	ld	a1,48(s0)
ffffffffc02006c6:	00006517          	auipc	a0,0x6
ffffffffc02006ca:	2ba50513          	addi	a0,a0,698 # ffffffffc0206980 <commands+0xf8>
ffffffffc02006ce:	9ffff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02006d2:	7c0c                	ld	a1,56(s0)
ffffffffc02006d4:	00006517          	auipc	a0,0x6
ffffffffc02006d8:	2c450513          	addi	a0,a0,708 # ffffffffc0206998 <commands+0x110>
ffffffffc02006dc:	9f1ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02006e0:	602c                	ld	a1,64(s0)
ffffffffc02006e2:	00006517          	auipc	a0,0x6
ffffffffc02006e6:	2ce50513          	addi	a0,a0,718 # ffffffffc02069b0 <commands+0x128>
ffffffffc02006ea:	9e3ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02006ee:	642c                	ld	a1,72(s0)
ffffffffc02006f0:	00006517          	auipc	a0,0x6
ffffffffc02006f4:	2d850513          	addi	a0,a0,728 # ffffffffc02069c8 <commands+0x140>
ffffffffc02006f8:	9d5ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02006fc:	682c                	ld	a1,80(s0)
ffffffffc02006fe:	00006517          	auipc	a0,0x6
ffffffffc0200702:	2e250513          	addi	a0,a0,738 # ffffffffc02069e0 <commands+0x158>
ffffffffc0200706:	9c7ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020070a:	6c2c                	ld	a1,88(s0)
ffffffffc020070c:	00006517          	auipc	a0,0x6
ffffffffc0200710:	2ec50513          	addi	a0,a0,748 # ffffffffc02069f8 <commands+0x170>
ffffffffc0200714:	9b9ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200718:	702c                	ld	a1,96(s0)
ffffffffc020071a:	00006517          	auipc	a0,0x6
ffffffffc020071e:	2f650513          	addi	a0,a0,758 # ffffffffc0206a10 <commands+0x188>
ffffffffc0200722:	9abff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200726:	742c                	ld	a1,104(s0)
ffffffffc0200728:	00006517          	auipc	a0,0x6
ffffffffc020072c:	30050513          	addi	a0,a0,768 # ffffffffc0206a28 <commands+0x1a0>
ffffffffc0200730:	99dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200734:	782c                	ld	a1,112(s0)
ffffffffc0200736:	00006517          	auipc	a0,0x6
ffffffffc020073a:	30a50513          	addi	a0,a0,778 # ffffffffc0206a40 <commands+0x1b8>
ffffffffc020073e:	98fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200742:	7c2c                	ld	a1,120(s0)
ffffffffc0200744:	00006517          	auipc	a0,0x6
ffffffffc0200748:	31450513          	addi	a0,a0,788 # ffffffffc0206a58 <commands+0x1d0>
ffffffffc020074c:	981ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200750:	604c                	ld	a1,128(s0)
ffffffffc0200752:	00006517          	auipc	a0,0x6
ffffffffc0200756:	31e50513          	addi	a0,a0,798 # ffffffffc0206a70 <commands+0x1e8>
ffffffffc020075a:	973ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020075e:	644c                	ld	a1,136(s0)
ffffffffc0200760:	00006517          	auipc	a0,0x6
ffffffffc0200764:	32850513          	addi	a0,a0,808 # ffffffffc0206a88 <commands+0x200>
ffffffffc0200768:	965ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020076c:	684c                	ld	a1,144(s0)
ffffffffc020076e:	00006517          	auipc	a0,0x6
ffffffffc0200772:	33250513          	addi	a0,a0,818 # ffffffffc0206aa0 <commands+0x218>
ffffffffc0200776:	957ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020077a:	6c4c                	ld	a1,152(s0)
ffffffffc020077c:	00006517          	auipc	a0,0x6
ffffffffc0200780:	33c50513          	addi	a0,a0,828 # ffffffffc0206ab8 <commands+0x230>
ffffffffc0200784:	949ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200788:	704c                	ld	a1,160(s0)
ffffffffc020078a:	00006517          	auipc	a0,0x6
ffffffffc020078e:	34650513          	addi	a0,a0,838 # ffffffffc0206ad0 <commands+0x248>
ffffffffc0200792:	93bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200796:	744c                	ld	a1,168(s0)
ffffffffc0200798:	00006517          	auipc	a0,0x6
ffffffffc020079c:	35050513          	addi	a0,a0,848 # ffffffffc0206ae8 <commands+0x260>
ffffffffc02007a0:	92dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02007a4:	784c                	ld	a1,176(s0)
ffffffffc02007a6:	00006517          	auipc	a0,0x6
ffffffffc02007aa:	35a50513          	addi	a0,a0,858 # ffffffffc0206b00 <commands+0x278>
ffffffffc02007ae:	91fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02007b2:	7c4c                	ld	a1,184(s0)
ffffffffc02007b4:	00006517          	auipc	a0,0x6
ffffffffc02007b8:	36450513          	addi	a0,a0,868 # ffffffffc0206b18 <commands+0x290>
ffffffffc02007bc:	911ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02007c0:	606c                	ld	a1,192(s0)
ffffffffc02007c2:	00006517          	auipc	a0,0x6
ffffffffc02007c6:	36e50513          	addi	a0,a0,878 # ffffffffc0206b30 <commands+0x2a8>
ffffffffc02007ca:	903ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02007ce:	646c                	ld	a1,200(s0)
ffffffffc02007d0:	00006517          	auipc	a0,0x6
ffffffffc02007d4:	37850513          	addi	a0,a0,888 # ffffffffc0206b48 <commands+0x2c0>
ffffffffc02007d8:	8f5ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02007dc:	686c                	ld	a1,208(s0)
ffffffffc02007de:	00006517          	auipc	a0,0x6
ffffffffc02007e2:	38250513          	addi	a0,a0,898 # ffffffffc0206b60 <commands+0x2d8>
ffffffffc02007e6:	8e7ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02007ea:	6c6c                	ld	a1,216(s0)
ffffffffc02007ec:	00006517          	auipc	a0,0x6
ffffffffc02007f0:	38c50513          	addi	a0,a0,908 # ffffffffc0206b78 <commands+0x2f0>
ffffffffc02007f4:	8d9ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02007f8:	706c                	ld	a1,224(s0)
ffffffffc02007fa:	00006517          	auipc	a0,0x6
ffffffffc02007fe:	39650513          	addi	a0,a0,918 # ffffffffc0206b90 <commands+0x308>
ffffffffc0200802:	8cbff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200806:	746c                	ld	a1,232(s0)
ffffffffc0200808:	00006517          	auipc	a0,0x6
ffffffffc020080c:	3a050513          	addi	a0,a0,928 # ffffffffc0206ba8 <commands+0x320>
ffffffffc0200810:	8bdff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200814:	786c                	ld	a1,240(s0)
ffffffffc0200816:	00006517          	auipc	a0,0x6
ffffffffc020081a:	3aa50513          	addi	a0,a0,938 # ffffffffc0206bc0 <commands+0x338>
ffffffffc020081e:	8afff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200822:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200824:	6402                	ld	s0,0(sp)
ffffffffc0200826:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200828:	00006517          	auipc	a0,0x6
ffffffffc020082c:	3b050513          	addi	a0,a0,944 # ffffffffc0206bd8 <commands+0x350>
}
ffffffffc0200830:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200832:	89bff06f          	j	ffffffffc02000cc <cprintf>

ffffffffc0200836 <print_trapframe>:
print_trapframe(struct trapframe *tf) {
ffffffffc0200836:	1141                	addi	sp,sp,-16
ffffffffc0200838:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020083a:	85aa                	mv	a1,a0
print_trapframe(struct trapframe *tf) {
ffffffffc020083c:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc020083e:	00006517          	auipc	a0,0x6
ffffffffc0200842:	3b250513          	addi	a0,a0,946 # ffffffffc0206bf0 <commands+0x368>
print_trapframe(struct trapframe *tf) {
ffffffffc0200846:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200848:	885ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    print_regs(&tf->gpr);
ffffffffc020084c:	8522                	mv	a0,s0
ffffffffc020084e:	e1bff0ef          	jal	ra,ffffffffc0200668 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200852:	10043583          	ld	a1,256(s0)
ffffffffc0200856:	00006517          	auipc	a0,0x6
ffffffffc020085a:	3b250513          	addi	a0,a0,946 # ffffffffc0206c08 <commands+0x380>
ffffffffc020085e:	86fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200862:	10843583          	ld	a1,264(s0)
ffffffffc0200866:	00006517          	auipc	a0,0x6
ffffffffc020086a:	3ba50513          	addi	a0,a0,954 # ffffffffc0206c20 <commands+0x398>
ffffffffc020086e:	85fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200872:	11043583          	ld	a1,272(s0)
ffffffffc0200876:	00006517          	auipc	a0,0x6
ffffffffc020087a:	3c250513          	addi	a0,a0,962 # ffffffffc0206c38 <commands+0x3b0>
ffffffffc020087e:	84fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200882:	11843583          	ld	a1,280(s0)
}
ffffffffc0200886:	6402                	ld	s0,0(sp)
ffffffffc0200888:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020088a:	00006517          	auipc	a0,0x6
ffffffffc020088e:	3be50513          	addi	a0,a0,958 # ffffffffc0206c48 <commands+0x3c0>
}
ffffffffc0200892:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200894:	839ff06f          	j	ffffffffc02000cc <cprintf>

ffffffffc0200898 <pgfault_handler>:
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int
pgfault_handler(struct trapframe *tf) {
ffffffffc0200898:	1101                	addi	sp,sp,-32
ffffffffc020089a:	e426                	sd	s1,8(sp)
    extern struct mm_struct *check_mm_struct;
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc020089c:	000b2497          	auipc	s1,0xb2
ffffffffc02008a0:	fe448493          	addi	s1,s1,-28 # ffffffffc02b2880 <check_mm_struct>
ffffffffc02008a4:	609c                	ld	a5,0(s1)
pgfault_handler(struct trapframe *tf) {
ffffffffc02008a6:	e822                	sd	s0,16(sp)
ffffffffc02008a8:	ec06                	sd	ra,24(sp)
ffffffffc02008aa:	842a                	mv	s0,a0
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc02008ac:	cbad                	beqz	a5,ffffffffc020091e <pgfault_handler+0x86>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008ae:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008b2:	11053583          	ld	a1,272(a0)
ffffffffc02008b6:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008ba:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008be:	c7b1                	beqz	a5,ffffffffc020090a <pgfault_handler+0x72>
ffffffffc02008c0:	11843703          	ld	a4,280(s0)
ffffffffc02008c4:	47bd                	li	a5,15
ffffffffc02008c6:	05700693          	li	a3,87
ffffffffc02008ca:	00f70463          	beq	a4,a5,ffffffffc02008d2 <pgfault_handler+0x3a>
ffffffffc02008ce:	05200693          	li	a3,82
ffffffffc02008d2:	00006517          	auipc	a0,0x6
ffffffffc02008d6:	38e50513          	addi	a0,a0,910 # ffffffffc0206c60 <commands+0x3d8>
ffffffffc02008da:	ff2ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            print_pgfault(tf);
        }
    struct mm_struct *mm;
    if (check_mm_struct != NULL) {
ffffffffc02008de:	6088                	ld	a0,0(s1)
ffffffffc02008e0:	cd1d                	beqz	a0,ffffffffc020091e <pgfault_handler+0x86>
        assert(current == idleproc);
ffffffffc02008e2:	000b2717          	auipc	a4,0xb2
ffffffffc02008e6:	fce73703          	ld	a4,-50(a4) # ffffffffc02b28b0 <current>
ffffffffc02008ea:	000b2797          	auipc	a5,0xb2
ffffffffc02008ee:	fce7b783          	ld	a5,-50(a5) # ffffffffc02b28b8 <idleproc>
ffffffffc02008f2:	04f71663          	bne	a4,a5,ffffffffc020093e <pgfault_handler+0xa6>
            print_pgfault(tf);
            panic("unhandled page fault.\n");
        }
        mm = current->mm;
    }
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc02008f6:	11043603          	ld	a2,272(s0)
ffffffffc02008fa:	11843583          	ld	a1,280(s0)
}
ffffffffc02008fe:	6442                	ld	s0,16(sp)
ffffffffc0200900:	60e2                	ld	ra,24(sp)
ffffffffc0200902:	64a2                	ld	s1,8(sp)
ffffffffc0200904:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200906:	1490206f          	j	ffffffffc020324e <do_pgfault>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc020090a:	11843703          	ld	a4,280(s0)
ffffffffc020090e:	47bd                	li	a5,15
ffffffffc0200910:	05500613          	li	a2,85
ffffffffc0200914:	05700693          	li	a3,87
ffffffffc0200918:	faf71be3          	bne	a4,a5,ffffffffc02008ce <pgfault_handler+0x36>
ffffffffc020091c:	bf5d                	j	ffffffffc02008d2 <pgfault_handler+0x3a>
        if (current == NULL) {
ffffffffc020091e:	000b2797          	auipc	a5,0xb2
ffffffffc0200922:	f927b783          	ld	a5,-110(a5) # ffffffffc02b28b0 <current>
ffffffffc0200926:	cf85                	beqz	a5,ffffffffc020095e <pgfault_handler+0xc6>
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200928:	11043603          	ld	a2,272(s0)
ffffffffc020092c:	11843583          	ld	a1,280(s0)
}
ffffffffc0200930:	6442                	ld	s0,16(sp)
ffffffffc0200932:	60e2                	ld	ra,24(sp)
ffffffffc0200934:	64a2                	ld	s1,8(sp)
        mm = current->mm;
ffffffffc0200936:	7788                	ld	a0,40(a5)
}
ffffffffc0200938:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc020093a:	1150206f          	j	ffffffffc020324e <do_pgfault>
        assert(current == idleproc);
ffffffffc020093e:	00006697          	auipc	a3,0x6
ffffffffc0200942:	34268693          	addi	a3,a3,834 # ffffffffc0206c80 <commands+0x3f8>
ffffffffc0200946:	00006617          	auipc	a2,0x6
ffffffffc020094a:	35260613          	addi	a2,a2,850 # ffffffffc0206c98 <commands+0x410>
ffffffffc020094e:	06b00593          	li	a1,107
ffffffffc0200952:	00006517          	auipc	a0,0x6
ffffffffc0200956:	35e50513          	addi	a0,a0,862 # ffffffffc0206cb0 <commands+0x428>
ffffffffc020095a:	8afff0ef          	jal	ra,ffffffffc0200208 <__panic>
            print_trapframe(tf);
ffffffffc020095e:	8522                	mv	a0,s0
ffffffffc0200960:	ed7ff0ef          	jal	ra,ffffffffc0200836 <print_trapframe>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200964:	10043783          	ld	a5,256(s0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200968:	11043583          	ld	a1,272(s0)
ffffffffc020096c:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200970:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200974:	e399                	bnez	a5,ffffffffc020097a <pgfault_handler+0xe2>
ffffffffc0200976:	05500613          	li	a2,85
ffffffffc020097a:	11843703          	ld	a4,280(s0)
ffffffffc020097e:	47bd                	li	a5,15
ffffffffc0200980:	02f70663          	beq	a4,a5,ffffffffc02009ac <pgfault_handler+0x114>
ffffffffc0200984:	05200693          	li	a3,82
ffffffffc0200988:	00006517          	auipc	a0,0x6
ffffffffc020098c:	2d850513          	addi	a0,a0,728 # ffffffffc0206c60 <commands+0x3d8>
ffffffffc0200990:	f3cff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            panic("unhandled page fault.\n");
ffffffffc0200994:	00006617          	auipc	a2,0x6
ffffffffc0200998:	33460613          	addi	a2,a2,820 # ffffffffc0206cc8 <commands+0x440>
ffffffffc020099c:	07200593          	li	a1,114
ffffffffc02009a0:	00006517          	auipc	a0,0x6
ffffffffc02009a4:	31050513          	addi	a0,a0,784 # ffffffffc0206cb0 <commands+0x428>
ffffffffc02009a8:	861ff0ef          	jal	ra,ffffffffc0200208 <__panic>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02009ac:	05700693          	li	a3,87
ffffffffc02009b0:	bfe1                	j	ffffffffc0200988 <pgfault_handler+0xf0>

ffffffffc02009b2 <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02009b2:	11853783          	ld	a5,280(a0)
ffffffffc02009b6:	472d                	li	a4,11
ffffffffc02009b8:	0786                	slli	a5,a5,0x1
ffffffffc02009ba:	8385                	srli	a5,a5,0x1
ffffffffc02009bc:	08f76363          	bltu	a4,a5,ffffffffc0200a42 <interrupt_handler+0x90>
ffffffffc02009c0:	00006717          	auipc	a4,0x6
ffffffffc02009c4:	3c070713          	addi	a4,a4,960 # ffffffffc0206d80 <commands+0x4f8>
ffffffffc02009c8:	078a                	slli	a5,a5,0x2
ffffffffc02009ca:	97ba                	add	a5,a5,a4
ffffffffc02009cc:	439c                	lw	a5,0(a5)
ffffffffc02009ce:	97ba                	add	a5,a5,a4
ffffffffc02009d0:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02009d2:	00006517          	auipc	a0,0x6
ffffffffc02009d6:	36e50513          	addi	a0,a0,878 # ffffffffc0206d40 <commands+0x4b8>
ffffffffc02009da:	ef2ff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02009de:	00006517          	auipc	a0,0x6
ffffffffc02009e2:	34250513          	addi	a0,a0,834 # ffffffffc0206d20 <commands+0x498>
ffffffffc02009e6:	ee6ff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02009ea:	00006517          	auipc	a0,0x6
ffffffffc02009ee:	2f650513          	addi	a0,a0,758 # ffffffffc0206ce0 <commands+0x458>
ffffffffc02009f2:	edaff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02009f6:	00006517          	auipc	a0,0x6
ffffffffc02009fa:	30a50513          	addi	a0,a0,778 # ffffffffc0206d00 <commands+0x478>
ffffffffc02009fe:	eceff06f          	j	ffffffffc02000cc <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200a02:	1141                	addi	sp,sp,-16
ffffffffc0200a04:	e406                	sd	ra,8(sp)
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc0200a06:	bafff0ef          	jal	ra,ffffffffc02005b4 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0 && current) {
ffffffffc0200a0a:	000b2697          	auipc	a3,0xb2
ffffffffc0200a0e:	e3668693          	addi	a3,a3,-458 # ffffffffc02b2840 <ticks>
ffffffffc0200a12:	629c                	ld	a5,0(a3)
ffffffffc0200a14:	06400713          	li	a4,100
ffffffffc0200a18:	0785                	addi	a5,a5,1
ffffffffc0200a1a:	02e7f733          	remu	a4,a5,a4
ffffffffc0200a1e:	e29c                	sd	a5,0(a3)
ffffffffc0200a20:	eb01                	bnez	a4,ffffffffc0200a30 <interrupt_handler+0x7e>
ffffffffc0200a22:	000b2797          	auipc	a5,0xb2
ffffffffc0200a26:	e8e7b783          	ld	a5,-370(a5) # ffffffffc02b28b0 <current>
ffffffffc0200a2a:	c399                	beqz	a5,ffffffffc0200a30 <interrupt_handler+0x7e>
                // print_ticks();
                current->need_resched = 1;
ffffffffc0200a2c:	4705                	li	a4,1
ffffffffc0200a2e:	ef98                	sd	a4,24(a5)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a30:	60a2                	ld	ra,8(sp)
ffffffffc0200a32:	0141                	addi	sp,sp,16
ffffffffc0200a34:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200a36:	00006517          	auipc	a0,0x6
ffffffffc0200a3a:	32a50513          	addi	a0,a0,810 # ffffffffc0206d60 <commands+0x4d8>
ffffffffc0200a3e:	e8eff06f          	j	ffffffffc02000cc <cprintf>
            print_trapframe(tf);
ffffffffc0200a42:	bbd5                	j	ffffffffc0200836 <print_trapframe>

ffffffffc0200a44 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf,uintptr_t kstacktop);
void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc0200a44:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200a48:	1101                	addi	sp,sp,-32
ffffffffc0200a4a:	e822                	sd	s0,16(sp)
ffffffffc0200a4c:	ec06                	sd	ra,24(sp)
ffffffffc0200a4e:	e426                	sd	s1,8(sp)
ffffffffc0200a50:	473d                	li	a4,15
ffffffffc0200a52:	842a                	mv	s0,a0
ffffffffc0200a54:	18f76563          	bltu	a4,a5,ffffffffc0200bde <exception_handler+0x19a>
ffffffffc0200a58:	00006717          	auipc	a4,0x6
ffffffffc0200a5c:	4f070713          	addi	a4,a4,1264 # ffffffffc0206f48 <commands+0x6c0>
ffffffffc0200a60:	078a                	slli	a5,a5,0x2
ffffffffc0200a62:	97ba                	add	a5,a5,a4
ffffffffc0200a64:	439c                	lw	a5,0(a5)
ffffffffc0200a66:	97ba                	add	a5,a5,a4
ffffffffc0200a68:	8782                	jr	a5
            //cprintf("Environment call from U-mode\n");
            tf->epc += 4;
            syscall();
            break;
        case CAUSE_SUPERVISOR_ECALL:
            cprintf("Environment call from S-mode\n");
ffffffffc0200a6a:	00006517          	auipc	a0,0x6
ffffffffc0200a6e:	43650513          	addi	a0,a0,1078 # ffffffffc0206ea0 <commands+0x618>
ffffffffc0200a72:	e5aff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            tf->epc += 4;
ffffffffc0200a76:	10843783          	ld	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a7a:	60e2                	ld	ra,24(sp)
ffffffffc0200a7c:	64a2                	ld	s1,8(sp)
            tf->epc += 4;
ffffffffc0200a7e:	0791                	addi	a5,a5,4
ffffffffc0200a80:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200a84:	6442                	ld	s0,16(sp)
ffffffffc0200a86:	6105                	addi	sp,sp,32
            syscall();
ffffffffc0200a88:	62a0506f          	j	ffffffffc02060b2 <syscall>
            cprintf("Environment call from H-mode\n");
ffffffffc0200a8c:	00006517          	auipc	a0,0x6
ffffffffc0200a90:	43450513          	addi	a0,a0,1076 # ffffffffc0206ec0 <commands+0x638>
}
ffffffffc0200a94:	6442                	ld	s0,16(sp)
ffffffffc0200a96:	60e2                	ld	ra,24(sp)
ffffffffc0200a98:	64a2                	ld	s1,8(sp)
ffffffffc0200a9a:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc0200a9c:	e30ff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("Environment call from M-mode\n");
ffffffffc0200aa0:	00006517          	auipc	a0,0x6
ffffffffc0200aa4:	44050513          	addi	a0,a0,1088 # ffffffffc0206ee0 <commands+0x658>
ffffffffc0200aa8:	b7f5                	j	ffffffffc0200a94 <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200aaa:	00006517          	auipc	a0,0x6
ffffffffc0200aae:	45650513          	addi	a0,a0,1110 # ffffffffc0206f00 <commands+0x678>
ffffffffc0200ab2:	b7cd                	j	ffffffffc0200a94 <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200ab4:	00006517          	auipc	a0,0x6
ffffffffc0200ab8:	46450513          	addi	a0,a0,1124 # ffffffffc0206f18 <commands+0x690>
ffffffffc0200abc:	e10ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200ac0:	8522                	mv	a0,s0
ffffffffc0200ac2:	dd7ff0ef          	jal	ra,ffffffffc0200898 <pgfault_handler>
ffffffffc0200ac6:	84aa                	mv	s1,a0
ffffffffc0200ac8:	12051d63          	bnez	a0,ffffffffc0200c02 <exception_handler+0x1be>
}
ffffffffc0200acc:	60e2                	ld	ra,24(sp)
ffffffffc0200ace:	6442                	ld	s0,16(sp)
ffffffffc0200ad0:	64a2                	ld	s1,8(sp)
ffffffffc0200ad2:	6105                	addi	sp,sp,32
ffffffffc0200ad4:	8082                	ret
            cprintf("Store/AMO page fault\n");
ffffffffc0200ad6:	00006517          	auipc	a0,0x6
ffffffffc0200ada:	45a50513          	addi	a0,a0,1114 # ffffffffc0206f30 <commands+0x6a8>
ffffffffc0200ade:	deeff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200ae2:	8522                	mv	a0,s0
ffffffffc0200ae4:	db5ff0ef          	jal	ra,ffffffffc0200898 <pgfault_handler>
ffffffffc0200ae8:	84aa                	mv	s1,a0
ffffffffc0200aea:	d16d                	beqz	a0,ffffffffc0200acc <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200aec:	8522                	mv	a0,s0
ffffffffc0200aee:	d49ff0ef          	jal	ra,ffffffffc0200836 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200af2:	86a6                	mv	a3,s1
ffffffffc0200af4:	00006617          	auipc	a2,0x6
ffffffffc0200af8:	35c60613          	addi	a2,a2,860 # ffffffffc0206e50 <commands+0x5c8>
ffffffffc0200afc:	0f800593          	li	a1,248
ffffffffc0200b00:	00006517          	auipc	a0,0x6
ffffffffc0200b04:	1b050513          	addi	a0,a0,432 # ffffffffc0206cb0 <commands+0x428>
ffffffffc0200b08:	f00ff0ef          	jal	ra,ffffffffc0200208 <__panic>
            cprintf("Instruction address misaligned\n");
ffffffffc0200b0c:	00006517          	auipc	a0,0x6
ffffffffc0200b10:	2a450513          	addi	a0,a0,676 # ffffffffc0206db0 <commands+0x528>
ffffffffc0200b14:	b741                	j	ffffffffc0200a94 <exception_handler+0x50>
            cprintf("Instruction access fault\n");
ffffffffc0200b16:	00006517          	auipc	a0,0x6
ffffffffc0200b1a:	2ba50513          	addi	a0,a0,698 # ffffffffc0206dd0 <commands+0x548>
ffffffffc0200b1e:	bf9d                	j	ffffffffc0200a94 <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc0200b20:	00006517          	auipc	a0,0x6
ffffffffc0200b24:	2d050513          	addi	a0,a0,720 # ffffffffc0206df0 <commands+0x568>
ffffffffc0200b28:	b7b5                	j	ffffffffc0200a94 <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc0200b2a:	00006517          	auipc	a0,0x6
ffffffffc0200b2e:	2de50513          	addi	a0,a0,734 # ffffffffc0206e08 <commands+0x580>
ffffffffc0200b32:	d9aff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if(tf->gpr.a7 == 10){
ffffffffc0200b36:	6458                	ld	a4,136(s0)
ffffffffc0200b38:	47a9                	li	a5,10
ffffffffc0200b3a:	f8f719e3          	bne	a4,a5,ffffffffc0200acc <exception_handler+0x88>
                tf->epc += 4;
ffffffffc0200b3e:	10843783          	ld	a5,264(s0)
ffffffffc0200b42:	0791                	addi	a5,a5,4
ffffffffc0200b44:	10f43423          	sd	a5,264(s0)
                syscall();
ffffffffc0200b48:	56a050ef          	jal	ra,ffffffffc02060b2 <syscall>
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b4c:	000b2797          	auipc	a5,0xb2
ffffffffc0200b50:	d647b783          	ld	a5,-668(a5) # ffffffffc02b28b0 <current>
ffffffffc0200b54:	6b9c                	ld	a5,16(a5)
ffffffffc0200b56:	8522                	mv	a0,s0
}
ffffffffc0200b58:	6442                	ld	s0,16(sp)
ffffffffc0200b5a:	60e2                	ld	ra,24(sp)
ffffffffc0200b5c:	64a2                	ld	s1,8(sp)
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b5e:	6589                	lui	a1,0x2
ffffffffc0200b60:	95be                	add	a1,a1,a5
}
ffffffffc0200b62:	6105                	addi	sp,sp,32
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b64:	ac19                	j	ffffffffc0200d7a <kernel_execve_ret>
            cprintf("Load address misaligned\n");
ffffffffc0200b66:	00006517          	auipc	a0,0x6
ffffffffc0200b6a:	2b250513          	addi	a0,a0,690 # ffffffffc0206e18 <commands+0x590>
ffffffffc0200b6e:	b71d                	j	ffffffffc0200a94 <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc0200b70:	00006517          	auipc	a0,0x6
ffffffffc0200b74:	2c850513          	addi	a0,a0,712 # ffffffffc0206e38 <commands+0x5b0>
ffffffffc0200b78:	d54ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200b7c:	8522                	mv	a0,s0
ffffffffc0200b7e:	d1bff0ef          	jal	ra,ffffffffc0200898 <pgfault_handler>
ffffffffc0200b82:	84aa                	mv	s1,a0
ffffffffc0200b84:	d521                	beqz	a0,ffffffffc0200acc <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200b86:	8522                	mv	a0,s0
ffffffffc0200b88:	cafff0ef          	jal	ra,ffffffffc0200836 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200b8c:	86a6                	mv	a3,s1
ffffffffc0200b8e:	00006617          	auipc	a2,0x6
ffffffffc0200b92:	2c260613          	addi	a2,a2,706 # ffffffffc0206e50 <commands+0x5c8>
ffffffffc0200b96:	0cd00593          	li	a1,205
ffffffffc0200b9a:	00006517          	auipc	a0,0x6
ffffffffc0200b9e:	11650513          	addi	a0,a0,278 # ffffffffc0206cb0 <commands+0x428>
ffffffffc0200ba2:	e66ff0ef          	jal	ra,ffffffffc0200208 <__panic>
            cprintf("Store/AMO access fault\n");
ffffffffc0200ba6:	00006517          	auipc	a0,0x6
ffffffffc0200baa:	2e250513          	addi	a0,a0,738 # ffffffffc0206e88 <commands+0x600>
ffffffffc0200bae:	d1eff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200bb2:	8522                	mv	a0,s0
ffffffffc0200bb4:	ce5ff0ef          	jal	ra,ffffffffc0200898 <pgfault_handler>
ffffffffc0200bb8:	84aa                	mv	s1,a0
ffffffffc0200bba:	f00509e3          	beqz	a0,ffffffffc0200acc <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200bbe:	8522                	mv	a0,s0
ffffffffc0200bc0:	c77ff0ef          	jal	ra,ffffffffc0200836 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200bc4:	86a6                	mv	a3,s1
ffffffffc0200bc6:	00006617          	auipc	a2,0x6
ffffffffc0200bca:	28a60613          	addi	a2,a2,650 # ffffffffc0206e50 <commands+0x5c8>
ffffffffc0200bce:	0d700593          	li	a1,215
ffffffffc0200bd2:	00006517          	auipc	a0,0x6
ffffffffc0200bd6:	0de50513          	addi	a0,a0,222 # ffffffffc0206cb0 <commands+0x428>
ffffffffc0200bda:	e2eff0ef          	jal	ra,ffffffffc0200208 <__panic>
            print_trapframe(tf);
ffffffffc0200bde:	8522                	mv	a0,s0
}
ffffffffc0200be0:	6442                	ld	s0,16(sp)
ffffffffc0200be2:	60e2                	ld	ra,24(sp)
ffffffffc0200be4:	64a2                	ld	s1,8(sp)
ffffffffc0200be6:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200be8:	b1b9                	j	ffffffffc0200836 <print_trapframe>
            panic("AMO address misaligned\n");
ffffffffc0200bea:	00006617          	auipc	a2,0x6
ffffffffc0200bee:	28660613          	addi	a2,a2,646 # ffffffffc0206e70 <commands+0x5e8>
ffffffffc0200bf2:	0d100593          	li	a1,209
ffffffffc0200bf6:	00006517          	auipc	a0,0x6
ffffffffc0200bfa:	0ba50513          	addi	a0,a0,186 # ffffffffc0206cb0 <commands+0x428>
ffffffffc0200bfe:	e0aff0ef          	jal	ra,ffffffffc0200208 <__panic>
                print_trapframe(tf);
ffffffffc0200c02:	8522                	mv	a0,s0
ffffffffc0200c04:	c33ff0ef          	jal	ra,ffffffffc0200836 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200c08:	86a6                	mv	a3,s1
ffffffffc0200c0a:	00006617          	auipc	a2,0x6
ffffffffc0200c0e:	24660613          	addi	a2,a2,582 # ffffffffc0206e50 <commands+0x5c8>
ffffffffc0200c12:	0f100593          	li	a1,241
ffffffffc0200c16:	00006517          	auipc	a0,0x6
ffffffffc0200c1a:	09a50513          	addi	a0,a0,154 # ffffffffc0206cb0 <commands+0x428>
ffffffffc0200c1e:	deaff0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0200c22 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
ffffffffc0200c22:	1101                	addi	sp,sp,-32
ffffffffc0200c24:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
//    cputs("some trap");
    if (current == NULL) {
ffffffffc0200c26:	000b2417          	auipc	s0,0xb2
ffffffffc0200c2a:	c8a40413          	addi	s0,s0,-886 # ffffffffc02b28b0 <current>
ffffffffc0200c2e:	6018                	ld	a4,0(s0)
trap(struct trapframe *tf) {
ffffffffc0200c30:	ec06                	sd	ra,24(sp)
ffffffffc0200c32:	e426                	sd	s1,8(sp)
ffffffffc0200c34:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c36:	11853683          	ld	a3,280(a0)
    if (current == NULL) {
ffffffffc0200c3a:	cf1d                	beqz	a4,ffffffffc0200c78 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c3c:	10053483          	ld	s1,256(a0)
        trap_dispatch(tf);
    } else {
        struct trapframe *otf = current->tf;
ffffffffc0200c40:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200c44:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c46:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c4a:	0206c463          	bltz	a3,ffffffffc0200c72 <trap+0x50>
        exception_handler(tf);
ffffffffc0200c4e:	df7ff0ef          	jal	ra,ffffffffc0200a44 <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200c52:	601c                	ld	a5,0(s0)
ffffffffc0200c54:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel) {
ffffffffc0200c58:	e499                	bnez	s1,ffffffffc0200c66 <trap+0x44>
            if (current->flags & PF_EXITING) {
ffffffffc0200c5a:	0b07a703          	lw	a4,176(a5)
ffffffffc0200c5e:	8b05                	andi	a4,a4,1
ffffffffc0200c60:	e329                	bnez	a4,ffffffffc0200ca2 <trap+0x80>
                do_exit(-E_KILLED);
            }
            if (current->need_resched) {
ffffffffc0200c62:	6f9c                	ld	a5,24(a5)
ffffffffc0200c64:	eb85                	bnez	a5,ffffffffc0200c94 <trap+0x72>
                schedule();
            }
        }
    }
}
ffffffffc0200c66:	60e2                	ld	ra,24(sp)
ffffffffc0200c68:	6442                	ld	s0,16(sp)
ffffffffc0200c6a:	64a2                	ld	s1,8(sp)
ffffffffc0200c6c:	6902                	ld	s2,0(sp)
ffffffffc0200c6e:	6105                	addi	sp,sp,32
ffffffffc0200c70:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200c72:	d41ff0ef          	jal	ra,ffffffffc02009b2 <interrupt_handler>
ffffffffc0200c76:	bff1                	j	ffffffffc0200c52 <trap+0x30>
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c78:	0006c863          	bltz	a3,ffffffffc0200c88 <trap+0x66>
}
ffffffffc0200c7c:	6442                	ld	s0,16(sp)
ffffffffc0200c7e:	60e2                	ld	ra,24(sp)
ffffffffc0200c80:	64a2                	ld	s1,8(sp)
ffffffffc0200c82:	6902                	ld	s2,0(sp)
ffffffffc0200c84:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200c86:	bb7d                	j	ffffffffc0200a44 <exception_handler>
}
ffffffffc0200c88:	6442                	ld	s0,16(sp)
ffffffffc0200c8a:	60e2                	ld	ra,24(sp)
ffffffffc0200c8c:	64a2                	ld	s1,8(sp)
ffffffffc0200c8e:	6902                	ld	s2,0(sp)
ffffffffc0200c90:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200c92:	b305                	j	ffffffffc02009b2 <interrupt_handler>
}
ffffffffc0200c94:	6442                	ld	s0,16(sp)
ffffffffc0200c96:	60e2                	ld	ra,24(sp)
ffffffffc0200c98:	64a2                	ld	s1,8(sp)
ffffffffc0200c9a:	6902                	ld	s2,0(sp)
ffffffffc0200c9c:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200c9e:	3280506f          	j	ffffffffc0205fc6 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200ca2:	555d                	li	a0,-9
ffffffffc0200ca4:	6d2040ef          	jal	ra,ffffffffc0205376 <do_exit>
            if (current->need_resched) {
ffffffffc0200ca8:	601c                	ld	a5,0(s0)
ffffffffc0200caa:	bf65                	j	ffffffffc0200c62 <trap+0x40>

ffffffffc0200cac <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200cac:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200cb0:	00011463          	bnez	sp,ffffffffc0200cb8 <__alltraps+0xc>
ffffffffc0200cb4:	14002173          	csrr	sp,sscratch
ffffffffc0200cb8:	712d                	addi	sp,sp,-288
ffffffffc0200cba:	e002                	sd	zero,0(sp)
ffffffffc0200cbc:	e406                	sd	ra,8(sp)
ffffffffc0200cbe:	ec0e                	sd	gp,24(sp)
ffffffffc0200cc0:	f012                	sd	tp,32(sp)
ffffffffc0200cc2:	f416                	sd	t0,40(sp)
ffffffffc0200cc4:	f81a                	sd	t1,48(sp)
ffffffffc0200cc6:	fc1e                	sd	t2,56(sp)
ffffffffc0200cc8:	e0a2                	sd	s0,64(sp)
ffffffffc0200cca:	e4a6                	sd	s1,72(sp)
ffffffffc0200ccc:	e8aa                	sd	a0,80(sp)
ffffffffc0200cce:	ecae                	sd	a1,88(sp)
ffffffffc0200cd0:	f0b2                	sd	a2,96(sp)
ffffffffc0200cd2:	f4b6                	sd	a3,104(sp)
ffffffffc0200cd4:	f8ba                	sd	a4,112(sp)
ffffffffc0200cd6:	fcbe                	sd	a5,120(sp)
ffffffffc0200cd8:	e142                	sd	a6,128(sp)
ffffffffc0200cda:	e546                	sd	a7,136(sp)
ffffffffc0200cdc:	e94a                	sd	s2,144(sp)
ffffffffc0200cde:	ed4e                	sd	s3,152(sp)
ffffffffc0200ce0:	f152                	sd	s4,160(sp)
ffffffffc0200ce2:	f556                	sd	s5,168(sp)
ffffffffc0200ce4:	f95a                	sd	s6,176(sp)
ffffffffc0200ce6:	fd5e                	sd	s7,184(sp)
ffffffffc0200ce8:	e1e2                	sd	s8,192(sp)
ffffffffc0200cea:	e5e6                	sd	s9,200(sp)
ffffffffc0200cec:	e9ea                	sd	s10,208(sp)
ffffffffc0200cee:	edee                	sd	s11,216(sp)
ffffffffc0200cf0:	f1f2                	sd	t3,224(sp)
ffffffffc0200cf2:	f5f6                	sd	t4,232(sp)
ffffffffc0200cf4:	f9fa                	sd	t5,240(sp)
ffffffffc0200cf6:	fdfe                	sd	t6,248(sp)
ffffffffc0200cf8:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200cfc:	100024f3          	csrr	s1,sstatus
ffffffffc0200d00:	14102973          	csrr	s2,sepc
ffffffffc0200d04:	143029f3          	csrr	s3,stval
ffffffffc0200d08:	14202a73          	csrr	s4,scause
ffffffffc0200d0c:	e822                	sd	s0,16(sp)
ffffffffc0200d0e:	e226                	sd	s1,256(sp)
ffffffffc0200d10:	e64a                	sd	s2,264(sp)
ffffffffc0200d12:	ea4e                	sd	s3,272(sp)
ffffffffc0200d14:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d16:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d18:	f0bff0ef          	jal	ra,ffffffffc0200c22 <trap>

ffffffffc0200d1c <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d1c:	6492                	ld	s1,256(sp)
ffffffffc0200d1e:	6932                	ld	s2,264(sp)
ffffffffc0200d20:	1004f413          	andi	s0,s1,256
ffffffffc0200d24:	e401                	bnez	s0,ffffffffc0200d2c <__trapret+0x10>
ffffffffc0200d26:	1200                	addi	s0,sp,288
ffffffffc0200d28:	14041073          	csrw	sscratch,s0
ffffffffc0200d2c:	10049073          	csrw	sstatus,s1
ffffffffc0200d30:	14191073          	csrw	sepc,s2
ffffffffc0200d34:	60a2                	ld	ra,8(sp)
ffffffffc0200d36:	61e2                	ld	gp,24(sp)
ffffffffc0200d38:	7202                	ld	tp,32(sp)
ffffffffc0200d3a:	72a2                	ld	t0,40(sp)
ffffffffc0200d3c:	7342                	ld	t1,48(sp)
ffffffffc0200d3e:	73e2                	ld	t2,56(sp)
ffffffffc0200d40:	6406                	ld	s0,64(sp)
ffffffffc0200d42:	64a6                	ld	s1,72(sp)
ffffffffc0200d44:	6546                	ld	a0,80(sp)
ffffffffc0200d46:	65e6                	ld	a1,88(sp)
ffffffffc0200d48:	7606                	ld	a2,96(sp)
ffffffffc0200d4a:	76a6                	ld	a3,104(sp)
ffffffffc0200d4c:	7746                	ld	a4,112(sp)
ffffffffc0200d4e:	77e6                	ld	a5,120(sp)
ffffffffc0200d50:	680a                	ld	a6,128(sp)
ffffffffc0200d52:	68aa                	ld	a7,136(sp)
ffffffffc0200d54:	694a                	ld	s2,144(sp)
ffffffffc0200d56:	69ea                	ld	s3,152(sp)
ffffffffc0200d58:	7a0a                	ld	s4,160(sp)
ffffffffc0200d5a:	7aaa                	ld	s5,168(sp)
ffffffffc0200d5c:	7b4a                	ld	s6,176(sp)
ffffffffc0200d5e:	7bea                	ld	s7,184(sp)
ffffffffc0200d60:	6c0e                	ld	s8,192(sp)
ffffffffc0200d62:	6cae                	ld	s9,200(sp)
ffffffffc0200d64:	6d4e                	ld	s10,208(sp)
ffffffffc0200d66:	6dee                	ld	s11,216(sp)
ffffffffc0200d68:	7e0e                	ld	t3,224(sp)
ffffffffc0200d6a:	7eae                	ld	t4,232(sp)
ffffffffc0200d6c:	7f4e                	ld	t5,240(sp)
ffffffffc0200d6e:	7fee                	ld	t6,248(sp)
ffffffffc0200d70:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200d72:	10200073          	sret

ffffffffc0200d76 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200d76:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200d78:	b755                	j	ffffffffc0200d1c <__trapret>

ffffffffc0200d7a <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200d7a:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cd8>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200d7e:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200d82:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200d86:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200d8a:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200d8e:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200d92:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200d96:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200d9a:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200d9e:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200da0:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200da2:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200da4:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200da6:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200da8:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200daa:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200dac:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200dae:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200db0:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200db2:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200db4:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200db6:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200db8:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200dba:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200dbc:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200dbe:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200dc0:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200dc2:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200dc4:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200dc6:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200dc8:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200dca:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200dcc:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200dce:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200dd0:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200dd2:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200dd4:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200dd6:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200dd8:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200dda:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200ddc:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200dde:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200de0:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200de2:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200de4:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200de6:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200de8:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200dea:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200dec:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200dee:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200df0:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200df2:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200df4:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200df6:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200df8:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200dfa:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200dfc:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200dfe:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200e00:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200e02:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200e04:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200e06:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200e08:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200e0a:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200e0c:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200e0e:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200e10:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200e12:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200e14:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200e16:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200e18:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200e1a:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200e1c:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200e1e:	812e                	mv	sp,a1
ffffffffc0200e20:	bdf5                	j	ffffffffc0200d1c <__trapret>

ffffffffc0200e22 <pa2page.part.0>:
page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
}

static inline struct Page *
pa2page(uintptr_t pa) {
ffffffffc0200e22:	1141                	addi	sp,sp,-16
    if (PPN(pa) >= npage) {
        panic("pa2page called with invalid pa");
ffffffffc0200e24:	00006617          	auipc	a2,0x6
ffffffffc0200e28:	16460613          	addi	a2,a2,356 # ffffffffc0206f88 <commands+0x700>
ffffffffc0200e2c:	06200593          	li	a1,98
ffffffffc0200e30:	00006517          	auipc	a0,0x6
ffffffffc0200e34:	17850513          	addi	a0,a0,376 # ffffffffc0206fa8 <commands+0x720>
pa2page(uintptr_t pa) {
ffffffffc0200e38:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0200e3a:	bceff0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0200e3e <pte2page.part.0>:
kva2page(void *kva) {
    return pa2page(PADDR(kva));
}

static inline struct Page *
pte2page(pte_t pte) {
ffffffffc0200e3e:	1141                	addi	sp,sp,-16
    if (!(pte & PTE_V)) {
        panic("pte2page called with invalid pte");
ffffffffc0200e40:	00006617          	auipc	a2,0x6
ffffffffc0200e44:	17860613          	addi	a2,a2,376 # ffffffffc0206fb8 <commands+0x730>
ffffffffc0200e48:	07400593          	li	a1,116
ffffffffc0200e4c:	00006517          	auipc	a0,0x6
ffffffffc0200e50:	15c50513          	addi	a0,a0,348 # ffffffffc0206fa8 <commands+0x720>
pte2page(pte_t pte) {
ffffffffc0200e54:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0200e56:	bb2ff0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0200e5a <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc0200e5a:	7139                	addi	sp,sp,-64
ffffffffc0200e5c:	f426                	sd	s1,40(sp)
ffffffffc0200e5e:	f04a                	sd	s2,32(sp)
ffffffffc0200e60:	ec4e                	sd	s3,24(sp)
ffffffffc0200e62:	e852                	sd	s4,16(sp)
ffffffffc0200e64:	e456                	sd	s5,8(sp)
ffffffffc0200e66:	e05a                	sd	s6,0(sp)
ffffffffc0200e68:	fc06                	sd	ra,56(sp)
ffffffffc0200e6a:	f822                	sd	s0,48(sp)
ffffffffc0200e6c:	84aa                	mv	s1,a0
ffffffffc0200e6e:	000b2917          	auipc	s2,0xb2
ffffffffc0200e72:	a0290913          	addi	s2,s2,-1534 # ffffffffc02b2870 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200e76:	4a05                	li	s4,1
ffffffffc0200e78:	000b2a97          	auipc	s5,0xb2
ffffffffc0200e7c:	a30a8a93          	addi	s5,s5,-1488 # ffffffffc02b28a8 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0200e80:	0005099b          	sext.w	s3,a0
ffffffffc0200e84:	000b2b17          	auipc	s6,0xb2
ffffffffc0200e88:	9fcb0b13          	addi	s6,s6,-1540 # ffffffffc02b2880 <check_mm_struct>
ffffffffc0200e8c:	a01d                	j	ffffffffc0200eb2 <alloc_pages+0x58>
            page = pmm_manager->alloc_pages(n);
ffffffffc0200e8e:	00093783          	ld	a5,0(s2)
ffffffffc0200e92:	6f9c                	ld	a5,24(a5)
ffffffffc0200e94:	9782                	jalr	a5
ffffffffc0200e96:	842a                	mv	s0,a0
        swap_out(check_mm_struct, n, 0);
ffffffffc0200e98:	4601                	li	a2,0
ffffffffc0200e9a:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200e9c:	ec0d                	bnez	s0,ffffffffc0200ed6 <alloc_pages+0x7c>
ffffffffc0200e9e:	029a6c63          	bltu	s4,s1,ffffffffc0200ed6 <alloc_pages+0x7c>
ffffffffc0200ea2:	000aa783          	lw	a5,0(s5)
ffffffffc0200ea6:	2781                	sext.w	a5,a5
ffffffffc0200ea8:	c79d                	beqz	a5,ffffffffc0200ed6 <alloc_pages+0x7c>
        swap_out(check_mm_struct, n, 0);
ffffffffc0200eaa:	000b3503          	ld	a0,0(s6)
ffffffffc0200eae:	09e030ef          	jal	ra,ffffffffc0203f4c <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200eb2:	100027f3          	csrr	a5,sstatus
ffffffffc0200eb6:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc0200eb8:	8526                	mv	a0,s1
ffffffffc0200eba:	dbf1                	beqz	a5,ffffffffc0200e8e <alloc_pages+0x34>
        intr_disable();
ffffffffc0200ebc:	f8cff0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc0200ec0:	00093783          	ld	a5,0(s2)
ffffffffc0200ec4:	8526                	mv	a0,s1
ffffffffc0200ec6:	6f9c                	ld	a5,24(a5)
ffffffffc0200ec8:	9782                	jalr	a5
ffffffffc0200eca:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200ecc:	f76ff0ef          	jal	ra,ffffffffc0200642 <intr_enable>
        swap_out(check_mm_struct, n, 0);
ffffffffc0200ed0:	4601                	li	a2,0
ffffffffc0200ed2:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200ed4:	d469                	beqz	s0,ffffffffc0200e9e <alloc_pages+0x44>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0200ed6:	70e2                	ld	ra,56(sp)
ffffffffc0200ed8:	8522                	mv	a0,s0
ffffffffc0200eda:	7442                	ld	s0,48(sp)
ffffffffc0200edc:	74a2                	ld	s1,40(sp)
ffffffffc0200ede:	7902                	ld	s2,32(sp)
ffffffffc0200ee0:	69e2                	ld	s3,24(sp)
ffffffffc0200ee2:	6a42                	ld	s4,16(sp)
ffffffffc0200ee4:	6aa2                	ld	s5,8(sp)
ffffffffc0200ee6:	6b02                	ld	s6,0(sp)
ffffffffc0200ee8:	6121                	addi	sp,sp,64
ffffffffc0200eea:	8082                	ret

ffffffffc0200eec <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200eec:	100027f3          	csrr	a5,sstatus
ffffffffc0200ef0:	8b89                	andi	a5,a5,2
ffffffffc0200ef2:	e799                	bnez	a5,ffffffffc0200f00 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200ef4:	000b2797          	auipc	a5,0xb2
ffffffffc0200ef8:	97c7b783          	ld	a5,-1668(a5) # ffffffffc02b2870 <pmm_manager>
ffffffffc0200efc:	739c                	ld	a5,32(a5)
ffffffffc0200efe:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0200f00:	1101                	addi	sp,sp,-32
ffffffffc0200f02:	ec06                	sd	ra,24(sp)
ffffffffc0200f04:	e822                	sd	s0,16(sp)
ffffffffc0200f06:	e426                	sd	s1,8(sp)
ffffffffc0200f08:	842a                	mv	s0,a0
ffffffffc0200f0a:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200f0c:	f3cff0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200f10:	000b2797          	auipc	a5,0xb2
ffffffffc0200f14:	9607b783          	ld	a5,-1696(a5) # ffffffffc02b2870 <pmm_manager>
ffffffffc0200f18:	739c                	ld	a5,32(a5)
ffffffffc0200f1a:	85a6                	mv	a1,s1
ffffffffc0200f1c:	8522                	mv	a0,s0
ffffffffc0200f1e:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200f20:	6442                	ld	s0,16(sp)
ffffffffc0200f22:	60e2                	ld	ra,24(sp)
ffffffffc0200f24:	64a2                	ld	s1,8(sp)
ffffffffc0200f26:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200f28:	f1aff06f          	j	ffffffffc0200642 <intr_enable>

ffffffffc0200f2c <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200f2c:	100027f3          	csrr	a5,sstatus
ffffffffc0200f30:	8b89                	andi	a5,a5,2
ffffffffc0200f32:	e799                	bnez	a5,ffffffffc0200f40 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200f34:	000b2797          	auipc	a5,0xb2
ffffffffc0200f38:	93c7b783          	ld	a5,-1732(a5) # ffffffffc02b2870 <pmm_manager>
ffffffffc0200f3c:	779c                	ld	a5,40(a5)
ffffffffc0200f3e:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0200f40:	1141                	addi	sp,sp,-16
ffffffffc0200f42:	e406                	sd	ra,8(sp)
ffffffffc0200f44:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200f46:	f02ff0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0200f4a:	000b2797          	auipc	a5,0xb2
ffffffffc0200f4e:	9267b783          	ld	a5,-1754(a5) # ffffffffc02b2870 <pmm_manager>
ffffffffc0200f52:	779c                	ld	a5,40(a5)
ffffffffc0200f54:	9782                	jalr	a5
ffffffffc0200f56:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200f58:	eeaff0ef          	jal	ra,ffffffffc0200642 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200f5c:	60a2                	ld	ra,8(sp)
ffffffffc0200f5e:	8522                	mv	a0,s0
ffffffffc0200f60:	6402                	ld	s0,0(sp)
ffffffffc0200f62:	0141                	addi	sp,sp,16
ffffffffc0200f64:	8082                	ret

ffffffffc0200f66 <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200f66:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0200f6a:	1ff7f793          	andi	a5,a5,511
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200f6e:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200f70:	078e                	slli	a5,a5,0x3
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200f72:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200f74:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V)) {
ffffffffc0200f78:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200f7a:	f04a                	sd	s2,32(sp)
ffffffffc0200f7c:	ec4e                	sd	s3,24(sp)
ffffffffc0200f7e:	e852                	sd	s4,16(sp)
ffffffffc0200f80:	fc06                	sd	ra,56(sp)
ffffffffc0200f82:	f822                	sd	s0,48(sp)
ffffffffc0200f84:	e456                	sd	s5,8(sp)
ffffffffc0200f86:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc0200f88:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200f8c:	892e                	mv	s2,a1
ffffffffc0200f8e:	89b2                	mv	s3,a2
ffffffffc0200f90:	000b2a17          	auipc	s4,0xb2
ffffffffc0200f94:	8d0a0a13          	addi	s4,s4,-1840 # ffffffffc02b2860 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc0200f98:	e7b5                	bnez	a5,ffffffffc0201004 <get_pte+0x9e>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0200f9a:	12060b63          	beqz	a2,ffffffffc02010d0 <get_pte+0x16a>
ffffffffc0200f9e:	4505                	li	a0,1
ffffffffc0200fa0:	ebbff0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc0200fa4:	842a                	mv	s0,a0
ffffffffc0200fa6:	12050563          	beqz	a0,ffffffffc02010d0 <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0200faa:	000b2b17          	auipc	s6,0xb2
ffffffffc0200fae:	8beb0b13          	addi	s6,s6,-1858 # ffffffffc02b2868 <pages>
ffffffffc0200fb2:	000b3503          	ld	a0,0(s6)
ffffffffc0200fb6:	00080ab7          	lui	s5,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200fba:	000b2a17          	auipc	s4,0xb2
ffffffffc0200fbe:	8a6a0a13          	addi	s4,s4,-1882 # ffffffffc02b2860 <npage>
ffffffffc0200fc2:	40a40533          	sub	a0,s0,a0
ffffffffc0200fc6:	8519                	srai	a0,a0,0x6
ffffffffc0200fc8:	9556                	add	a0,a0,s5
ffffffffc0200fca:	000a3703          	ld	a4,0(s4)
ffffffffc0200fce:	00c51793          	slli	a5,a0,0xc
    return page->ref;
}

static inline void
set_page_ref(struct Page *page, int val) {
    page->ref = val;
ffffffffc0200fd2:	4685                	li	a3,1
ffffffffc0200fd4:	c014                	sw	a3,0(s0)
ffffffffc0200fd6:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200fd8:	0532                	slli	a0,a0,0xc
ffffffffc0200fda:	14e7f263          	bgeu	a5,a4,ffffffffc020111e <get_pte+0x1b8>
ffffffffc0200fde:	000b2797          	auipc	a5,0xb2
ffffffffc0200fe2:	89a7b783          	ld	a5,-1894(a5) # ffffffffc02b2878 <va_pa_offset>
ffffffffc0200fe6:	6605                	lui	a2,0x1
ffffffffc0200fe8:	4581                	li	a1,0
ffffffffc0200fea:	953e                	add	a0,a0,a5
ffffffffc0200fec:	1c2050ef          	jal	ra,ffffffffc02061ae <memset>
    return page - pages + nbase;
ffffffffc0200ff0:	000b3683          	ld	a3,0(s6)
ffffffffc0200ff4:	40d406b3          	sub	a3,s0,a3
ffffffffc0200ff8:	8699                	srai	a3,a3,0x6
ffffffffc0200ffa:	96d6                	add	a3,a3,s5
  asm volatile("sfence.vma");
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200ffc:	06aa                	slli	a3,a3,0xa
ffffffffc0200ffe:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201002:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201004:	77fd                	lui	a5,0xfffff
ffffffffc0201006:	068a                	slli	a3,a3,0x2
ffffffffc0201008:	000a3703          	ld	a4,0(s4)
ffffffffc020100c:	8efd                	and	a3,a3,a5
ffffffffc020100e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201012:	0ce7f163          	bgeu	a5,a4,ffffffffc02010d4 <get_pte+0x16e>
ffffffffc0201016:	000b2a97          	auipc	s5,0xb2
ffffffffc020101a:	862a8a93          	addi	s5,s5,-1950 # ffffffffc02b2878 <va_pa_offset>
ffffffffc020101e:	000ab403          	ld	s0,0(s5)
ffffffffc0201022:	01595793          	srli	a5,s2,0x15
ffffffffc0201026:	1ff7f793          	andi	a5,a5,511
ffffffffc020102a:	96a2                	add	a3,a3,s0
ffffffffc020102c:	00379413          	slli	s0,a5,0x3
ffffffffc0201030:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V)) {
ffffffffc0201032:	6014                	ld	a3,0(s0)
ffffffffc0201034:	0016f793          	andi	a5,a3,1
ffffffffc0201038:	e3ad                	bnez	a5,ffffffffc020109a <get_pte+0x134>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc020103a:	08098b63          	beqz	s3,ffffffffc02010d0 <get_pte+0x16a>
ffffffffc020103e:	4505                	li	a0,1
ffffffffc0201040:	e1bff0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc0201044:	84aa                	mv	s1,a0
ffffffffc0201046:	c549                	beqz	a0,ffffffffc02010d0 <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0201048:	000b2b17          	auipc	s6,0xb2
ffffffffc020104c:	820b0b13          	addi	s6,s6,-2016 # ffffffffc02b2868 <pages>
ffffffffc0201050:	000b3503          	ld	a0,0(s6)
ffffffffc0201054:	000809b7          	lui	s3,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201058:	000a3703          	ld	a4,0(s4)
ffffffffc020105c:	40a48533          	sub	a0,s1,a0
ffffffffc0201060:	8519                	srai	a0,a0,0x6
ffffffffc0201062:	954e                	add	a0,a0,s3
ffffffffc0201064:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201068:	4685                	li	a3,1
ffffffffc020106a:	c094                	sw	a3,0(s1)
ffffffffc020106c:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020106e:	0532                	slli	a0,a0,0xc
ffffffffc0201070:	08e7fa63          	bgeu	a5,a4,ffffffffc0201104 <get_pte+0x19e>
ffffffffc0201074:	000ab783          	ld	a5,0(s5)
ffffffffc0201078:	6605                	lui	a2,0x1
ffffffffc020107a:	4581                	li	a1,0
ffffffffc020107c:	953e                	add	a0,a0,a5
ffffffffc020107e:	130050ef          	jal	ra,ffffffffc02061ae <memset>
    return page - pages + nbase;
ffffffffc0201082:	000b3683          	ld	a3,0(s6)
ffffffffc0201086:	40d486b3          	sub	a3,s1,a3
ffffffffc020108a:	8699                	srai	a3,a3,0x6
ffffffffc020108c:	96ce                	add	a3,a3,s3
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020108e:	06aa                	slli	a3,a3,0xa
ffffffffc0201090:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201094:	e014                	sd	a3,0(s0)
        }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201096:	000a3703          	ld	a4,0(s4)
ffffffffc020109a:	068a                	slli	a3,a3,0x2
ffffffffc020109c:	757d                	lui	a0,0xfffff
ffffffffc020109e:	8ee9                	and	a3,a3,a0
ffffffffc02010a0:	00c6d793          	srli	a5,a3,0xc
ffffffffc02010a4:	04e7f463          	bgeu	a5,a4,ffffffffc02010ec <get_pte+0x186>
ffffffffc02010a8:	000ab503          	ld	a0,0(s5)
ffffffffc02010ac:	00c95913          	srli	s2,s2,0xc
ffffffffc02010b0:	1ff97913          	andi	s2,s2,511
ffffffffc02010b4:	96aa                	add	a3,a3,a0
ffffffffc02010b6:	00391513          	slli	a0,s2,0x3
ffffffffc02010ba:	9536                	add	a0,a0,a3
}
ffffffffc02010bc:	70e2                	ld	ra,56(sp)
ffffffffc02010be:	7442                	ld	s0,48(sp)
ffffffffc02010c0:	74a2                	ld	s1,40(sp)
ffffffffc02010c2:	7902                	ld	s2,32(sp)
ffffffffc02010c4:	69e2                	ld	s3,24(sp)
ffffffffc02010c6:	6a42                	ld	s4,16(sp)
ffffffffc02010c8:	6aa2                	ld	s5,8(sp)
ffffffffc02010ca:	6b02                	ld	s6,0(sp)
ffffffffc02010cc:	6121                	addi	sp,sp,64
ffffffffc02010ce:	8082                	ret
            return NULL;
ffffffffc02010d0:	4501                	li	a0,0
ffffffffc02010d2:	b7ed                	j	ffffffffc02010bc <get_pte+0x156>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02010d4:	00006617          	auipc	a2,0x6
ffffffffc02010d8:	f0c60613          	addi	a2,a2,-244 # ffffffffc0206fe0 <commands+0x758>
ffffffffc02010dc:	0e300593          	li	a1,227
ffffffffc02010e0:	00006517          	auipc	a0,0x6
ffffffffc02010e4:	f2850513          	addi	a0,a0,-216 # ffffffffc0207008 <commands+0x780>
ffffffffc02010e8:	920ff0ef          	jal	ra,ffffffffc0200208 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02010ec:	00006617          	auipc	a2,0x6
ffffffffc02010f0:	ef460613          	addi	a2,a2,-268 # ffffffffc0206fe0 <commands+0x758>
ffffffffc02010f4:	0ee00593          	li	a1,238
ffffffffc02010f8:	00006517          	auipc	a0,0x6
ffffffffc02010fc:	f1050513          	addi	a0,a0,-240 # ffffffffc0207008 <commands+0x780>
ffffffffc0201100:	908ff0ef          	jal	ra,ffffffffc0200208 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201104:	86aa                	mv	a3,a0
ffffffffc0201106:	00006617          	auipc	a2,0x6
ffffffffc020110a:	eda60613          	addi	a2,a2,-294 # ffffffffc0206fe0 <commands+0x758>
ffffffffc020110e:	0eb00593          	li	a1,235
ffffffffc0201112:	00006517          	auipc	a0,0x6
ffffffffc0201116:	ef650513          	addi	a0,a0,-266 # ffffffffc0207008 <commands+0x780>
ffffffffc020111a:	8eeff0ef          	jal	ra,ffffffffc0200208 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020111e:	86aa                	mv	a3,a0
ffffffffc0201120:	00006617          	auipc	a2,0x6
ffffffffc0201124:	ec060613          	addi	a2,a2,-320 # ffffffffc0206fe0 <commands+0x758>
ffffffffc0201128:	0df00593          	li	a1,223
ffffffffc020112c:	00006517          	auipc	a0,0x6
ffffffffc0201130:	edc50513          	addi	a0,a0,-292 # ffffffffc0207008 <commands+0x780>
ffffffffc0201134:	8d4ff0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0201138 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201138:	1141                	addi	sp,sp,-16
ffffffffc020113a:	e022                	sd	s0,0(sp)
ffffffffc020113c:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020113e:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201140:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201142:	e25ff0ef          	jal	ra,ffffffffc0200f66 <get_pte>
    if (ptep_store != NULL) {
ffffffffc0201146:	c011                	beqz	s0,ffffffffc020114a <get_page+0x12>
        *ptep_store = ptep;
ffffffffc0201148:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc020114a:	c511                	beqz	a0,ffffffffc0201156 <get_page+0x1e>
ffffffffc020114c:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc020114e:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0201150:	0017f713          	andi	a4,a5,1
ffffffffc0201154:	e709                	bnez	a4,ffffffffc020115e <get_page+0x26>
}
ffffffffc0201156:	60a2                	ld	ra,8(sp)
ffffffffc0201158:	6402                	ld	s0,0(sp)
ffffffffc020115a:	0141                	addi	sp,sp,16
ffffffffc020115c:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020115e:	078a                	slli	a5,a5,0x2
ffffffffc0201160:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201162:	000b1717          	auipc	a4,0xb1
ffffffffc0201166:	6fe73703          	ld	a4,1790(a4) # ffffffffc02b2860 <npage>
ffffffffc020116a:	00e7ff63          	bgeu	a5,a4,ffffffffc0201188 <get_page+0x50>
ffffffffc020116e:	60a2                	ld	ra,8(sp)
ffffffffc0201170:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0201172:	fff80537          	lui	a0,0xfff80
ffffffffc0201176:	97aa                	add	a5,a5,a0
ffffffffc0201178:	079a                	slli	a5,a5,0x6
ffffffffc020117a:	000b1517          	auipc	a0,0xb1
ffffffffc020117e:	6ee53503          	ld	a0,1774(a0) # ffffffffc02b2868 <pages>
ffffffffc0201182:	953e                	add	a0,a0,a5
ffffffffc0201184:	0141                	addi	sp,sp,16
ffffffffc0201186:	8082                	ret
ffffffffc0201188:	c9bff0ef          	jal	ra,ffffffffc0200e22 <pa2page.part.0>

ffffffffc020118c <unmap_range>:
        *ptep = 0;                  //(5) clear second page table entry
        tlb_invalidate(pgdir, la);  //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc020118c:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020118e:	00c5e7b3          	or	a5,a1,a2
void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0201192:	f486                	sd	ra,104(sp)
ffffffffc0201194:	f0a2                	sd	s0,96(sp)
ffffffffc0201196:	eca6                	sd	s1,88(sp)
ffffffffc0201198:	e8ca                	sd	s2,80(sp)
ffffffffc020119a:	e4ce                	sd	s3,72(sp)
ffffffffc020119c:	e0d2                	sd	s4,64(sp)
ffffffffc020119e:	fc56                	sd	s5,56(sp)
ffffffffc02011a0:	f85a                	sd	s6,48(sp)
ffffffffc02011a2:	f45e                	sd	s7,40(sp)
ffffffffc02011a4:	f062                	sd	s8,32(sp)
ffffffffc02011a6:	ec66                	sd	s9,24(sp)
ffffffffc02011a8:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02011aa:	17d2                	slli	a5,a5,0x34
ffffffffc02011ac:	e3ed                	bnez	a5,ffffffffc020128e <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc02011ae:	002007b7          	lui	a5,0x200
ffffffffc02011b2:	842e                	mv	s0,a1
ffffffffc02011b4:	0ef5ed63          	bltu	a1,a5,ffffffffc02012ae <unmap_range+0x122>
ffffffffc02011b8:	8932                	mv	s2,a2
ffffffffc02011ba:	0ec5fa63          	bgeu	a1,a2,ffffffffc02012ae <unmap_range+0x122>
ffffffffc02011be:	4785                	li	a5,1
ffffffffc02011c0:	07fe                	slli	a5,a5,0x1f
ffffffffc02011c2:	0ec7e663          	bltu	a5,a2,ffffffffc02012ae <unmap_range+0x122>
ffffffffc02011c6:	89aa                	mv	s3,a0
            continue;
        }
        if (*ptep != 0) {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02011c8:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage) {
ffffffffc02011ca:	000b1c97          	auipc	s9,0xb1
ffffffffc02011ce:	696c8c93          	addi	s9,s9,1686 # ffffffffc02b2860 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02011d2:	000b1c17          	auipc	s8,0xb1
ffffffffc02011d6:	696c0c13          	addi	s8,s8,1686 # ffffffffc02b2868 <pages>
ffffffffc02011da:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc02011de:	000b1d17          	auipc	s10,0xb1
ffffffffc02011e2:	692d0d13          	addi	s10,s10,1682 # ffffffffc02b2870 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02011e6:	00200b37          	lui	s6,0x200
ffffffffc02011ea:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02011ee:	4601                	li	a2,0
ffffffffc02011f0:	85a2                	mv	a1,s0
ffffffffc02011f2:	854e                	mv	a0,s3
ffffffffc02011f4:	d73ff0ef          	jal	ra,ffffffffc0200f66 <get_pte>
ffffffffc02011f8:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc02011fa:	cd29                	beqz	a0,ffffffffc0201254 <unmap_range+0xc8>
        if (*ptep != 0) {
ffffffffc02011fc:	611c                	ld	a5,0(a0)
ffffffffc02011fe:	e395                	bnez	a5,ffffffffc0201222 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc0201200:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0201202:	ff2466e3          	bltu	s0,s2,ffffffffc02011ee <unmap_range+0x62>
}
ffffffffc0201206:	70a6                	ld	ra,104(sp)
ffffffffc0201208:	7406                	ld	s0,96(sp)
ffffffffc020120a:	64e6                	ld	s1,88(sp)
ffffffffc020120c:	6946                	ld	s2,80(sp)
ffffffffc020120e:	69a6                	ld	s3,72(sp)
ffffffffc0201210:	6a06                	ld	s4,64(sp)
ffffffffc0201212:	7ae2                	ld	s5,56(sp)
ffffffffc0201214:	7b42                	ld	s6,48(sp)
ffffffffc0201216:	7ba2                	ld	s7,40(sp)
ffffffffc0201218:	7c02                	ld	s8,32(sp)
ffffffffc020121a:	6ce2                	ld	s9,24(sp)
ffffffffc020121c:	6d42                	ld	s10,16(sp)
ffffffffc020121e:	6165                	addi	sp,sp,112
ffffffffc0201220:	8082                	ret
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0201222:	0017f713          	andi	a4,a5,1
ffffffffc0201226:	df69                	beqz	a4,ffffffffc0201200 <unmap_range+0x74>
    if (PPN(pa) >= npage) {
ffffffffc0201228:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020122c:	078a                	slli	a5,a5,0x2
ffffffffc020122e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201230:	08e7ff63          	bgeu	a5,a4,ffffffffc02012ce <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0201234:	000c3503          	ld	a0,0(s8)
ffffffffc0201238:	97de                	add	a5,a5,s7
ffffffffc020123a:	079a                	slli	a5,a5,0x6
ffffffffc020123c:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020123e:	411c                	lw	a5,0(a0)
ffffffffc0201240:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201244:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201246:	cf11                	beqz	a4,ffffffffc0201262 <unmap_range+0xd6>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0201248:	0004b023          	sd	zero,0(s1)
}

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020124c:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0201250:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0201252:	bf45                	j	ffffffffc0201202 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0201254:	945a                	add	s0,s0,s6
ffffffffc0201256:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc020125a:	d455                	beqz	s0,ffffffffc0201206 <unmap_range+0x7a>
ffffffffc020125c:	f92469e3          	bltu	s0,s2,ffffffffc02011ee <unmap_range+0x62>
ffffffffc0201260:	b75d                	j	ffffffffc0201206 <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201262:	100027f3          	csrr	a5,sstatus
ffffffffc0201266:	8b89                	andi	a5,a5,2
ffffffffc0201268:	e799                	bnez	a5,ffffffffc0201276 <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc020126a:	000d3783          	ld	a5,0(s10)
ffffffffc020126e:	4585                	li	a1,1
ffffffffc0201270:	739c                	ld	a5,32(a5)
ffffffffc0201272:	9782                	jalr	a5
    if (flag) {
ffffffffc0201274:	bfd1                	j	ffffffffc0201248 <unmap_range+0xbc>
ffffffffc0201276:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201278:	bd0ff0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc020127c:	000d3783          	ld	a5,0(s10)
ffffffffc0201280:	6522                	ld	a0,8(sp)
ffffffffc0201282:	4585                	li	a1,1
ffffffffc0201284:	739c                	ld	a5,32(a5)
ffffffffc0201286:	9782                	jalr	a5
        intr_enable();
ffffffffc0201288:	bbaff0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc020128c:	bf75                	j	ffffffffc0201248 <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020128e:	00006697          	auipc	a3,0x6
ffffffffc0201292:	d8a68693          	addi	a3,a3,-630 # ffffffffc0207018 <commands+0x790>
ffffffffc0201296:	00006617          	auipc	a2,0x6
ffffffffc020129a:	a0260613          	addi	a2,a2,-1534 # ffffffffc0206c98 <commands+0x410>
ffffffffc020129e:	10f00593          	li	a1,271
ffffffffc02012a2:	00006517          	auipc	a0,0x6
ffffffffc02012a6:	d6650513          	addi	a0,a0,-666 # ffffffffc0207008 <commands+0x780>
ffffffffc02012aa:	f5ffe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02012ae:	00006697          	auipc	a3,0x6
ffffffffc02012b2:	d9a68693          	addi	a3,a3,-614 # ffffffffc0207048 <commands+0x7c0>
ffffffffc02012b6:	00006617          	auipc	a2,0x6
ffffffffc02012ba:	9e260613          	addi	a2,a2,-1566 # ffffffffc0206c98 <commands+0x410>
ffffffffc02012be:	11000593          	li	a1,272
ffffffffc02012c2:	00006517          	auipc	a0,0x6
ffffffffc02012c6:	d4650513          	addi	a0,a0,-698 # ffffffffc0207008 <commands+0x780>
ffffffffc02012ca:	f3ffe0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc02012ce:	b55ff0ef          	jal	ra,ffffffffc0200e22 <pa2page.part.0>

ffffffffc02012d2 <exit_range>:
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc02012d2:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02012d4:	00c5e7b3          	or	a5,a1,a2
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc02012d8:	fc86                	sd	ra,120(sp)
ffffffffc02012da:	f8a2                	sd	s0,112(sp)
ffffffffc02012dc:	f4a6                	sd	s1,104(sp)
ffffffffc02012de:	f0ca                	sd	s2,96(sp)
ffffffffc02012e0:	ecce                	sd	s3,88(sp)
ffffffffc02012e2:	e8d2                	sd	s4,80(sp)
ffffffffc02012e4:	e4d6                	sd	s5,72(sp)
ffffffffc02012e6:	e0da                	sd	s6,64(sp)
ffffffffc02012e8:	fc5e                	sd	s7,56(sp)
ffffffffc02012ea:	f862                	sd	s8,48(sp)
ffffffffc02012ec:	f466                	sd	s9,40(sp)
ffffffffc02012ee:	f06a                	sd	s10,32(sp)
ffffffffc02012f0:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02012f2:	17d2                	slli	a5,a5,0x34
ffffffffc02012f4:	20079a63          	bnez	a5,ffffffffc0201508 <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc02012f8:	002007b7          	lui	a5,0x200
ffffffffc02012fc:	24f5e463          	bltu	a1,a5,ffffffffc0201544 <exit_range+0x272>
ffffffffc0201300:	8ab2                	mv	s5,a2
ffffffffc0201302:	24c5f163          	bgeu	a1,a2,ffffffffc0201544 <exit_range+0x272>
ffffffffc0201306:	4785                	li	a5,1
ffffffffc0201308:	07fe                	slli	a5,a5,0x1f
ffffffffc020130a:	22c7ed63          	bltu	a5,a2,ffffffffc0201544 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc020130e:	c00009b7          	lui	s3,0xc0000
ffffffffc0201312:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0201316:	ffe00937          	lui	s2,0xffe00
ffffffffc020131a:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc020131e:	5cfd                	li	s9,-1
ffffffffc0201320:	8c2a                	mv	s8,a0
ffffffffc0201322:	0125f933          	and	s2,a1,s2
ffffffffc0201326:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage) {
ffffffffc0201328:	000b1d17          	auipc	s10,0xb1
ffffffffc020132c:	538d0d13          	addi	s10,s10,1336 # ffffffffc02b2860 <npage>
    return KADDR(page2pa(page));
ffffffffc0201330:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0201334:	000b1717          	auipc	a4,0xb1
ffffffffc0201338:	53470713          	addi	a4,a4,1332 # ffffffffc02b2868 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc020133c:	000b1d97          	auipc	s11,0xb1
ffffffffc0201340:	534d8d93          	addi	s11,s11,1332 # ffffffffc02b2870 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0201344:	c0000437          	lui	s0,0xc0000
ffffffffc0201348:	944e                	add	s0,s0,s3
ffffffffc020134a:	8079                	srli	s0,s0,0x1e
ffffffffc020134c:	1ff47413          	andi	s0,s0,511
ffffffffc0201350:	040e                	slli	s0,s0,0x3
ffffffffc0201352:	9462                	add	s0,s0,s8
ffffffffc0201354:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ed8>
        if (pde1&PTE_V){
ffffffffc0201358:	001a7793          	andi	a5,s4,1
ffffffffc020135c:	eb99                	bnez	a5,ffffffffc0201372 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc020135e:	12098463          	beqz	s3,ffffffffc0201486 <exit_range+0x1b4>
ffffffffc0201362:	400007b7          	lui	a5,0x40000
ffffffffc0201366:	97ce                	add	a5,a5,s3
ffffffffc0201368:	894e                	mv	s2,s3
ffffffffc020136a:	1159fe63          	bgeu	s3,s5,ffffffffc0201486 <exit_range+0x1b4>
ffffffffc020136e:	89be                	mv	s3,a5
ffffffffc0201370:	bfd1                	j	ffffffffc0201344 <exit_range+0x72>
    if (PPN(pa) >= npage) {
ffffffffc0201372:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201376:	0a0a                	slli	s4,s4,0x2
ffffffffc0201378:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage) {
ffffffffc020137c:	1cfa7263          	bgeu	s4,a5,ffffffffc0201540 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0201380:	fff80637          	lui	a2,0xfff80
ffffffffc0201384:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc0201386:	000806b7          	lui	a3,0x80
ffffffffc020138a:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc020138c:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0201390:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0201392:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201394:	18f5fa63          	bgeu	a1,a5,ffffffffc0201528 <exit_range+0x256>
ffffffffc0201398:	000b1817          	auipc	a6,0xb1
ffffffffc020139c:	4e080813          	addi	a6,a6,1248 # ffffffffc02b2878 <va_pa_offset>
ffffffffc02013a0:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc02013a4:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc02013a6:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc02013aa:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc02013ac:	00080337          	lui	t1,0x80
ffffffffc02013b0:	6885                	lui	a7,0x1
ffffffffc02013b2:	a819                	j	ffffffffc02013c8 <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc02013b4:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc02013b6:	002007b7          	lui	a5,0x200
ffffffffc02013ba:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc02013bc:	08090c63          	beqz	s2,ffffffffc0201454 <exit_range+0x182>
ffffffffc02013c0:	09397a63          	bgeu	s2,s3,ffffffffc0201454 <exit_range+0x182>
ffffffffc02013c4:	0f597063          	bgeu	s2,s5,ffffffffc02014a4 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02013c8:	01595493          	srli	s1,s2,0x15
ffffffffc02013cc:	1ff4f493          	andi	s1,s1,511
ffffffffc02013d0:	048e                	slli	s1,s1,0x3
ffffffffc02013d2:	94da                	add	s1,s1,s6
ffffffffc02013d4:	609c                	ld	a5,0(s1)
                if (pde0&PTE_V) {
ffffffffc02013d6:	0017f693          	andi	a3,a5,1
ffffffffc02013da:	dee9                	beqz	a3,ffffffffc02013b4 <exit_range+0xe2>
    if (PPN(pa) >= npage) {
ffffffffc02013dc:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02013e0:	078a                	slli	a5,a5,0x2
ffffffffc02013e2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02013e4:	14b7fe63          	bgeu	a5,a1,ffffffffc0201540 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02013e8:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc02013ea:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc02013ee:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02013f2:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02013f6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02013f8:	12bef863          	bgeu	t4,a1,ffffffffc0201528 <exit_range+0x256>
ffffffffc02013fc:	00083783          	ld	a5,0(a6)
ffffffffc0201400:	96be                	add	a3,a3,a5
                    for (int i = 0;i <NPTEENTRY;i++)
ffffffffc0201402:	011685b3          	add	a1,a3,a7
                        if (pt[i]&PTE_V){
ffffffffc0201406:	629c                	ld	a5,0(a3)
ffffffffc0201408:	8b85                	andi	a5,a5,1
ffffffffc020140a:	f7d5                	bnez	a5,ffffffffc02013b6 <exit_range+0xe4>
                    for (int i = 0;i <NPTEENTRY;i++)
ffffffffc020140c:	06a1                	addi	a3,a3,8
ffffffffc020140e:	fed59ce3          	bne	a1,a3,ffffffffc0201406 <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0201412:	631c                	ld	a5,0(a4)
ffffffffc0201414:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201416:	100027f3          	csrr	a5,sstatus
ffffffffc020141a:	8b89                	andi	a5,a5,2
ffffffffc020141c:	e7d9                	bnez	a5,ffffffffc02014aa <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc020141e:	000db783          	ld	a5,0(s11)
ffffffffc0201422:	4585                	li	a1,1
ffffffffc0201424:	e032                	sd	a2,0(sp)
ffffffffc0201426:	739c                	ld	a5,32(a5)
ffffffffc0201428:	9782                	jalr	a5
    if (flag) {
ffffffffc020142a:	6602                	ld	a2,0(sp)
ffffffffc020142c:	000b1817          	auipc	a6,0xb1
ffffffffc0201430:	44c80813          	addi	a6,a6,1100 # ffffffffc02b2878 <va_pa_offset>
ffffffffc0201434:	fff80e37          	lui	t3,0xfff80
ffffffffc0201438:	00080337          	lui	t1,0x80
ffffffffc020143c:	6885                	lui	a7,0x1
ffffffffc020143e:	000b1717          	auipc	a4,0xb1
ffffffffc0201442:	42a70713          	addi	a4,a4,1066 # ffffffffc02b2868 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0201446:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc020144a:	002007b7          	lui	a5,0x200
ffffffffc020144e:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc0201450:	f60918e3          	bnez	s2,ffffffffc02013c0 <exit_range+0xee>
            if (free_pd0) {
ffffffffc0201454:	f00b85e3          	beqz	s7,ffffffffc020135e <exit_range+0x8c>
    if (PPN(pa) >= npage) {
ffffffffc0201458:	000d3783          	ld	a5,0(s10)
ffffffffc020145c:	0efa7263          	bgeu	s4,a5,ffffffffc0201540 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0201460:	6308                	ld	a0,0(a4)
ffffffffc0201462:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201464:	100027f3          	csrr	a5,sstatus
ffffffffc0201468:	8b89                	andi	a5,a5,2
ffffffffc020146a:	efad                	bnez	a5,ffffffffc02014e4 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc020146c:	000db783          	ld	a5,0(s11)
ffffffffc0201470:	4585                	li	a1,1
ffffffffc0201472:	739c                	ld	a5,32(a5)
ffffffffc0201474:	9782                	jalr	a5
ffffffffc0201476:	000b1717          	auipc	a4,0xb1
ffffffffc020147a:	3f270713          	addi	a4,a4,1010 # ffffffffc02b2868 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc020147e:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc0201482:	ee0990e3          	bnez	s3,ffffffffc0201362 <exit_range+0x90>
}
ffffffffc0201486:	70e6                	ld	ra,120(sp)
ffffffffc0201488:	7446                	ld	s0,112(sp)
ffffffffc020148a:	74a6                	ld	s1,104(sp)
ffffffffc020148c:	7906                	ld	s2,96(sp)
ffffffffc020148e:	69e6                	ld	s3,88(sp)
ffffffffc0201490:	6a46                	ld	s4,80(sp)
ffffffffc0201492:	6aa6                	ld	s5,72(sp)
ffffffffc0201494:	6b06                	ld	s6,64(sp)
ffffffffc0201496:	7be2                	ld	s7,56(sp)
ffffffffc0201498:	7c42                	ld	s8,48(sp)
ffffffffc020149a:	7ca2                	ld	s9,40(sp)
ffffffffc020149c:	7d02                	ld	s10,32(sp)
ffffffffc020149e:	6de2                	ld	s11,24(sp)
ffffffffc02014a0:	6109                	addi	sp,sp,128
ffffffffc02014a2:	8082                	ret
            if (free_pd0) {
ffffffffc02014a4:	ea0b8fe3          	beqz	s7,ffffffffc0201362 <exit_range+0x90>
ffffffffc02014a8:	bf45                	j	ffffffffc0201458 <exit_range+0x186>
ffffffffc02014aa:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc02014ac:	e42a                	sd	a0,8(sp)
ffffffffc02014ae:	99aff0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02014b2:	000db783          	ld	a5,0(s11)
ffffffffc02014b6:	6522                	ld	a0,8(sp)
ffffffffc02014b8:	4585                	li	a1,1
ffffffffc02014ba:	739c                	ld	a5,32(a5)
ffffffffc02014bc:	9782                	jalr	a5
        intr_enable();
ffffffffc02014be:	984ff0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc02014c2:	6602                	ld	a2,0(sp)
ffffffffc02014c4:	000b1717          	auipc	a4,0xb1
ffffffffc02014c8:	3a470713          	addi	a4,a4,932 # ffffffffc02b2868 <pages>
ffffffffc02014cc:	6885                	lui	a7,0x1
ffffffffc02014ce:	00080337          	lui	t1,0x80
ffffffffc02014d2:	fff80e37          	lui	t3,0xfff80
ffffffffc02014d6:	000b1817          	auipc	a6,0xb1
ffffffffc02014da:	3a280813          	addi	a6,a6,930 # ffffffffc02b2878 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02014de:	0004b023          	sd	zero,0(s1)
ffffffffc02014e2:	b7a5                	j	ffffffffc020144a <exit_range+0x178>
ffffffffc02014e4:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc02014e6:	962ff0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02014ea:	000db783          	ld	a5,0(s11)
ffffffffc02014ee:	6502                	ld	a0,0(sp)
ffffffffc02014f0:	4585                	li	a1,1
ffffffffc02014f2:	739c                	ld	a5,32(a5)
ffffffffc02014f4:	9782                	jalr	a5
        intr_enable();
ffffffffc02014f6:	94cff0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc02014fa:	000b1717          	auipc	a4,0xb1
ffffffffc02014fe:	36e70713          	addi	a4,a4,878 # ffffffffc02b2868 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0201502:	00043023          	sd	zero,0(s0)
ffffffffc0201506:	bfb5                	j	ffffffffc0201482 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0201508:	00006697          	auipc	a3,0x6
ffffffffc020150c:	b1068693          	addi	a3,a3,-1264 # ffffffffc0207018 <commands+0x790>
ffffffffc0201510:	00005617          	auipc	a2,0x5
ffffffffc0201514:	78860613          	addi	a2,a2,1928 # ffffffffc0206c98 <commands+0x410>
ffffffffc0201518:	12000593          	li	a1,288
ffffffffc020151c:	00006517          	auipc	a0,0x6
ffffffffc0201520:	aec50513          	addi	a0,a0,-1300 # ffffffffc0207008 <commands+0x780>
ffffffffc0201524:	ce5fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    return KADDR(page2pa(page));
ffffffffc0201528:	00006617          	auipc	a2,0x6
ffffffffc020152c:	ab860613          	addi	a2,a2,-1352 # ffffffffc0206fe0 <commands+0x758>
ffffffffc0201530:	06900593          	li	a1,105
ffffffffc0201534:	00006517          	auipc	a0,0x6
ffffffffc0201538:	a7450513          	addi	a0,a0,-1420 # ffffffffc0206fa8 <commands+0x720>
ffffffffc020153c:	ccdfe0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0201540:	8e3ff0ef          	jal	ra,ffffffffc0200e22 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0201544:	00006697          	auipc	a3,0x6
ffffffffc0201548:	b0468693          	addi	a3,a3,-1276 # ffffffffc0207048 <commands+0x7c0>
ffffffffc020154c:	00005617          	auipc	a2,0x5
ffffffffc0201550:	74c60613          	addi	a2,a2,1868 # ffffffffc0206c98 <commands+0x410>
ffffffffc0201554:	12100593          	li	a1,289
ffffffffc0201558:	00006517          	auipc	a0,0x6
ffffffffc020155c:	ab050513          	addi	a0,a0,-1360 # ffffffffc0207008 <commands+0x780>
ffffffffc0201560:	ca9fe0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0201564 <page_remove>:
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0201564:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201566:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0201568:	ec26                	sd	s1,24(sp)
ffffffffc020156a:	f406                	sd	ra,40(sp)
ffffffffc020156c:	f022                	sd	s0,32(sp)
ffffffffc020156e:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201570:	9f7ff0ef          	jal	ra,ffffffffc0200f66 <get_pte>
    if (ptep != NULL) {
ffffffffc0201574:	c511                	beqz	a0,ffffffffc0201580 <page_remove+0x1c>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0201576:	611c                	ld	a5,0(a0)
ffffffffc0201578:	842a                	mv	s0,a0
ffffffffc020157a:	0017f713          	andi	a4,a5,1
ffffffffc020157e:	e711                	bnez	a4,ffffffffc020158a <page_remove+0x26>
}
ffffffffc0201580:	70a2                	ld	ra,40(sp)
ffffffffc0201582:	7402                	ld	s0,32(sp)
ffffffffc0201584:	64e2                	ld	s1,24(sp)
ffffffffc0201586:	6145                	addi	sp,sp,48
ffffffffc0201588:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020158a:	078a                	slli	a5,a5,0x2
ffffffffc020158c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020158e:	000b1717          	auipc	a4,0xb1
ffffffffc0201592:	2d273703          	ld	a4,722(a4) # ffffffffc02b2860 <npage>
ffffffffc0201596:	06e7f363          	bgeu	a5,a4,ffffffffc02015fc <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc020159a:	fff80537          	lui	a0,0xfff80
ffffffffc020159e:	97aa                	add	a5,a5,a0
ffffffffc02015a0:	079a                	slli	a5,a5,0x6
ffffffffc02015a2:	000b1517          	auipc	a0,0xb1
ffffffffc02015a6:	2c653503          	ld	a0,710(a0) # ffffffffc02b2868 <pages>
ffffffffc02015aa:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02015ac:	411c                	lw	a5,0(a0)
ffffffffc02015ae:	fff7871b          	addiw	a4,a5,-1
ffffffffc02015b2:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc02015b4:	cb11                	beqz	a4,ffffffffc02015c8 <page_remove+0x64>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc02015b6:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02015ba:	12048073          	sfence.vma	s1
}
ffffffffc02015be:	70a2                	ld	ra,40(sp)
ffffffffc02015c0:	7402                	ld	s0,32(sp)
ffffffffc02015c2:	64e2                	ld	s1,24(sp)
ffffffffc02015c4:	6145                	addi	sp,sp,48
ffffffffc02015c6:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02015c8:	100027f3          	csrr	a5,sstatus
ffffffffc02015cc:	8b89                	andi	a5,a5,2
ffffffffc02015ce:	eb89                	bnez	a5,ffffffffc02015e0 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc02015d0:	000b1797          	auipc	a5,0xb1
ffffffffc02015d4:	2a07b783          	ld	a5,672(a5) # ffffffffc02b2870 <pmm_manager>
ffffffffc02015d8:	739c                	ld	a5,32(a5)
ffffffffc02015da:	4585                	li	a1,1
ffffffffc02015dc:	9782                	jalr	a5
    if (flag) {
ffffffffc02015de:	bfe1                	j	ffffffffc02015b6 <page_remove+0x52>
        intr_disable();
ffffffffc02015e0:	e42a                	sd	a0,8(sp)
ffffffffc02015e2:	866ff0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc02015e6:	000b1797          	auipc	a5,0xb1
ffffffffc02015ea:	28a7b783          	ld	a5,650(a5) # ffffffffc02b2870 <pmm_manager>
ffffffffc02015ee:	739c                	ld	a5,32(a5)
ffffffffc02015f0:	6522                	ld	a0,8(sp)
ffffffffc02015f2:	4585                	li	a1,1
ffffffffc02015f4:	9782                	jalr	a5
        intr_enable();
ffffffffc02015f6:	84cff0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc02015fa:	bf75                	j	ffffffffc02015b6 <page_remove+0x52>
ffffffffc02015fc:	827ff0ef          	jal	ra,ffffffffc0200e22 <pa2page.part.0>

ffffffffc0201600 <page_insert>:
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0201600:	7139                	addi	sp,sp,-64
ffffffffc0201602:	e852                	sd	s4,16(sp)
ffffffffc0201604:	8a32                	mv	s4,a2
ffffffffc0201606:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201608:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc020160a:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020160c:	85d2                	mv	a1,s4
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc020160e:	f426                	sd	s1,40(sp)
ffffffffc0201610:	fc06                	sd	ra,56(sp)
ffffffffc0201612:	f04a                	sd	s2,32(sp)
ffffffffc0201614:	ec4e                	sd	s3,24(sp)
ffffffffc0201616:	e456                	sd	s5,8(sp)
ffffffffc0201618:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020161a:	94dff0ef          	jal	ra,ffffffffc0200f66 <get_pte>
    if (ptep == NULL) {
ffffffffc020161e:	c961                	beqz	a0,ffffffffc02016ee <page_insert+0xee>
    page->ref += 1;
ffffffffc0201620:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V) {
ffffffffc0201622:	611c                	ld	a5,0(a0)
ffffffffc0201624:	89aa                	mv	s3,a0
ffffffffc0201626:	0016871b          	addiw	a4,a3,1
ffffffffc020162a:	c018                	sw	a4,0(s0)
ffffffffc020162c:	0017f713          	andi	a4,a5,1
ffffffffc0201630:	ef05                	bnez	a4,ffffffffc0201668 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0201632:	000b1717          	auipc	a4,0xb1
ffffffffc0201636:	23673703          	ld	a4,566(a4) # ffffffffc02b2868 <pages>
ffffffffc020163a:	8c19                	sub	s0,s0,a4
ffffffffc020163c:	000807b7          	lui	a5,0x80
ffffffffc0201640:	8419                	srai	s0,s0,0x6
ffffffffc0201642:	943e                	add	s0,s0,a5
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201644:	042a                	slli	s0,s0,0xa
ffffffffc0201646:	8cc1                	or	s1,s1,s0
ffffffffc0201648:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc020164c:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ed8>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201650:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0201654:	4501                	li	a0,0
}
ffffffffc0201656:	70e2                	ld	ra,56(sp)
ffffffffc0201658:	7442                	ld	s0,48(sp)
ffffffffc020165a:	74a2                	ld	s1,40(sp)
ffffffffc020165c:	7902                	ld	s2,32(sp)
ffffffffc020165e:	69e2                	ld	s3,24(sp)
ffffffffc0201660:	6a42                	ld	s4,16(sp)
ffffffffc0201662:	6aa2                	ld	s5,8(sp)
ffffffffc0201664:	6121                	addi	sp,sp,64
ffffffffc0201666:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201668:	078a                	slli	a5,a5,0x2
ffffffffc020166a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020166c:	000b1717          	auipc	a4,0xb1
ffffffffc0201670:	1f473703          	ld	a4,500(a4) # ffffffffc02b2860 <npage>
ffffffffc0201674:	06e7ff63          	bgeu	a5,a4,ffffffffc02016f2 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0201678:	000b1a97          	auipc	s5,0xb1
ffffffffc020167c:	1f0a8a93          	addi	s5,s5,496 # ffffffffc02b2868 <pages>
ffffffffc0201680:	000ab703          	ld	a4,0(s5)
ffffffffc0201684:	fff80937          	lui	s2,0xfff80
ffffffffc0201688:	993e                	add	s2,s2,a5
ffffffffc020168a:	091a                	slli	s2,s2,0x6
ffffffffc020168c:	993a                	add	s2,s2,a4
        if (p == page) {
ffffffffc020168e:	01240c63          	beq	s0,s2,ffffffffc02016a6 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0201692:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fccd734>
ffffffffc0201696:	fff7869b          	addiw	a3,a5,-1
ffffffffc020169a:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc020169e:	c691                	beqz	a3,ffffffffc02016aa <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02016a0:	120a0073          	sfence.vma	s4
}
ffffffffc02016a4:	bf59                	j	ffffffffc020163a <page_insert+0x3a>
ffffffffc02016a6:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc02016a8:	bf49                	j	ffffffffc020163a <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016aa:	100027f3          	csrr	a5,sstatus
ffffffffc02016ae:	8b89                	andi	a5,a5,2
ffffffffc02016b0:	ef91                	bnez	a5,ffffffffc02016cc <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc02016b2:	000b1797          	auipc	a5,0xb1
ffffffffc02016b6:	1be7b783          	ld	a5,446(a5) # ffffffffc02b2870 <pmm_manager>
ffffffffc02016ba:	739c                	ld	a5,32(a5)
ffffffffc02016bc:	4585                	li	a1,1
ffffffffc02016be:	854a                	mv	a0,s2
ffffffffc02016c0:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02016c2:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02016c6:	120a0073          	sfence.vma	s4
ffffffffc02016ca:	bf85                	j	ffffffffc020163a <page_insert+0x3a>
        intr_disable();
ffffffffc02016cc:	f7dfe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02016d0:	000b1797          	auipc	a5,0xb1
ffffffffc02016d4:	1a07b783          	ld	a5,416(a5) # ffffffffc02b2870 <pmm_manager>
ffffffffc02016d8:	739c                	ld	a5,32(a5)
ffffffffc02016da:	4585                	li	a1,1
ffffffffc02016dc:	854a                	mv	a0,s2
ffffffffc02016de:	9782                	jalr	a5
        intr_enable();
ffffffffc02016e0:	f63fe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc02016e4:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02016e8:	120a0073          	sfence.vma	s4
ffffffffc02016ec:	b7b9                	j	ffffffffc020163a <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc02016ee:	5571                	li	a0,-4
ffffffffc02016f0:	b79d                	j	ffffffffc0201656 <page_insert+0x56>
ffffffffc02016f2:	f30ff0ef          	jal	ra,ffffffffc0200e22 <pa2page.part.0>

ffffffffc02016f6 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02016f6:	00007797          	auipc	a5,0x7
ffffffffc02016fa:	c4a78793          	addi	a5,a5,-950 # ffffffffc0208340 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02016fe:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0201700:	711d                	addi	sp,sp,-96
ffffffffc0201702:	ec5e                	sd	s7,24(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201704:	00006517          	auipc	a0,0x6
ffffffffc0201708:	95c50513          	addi	a0,a0,-1700 # ffffffffc0207060 <commands+0x7d8>
    pmm_manager = &default_pmm_manager;
ffffffffc020170c:	000b1b97          	auipc	s7,0xb1
ffffffffc0201710:	164b8b93          	addi	s7,s7,356 # ffffffffc02b2870 <pmm_manager>
void pmm_init(void) {
ffffffffc0201714:	ec86                	sd	ra,88(sp)
ffffffffc0201716:	e4a6                	sd	s1,72(sp)
ffffffffc0201718:	fc4e                	sd	s3,56(sp)
ffffffffc020171a:	f05a                	sd	s6,32(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020171c:	00fbb023          	sd	a5,0(s7)
void pmm_init(void) {
ffffffffc0201720:	e8a2                	sd	s0,80(sp)
ffffffffc0201722:	e0ca                	sd	s2,64(sp)
ffffffffc0201724:	f852                	sd	s4,48(sp)
ffffffffc0201726:	f456                	sd	s5,40(sp)
ffffffffc0201728:	e862                	sd	s8,16(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020172a:	9a3fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    pmm_manager->init();
ffffffffc020172e:	000bb783          	ld	a5,0(s7)
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201732:	000b1997          	auipc	s3,0xb1
ffffffffc0201736:	14698993          	addi	s3,s3,326 # ffffffffc02b2878 <va_pa_offset>
    npage = maxpa / PGSIZE;
ffffffffc020173a:	000b1497          	auipc	s1,0xb1
ffffffffc020173e:	12648493          	addi	s1,s1,294 # ffffffffc02b2860 <npage>
    pmm_manager->init();
ffffffffc0201742:	679c                	ld	a5,8(a5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201744:	000b1b17          	auipc	s6,0xb1
ffffffffc0201748:	124b0b13          	addi	s6,s6,292 # ffffffffc02b2868 <pages>
    pmm_manager->init();
ffffffffc020174c:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc020174e:	57f5                	li	a5,-3
ffffffffc0201750:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0201752:	00006517          	auipc	a0,0x6
ffffffffc0201756:	92650513          	addi	a0,a0,-1754 # ffffffffc0207078 <commands+0x7f0>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc020175a:	00f9b023          	sd	a5,0(s3)
    cprintf("physcial memory map:\n");
ffffffffc020175e:	96ffe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0201762:	46c5                	li	a3,17
ffffffffc0201764:	06ee                	slli	a3,a3,0x1b
ffffffffc0201766:	40100613          	li	a2,1025
ffffffffc020176a:	07e005b7          	lui	a1,0x7e00
ffffffffc020176e:	16fd                	addi	a3,a3,-1
ffffffffc0201770:	0656                	slli	a2,a2,0x15
ffffffffc0201772:	00006517          	auipc	a0,0x6
ffffffffc0201776:	91e50513          	addi	a0,a0,-1762 # ffffffffc0207090 <commands+0x808>
ffffffffc020177a:	953fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020177e:	777d                	lui	a4,0xfffff
ffffffffc0201780:	000b2797          	auipc	a5,0xb2
ffffffffc0201784:	14b78793          	addi	a5,a5,331 # ffffffffc02b38cb <end+0xfff>
ffffffffc0201788:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc020178a:	00088737          	lui	a4,0x88
ffffffffc020178e:	e098                	sd	a4,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201790:	00fb3023          	sd	a5,0(s6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201794:	4701                	li	a4,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201796:	4585                	li	a1,1
ffffffffc0201798:	fff80837          	lui	a6,0xfff80
ffffffffc020179c:	a019                	j	ffffffffc02017a2 <pmm_init+0xac>
        SetPageReserved(pages + i);
ffffffffc020179e:	000b3783          	ld	a5,0(s6)
ffffffffc02017a2:	00671693          	slli	a3,a4,0x6
ffffffffc02017a6:	97b6                	add	a5,a5,a3
ffffffffc02017a8:	07a1                	addi	a5,a5,8
ffffffffc02017aa:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02017ae:	6090                	ld	a2,0(s1)
ffffffffc02017b0:	0705                	addi	a4,a4,1
ffffffffc02017b2:	010607b3          	add	a5,a2,a6
ffffffffc02017b6:	fef764e3          	bltu	a4,a5,ffffffffc020179e <pmm_init+0xa8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02017ba:	000b3503          	ld	a0,0(s6)
ffffffffc02017be:	079a                	slli	a5,a5,0x6
ffffffffc02017c0:	c0200737          	lui	a4,0xc0200
ffffffffc02017c4:	00f506b3          	add	a3,a0,a5
ffffffffc02017c8:	60e6e563          	bltu	a3,a4,ffffffffc0201dd2 <pmm_init+0x6dc>
ffffffffc02017cc:	0009b583          	ld	a1,0(s3)
    if (freemem < mem_end) {
ffffffffc02017d0:	4745                	li	a4,17
ffffffffc02017d2:	076e                	slli	a4,a4,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02017d4:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end) {
ffffffffc02017d6:	4ae6e563          	bltu	a3,a4,ffffffffc0201c80 <pmm_init+0x58a>
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc02017da:	00006517          	auipc	a0,0x6
ffffffffc02017de:	90650513          	addi	a0,a0,-1786 # ffffffffc02070e0 <commands+0x858>
ffffffffc02017e2:	8ebfe0ef          	jal	ra,ffffffffc02000cc <cprintf>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02017e6:	000bb783          	ld	a5,0(s7)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc02017ea:	000b1917          	auipc	s2,0xb1
ffffffffc02017ee:	06e90913          	addi	s2,s2,110 # ffffffffc02b2858 <boot_pgdir>
    pmm_manager->check();
ffffffffc02017f2:	7b9c                	ld	a5,48(a5)
ffffffffc02017f4:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02017f6:	00006517          	auipc	a0,0x6
ffffffffc02017fa:	90250513          	addi	a0,a0,-1790 # ffffffffc02070f8 <commands+0x870>
ffffffffc02017fe:	8cffe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0201802:	00009697          	auipc	a3,0x9
ffffffffc0201806:	7fe68693          	addi	a3,a3,2046 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc020180a:	00d93023          	sd	a3,0(s2)
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc020180e:	c02007b7          	lui	a5,0xc0200
ffffffffc0201812:	5cf6ec63          	bltu	a3,a5,ffffffffc0201dea <pmm_init+0x6f4>
ffffffffc0201816:	0009b783          	ld	a5,0(s3)
ffffffffc020181a:	8e9d                	sub	a3,a3,a5
ffffffffc020181c:	000b1797          	auipc	a5,0xb1
ffffffffc0201820:	02d7ba23          	sd	a3,52(a5) # ffffffffc02b2850 <boot_cr3>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201824:	100027f3          	csrr	a5,sstatus
ffffffffc0201828:	8b89                	andi	a5,a5,2
ffffffffc020182a:	48079263          	bnez	a5,ffffffffc0201cae <pmm_init+0x5b8>
        ret = pmm_manager->nr_free_pages();
ffffffffc020182e:	000bb783          	ld	a5,0(s7)
ffffffffc0201832:	779c                	ld	a5,40(a5)
ffffffffc0201834:	9782                	jalr	a5
ffffffffc0201836:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201838:	6098                	ld	a4,0(s1)
ffffffffc020183a:	c80007b7          	lui	a5,0xc8000
ffffffffc020183e:	83b1                	srli	a5,a5,0xc
ffffffffc0201840:	5ee7e163          	bltu	a5,a4,ffffffffc0201e22 <pmm_init+0x72c>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0201844:	00093503          	ld	a0,0(s2)
ffffffffc0201848:	5a050d63          	beqz	a0,ffffffffc0201e02 <pmm_init+0x70c>
ffffffffc020184c:	03451793          	slli	a5,a0,0x34
ffffffffc0201850:	5a079963          	bnez	a5,ffffffffc0201e02 <pmm_init+0x70c>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0201854:	4601                	li	a2,0
ffffffffc0201856:	4581                	li	a1,0
ffffffffc0201858:	8e1ff0ef          	jal	ra,ffffffffc0201138 <get_page>
ffffffffc020185c:	62051563          	bnez	a0,ffffffffc0201e86 <pmm_init+0x790>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc0201860:	4505                	li	a0,1
ffffffffc0201862:	df8ff0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc0201866:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0201868:	00093503          	ld	a0,0(s2)
ffffffffc020186c:	4681                	li	a3,0
ffffffffc020186e:	4601                	li	a2,0
ffffffffc0201870:	85d2                	mv	a1,s4
ffffffffc0201872:	d8fff0ef          	jal	ra,ffffffffc0201600 <page_insert>
ffffffffc0201876:	5e051863          	bnez	a0,ffffffffc0201e66 <pmm_init+0x770>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc020187a:	00093503          	ld	a0,0(s2)
ffffffffc020187e:	4601                	li	a2,0
ffffffffc0201880:	4581                	li	a1,0
ffffffffc0201882:	ee4ff0ef          	jal	ra,ffffffffc0200f66 <get_pte>
ffffffffc0201886:	5c050063          	beqz	a0,ffffffffc0201e46 <pmm_init+0x750>
    assert(pte2page(*ptep) == p1);
ffffffffc020188a:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc020188c:	0017f713          	andi	a4,a5,1
ffffffffc0201890:	5a070963          	beqz	a4,ffffffffc0201e42 <pmm_init+0x74c>
    if (PPN(pa) >= npage) {
ffffffffc0201894:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201896:	078a                	slli	a5,a5,0x2
ffffffffc0201898:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020189a:	52e7fa63          	bgeu	a5,a4,ffffffffc0201dce <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc020189e:	000b3683          	ld	a3,0(s6)
ffffffffc02018a2:	fff80637          	lui	a2,0xfff80
ffffffffc02018a6:	97b2                	add	a5,a5,a2
ffffffffc02018a8:	079a                	slli	a5,a5,0x6
ffffffffc02018aa:	97b6                	add	a5,a5,a3
ffffffffc02018ac:	10fa16e3          	bne	s4,a5,ffffffffc02021b8 <pmm_init+0xac2>
    assert(page_ref(p1) == 1);
ffffffffc02018b0:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc02018b4:	4785                	li	a5,1
ffffffffc02018b6:	12f69de3          	bne	a3,a5,ffffffffc02021f0 <pmm_init+0xafa>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc02018ba:	00093503          	ld	a0,0(s2)
ffffffffc02018be:	77fd                	lui	a5,0xfffff
ffffffffc02018c0:	6114                	ld	a3,0(a0)
ffffffffc02018c2:	068a                	slli	a3,a3,0x2
ffffffffc02018c4:	8efd                	and	a3,a3,a5
ffffffffc02018c6:	00c6d613          	srli	a2,a3,0xc
ffffffffc02018ca:	10e677e3          	bgeu	a2,a4,ffffffffc02021d8 <pmm_init+0xae2>
ffffffffc02018ce:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02018d2:	96e2                	add	a3,a3,s8
ffffffffc02018d4:	0006ba83          	ld	s5,0(a3)
ffffffffc02018d8:	0a8a                	slli	s5,s5,0x2
ffffffffc02018da:	00fafab3          	and	s5,s5,a5
ffffffffc02018de:	00cad793          	srli	a5,s5,0xc
ffffffffc02018e2:	62e7f263          	bgeu	a5,a4,ffffffffc0201f06 <pmm_init+0x810>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02018e6:	4601                	li	a2,0
ffffffffc02018e8:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02018ea:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02018ec:	e7aff0ef          	jal	ra,ffffffffc0200f66 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02018f0:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02018f2:	5f551a63          	bne	a0,s5,ffffffffc0201ee6 <pmm_init+0x7f0>

    p2 = alloc_page();
ffffffffc02018f6:	4505                	li	a0,1
ffffffffc02018f8:	d62ff0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc02018fc:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02018fe:	00093503          	ld	a0,0(s2)
ffffffffc0201902:	46d1                	li	a3,20
ffffffffc0201904:	6605                	lui	a2,0x1
ffffffffc0201906:	85d6                	mv	a1,s5
ffffffffc0201908:	cf9ff0ef          	jal	ra,ffffffffc0201600 <page_insert>
ffffffffc020190c:	58051d63          	bnez	a0,ffffffffc0201ea6 <pmm_init+0x7b0>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201910:	00093503          	ld	a0,0(s2)
ffffffffc0201914:	4601                	li	a2,0
ffffffffc0201916:	6585                	lui	a1,0x1
ffffffffc0201918:	e4eff0ef          	jal	ra,ffffffffc0200f66 <get_pte>
ffffffffc020191c:	0e050ae3          	beqz	a0,ffffffffc0202210 <pmm_init+0xb1a>
    assert(*ptep & PTE_U);
ffffffffc0201920:	611c                	ld	a5,0(a0)
ffffffffc0201922:	0107f713          	andi	a4,a5,16
ffffffffc0201926:	6e070d63          	beqz	a4,ffffffffc0202020 <pmm_init+0x92a>
    assert(*ptep & PTE_W);
ffffffffc020192a:	8b91                	andi	a5,a5,4
ffffffffc020192c:	6a078a63          	beqz	a5,ffffffffc0201fe0 <pmm_init+0x8ea>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0201930:	00093503          	ld	a0,0(s2)
ffffffffc0201934:	611c                	ld	a5,0(a0)
ffffffffc0201936:	8bc1                	andi	a5,a5,16
ffffffffc0201938:	68078463          	beqz	a5,ffffffffc0201fc0 <pmm_init+0x8ca>
    assert(page_ref(p2) == 1);
ffffffffc020193c:	000aa703          	lw	a4,0(s5)
ffffffffc0201940:	4785                	li	a5,1
ffffffffc0201942:	58f71263          	bne	a4,a5,ffffffffc0201ec6 <pmm_init+0x7d0>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0201946:	4681                	li	a3,0
ffffffffc0201948:	6605                	lui	a2,0x1
ffffffffc020194a:	85d2                	mv	a1,s4
ffffffffc020194c:	cb5ff0ef          	jal	ra,ffffffffc0201600 <page_insert>
ffffffffc0201950:	62051863          	bnez	a0,ffffffffc0201f80 <pmm_init+0x88a>
    assert(page_ref(p1) == 2);
ffffffffc0201954:	000a2703          	lw	a4,0(s4)
ffffffffc0201958:	4789                	li	a5,2
ffffffffc020195a:	60f71363          	bne	a4,a5,ffffffffc0201f60 <pmm_init+0x86a>
    assert(page_ref(p2) == 0);
ffffffffc020195e:	000aa783          	lw	a5,0(s5)
ffffffffc0201962:	5c079f63          	bnez	a5,ffffffffc0201f40 <pmm_init+0x84a>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201966:	00093503          	ld	a0,0(s2)
ffffffffc020196a:	4601                	li	a2,0
ffffffffc020196c:	6585                	lui	a1,0x1
ffffffffc020196e:	df8ff0ef          	jal	ra,ffffffffc0200f66 <get_pte>
ffffffffc0201972:	5a050763          	beqz	a0,ffffffffc0201f20 <pmm_init+0x82a>
    assert(pte2page(*ptep) == p1);
ffffffffc0201976:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201978:	00177793          	andi	a5,a4,1
ffffffffc020197c:	4c078363          	beqz	a5,ffffffffc0201e42 <pmm_init+0x74c>
    if (PPN(pa) >= npage) {
ffffffffc0201980:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201982:	00271793          	slli	a5,a4,0x2
ffffffffc0201986:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201988:	44d7f363          	bgeu	a5,a3,ffffffffc0201dce <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc020198c:	000b3683          	ld	a3,0(s6)
ffffffffc0201990:	fff80637          	lui	a2,0xfff80
ffffffffc0201994:	97b2                	add	a5,a5,a2
ffffffffc0201996:	079a                	slli	a5,a5,0x6
ffffffffc0201998:	97b6                	add	a5,a5,a3
ffffffffc020199a:	6efa1363          	bne	s4,a5,ffffffffc0202080 <pmm_init+0x98a>
    assert((*ptep & PTE_U) == 0);
ffffffffc020199e:	8b41                	andi	a4,a4,16
ffffffffc02019a0:	6c071063          	bnez	a4,ffffffffc0202060 <pmm_init+0x96a>

    page_remove(boot_pgdir, 0x0);
ffffffffc02019a4:	00093503          	ld	a0,0(s2)
ffffffffc02019a8:	4581                	li	a1,0
ffffffffc02019aa:	bbbff0ef          	jal	ra,ffffffffc0201564 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc02019ae:	000a2703          	lw	a4,0(s4)
ffffffffc02019b2:	4785                	li	a5,1
ffffffffc02019b4:	68f71663          	bne	a4,a5,ffffffffc0202040 <pmm_init+0x94a>
    assert(page_ref(p2) == 0);
ffffffffc02019b8:	000aa783          	lw	a5,0(s5)
ffffffffc02019bc:	74079e63          	bnez	a5,ffffffffc0202118 <pmm_init+0xa22>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc02019c0:	00093503          	ld	a0,0(s2)
ffffffffc02019c4:	6585                	lui	a1,0x1
ffffffffc02019c6:	b9fff0ef          	jal	ra,ffffffffc0201564 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc02019ca:	000a2783          	lw	a5,0(s4)
ffffffffc02019ce:	72079563          	bnez	a5,ffffffffc02020f8 <pmm_init+0xa02>
    assert(page_ref(p2) == 0);
ffffffffc02019d2:	000aa783          	lw	a5,0(s5)
ffffffffc02019d6:	70079163          	bnez	a5,ffffffffc02020d8 <pmm_init+0x9e2>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc02019da:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc02019de:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02019e0:	000a3683          	ld	a3,0(s4)
ffffffffc02019e4:	068a                	slli	a3,a3,0x2
ffffffffc02019e6:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc02019e8:	3ee6f363          	bgeu	a3,a4,ffffffffc0201dce <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc02019ec:	fff807b7          	lui	a5,0xfff80
ffffffffc02019f0:	000b3503          	ld	a0,0(s6)
ffffffffc02019f4:	96be                	add	a3,a3,a5
ffffffffc02019f6:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc02019f8:	00d507b3          	add	a5,a0,a3
ffffffffc02019fc:	4390                	lw	a2,0(a5)
ffffffffc02019fe:	4785                	li	a5,1
ffffffffc0201a00:	6af61c63          	bne	a2,a5,ffffffffc02020b8 <pmm_init+0x9c2>
    return page - pages + nbase;
ffffffffc0201a04:	8699                	srai	a3,a3,0x6
ffffffffc0201a06:	000805b7          	lui	a1,0x80
ffffffffc0201a0a:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0201a0c:	00c69613          	slli	a2,a3,0xc
ffffffffc0201a10:	8231                	srli	a2,a2,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201a12:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201a14:	68e67663          	bgeu	a2,a4,ffffffffc02020a0 <pmm_init+0x9aa>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0201a18:	0009b603          	ld	a2,0(s3)
ffffffffc0201a1c:	96b2                	add	a3,a3,a2
    return pa2page(PDE_ADDR(pde));
ffffffffc0201a1e:	629c                	ld	a5,0(a3)
ffffffffc0201a20:	078a                	slli	a5,a5,0x2
ffffffffc0201a22:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201a24:	3ae7f563          	bgeu	a5,a4,ffffffffc0201dce <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0201a28:	8f8d                	sub	a5,a5,a1
ffffffffc0201a2a:	079a                	slli	a5,a5,0x6
ffffffffc0201a2c:	953e                	add	a0,a0,a5
ffffffffc0201a2e:	100027f3          	csrr	a5,sstatus
ffffffffc0201a32:	8b89                	andi	a5,a5,2
ffffffffc0201a34:	2c079763          	bnez	a5,ffffffffc0201d02 <pmm_init+0x60c>
        pmm_manager->free_pages(base, n);
ffffffffc0201a38:	000bb783          	ld	a5,0(s7)
ffffffffc0201a3c:	4585                	li	a1,1
ffffffffc0201a3e:	739c                	ld	a5,32(a5)
ffffffffc0201a40:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201a42:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc0201a46:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201a48:	078a                	slli	a5,a5,0x2
ffffffffc0201a4a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201a4c:	38e7f163          	bgeu	a5,a4,ffffffffc0201dce <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0201a50:	000b3503          	ld	a0,0(s6)
ffffffffc0201a54:	fff80737          	lui	a4,0xfff80
ffffffffc0201a58:	97ba                	add	a5,a5,a4
ffffffffc0201a5a:	079a                	slli	a5,a5,0x6
ffffffffc0201a5c:	953e                	add	a0,a0,a5
ffffffffc0201a5e:	100027f3          	csrr	a5,sstatus
ffffffffc0201a62:	8b89                	andi	a5,a5,2
ffffffffc0201a64:	28079363          	bnez	a5,ffffffffc0201cea <pmm_init+0x5f4>
ffffffffc0201a68:	000bb783          	ld	a5,0(s7)
ffffffffc0201a6c:	4585                	li	a1,1
ffffffffc0201a6e:	739c                	ld	a5,32(a5)
ffffffffc0201a70:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0201a72:	00093783          	ld	a5,0(s2)
ffffffffc0201a76:	0007b023          	sd	zero,0(a5) # fffffffffff80000 <end+0x3fccd734>
  asm volatile("sfence.vma");
ffffffffc0201a7a:	12000073          	sfence.vma
ffffffffc0201a7e:	100027f3          	csrr	a5,sstatus
ffffffffc0201a82:	8b89                	andi	a5,a5,2
ffffffffc0201a84:	24079963          	bnez	a5,ffffffffc0201cd6 <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201a88:	000bb783          	ld	a5,0(s7)
ffffffffc0201a8c:	779c                	ld	a5,40(a5)
ffffffffc0201a8e:	9782                	jalr	a5
ffffffffc0201a90:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0201a92:	71441363          	bne	s0,s4,ffffffffc0202198 <pmm_init+0xaa2>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0201a96:	00006517          	auipc	a0,0x6
ffffffffc0201a9a:	94a50513          	addi	a0,a0,-1718 # ffffffffc02073e0 <commands+0xb58>
ffffffffc0201a9e:	e2efe0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0201aa2:	100027f3          	csrr	a5,sstatus
ffffffffc0201aa6:	8b89                	andi	a5,a5,2
ffffffffc0201aa8:	20079d63          	bnez	a5,ffffffffc0201cc2 <pmm_init+0x5cc>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201aac:	000bb783          	ld	a5,0(s7)
ffffffffc0201ab0:	779c                	ld	a5,40(a5)
ffffffffc0201ab2:	9782                	jalr	a5
ffffffffc0201ab4:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201ab6:	6098                	ld	a4,0(s1)
ffffffffc0201ab8:	c0200437          	lui	s0,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201abc:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201abe:	00c71793          	slli	a5,a4,0xc
ffffffffc0201ac2:	6a05                	lui	s4,0x1
ffffffffc0201ac4:	02f47c63          	bgeu	s0,a5,ffffffffc0201afc <pmm_init+0x406>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201ac8:	00c45793          	srli	a5,s0,0xc
ffffffffc0201acc:	00093503          	ld	a0,0(s2)
ffffffffc0201ad0:	2ee7f263          	bgeu	a5,a4,ffffffffc0201db4 <pmm_init+0x6be>
ffffffffc0201ad4:	0009b583          	ld	a1,0(s3)
ffffffffc0201ad8:	4601                	li	a2,0
ffffffffc0201ada:	95a2                	add	a1,a1,s0
ffffffffc0201adc:	c8aff0ef          	jal	ra,ffffffffc0200f66 <get_pte>
ffffffffc0201ae0:	2a050a63          	beqz	a0,ffffffffc0201d94 <pmm_init+0x69e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201ae4:	611c                	ld	a5,0(a0)
ffffffffc0201ae6:	078a                	slli	a5,a5,0x2
ffffffffc0201ae8:	0157f7b3          	and	a5,a5,s5
ffffffffc0201aec:	28879463          	bne	a5,s0,ffffffffc0201d74 <pmm_init+0x67e>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201af0:	6098                	ld	a4,0(s1)
ffffffffc0201af2:	9452                	add	s0,s0,s4
ffffffffc0201af4:	00c71793          	slli	a5,a4,0xc
ffffffffc0201af8:	fcf468e3          	bltu	s0,a5,ffffffffc0201ac8 <pmm_init+0x3d2>
    }


    assert(boot_pgdir[0] == 0);
ffffffffc0201afc:	00093783          	ld	a5,0(s2)
ffffffffc0201b00:	639c                	ld	a5,0(a5)
ffffffffc0201b02:	66079b63          	bnez	a5,ffffffffc0202178 <pmm_init+0xa82>

    struct Page *p;
    p = alloc_page();
ffffffffc0201b06:	4505                	li	a0,1
ffffffffc0201b08:	b52ff0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc0201b0c:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201b0e:	00093503          	ld	a0,0(s2)
ffffffffc0201b12:	4699                	li	a3,6
ffffffffc0201b14:	10000613          	li	a2,256
ffffffffc0201b18:	85d6                	mv	a1,s5
ffffffffc0201b1a:	ae7ff0ef          	jal	ra,ffffffffc0201600 <page_insert>
ffffffffc0201b1e:	62051d63          	bnez	a0,ffffffffc0202158 <pmm_init+0xa62>
    assert(page_ref(p) == 1);
ffffffffc0201b22:	000aa703          	lw	a4,0(s5) # fffffffffffff000 <end+0x3fd4c734>
ffffffffc0201b26:	4785                	li	a5,1
ffffffffc0201b28:	60f71863          	bne	a4,a5,ffffffffc0202138 <pmm_init+0xa42>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0201b2c:	00093503          	ld	a0,0(s2)
ffffffffc0201b30:	6405                	lui	s0,0x1
ffffffffc0201b32:	4699                	li	a3,6
ffffffffc0201b34:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8ab8>
ffffffffc0201b38:	85d6                	mv	a1,s5
ffffffffc0201b3a:	ac7ff0ef          	jal	ra,ffffffffc0201600 <page_insert>
ffffffffc0201b3e:	46051163          	bnez	a0,ffffffffc0201fa0 <pmm_init+0x8aa>
    assert(page_ref(p) == 2);
ffffffffc0201b42:	000aa703          	lw	a4,0(s5)
ffffffffc0201b46:	4789                	li	a5,2
ffffffffc0201b48:	72f71463          	bne	a4,a5,ffffffffc0202270 <pmm_init+0xb7a>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0201b4c:	00006597          	auipc	a1,0x6
ffffffffc0201b50:	9cc58593          	addi	a1,a1,-1588 # ffffffffc0207518 <commands+0xc90>
ffffffffc0201b54:	10000513          	li	a0,256
ffffffffc0201b58:	610040ef          	jal	ra,ffffffffc0206168 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0201b5c:	10040593          	addi	a1,s0,256
ffffffffc0201b60:	10000513          	li	a0,256
ffffffffc0201b64:	616040ef          	jal	ra,ffffffffc020617a <strcmp>
ffffffffc0201b68:	6e051463          	bnez	a0,ffffffffc0202250 <pmm_init+0xb5a>
    return page - pages + nbase;
ffffffffc0201b6c:	000b3683          	ld	a3,0(s6)
ffffffffc0201b70:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0201b74:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0201b76:	40da86b3          	sub	a3,s5,a3
ffffffffc0201b7a:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0201b7c:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0201b7e:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0201b80:	8031                	srli	s0,s0,0xc
ffffffffc0201b82:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b86:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201b88:	50f77c63          	bgeu	a4,a5,ffffffffc02020a0 <pmm_init+0x9aa>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0201b8c:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201b90:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0201b94:	96be                	add	a3,a3,a5
ffffffffc0201b96:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201b9a:	598040ef          	jal	ra,ffffffffc0206132 <strlen>
ffffffffc0201b9e:	68051963          	bnez	a0,ffffffffc0202230 <pmm_init+0xb3a>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0201ba2:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0201ba6:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201ba8:	000a3683          	ld	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc0201bac:	068a                	slli	a3,a3,0x2
ffffffffc0201bae:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201bb0:	20f6ff63          	bgeu	a3,a5,ffffffffc0201dce <pmm_init+0x6d8>
    return KADDR(page2pa(page));
ffffffffc0201bb4:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0201bb6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201bb8:	4ef47463          	bgeu	s0,a5,ffffffffc02020a0 <pmm_init+0x9aa>
ffffffffc0201bbc:	0009b403          	ld	s0,0(s3)
ffffffffc0201bc0:	9436                	add	s0,s0,a3
ffffffffc0201bc2:	100027f3          	csrr	a5,sstatus
ffffffffc0201bc6:	8b89                	andi	a5,a5,2
ffffffffc0201bc8:	18079b63          	bnez	a5,ffffffffc0201d5e <pmm_init+0x668>
        pmm_manager->free_pages(base, n);
ffffffffc0201bcc:	000bb783          	ld	a5,0(s7)
ffffffffc0201bd0:	4585                	li	a1,1
ffffffffc0201bd2:	8556                	mv	a0,s5
ffffffffc0201bd4:	739c                	ld	a5,32(a5)
ffffffffc0201bd6:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201bd8:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0201bda:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201bdc:	078a                	slli	a5,a5,0x2
ffffffffc0201bde:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201be0:	1ee7f763          	bgeu	a5,a4,ffffffffc0201dce <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0201be4:	000b3503          	ld	a0,0(s6)
ffffffffc0201be8:	fff80737          	lui	a4,0xfff80
ffffffffc0201bec:	97ba                	add	a5,a5,a4
ffffffffc0201bee:	079a                	slli	a5,a5,0x6
ffffffffc0201bf0:	953e                	add	a0,a0,a5
ffffffffc0201bf2:	100027f3          	csrr	a5,sstatus
ffffffffc0201bf6:	8b89                	andi	a5,a5,2
ffffffffc0201bf8:	14079763          	bnez	a5,ffffffffc0201d46 <pmm_init+0x650>
ffffffffc0201bfc:	000bb783          	ld	a5,0(s7)
ffffffffc0201c00:	4585                	li	a1,1
ffffffffc0201c02:	739c                	ld	a5,32(a5)
ffffffffc0201c04:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201c06:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc0201c0a:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201c0c:	078a                	slli	a5,a5,0x2
ffffffffc0201c0e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201c10:	1ae7ff63          	bgeu	a5,a4,ffffffffc0201dce <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0201c14:	000b3503          	ld	a0,0(s6)
ffffffffc0201c18:	fff80737          	lui	a4,0xfff80
ffffffffc0201c1c:	97ba                	add	a5,a5,a4
ffffffffc0201c1e:	079a                	slli	a5,a5,0x6
ffffffffc0201c20:	953e                	add	a0,a0,a5
ffffffffc0201c22:	100027f3          	csrr	a5,sstatus
ffffffffc0201c26:	8b89                	andi	a5,a5,2
ffffffffc0201c28:	10079363          	bnez	a5,ffffffffc0201d2e <pmm_init+0x638>
ffffffffc0201c2c:	000bb783          	ld	a5,0(s7)
ffffffffc0201c30:	4585                	li	a1,1
ffffffffc0201c32:	739c                	ld	a5,32(a5)
ffffffffc0201c34:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0201c36:	00093783          	ld	a5,0(s2)
ffffffffc0201c3a:	0007b023          	sd	zero,0(a5)
  asm volatile("sfence.vma");
ffffffffc0201c3e:	12000073          	sfence.vma
ffffffffc0201c42:	100027f3          	csrr	a5,sstatus
ffffffffc0201c46:	8b89                	andi	a5,a5,2
ffffffffc0201c48:	0c079963          	bnez	a5,ffffffffc0201d1a <pmm_init+0x624>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201c4c:	000bb783          	ld	a5,0(s7)
ffffffffc0201c50:	779c                	ld	a5,40(a5)
ffffffffc0201c52:	9782                	jalr	a5
ffffffffc0201c54:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0201c56:	3a8c1563          	bne	s8,s0,ffffffffc0202000 <pmm_init+0x90a>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0201c5a:	00006517          	auipc	a0,0x6
ffffffffc0201c5e:	93650513          	addi	a0,a0,-1738 # ffffffffc0207590 <commands+0xd08>
ffffffffc0201c62:	c6afe0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc0201c66:	6446                	ld	s0,80(sp)
ffffffffc0201c68:	60e6                	ld	ra,88(sp)
ffffffffc0201c6a:	64a6                	ld	s1,72(sp)
ffffffffc0201c6c:	6906                	ld	s2,64(sp)
ffffffffc0201c6e:	79e2                	ld	s3,56(sp)
ffffffffc0201c70:	7a42                	ld	s4,48(sp)
ffffffffc0201c72:	7aa2                	ld	s5,40(sp)
ffffffffc0201c74:	7b02                	ld	s6,32(sp)
ffffffffc0201c76:	6be2                	ld	s7,24(sp)
ffffffffc0201c78:	6c42                	ld	s8,16(sp)
ffffffffc0201c7a:	6125                	addi	sp,sp,96
    kmalloc_init();
ffffffffc0201c7c:	1890106f          	j	ffffffffc0203604 <kmalloc_init>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201c80:	6785                	lui	a5,0x1
ffffffffc0201c82:	17fd                	addi	a5,a5,-1
ffffffffc0201c84:	96be                	add	a3,a3,a5
ffffffffc0201c86:	77fd                	lui	a5,0xfffff
ffffffffc0201c88:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage) {
ffffffffc0201c8a:	00c7d693          	srli	a3,a5,0xc
ffffffffc0201c8e:	14c6f063          	bgeu	a3,a2,ffffffffc0201dce <pmm_init+0x6d8>
    pmm_manager->init_memmap(base, n);
ffffffffc0201c92:	000bb603          	ld	a2,0(s7)
    return &pages[PPN(pa) - nbase];
ffffffffc0201c96:	96c2                	add	a3,a3,a6
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201c98:	40f707b3          	sub	a5,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0201c9c:	6a10                	ld	a2,16(a2)
ffffffffc0201c9e:	069a                	slli	a3,a3,0x6
ffffffffc0201ca0:	00c7d593          	srli	a1,a5,0xc
ffffffffc0201ca4:	9536                	add	a0,a0,a3
ffffffffc0201ca6:	9602                	jalr	a2
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0201ca8:	0009b583          	ld	a1,0(s3)
}
ffffffffc0201cac:	b63d                	j	ffffffffc02017da <pmm_init+0xe4>
        intr_disable();
ffffffffc0201cae:	99bfe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201cb2:	000bb783          	ld	a5,0(s7)
ffffffffc0201cb6:	779c                	ld	a5,40(a5)
ffffffffc0201cb8:	9782                	jalr	a5
ffffffffc0201cba:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201cbc:	987fe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0201cc0:	bea5                	j	ffffffffc0201838 <pmm_init+0x142>
        intr_disable();
ffffffffc0201cc2:	987fe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc0201cc6:	000bb783          	ld	a5,0(s7)
ffffffffc0201cca:	779c                	ld	a5,40(a5)
ffffffffc0201ccc:	9782                	jalr	a5
ffffffffc0201cce:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0201cd0:	973fe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0201cd4:	b3cd                	j	ffffffffc0201ab6 <pmm_init+0x3c0>
        intr_disable();
ffffffffc0201cd6:	973fe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc0201cda:	000bb783          	ld	a5,0(s7)
ffffffffc0201cde:	779c                	ld	a5,40(a5)
ffffffffc0201ce0:	9782                	jalr	a5
ffffffffc0201ce2:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0201ce4:	95ffe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0201ce8:	b36d                	j	ffffffffc0201a92 <pmm_init+0x39c>
ffffffffc0201cea:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201cec:	95dfe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201cf0:	000bb783          	ld	a5,0(s7)
ffffffffc0201cf4:	6522                	ld	a0,8(sp)
ffffffffc0201cf6:	4585                	li	a1,1
ffffffffc0201cf8:	739c                	ld	a5,32(a5)
ffffffffc0201cfa:	9782                	jalr	a5
        intr_enable();
ffffffffc0201cfc:	947fe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0201d00:	bb8d                	j	ffffffffc0201a72 <pmm_init+0x37c>
ffffffffc0201d02:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201d04:	945fe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc0201d08:	000bb783          	ld	a5,0(s7)
ffffffffc0201d0c:	6522                	ld	a0,8(sp)
ffffffffc0201d0e:	4585                	li	a1,1
ffffffffc0201d10:	739c                	ld	a5,32(a5)
ffffffffc0201d12:	9782                	jalr	a5
        intr_enable();
ffffffffc0201d14:	92ffe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0201d18:	b32d                	j	ffffffffc0201a42 <pmm_init+0x34c>
        intr_disable();
ffffffffc0201d1a:	92ffe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201d1e:	000bb783          	ld	a5,0(s7)
ffffffffc0201d22:	779c                	ld	a5,40(a5)
ffffffffc0201d24:	9782                	jalr	a5
ffffffffc0201d26:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201d28:	91bfe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0201d2c:	b72d                	j	ffffffffc0201c56 <pmm_init+0x560>
ffffffffc0201d2e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201d30:	919fe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201d34:	000bb783          	ld	a5,0(s7)
ffffffffc0201d38:	6522                	ld	a0,8(sp)
ffffffffc0201d3a:	4585                	li	a1,1
ffffffffc0201d3c:	739c                	ld	a5,32(a5)
ffffffffc0201d3e:	9782                	jalr	a5
        intr_enable();
ffffffffc0201d40:	903fe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0201d44:	bdcd                	j	ffffffffc0201c36 <pmm_init+0x540>
ffffffffc0201d46:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201d48:	901fe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc0201d4c:	000bb783          	ld	a5,0(s7)
ffffffffc0201d50:	6522                	ld	a0,8(sp)
ffffffffc0201d52:	4585                	li	a1,1
ffffffffc0201d54:	739c                	ld	a5,32(a5)
ffffffffc0201d56:	9782                	jalr	a5
        intr_enable();
ffffffffc0201d58:	8ebfe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0201d5c:	b56d                	j	ffffffffc0201c06 <pmm_init+0x510>
        intr_disable();
ffffffffc0201d5e:	8ebfe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc0201d62:	000bb783          	ld	a5,0(s7)
ffffffffc0201d66:	4585                	li	a1,1
ffffffffc0201d68:	8556                	mv	a0,s5
ffffffffc0201d6a:	739c                	ld	a5,32(a5)
ffffffffc0201d6c:	9782                	jalr	a5
        intr_enable();
ffffffffc0201d6e:	8d5fe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0201d72:	b59d                	j	ffffffffc0201bd8 <pmm_init+0x4e2>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201d74:	00005697          	auipc	a3,0x5
ffffffffc0201d78:	6cc68693          	addi	a3,a3,1740 # ffffffffc0207440 <commands+0xbb8>
ffffffffc0201d7c:	00005617          	auipc	a2,0x5
ffffffffc0201d80:	f1c60613          	addi	a2,a2,-228 # ffffffffc0206c98 <commands+0x410>
ffffffffc0201d84:	23000593          	li	a1,560
ffffffffc0201d88:	00005517          	auipc	a0,0x5
ffffffffc0201d8c:	28050513          	addi	a0,a0,640 # ffffffffc0207008 <commands+0x780>
ffffffffc0201d90:	c78fe0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201d94:	00005697          	auipc	a3,0x5
ffffffffc0201d98:	66c68693          	addi	a3,a3,1644 # ffffffffc0207400 <commands+0xb78>
ffffffffc0201d9c:	00005617          	auipc	a2,0x5
ffffffffc0201da0:	efc60613          	addi	a2,a2,-260 # ffffffffc0206c98 <commands+0x410>
ffffffffc0201da4:	22f00593          	li	a1,559
ffffffffc0201da8:	00005517          	auipc	a0,0x5
ffffffffc0201dac:	26050513          	addi	a0,a0,608 # ffffffffc0207008 <commands+0x780>
ffffffffc0201db0:	c58fe0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0201db4:	86a2                	mv	a3,s0
ffffffffc0201db6:	00005617          	auipc	a2,0x5
ffffffffc0201dba:	22a60613          	addi	a2,a2,554 # ffffffffc0206fe0 <commands+0x758>
ffffffffc0201dbe:	22f00593          	li	a1,559
ffffffffc0201dc2:	00005517          	auipc	a0,0x5
ffffffffc0201dc6:	24650513          	addi	a0,a0,582 # ffffffffc0207008 <commands+0x780>
ffffffffc0201dca:	c3efe0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0201dce:	854ff0ef          	jal	ra,ffffffffc0200e22 <pa2page.part.0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201dd2:	00005617          	auipc	a2,0x5
ffffffffc0201dd6:	2e660613          	addi	a2,a2,742 # ffffffffc02070b8 <commands+0x830>
ffffffffc0201dda:	07f00593          	li	a1,127
ffffffffc0201dde:	00005517          	auipc	a0,0x5
ffffffffc0201de2:	22a50513          	addi	a0,a0,554 # ffffffffc0207008 <commands+0x780>
ffffffffc0201de6:	c22fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0201dea:	00005617          	auipc	a2,0x5
ffffffffc0201dee:	2ce60613          	addi	a2,a2,718 # ffffffffc02070b8 <commands+0x830>
ffffffffc0201df2:	0c100593          	li	a1,193
ffffffffc0201df6:	00005517          	auipc	a0,0x5
ffffffffc0201dfa:	21250513          	addi	a0,a0,530 # ffffffffc0207008 <commands+0x780>
ffffffffc0201dfe:	c0afe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0201e02:	00005697          	auipc	a3,0x5
ffffffffc0201e06:	33668693          	addi	a3,a3,822 # ffffffffc0207138 <commands+0x8b0>
ffffffffc0201e0a:	00005617          	auipc	a2,0x5
ffffffffc0201e0e:	e8e60613          	addi	a2,a2,-370 # ffffffffc0206c98 <commands+0x410>
ffffffffc0201e12:	1f300593          	li	a1,499
ffffffffc0201e16:	00005517          	auipc	a0,0x5
ffffffffc0201e1a:	1f250513          	addi	a0,a0,498 # ffffffffc0207008 <commands+0x780>
ffffffffc0201e1e:	beafe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201e22:	00005697          	auipc	a3,0x5
ffffffffc0201e26:	2f668693          	addi	a3,a3,758 # ffffffffc0207118 <commands+0x890>
ffffffffc0201e2a:	00005617          	auipc	a2,0x5
ffffffffc0201e2e:	e6e60613          	addi	a2,a2,-402 # ffffffffc0206c98 <commands+0x410>
ffffffffc0201e32:	1f200593          	li	a1,498
ffffffffc0201e36:	00005517          	auipc	a0,0x5
ffffffffc0201e3a:	1d250513          	addi	a0,a0,466 # ffffffffc0207008 <commands+0x780>
ffffffffc0201e3e:	bcafe0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0201e42:	ffdfe0ef          	jal	ra,ffffffffc0200e3e <pte2page.part.0>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0201e46:	00005697          	auipc	a3,0x5
ffffffffc0201e4a:	38268693          	addi	a3,a3,898 # ffffffffc02071c8 <commands+0x940>
ffffffffc0201e4e:	00005617          	auipc	a2,0x5
ffffffffc0201e52:	e4a60613          	addi	a2,a2,-438 # ffffffffc0206c98 <commands+0x410>
ffffffffc0201e56:	1fb00593          	li	a1,507
ffffffffc0201e5a:	00005517          	auipc	a0,0x5
ffffffffc0201e5e:	1ae50513          	addi	a0,a0,430 # ffffffffc0207008 <commands+0x780>
ffffffffc0201e62:	ba6fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0201e66:	00005697          	auipc	a3,0x5
ffffffffc0201e6a:	33268693          	addi	a3,a3,818 # ffffffffc0207198 <commands+0x910>
ffffffffc0201e6e:	00005617          	auipc	a2,0x5
ffffffffc0201e72:	e2a60613          	addi	a2,a2,-470 # ffffffffc0206c98 <commands+0x410>
ffffffffc0201e76:	1f800593          	li	a1,504
ffffffffc0201e7a:	00005517          	auipc	a0,0x5
ffffffffc0201e7e:	18e50513          	addi	a0,a0,398 # ffffffffc0207008 <commands+0x780>
ffffffffc0201e82:	b86fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0201e86:	00005697          	auipc	a3,0x5
ffffffffc0201e8a:	2ea68693          	addi	a3,a3,746 # ffffffffc0207170 <commands+0x8e8>
ffffffffc0201e8e:	00005617          	auipc	a2,0x5
ffffffffc0201e92:	e0a60613          	addi	a2,a2,-502 # ffffffffc0206c98 <commands+0x410>
ffffffffc0201e96:	1f400593          	li	a1,500
ffffffffc0201e9a:	00005517          	auipc	a0,0x5
ffffffffc0201e9e:	16e50513          	addi	a0,a0,366 # ffffffffc0207008 <commands+0x780>
ffffffffc0201ea2:	b66fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201ea6:	00005697          	auipc	a3,0x5
ffffffffc0201eaa:	3aa68693          	addi	a3,a3,938 # ffffffffc0207250 <commands+0x9c8>
ffffffffc0201eae:	00005617          	auipc	a2,0x5
ffffffffc0201eb2:	dea60613          	addi	a2,a2,-534 # ffffffffc0206c98 <commands+0x410>
ffffffffc0201eb6:	20400593          	li	a1,516
ffffffffc0201eba:	00005517          	auipc	a0,0x5
ffffffffc0201ebe:	14e50513          	addi	a0,a0,334 # ffffffffc0207008 <commands+0x780>
ffffffffc0201ec2:	b46fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0201ec6:	00005697          	auipc	a3,0x5
ffffffffc0201eca:	42a68693          	addi	a3,a3,1066 # ffffffffc02072f0 <commands+0xa68>
ffffffffc0201ece:	00005617          	auipc	a2,0x5
ffffffffc0201ed2:	dca60613          	addi	a2,a2,-566 # ffffffffc0206c98 <commands+0x410>
ffffffffc0201ed6:	20900593          	li	a1,521
ffffffffc0201eda:	00005517          	auipc	a0,0x5
ffffffffc0201ede:	12e50513          	addi	a0,a0,302 # ffffffffc0207008 <commands+0x780>
ffffffffc0201ee2:	b26fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201ee6:	00005697          	auipc	a3,0x5
ffffffffc0201eea:	34268693          	addi	a3,a3,834 # ffffffffc0207228 <commands+0x9a0>
ffffffffc0201eee:	00005617          	auipc	a2,0x5
ffffffffc0201ef2:	daa60613          	addi	a2,a2,-598 # ffffffffc0206c98 <commands+0x410>
ffffffffc0201ef6:	20100593          	li	a1,513
ffffffffc0201efa:	00005517          	auipc	a0,0x5
ffffffffc0201efe:	10e50513          	addi	a0,a0,270 # ffffffffc0207008 <commands+0x780>
ffffffffc0201f02:	b06fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201f06:	86d6                	mv	a3,s5
ffffffffc0201f08:	00005617          	auipc	a2,0x5
ffffffffc0201f0c:	0d860613          	addi	a2,a2,216 # ffffffffc0206fe0 <commands+0x758>
ffffffffc0201f10:	20000593          	li	a1,512
ffffffffc0201f14:	00005517          	auipc	a0,0x5
ffffffffc0201f18:	0f450513          	addi	a0,a0,244 # ffffffffc0207008 <commands+0x780>
ffffffffc0201f1c:	aecfe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201f20:	00005697          	auipc	a3,0x5
ffffffffc0201f24:	36868693          	addi	a3,a3,872 # ffffffffc0207288 <commands+0xa00>
ffffffffc0201f28:	00005617          	auipc	a2,0x5
ffffffffc0201f2c:	d7060613          	addi	a2,a2,-656 # ffffffffc0206c98 <commands+0x410>
ffffffffc0201f30:	20e00593          	li	a1,526
ffffffffc0201f34:	00005517          	auipc	a0,0x5
ffffffffc0201f38:	0d450513          	addi	a0,a0,212 # ffffffffc0207008 <commands+0x780>
ffffffffc0201f3c:	accfe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201f40:	00005697          	auipc	a3,0x5
ffffffffc0201f44:	41068693          	addi	a3,a3,1040 # ffffffffc0207350 <commands+0xac8>
ffffffffc0201f48:	00005617          	auipc	a2,0x5
ffffffffc0201f4c:	d5060613          	addi	a2,a2,-688 # ffffffffc0206c98 <commands+0x410>
ffffffffc0201f50:	20d00593          	li	a1,525
ffffffffc0201f54:	00005517          	auipc	a0,0x5
ffffffffc0201f58:	0b450513          	addi	a0,a0,180 # ffffffffc0207008 <commands+0x780>
ffffffffc0201f5c:	aacfe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0201f60:	00005697          	auipc	a3,0x5
ffffffffc0201f64:	3d868693          	addi	a3,a3,984 # ffffffffc0207338 <commands+0xab0>
ffffffffc0201f68:	00005617          	auipc	a2,0x5
ffffffffc0201f6c:	d3060613          	addi	a2,a2,-720 # ffffffffc0206c98 <commands+0x410>
ffffffffc0201f70:	20c00593          	li	a1,524
ffffffffc0201f74:	00005517          	auipc	a0,0x5
ffffffffc0201f78:	09450513          	addi	a0,a0,148 # ffffffffc0207008 <commands+0x780>
ffffffffc0201f7c:	a8cfe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0201f80:	00005697          	auipc	a3,0x5
ffffffffc0201f84:	38868693          	addi	a3,a3,904 # ffffffffc0207308 <commands+0xa80>
ffffffffc0201f88:	00005617          	auipc	a2,0x5
ffffffffc0201f8c:	d1060613          	addi	a2,a2,-752 # ffffffffc0206c98 <commands+0x410>
ffffffffc0201f90:	20b00593          	li	a1,523
ffffffffc0201f94:	00005517          	auipc	a0,0x5
ffffffffc0201f98:	07450513          	addi	a0,a0,116 # ffffffffc0207008 <commands+0x780>
ffffffffc0201f9c:	a6cfe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0201fa0:	00005697          	auipc	a3,0x5
ffffffffc0201fa4:	52068693          	addi	a3,a3,1312 # ffffffffc02074c0 <commands+0xc38>
ffffffffc0201fa8:	00005617          	auipc	a2,0x5
ffffffffc0201fac:	cf060613          	addi	a2,a2,-784 # ffffffffc0206c98 <commands+0x410>
ffffffffc0201fb0:	23a00593          	li	a1,570
ffffffffc0201fb4:	00005517          	auipc	a0,0x5
ffffffffc0201fb8:	05450513          	addi	a0,a0,84 # ffffffffc0207008 <commands+0x780>
ffffffffc0201fbc:	a4cfe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0201fc0:	00005697          	auipc	a3,0x5
ffffffffc0201fc4:	31868693          	addi	a3,a3,792 # ffffffffc02072d8 <commands+0xa50>
ffffffffc0201fc8:	00005617          	auipc	a2,0x5
ffffffffc0201fcc:	cd060613          	addi	a2,a2,-816 # ffffffffc0206c98 <commands+0x410>
ffffffffc0201fd0:	20800593          	li	a1,520
ffffffffc0201fd4:	00005517          	auipc	a0,0x5
ffffffffc0201fd8:	03450513          	addi	a0,a0,52 # ffffffffc0207008 <commands+0x780>
ffffffffc0201fdc:	a2cfe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0201fe0:	00005697          	auipc	a3,0x5
ffffffffc0201fe4:	2e868693          	addi	a3,a3,744 # ffffffffc02072c8 <commands+0xa40>
ffffffffc0201fe8:	00005617          	auipc	a2,0x5
ffffffffc0201fec:	cb060613          	addi	a2,a2,-848 # ffffffffc0206c98 <commands+0x410>
ffffffffc0201ff0:	20700593          	li	a1,519
ffffffffc0201ff4:	00005517          	auipc	a0,0x5
ffffffffc0201ff8:	01450513          	addi	a0,a0,20 # ffffffffc0207008 <commands+0x780>
ffffffffc0201ffc:	a0cfe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0202000:	00005697          	auipc	a3,0x5
ffffffffc0202004:	3c068693          	addi	a3,a3,960 # ffffffffc02073c0 <commands+0xb38>
ffffffffc0202008:	00005617          	auipc	a2,0x5
ffffffffc020200c:	c9060613          	addi	a2,a2,-880 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202010:	24b00593          	li	a1,587
ffffffffc0202014:	00005517          	auipc	a0,0x5
ffffffffc0202018:	ff450513          	addi	a0,a0,-12 # ffffffffc0207008 <commands+0x780>
ffffffffc020201c:	9ecfe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202020:	00005697          	auipc	a3,0x5
ffffffffc0202024:	29868693          	addi	a3,a3,664 # ffffffffc02072b8 <commands+0xa30>
ffffffffc0202028:	00005617          	auipc	a2,0x5
ffffffffc020202c:	c7060613          	addi	a2,a2,-912 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202030:	20600593          	li	a1,518
ffffffffc0202034:	00005517          	auipc	a0,0x5
ffffffffc0202038:	fd450513          	addi	a0,a0,-44 # ffffffffc0207008 <commands+0x780>
ffffffffc020203c:	9ccfe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202040:	00005697          	auipc	a3,0x5
ffffffffc0202044:	1d068693          	addi	a3,a3,464 # ffffffffc0207210 <commands+0x988>
ffffffffc0202048:	00005617          	auipc	a2,0x5
ffffffffc020204c:	c5060613          	addi	a2,a2,-944 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202050:	21300593          	li	a1,531
ffffffffc0202054:	00005517          	auipc	a0,0x5
ffffffffc0202058:	fb450513          	addi	a0,a0,-76 # ffffffffc0207008 <commands+0x780>
ffffffffc020205c:	9acfe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202060:	00005697          	auipc	a3,0x5
ffffffffc0202064:	30868693          	addi	a3,a3,776 # ffffffffc0207368 <commands+0xae0>
ffffffffc0202068:	00005617          	auipc	a2,0x5
ffffffffc020206c:	c3060613          	addi	a2,a2,-976 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202070:	21000593          	li	a1,528
ffffffffc0202074:	00005517          	auipc	a0,0x5
ffffffffc0202078:	f9450513          	addi	a0,a0,-108 # ffffffffc0207008 <commands+0x780>
ffffffffc020207c:	98cfe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202080:	00005697          	auipc	a3,0x5
ffffffffc0202084:	17868693          	addi	a3,a3,376 # ffffffffc02071f8 <commands+0x970>
ffffffffc0202088:	00005617          	auipc	a2,0x5
ffffffffc020208c:	c1060613          	addi	a2,a2,-1008 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202090:	20f00593          	li	a1,527
ffffffffc0202094:	00005517          	auipc	a0,0x5
ffffffffc0202098:	f7450513          	addi	a0,a0,-140 # ffffffffc0207008 <commands+0x780>
ffffffffc020209c:	96cfe0ef          	jal	ra,ffffffffc0200208 <__panic>
    return KADDR(page2pa(page));
ffffffffc02020a0:	00005617          	auipc	a2,0x5
ffffffffc02020a4:	f4060613          	addi	a2,a2,-192 # ffffffffc0206fe0 <commands+0x758>
ffffffffc02020a8:	06900593          	li	a1,105
ffffffffc02020ac:	00005517          	auipc	a0,0x5
ffffffffc02020b0:	efc50513          	addi	a0,a0,-260 # ffffffffc0206fa8 <commands+0x720>
ffffffffc02020b4:	954fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc02020b8:	00005697          	auipc	a3,0x5
ffffffffc02020bc:	2e068693          	addi	a3,a3,736 # ffffffffc0207398 <commands+0xb10>
ffffffffc02020c0:	00005617          	auipc	a2,0x5
ffffffffc02020c4:	bd860613          	addi	a2,a2,-1064 # ffffffffc0206c98 <commands+0x410>
ffffffffc02020c8:	21a00593          	li	a1,538
ffffffffc02020cc:	00005517          	auipc	a0,0x5
ffffffffc02020d0:	f3c50513          	addi	a0,a0,-196 # ffffffffc0207008 <commands+0x780>
ffffffffc02020d4:	934fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02020d8:	00005697          	auipc	a3,0x5
ffffffffc02020dc:	27868693          	addi	a3,a3,632 # ffffffffc0207350 <commands+0xac8>
ffffffffc02020e0:	00005617          	auipc	a2,0x5
ffffffffc02020e4:	bb860613          	addi	a2,a2,-1096 # ffffffffc0206c98 <commands+0x410>
ffffffffc02020e8:	21800593          	li	a1,536
ffffffffc02020ec:	00005517          	auipc	a0,0x5
ffffffffc02020f0:	f1c50513          	addi	a0,a0,-228 # ffffffffc0207008 <commands+0x780>
ffffffffc02020f4:	914fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc02020f8:	00005697          	auipc	a3,0x5
ffffffffc02020fc:	28868693          	addi	a3,a3,648 # ffffffffc0207380 <commands+0xaf8>
ffffffffc0202100:	00005617          	auipc	a2,0x5
ffffffffc0202104:	b9860613          	addi	a2,a2,-1128 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202108:	21700593          	li	a1,535
ffffffffc020210c:	00005517          	auipc	a0,0x5
ffffffffc0202110:	efc50513          	addi	a0,a0,-260 # ffffffffc0207008 <commands+0x780>
ffffffffc0202114:	8f4fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202118:	00005697          	auipc	a3,0x5
ffffffffc020211c:	23868693          	addi	a3,a3,568 # ffffffffc0207350 <commands+0xac8>
ffffffffc0202120:	00005617          	auipc	a2,0x5
ffffffffc0202124:	b7860613          	addi	a2,a2,-1160 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202128:	21400593          	li	a1,532
ffffffffc020212c:	00005517          	auipc	a0,0x5
ffffffffc0202130:	edc50513          	addi	a0,a0,-292 # ffffffffc0207008 <commands+0x780>
ffffffffc0202134:	8d4fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202138:	00005697          	auipc	a3,0x5
ffffffffc020213c:	37068693          	addi	a3,a3,880 # ffffffffc02074a8 <commands+0xc20>
ffffffffc0202140:	00005617          	auipc	a2,0x5
ffffffffc0202144:	b5860613          	addi	a2,a2,-1192 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202148:	23900593          	li	a1,569
ffffffffc020214c:	00005517          	auipc	a0,0x5
ffffffffc0202150:	ebc50513          	addi	a0,a0,-324 # ffffffffc0207008 <commands+0x780>
ffffffffc0202154:	8b4fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202158:	00005697          	auipc	a3,0x5
ffffffffc020215c:	31868693          	addi	a3,a3,792 # ffffffffc0207470 <commands+0xbe8>
ffffffffc0202160:	00005617          	auipc	a2,0x5
ffffffffc0202164:	b3860613          	addi	a2,a2,-1224 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202168:	23800593          	li	a1,568
ffffffffc020216c:	00005517          	auipc	a0,0x5
ffffffffc0202170:	e9c50513          	addi	a0,a0,-356 # ffffffffc0207008 <commands+0x780>
ffffffffc0202174:	894fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc0202178:	00005697          	auipc	a3,0x5
ffffffffc020217c:	2e068693          	addi	a3,a3,736 # ffffffffc0207458 <commands+0xbd0>
ffffffffc0202180:	00005617          	auipc	a2,0x5
ffffffffc0202184:	b1860613          	addi	a2,a2,-1256 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202188:	23400593          	li	a1,564
ffffffffc020218c:	00005517          	auipc	a0,0x5
ffffffffc0202190:	e7c50513          	addi	a0,a0,-388 # ffffffffc0207008 <commands+0x780>
ffffffffc0202194:	874fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0202198:	00005697          	auipc	a3,0x5
ffffffffc020219c:	22868693          	addi	a3,a3,552 # ffffffffc02073c0 <commands+0xb38>
ffffffffc02021a0:	00005617          	auipc	a2,0x5
ffffffffc02021a4:	af860613          	addi	a2,a2,-1288 # ffffffffc0206c98 <commands+0x410>
ffffffffc02021a8:	22200593          	li	a1,546
ffffffffc02021ac:	00005517          	auipc	a0,0x5
ffffffffc02021b0:	e5c50513          	addi	a0,a0,-420 # ffffffffc0207008 <commands+0x780>
ffffffffc02021b4:	854fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02021b8:	00005697          	auipc	a3,0x5
ffffffffc02021bc:	04068693          	addi	a3,a3,64 # ffffffffc02071f8 <commands+0x970>
ffffffffc02021c0:	00005617          	auipc	a2,0x5
ffffffffc02021c4:	ad860613          	addi	a2,a2,-1320 # ffffffffc0206c98 <commands+0x410>
ffffffffc02021c8:	1fc00593          	li	a1,508
ffffffffc02021cc:	00005517          	auipc	a0,0x5
ffffffffc02021d0:	e3c50513          	addi	a0,a0,-452 # ffffffffc0207008 <commands+0x780>
ffffffffc02021d4:	834fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc02021d8:	00005617          	auipc	a2,0x5
ffffffffc02021dc:	e0860613          	addi	a2,a2,-504 # ffffffffc0206fe0 <commands+0x758>
ffffffffc02021e0:	1ff00593          	li	a1,511
ffffffffc02021e4:	00005517          	auipc	a0,0x5
ffffffffc02021e8:	e2450513          	addi	a0,a0,-476 # ffffffffc0207008 <commands+0x780>
ffffffffc02021ec:	81cfe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02021f0:	00005697          	auipc	a3,0x5
ffffffffc02021f4:	02068693          	addi	a3,a3,32 # ffffffffc0207210 <commands+0x988>
ffffffffc02021f8:	00005617          	auipc	a2,0x5
ffffffffc02021fc:	aa060613          	addi	a2,a2,-1376 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202200:	1fd00593          	li	a1,509
ffffffffc0202204:	00005517          	auipc	a0,0x5
ffffffffc0202208:	e0450513          	addi	a0,a0,-508 # ffffffffc0207008 <commands+0x780>
ffffffffc020220c:	ffdfd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202210:	00005697          	auipc	a3,0x5
ffffffffc0202214:	07868693          	addi	a3,a3,120 # ffffffffc0207288 <commands+0xa00>
ffffffffc0202218:	00005617          	auipc	a2,0x5
ffffffffc020221c:	a8060613          	addi	a2,a2,-1408 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202220:	20500593          	li	a1,517
ffffffffc0202224:	00005517          	auipc	a0,0x5
ffffffffc0202228:	de450513          	addi	a0,a0,-540 # ffffffffc0207008 <commands+0x780>
ffffffffc020222c:	fddfd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202230:	00005697          	auipc	a3,0x5
ffffffffc0202234:	33868693          	addi	a3,a3,824 # ffffffffc0207568 <commands+0xce0>
ffffffffc0202238:	00005617          	auipc	a2,0x5
ffffffffc020223c:	a6060613          	addi	a2,a2,-1440 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202240:	24200593          	li	a1,578
ffffffffc0202244:	00005517          	auipc	a0,0x5
ffffffffc0202248:	dc450513          	addi	a0,a0,-572 # ffffffffc0207008 <commands+0x780>
ffffffffc020224c:	fbdfd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202250:	00005697          	auipc	a3,0x5
ffffffffc0202254:	2e068693          	addi	a3,a3,736 # ffffffffc0207530 <commands+0xca8>
ffffffffc0202258:	00005617          	auipc	a2,0x5
ffffffffc020225c:	a4060613          	addi	a2,a2,-1472 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202260:	23f00593          	li	a1,575
ffffffffc0202264:	00005517          	auipc	a0,0x5
ffffffffc0202268:	da450513          	addi	a0,a0,-604 # ffffffffc0207008 <commands+0x780>
ffffffffc020226c:	f9dfd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202270:	00005697          	auipc	a3,0x5
ffffffffc0202274:	29068693          	addi	a3,a3,656 # ffffffffc0207500 <commands+0xc78>
ffffffffc0202278:	00005617          	auipc	a2,0x5
ffffffffc020227c:	a2060613          	addi	a2,a2,-1504 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202280:	23b00593          	li	a1,571
ffffffffc0202284:	00005517          	auipc	a0,0x5
ffffffffc0202288:	d8450513          	addi	a0,a0,-636 # ffffffffc0207008 <commands+0x780>
ffffffffc020228c:	f7dfd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0202290 <copy_range>:
               bool share) {
ffffffffc0202290:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202292:	00d667b3          	or	a5,a2,a3
               bool share) {
ffffffffc0202296:	f486                	sd	ra,104(sp)
ffffffffc0202298:	f0a2                	sd	s0,96(sp)
ffffffffc020229a:	eca6                	sd	s1,88(sp)
ffffffffc020229c:	e8ca                	sd	s2,80(sp)
ffffffffc020229e:	e4ce                	sd	s3,72(sp)
ffffffffc02022a0:	e0d2                	sd	s4,64(sp)
ffffffffc02022a2:	fc56                	sd	s5,56(sp)
ffffffffc02022a4:	f85a                	sd	s6,48(sp)
ffffffffc02022a6:	f45e                	sd	s7,40(sp)
ffffffffc02022a8:	f062                	sd	s8,32(sp)
ffffffffc02022aa:	ec66                	sd	s9,24(sp)
ffffffffc02022ac:	e86a                	sd	s10,16(sp)
ffffffffc02022ae:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022b0:	17d2                	slli	a5,a5,0x34
ffffffffc02022b2:	1c079963          	bnez	a5,ffffffffc0202484 <copy_range+0x1f4>
    assert(USER_ACCESS(start, end));
ffffffffc02022b6:	002007b7          	lui	a5,0x200
ffffffffc02022ba:	8432                	mv	s0,a2
ffffffffc02022bc:	18f66463          	bltu	a2,a5,ffffffffc0202444 <copy_range+0x1b4>
ffffffffc02022c0:	8936                	mv	s2,a3
ffffffffc02022c2:	18d67163          	bgeu	a2,a3,ffffffffc0202444 <copy_range+0x1b4>
ffffffffc02022c6:	4785                	li	a5,1
ffffffffc02022c8:	07fe                	slli	a5,a5,0x1f
ffffffffc02022ca:	16d7ed63          	bltu	a5,a3,ffffffffc0202444 <copy_range+0x1b4>
ffffffffc02022ce:	5afd                	li	s5,-1
ffffffffc02022d0:	8a2a                	mv	s4,a0
ffffffffc02022d2:	89ae                	mv	s3,a1
    if (PPN(pa) >= npage) {
ffffffffc02022d4:	000b0c17          	auipc	s8,0xb0
ffffffffc02022d8:	58cc0c13          	addi	s8,s8,1420 # ffffffffc02b2860 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02022dc:	000b0b97          	auipc	s7,0xb0
ffffffffc02022e0:	58cb8b93          	addi	s7,s7,1420 # ffffffffc02b2868 <pages>
ffffffffc02022e4:	fff80d37          	lui	s10,0xfff80
    return page - pages + nbase;
ffffffffc02022e8:	00080b37          	lui	s6,0x80
    return KADDR(page2pa(page));
ffffffffc02022ec:	00cada93          	srli	s5,s5,0xc
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc02022f0:	4601                	li	a2,0
ffffffffc02022f2:	85a2                	mv	a1,s0
ffffffffc02022f4:	854e                	mv	a0,s3
ffffffffc02022f6:	c71fe0ef          	jal	ra,ffffffffc0200f66 <get_pte>
ffffffffc02022fa:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc02022fc:	c179                	beqz	a0,ffffffffc02023c2 <copy_range+0x132>
        if (*ptep & PTE_V) {
ffffffffc02022fe:	611c                	ld	a5,0(a0)
ffffffffc0202300:	8b85                	andi	a5,a5,1
ffffffffc0202302:	e78d                	bnez	a5,ffffffffc020232c <copy_range+0x9c>
        start += PGSIZE;
ffffffffc0202304:	6785                	lui	a5,0x1
ffffffffc0202306:	943e                	add	s0,s0,a5
    } while (start != 0 && start < end);
ffffffffc0202308:	ff2464e3          	bltu	s0,s2,ffffffffc02022f0 <copy_range+0x60>
    return 0;
ffffffffc020230c:	4501                	li	a0,0
}
ffffffffc020230e:	70a6                	ld	ra,104(sp)
ffffffffc0202310:	7406                	ld	s0,96(sp)
ffffffffc0202312:	64e6                	ld	s1,88(sp)
ffffffffc0202314:	6946                	ld	s2,80(sp)
ffffffffc0202316:	69a6                	ld	s3,72(sp)
ffffffffc0202318:	6a06                	ld	s4,64(sp)
ffffffffc020231a:	7ae2                	ld	s5,56(sp)
ffffffffc020231c:	7b42                	ld	s6,48(sp)
ffffffffc020231e:	7ba2                	ld	s7,40(sp)
ffffffffc0202320:	7c02                	ld	s8,32(sp)
ffffffffc0202322:	6ce2                	ld	s9,24(sp)
ffffffffc0202324:	6d42                	ld	s10,16(sp)
ffffffffc0202326:	6da2                	ld	s11,8(sp)
ffffffffc0202328:	6165                	addi	sp,sp,112
ffffffffc020232a:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL) {
ffffffffc020232c:	4605                	li	a2,1
ffffffffc020232e:	85a2                	mv	a1,s0
ffffffffc0202330:	8552                	mv	a0,s4
ffffffffc0202332:	c35fe0ef          	jal	ra,ffffffffc0200f66 <get_pte>
ffffffffc0202336:	c145                	beqz	a0,ffffffffc02023d6 <copy_range+0x146>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0202338:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V)) {
ffffffffc020233a:	0017f713          	andi	a4,a5,1
ffffffffc020233e:	01f7f493          	andi	s1,a5,31
ffffffffc0202342:	0e070563          	beqz	a4,ffffffffc020242c <copy_range+0x19c>
    if (PPN(pa) >= npage) {
ffffffffc0202346:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc020234a:	078a                	slli	a5,a5,0x2
ffffffffc020234c:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202350:	0cd77263          	bgeu	a4,a3,ffffffffc0202414 <copy_range+0x184>
    return &pages[PPN(pa) - nbase];
ffffffffc0202354:	000bb783          	ld	a5,0(s7)
ffffffffc0202358:	976a                	add	a4,a4,s10
ffffffffc020235a:	071a                	slli	a4,a4,0x6
            struct Page *npage = alloc_page();
ffffffffc020235c:	4505                	li	a0,1
ffffffffc020235e:	00e78cb3          	add	s9,a5,a4
ffffffffc0202362:	af9fe0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc0202366:	8daa                	mv	s11,a0
            assert(page != NULL);
ffffffffc0202368:	080c8663          	beqz	s9,ffffffffc02023f4 <copy_range+0x164>
            assert(npage != NULL);
ffffffffc020236c:	0e050c63          	beqz	a0,ffffffffc0202464 <copy_range+0x1d4>
    return page - pages + nbase;
ffffffffc0202370:	000bb703          	ld	a4,0(s7)
    return KADDR(page2pa(page));
ffffffffc0202374:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0202378:	40ec86b3          	sub	a3,s9,a4
ffffffffc020237c:	8699                	srai	a3,a3,0x6
ffffffffc020237e:	96da                	add	a3,a3,s6
    return KADDR(page2pa(page));
ffffffffc0202380:	0156f7b3          	and	a5,a3,s5
    return page2ppn(page) << PGSHIFT;
ffffffffc0202384:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202386:	04c7fb63          	bgeu	a5,a2,ffffffffc02023dc <copy_range+0x14c>
    return page - pages + nbase;
ffffffffc020238a:	40e507b3          	sub	a5,a0,a4
    return KADDR(page2pa(page));
ffffffffc020238e:	000b0717          	auipc	a4,0xb0
ffffffffc0202392:	4ea70713          	addi	a4,a4,1258 # ffffffffc02b2878 <va_pa_offset>
ffffffffc0202396:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc0202398:	8799                	srai	a5,a5,0x6
ffffffffc020239a:	97da                	add	a5,a5,s6
    return KADDR(page2pa(page));
ffffffffc020239c:	0157f733          	and	a4,a5,s5
ffffffffc02023a0:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02023a4:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02023a6:	02c77a63          	bgeu	a4,a2,ffffffffc02023da <copy_range+0x14a>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc02023aa:	6605                	lui	a2,0x1
ffffffffc02023ac:	953e                	add	a0,a0,a5
ffffffffc02023ae:	613030ef          	jal	ra,ffffffffc02061c0 <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc02023b2:	86a6                	mv	a3,s1
ffffffffc02023b4:	8622                	mv	a2,s0
ffffffffc02023b6:	85ee                	mv	a1,s11
ffffffffc02023b8:	8552                	mv	a0,s4
ffffffffc02023ba:	a46ff0ef          	jal	ra,ffffffffc0201600 <page_insert>
            if (ret != 0) {
ffffffffc02023be:	d139                	beqz	a0,ffffffffc0202304 <copy_range+0x74>
ffffffffc02023c0:	b7b9                	j	ffffffffc020230e <copy_range+0x7e>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02023c2:	002007b7          	lui	a5,0x200
ffffffffc02023c6:	943e                	add	s0,s0,a5
ffffffffc02023c8:	ffe007b7          	lui	a5,0xffe00
ffffffffc02023cc:	8c7d                	and	s0,s0,a5
    } while (start != 0 && start < end);
ffffffffc02023ce:	dc1d                	beqz	s0,ffffffffc020230c <copy_range+0x7c>
ffffffffc02023d0:	f32460e3          	bltu	s0,s2,ffffffffc02022f0 <copy_range+0x60>
ffffffffc02023d4:	bf25                	j	ffffffffc020230c <copy_range+0x7c>
                return -E_NO_MEM;
ffffffffc02023d6:	5571                	li	a0,-4
ffffffffc02023d8:	bf1d                	j	ffffffffc020230e <copy_range+0x7e>
ffffffffc02023da:	86be                	mv	a3,a5
ffffffffc02023dc:	00005617          	auipc	a2,0x5
ffffffffc02023e0:	c0460613          	addi	a2,a2,-1020 # ffffffffc0206fe0 <commands+0x758>
ffffffffc02023e4:	06900593          	li	a1,105
ffffffffc02023e8:	00005517          	auipc	a0,0x5
ffffffffc02023ec:	bc050513          	addi	a0,a0,-1088 # ffffffffc0206fa8 <commands+0x720>
ffffffffc02023f0:	e19fd0ef          	jal	ra,ffffffffc0200208 <__panic>
            assert(page != NULL);
ffffffffc02023f4:	00005697          	auipc	a3,0x5
ffffffffc02023f8:	1bc68693          	addi	a3,a3,444 # ffffffffc02075b0 <commands+0xd28>
ffffffffc02023fc:	00005617          	auipc	a2,0x5
ffffffffc0202400:	89c60613          	addi	a2,a2,-1892 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202404:	17200593          	li	a1,370
ffffffffc0202408:	00005517          	auipc	a0,0x5
ffffffffc020240c:	c0050513          	addi	a0,a0,-1024 # ffffffffc0207008 <commands+0x780>
ffffffffc0202410:	df9fd0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202414:	00005617          	auipc	a2,0x5
ffffffffc0202418:	b7460613          	addi	a2,a2,-1164 # ffffffffc0206f88 <commands+0x700>
ffffffffc020241c:	06200593          	li	a1,98
ffffffffc0202420:	00005517          	auipc	a0,0x5
ffffffffc0202424:	b8850513          	addi	a0,a0,-1144 # ffffffffc0206fa8 <commands+0x720>
ffffffffc0202428:	de1fd0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc020242c:	00005617          	auipc	a2,0x5
ffffffffc0202430:	b8c60613          	addi	a2,a2,-1140 # ffffffffc0206fb8 <commands+0x730>
ffffffffc0202434:	07400593          	li	a1,116
ffffffffc0202438:	00005517          	auipc	a0,0x5
ffffffffc020243c:	b7050513          	addi	a0,a0,-1168 # ffffffffc0206fa8 <commands+0x720>
ffffffffc0202440:	dc9fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202444:	00005697          	auipc	a3,0x5
ffffffffc0202448:	c0468693          	addi	a3,a3,-1020 # ffffffffc0207048 <commands+0x7c0>
ffffffffc020244c:	00005617          	auipc	a2,0x5
ffffffffc0202450:	84c60613          	addi	a2,a2,-1972 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202454:	15e00593          	li	a1,350
ffffffffc0202458:	00005517          	auipc	a0,0x5
ffffffffc020245c:	bb050513          	addi	a0,a0,-1104 # ffffffffc0207008 <commands+0x780>
ffffffffc0202460:	da9fd0ef          	jal	ra,ffffffffc0200208 <__panic>
            assert(npage != NULL);
ffffffffc0202464:	00005697          	auipc	a3,0x5
ffffffffc0202468:	15c68693          	addi	a3,a3,348 # ffffffffc02075c0 <commands+0xd38>
ffffffffc020246c:	00005617          	auipc	a2,0x5
ffffffffc0202470:	82c60613          	addi	a2,a2,-2004 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202474:	17300593          	li	a1,371
ffffffffc0202478:	00005517          	auipc	a0,0x5
ffffffffc020247c:	b9050513          	addi	a0,a0,-1136 # ffffffffc0207008 <commands+0x780>
ffffffffc0202480:	d89fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202484:	00005697          	auipc	a3,0x5
ffffffffc0202488:	b9468693          	addi	a3,a3,-1132 # ffffffffc0207018 <commands+0x790>
ffffffffc020248c:	00005617          	auipc	a2,0x5
ffffffffc0202490:	80c60613          	addi	a2,a2,-2036 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202494:	15d00593          	li	a1,349
ffffffffc0202498:	00005517          	auipc	a0,0x5
ffffffffc020249c:	b7050513          	addi	a0,a0,-1168 # ffffffffc0207008 <commands+0x780>
ffffffffc02024a0:	d69fd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02024a4 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02024a4:	12058073          	sfence.vma	a1
}
ffffffffc02024a8:	8082                	ret

ffffffffc02024aa <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc02024aa:	7179                	addi	sp,sp,-48
ffffffffc02024ac:	e84a                	sd	s2,16(sp)
ffffffffc02024ae:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc02024b0:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc02024b2:	f022                	sd	s0,32(sp)
ffffffffc02024b4:	ec26                	sd	s1,24(sp)
ffffffffc02024b6:	e44e                	sd	s3,8(sp)
ffffffffc02024b8:	f406                	sd	ra,40(sp)
ffffffffc02024ba:	84ae                	mv	s1,a1
ffffffffc02024bc:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc02024be:	99dfe0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc02024c2:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc02024c4:	cd05                	beqz	a0,ffffffffc02024fc <pgdir_alloc_page+0x52>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc02024c6:	85aa                	mv	a1,a0
ffffffffc02024c8:	86ce                	mv	a3,s3
ffffffffc02024ca:	8626                	mv	a2,s1
ffffffffc02024cc:	854a                	mv	a0,s2
ffffffffc02024ce:	932ff0ef          	jal	ra,ffffffffc0201600 <page_insert>
ffffffffc02024d2:	ed0d                	bnez	a0,ffffffffc020250c <pgdir_alloc_page+0x62>
        if (swap_init_ok) {
ffffffffc02024d4:	000b0797          	auipc	a5,0xb0
ffffffffc02024d8:	3d47a783          	lw	a5,980(a5) # ffffffffc02b28a8 <swap_init_ok>
ffffffffc02024dc:	c385                	beqz	a5,ffffffffc02024fc <pgdir_alloc_page+0x52>
            if (check_mm_struct != NULL) {
ffffffffc02024de:	000b0517          	auipc	a0,0xb0
ffffffffc02024e2:	3a253503          	ld	a0,930(a0) # ffffffffc02b2880 <check_mm_struct>
ffffffffc02024e6:	c919                	beqz	a0,ffffffffc02024fc <pgdir_alloc_page+0x52>
                swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc02024e8:	4681                	li	a3,0
ffffffffc02024ea:	8622                	mv	a2,s0
ffffffffc02024ec:	85a6                	mv	a1,s1
ffffffffc02024ee:	253010ef          	jal	ra,ffffffffc0203f40 <swap_map_swappable>
                assert(page_ref(page) == 1);
ffffffffc02024f2:	4018                	lw	a4,0(s0)
                page->pra_vaddr = la;
ffffffffc02024f4:	fc04                	sd	s1,56(s0)
                assert(page_ref(page) == 1);
ffffffffc02024f6:	4785                	li	a5,1
ffffffffc02024f8:	04f71663          	bne	a4,a5,ffffffffc0202544 <pgdir_alloc_page+0x9a>
}
ffffffffc02024fc:	70a2                	ld	ra,40(sp)
ffffffffc02024fe:	8522                	mv	a0,s0
ffffffffc0202500:	7402                	ld	s0,32(sp)
ffffffffc0202502:	64e2                	ld	s1,24(sp)
ffffffffc0202504:	6942                	ld	s2,16(sp)
ffffffffc0202506:	69a2                	ld	s3,8(sp)
ffffffffc0202508:	6145                	addi	sp,sp,48
ffffffffc020250a:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020250c:	100027f3          	csrr	a5,sstatus
ffffffffc0202510:	8b89                	andi	a5,a5,2
ffffffffc0202512:	eb99                	bnez	a5,ffffffffc0202528 <pgdir_alloc_page+0x7e>
        pmm_manager->free_pages(base, n);
ffffffffc0202514:	000b0797          	auipc	a5,0xb0
ffffffffc0202518:	35c7b783          	ld	a5,860(a5) # ffffffffc02b2870 <pmm_manager>
ffffffffc020251c:	739c                	ld	a5,32(a5)
ffffffffc020251e:	8522                	mv	a0,s0
ffffffffc0202520:	4585                	li	a1,1
ffffffffc0202522:	9782                	jalr	a5
            return NULL;
ffffffffc0202524:	4401                	li	s0,0
ffffffffc0202526:	bfd9                	j	ffffffffc02024fc <pgdir_alloc_page+0x52>
        intr_disable();
ffffffffc0202528:	920fe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020252c:	000b0797          	auipc	a5,0xb0
ffffffffc0202530:	3447b783          	ld	a5,836(a5) # ffffffffc02b2870 <pmm_manager>
ffffffffc0202534:	739c                	ld	a5,32(a5)
ffffffffc0202536:	8522                	mv	a0,s0
ffffffffc0202538:	4585                	li	a1,1
ffffffffc020253a:	9782                	jalr	a5
            return NULL;
ffffffffc020253c:	4401                	li	s0,0
        intr_enable();
ffffffffc020253e:	904fe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0202542:	bf6d                	j	ffffffffc02024fc <pgdir_alloc_page+0x52>
                assert(page_ref(page) == 1);
ffffffffc0202544:	00005697          	auipc	a3,0x5
ffffffffc0202548:	08c68693          	addi	a3,a3,140 # ffffffffc02075d0 <commands+0xd48>
ffffffffc020254c:	00004617          	auipc	a2,0x4
ffffffffc0202550:	74c60613          	addi	a2,a2,1868 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202554:	1d300593          	li	a1,467
ffffffffc0202558:	00005517          	auipc	a0,0x5
ffffffffc020255c:	ab050513          	addi	a0,a0,-1360 # ffffffffc0207008 <commands+0x780>
ffffffffc0202560:	ca9fd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0202564 <_fifo_init_mm>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0202564:	000ac797          	auipc	a5,0xac
ffffffffc0202568:	20c78793          	addi	a5,a5,524 # ffffffffc02ae770 <pra_list_head>
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
ffffffffc020256c:	f51c                	sd	a5,40(a0)
ffffffffc020256e:	e79c                	sd	a5,8(a5)
ffffffffc0202570:	e39c                	sd	a5,0(a5)
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
ffffffffc0202572:	4501                	li	a0,0
ffffffffc0202574:	8082                	ret

ffffffffc0202576 <_fifo_init>:

static int
_fifo_init(void)
{
    return 0;
}
ffffffffc0202576:	4501                	li	a0,0
ffffffffc0202578:	8082                	ret

ffffffffc020257a <_fifo_set_unswappable>:

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc020257a:	4501                	li	a0,0
ffffffffc020257c:	8082                	ret

ffffffffc020257e <_fifo_tick_event>:

static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc020257e:	4501                	li	a0,0
ffffffffc0202580:	8082                	ret

ffffffffc0202582 <_fifo_check_swap>:
_fifo_check_swap(void) {
ffffffffc0202582:	711d                	addi	sp,sp,-96
ffffffffc0202584:	fc4e                	sd	s3,56(sp)
ffffffffc0202586:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0202588:	00005517          	auipc	a0,0x5
ffffffffc020258c:	06050513          	addi	a0,a0,96 # ffffffffc02075e8 <commands+0xd60>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0202590:	698d                	lui	s3,0x3
ffffffffc0202592:	4a31                	li	s4,12
_fifo_check_swap(void) {
ffffffffc0202594:	e0ca                	sd	s2,64(sp)
ffffffffc0202596:	ec86                	sd	ra,88(sp)
ffffffffc0202598:	e8a2                	sd	s0,80(sp)
ffffffffc020259a:	e4a6                	sd	s1,72(sp)
ffffffffc020259c:	f456                	sd	s5,40(sp)
ffffffffc020259e:	f05a                	sd	s6,32(sp)
ffffffffc02025a0:	ec5e                	sd	s7,24(sp)
ffffffffc02025a2:	e862                	sd	s8,16(sp)
ffffffffc02025a4:	e466                	sd	s9,8(sp)
ffffffffc02025a6:	e06a                	sd	s10,0(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc02025a8:	b25fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc02025ac:	01498023          	sb	s4,0(s3) # 3000 <_binary_obj___user_faultread_out_size-0x6bb8>
    assert(pgfault_num==4);
ffffffffc02025b0:	000b0917          	auipc	s2,0xb0
ffffffffc02025b4:	2d892903          	lw	s2,728(s2) # ffffffffc02b2888 <pgfault_num>
ffffffffc02025b8:	4791                	li	a5,4
ffffffffc02025ba:	14f91e63          	bne	s2,a5,ffffffffc0202716 <_fifo_check_swap+0x194>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc02025be:	00005517          	auipc	a0,0x5
ffffffffc02025c2:	07a50513          	addi	a0,a0,122 # ffffffffc0207638 <commands+0xdb0>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc02025c6:	6a85                	lui	s5,0x1
ffffffffc02025c8:	4b29                	li	s6,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc02025ca:	b03fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc02025ce:	000b0417          	auipc	s0,0xb0
ffffffffc02025d2:	2ba40413          	addi	s0,s0,698 # ffffffffc02b2888 <pgfault_num>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc02025d6:	016a8023          	sb	s6,0(s5) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
    assert(pgfault_num==4);
ffffffffc02025da:	4004                	lw	s1,0(s0)
ffffffffc02025dc:	2481                	sext.w	s1,s1
ffffffffc02025de:	2b249c63          	bne	s1,s2,ffffffffc0202896 <_fifo_check_swap+0x314>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc02025e2:	00005517          	auipc	a0,0x5
ffffffffc02025e6:	07e50513          	addi	a0,a0,126 # ffffffffc0207660 <commands+0xdd8>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02025ea:	6b91                	lui	s7,0x4
ffffffffc02025ec:	4c35                	li	s8,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc02025ee:	adffd0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02025f2:	018b8023          	sb	s8,0(s7) # 4000 <_binary_obj___user_faultread_out_size-0x5bb8>
    assert(pgfault_num==4);
ffffffffc02025f6:	00042903          	lw	s2,0(s0)
ffffffffc02025fa:	2901                	sext.w	s2,s2
ffffffffc02025fc:	26991d63          	bne	s2,s1,ffffffffc0202876 <_fifo_check_swap+0x2f4>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0202600:	00005517          	auipc	a0,0x5
ffffffffc0202604:	08850513          	addi	a0,a0,136 # ffffffffc0207688 <commands+0xe00>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202608:	6c89                	lui	s9,0x2
ffffffffc020260a:	4d2d                	li	s10,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc020260c:	ac1fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202610:	01ac8023          	sb	s10,0(s9) # 2000 <_binary_obj___user_faultread_out_size-0x7bb8>
    assert(pgfault_num==4);
ffffffffc0202614:	401c                	lw	a5,0(s0)
ffffffffc0202616:	2781                	sext.w	a5,a5
ffffffffc0202618:	23279f63          	bne	a5,s2,ffffffffc0202856 <_fifo_check_swap+0x2d4>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc020261c:	00005517          	auipc	a0,0x5
ffffffffc0202620:	09450513          	addi	a0,a0,148 # ffffffffc02076b0 <commands+0xe28>
ffffffffc0202624:	aa9fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0202628:	6795                	lui	a5,0x5
ffffffffc020262a:	4739                	li	a4,14
ffffffffc020262c:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4bb8>
    assert(pgfault_num==5);
ffffffffc0202630:	4004                	lw	s1,0(s0)
ffffffffc0202632:	4795                	li	a5,5
ffffffffc0202634:	2481                	sext.w	s1,s1
ffffffffc0202636:	20f49063          	bne	s1,a5,ffffffffc0202836 <_fifo_check_swap+0x2b4>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc020263a:	00005517          	auipc	a0,0x5
ffffffffc020263e:	04e50513          	addi	a0,a0,78 # ffffffffc0207688 <commands+0xe00>
ffffffffc0202642:	a8bfd0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202646:	01ac8023          	sb	s10,0(s9)
    assert(pgfault_num==5);
ffffffffc020264a:	401c                	lw	a5,0(s0)
ffffffffc020264c:	2781                	sext.w	a5,a5
ffffffffc020264e:	1c979463          	bne	a5,s1,ffffffffc0202816 <_fifo_check_swap+0x294>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0202652:	00005517          	auipc	a0,0x5
ffffffffc0202656:	fe650513          	addi	a0,a0,-26 # ffffffffc0207638 <commands+0xdb0>
ffffffffc020265a:	a73fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc020265e:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num==6);
ffffffffc0202662:	401c                	lw	a5,0(s0)
ffffffffc0202664:	4719                	li	a4,6
ffffffffc0202666:	2781                	sext.w	a5,a5
ffffffffc0202668:	18e79763          	bne	a5,a4,ffffffffc02027f6 <_fifo_check_swap+0x274>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc020266c:	00005517          	auipc	a0,0x5
ffffffffc0202670:	01c50513          	addi	a0,a0,28 # ffffffffc0207688 <commands+0xe00>
ffffffffc0202674:	a59fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202678:	01ac8023          	sb	s10,0(s9)
    assert(pgfault_num==7);
ffffffffc020267c:	401c                	lw	a5,0(s0)
ffffffffc020267e:	471d                	li	a4,7
ffffffffc0202680:	2781                	sext.w	a5,a5
ffffffffc0202682:	14e79a63          	bne	a5,a4,ffffffffc02027d6 <_fifo_check_swap+0x254>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0202686:	00005517          	auipc	a0,0x5
ffffffffc020268a:	f6250513          	addi	a0,a0,-158 # ffffffffc02075e8 <commands+0xd60>
ffffffffc020268e:	a3ffd0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0202692:	01498023          	sb	s4,0(s3)
    assert(pgfault_num==8);
ffffffffc0202696:	401c                	lw	a5,0(s0)
ffffffffc0202698:	4721                	li	a4,8
ffffffffc020269a:	2781                	sext.w	a5,a5
ffffffffc020269c:	10e79d63          	bne	a5,a4,ffffffffc02027b6 <_fifo_check_swap+0x234>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc02026a0:	00005517          	auipc	a0,0x5
ffffffffc02026a4:	fc050513          	addi	a0,a0,-64 # ffffffffc0207660 <commands+0xdd8>
ffffffffc02026a8:	a25fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02026ac:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num==9);
ffffffffc02026b0:	401c                	lw	a5,0(s0)
ffffffffc02026b2:	4725                	li	a4,9
ffffffffc02026b4:	2781                	sext.w	a5,a5
ffffffffc02026b6:	0ee79063          	bne	a5,a4,ffffffffc0202796 <_fifo_check_swap+0x214>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc02026ba:	00005517          	auipc	a0,0x5
ffffffffc02026be:	ff650513          	addi	a0,a0,-10 # ffffffffc02076b0 <commands+0xe28>
ffffffffc02026c2:	a0bfd0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc02026c6:	6795                	lui	a5,0x5
ffffffffc02026c8:	4739                	li	a4,14
ffffffffc02026ca:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4bb8>
    assert(pgfault_num==10);
ffffffffc02026ce:	4004                	lw	s1,0(s0)
ffffffffc02026d0:	47a9                	li	a5,10
ffffffffc02026d2:	2481                	sext.w	s1,s1
ffffffffc02026d4:	0af49163          	bne	s1,a5,ffffffffc0202776 <_fifo_check_swap+0x1f4>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc02026d8:	00005517          	auipc	a0,0x5
ffffffffc02026dc:	f6050513          	addi	a0,a0,-160 # ffffffffc0207638 <commands+0xdb0>
ffffffffc02026e0:	9edfd0ef          	jal	ra,ffffffffc02000cc <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc02026e4:	6785                	lui	a5,0x1
ffffffffc02026e6:	0007c783          	lbu	a5,0(a5) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc02026ea:	06979663          	bne	a5,s1,ffffffffc0202756 <_fifo_check_swap+0x1d4>
    assert(pgfault_num==11);
ffffffffc02026ee:	401c                	lw	a5,0(s0)
ffffffffc02026f0:	472d                	li	a4,11
ffffffffc02026f2:	2781                	sext.w	a5,a5
ffffffffc02026f4:	04e79163          	bne	a5,a4,ffffffffc0202736 <_fifo_check_swap+0x1b4>
}
ffffffffc02026f8:	60e6                	ld	ra,88(sp)
ffffffffc02026fa:	6446                	ld	s0,80(sp)
ffffffffc02026fc:	64a6                	ld	s1,72(sp)
ffffffffc02026fe:	6906                	ld	s2,64(sp)
ffffffffc0202700:	79e2                	ld	s3,56(sp)
ffffffffc0202702:	7a42                	ld	s4,48(sp)
ffffffffc0202704:	7aa2                	ld	s5,40(sp)
ffffffffc0202706:	7b02                	ld	s6,32(sp)
ffffffffc0202708:	6be2                	ld	s7,24(sp)
ffffffffc020270a:	6c42                	ld	s8,16(sp)
ffffffffc020270c:	6ca2                	ld	s9,8(sp)
ffffffffc020270e:	6d02                	ld	s10,0(sp)
ffffffffc0202710:	4501                	li	a0,0
ffffffffc0202712:	6125                	addi	sp,sp,96
ffffffffc0202714:	8082                	ret
    assert(pgfault_num==4);
ffffffffc0202716:	00005697          	auipc	a3,0x5
ffffffffc020271a:	efa68693          	addi	a3,a3,-262 # ffffffffc0207610 <commands+0xd88>
ffffffffc020271e:	00004617          	auipc	a2,0x4
ffffffffc0202722:	57a60613          	addi	a2,a2,1402 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202726:	05100593          	li	a1,81
ffffffffc020272a:	00005517          	auipc	a0,0x5
ffffffffc020272e:	ef650513          	addi	a0,a0,-266 # ffffffffc0207620 <commands+0xd98>
ffffffffc0202732:	ad7fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==11);
ffffffffc0202736:	00005697          	auipc	a3,0x5
ffffffffc020273a:	02a68693          	addi	a3,a3,42 # ffffffffc0207760 <commands+0xed8>
ffffffffc020273e:	00004617          	auipc	a2,0x4
ffffffffc0202742:	55a60613          	addi	a2,a2,1370 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202746:	07300593          	li	a1,115
ffffffffc020274a:	00005517          	auipc	a0,0x5
ffffffffc020274e:	ed650513          	addi	a0,a0,-298 # ffffffffc0207620 <commands+0xd98>
ffffffffc0202752:	ab7fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0202756:	00005697          	auipc	a3,0x5
ffffffffc020275a:	fe268693          	addi	a3,a3,-30 # ffffffffc0207738 <commands+0xeb0>
ffffffffc020275e:	00004617          	auipc	a2,0x4
ffffffffc0202762:	53a60613          	addi	a2,a2,1338 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202766:	07100593          	li	a1,113
ffffffffc020276a:	00005517          	auipc	a0,0x5
ffffffffc020276e:	eb650513          	addi	a0,a0,-330 # ffffffffc0207620 <commands+0xd98>
ffffffffc0202772:	a97fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==10);
ffffffffc0202776:	00005697          	auipc	a3,0x5
ffffffffc020277a:	fb268693          	addi	a3,a3,-78 # ffffffffc0207728 <commands+0xea0>
ffffffffc020277e:	00004617          	auipc	a2,0x4
ffffffffc0202782:	51a60613          	addi	a2,a2,1306 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202786:	06f00593          	li	a1,111
ffffffffc020278a:	00005517          	auipc	a0,0x5
ffffffffc020278e:	e9650513          	addi	a0,a0,-362 # ffffffffc0207620 <commands+0xd98>
ffffffffc0202792:	a77fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==9);
ffffffffc0202796:	00005697          	auipc	a3,0x5
ffffffffc020279a:	f8268693          	addi	a3,a3,-126 # ffffffffc0207718 <commands+0xe90>
ffffffffc020279e:	00004617          	auipc	a2,0x4
ffffffffc02027a2:	4fa60613          	addi	a2,a2,1274 # ffffffffc0206c98 <commands+0x410>
ffffffffc02027a6:	06c00593          	li	a1,108
ffffffffc02027aa:	00005517          	auipc	a0,0x5
ffffffffc02027ae:	e7650513          	addi	a0,a0,-394 # ffffffffc0207620 <commands+0xd98>
ffffffffc02027b2:	a57fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==8);
ffffffffc02027b6:	00005697          	auipc	a3,0x5
ffffffffc02027ba:	f5268693          	addi	a3,a3,-174 # ffffffffc0207708 <commands+0xe80>
ffffffffc02027be:	00004617          	auipc	a2,0x4
ffffffffc02027c2:	4da60613          	addi	a2,a2,1242 # ffffffffc0206c98 <commands+0x410>
ffffffffc02027c6:	06900593          	li	a1,105
ffffffffc02027ca:	00005517          	auipc	a0,0x5
ffffffffc02027ce:	e5650513          	addi	a0,a0,-426 # ffffffffc0207620 <commands+0xd98>
ffffffffc02027d2:	a37fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==7);
ffffffffc02027d6:	00005697          	auipc	a3,0x5
ffffffffc02027da:	f2268693          	addi	a3,a3,-222 # ffffffffc02076f8 <commands+0xe70>
ffffffffc02027de:	00004617          	auipc	a2,0x4
ffffffffc02027e2:	4ba60613          	addi	a2,a2,1210 # ffffffffc0206c98 <commands+0x410>
ffffffffc02027e6:	06600593          	li	a1,102
ffffffffc02027ea:	00005517          	auipc	a0,0x5
ffffffffc02027ee:	e3650513          	addi	a0,a0,-458 # ffffffffc0207620 <commands+0xd98>
ffffffffc02027f2:	a17fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==6);
ffffffffc02027f6:	00005697          	auipc	a3,0x5
ffffffffc02027fa:	ef268693          	addi	a3,a3,-270 # ffffffffc02076e8 <commands+0xe60>
ffffffffc02027fe:	00004617          	auipc	a2,0x4
ffffffffc0202802:	49a60613          	addi	a2,a2,1178 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202806:	06300593          	li	a1,99
ffffffffc020280a:	00005517          	auipc	a0,0x5
ffffffffc020280e:	e1650513          	addi	a0,a0,-490 # ffffffffc0207620 <commands+0xd98>
ffffffffc0202812:	9f7fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==5);
ffffffffc0202816:	00005697          	auipc	a3,0x5
ffffffffc020281a:	ec268693          	addi	a3,a3,-318 # ffffffffc02076d8 <commands+0xe50>
ffffffffc020281e:	00004617          	auipc	a2,0x4
ffffffffc0202822:	47a60613          	addi	a2,a2,1146 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202826:	06000593          	li	a1,96
ffffffffc020282a:	00005517          	auipc	a0,0x5
ffffffffc020282e:	df650513          	addi	a0,a0,-522 # ffffffffc0207620 <commands+0xd98>
ffffffffc0202832:	9d7fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==5);
ffffffffc0202836:	00005697          	auipc	a3,0x5
ffffffffc020283a:	ea268693          	addi	a3,a3,-350 # ffffffffc02076d8 <commands+0xe50>
ffffffffc020283e:	00004617          	auipc	a2,0x4
ffffffffc0202842:	45a60613          	addi	a2,a2,1114 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202846:	05d00593          	li	a1,93
ffffffffc020284a:	00005517          	auipc	a0,0x5
ffffffffc020284e:	dd650513          	addi	a0,a0,-554 # ffffffffc0207620 <commands+0xd98>
ffffffffc0202852:	9b7fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==4);
ffffffffc0202856:	00005697          	auipc	a3,0x5
ffffffffc020285a:	dba68693          	addi	a3,a3,-582 # ffffffffc0207610 <commands+0xd88>
ffffffffc020285e:	00004617          	auipc	a2,0x4
ffffffffc0202862:	43a60613          	addi	a2,a2,1082 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202866:	05a00593          	li	a1,90
ffffffffc020286a:	00005517          	auipc	a0,0x5
ffffffffc020286e:	db650513          	addi	a0,a0,-586 # ffffffffc0207620 <commands+0xd98>
ffffffffc0202872:	997fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==4);
ffffffffc0202876:	00005697          	auipc	a3,0x5
ffffffffc020287a:	d9a68693          	addi	a3,a3,-614 # ffffffffc0207610 <commands+0xd88>
ffffffffc020287e:	00004617          	auipc	a2,0x4
ffffffffc0202882:	41a60613          	addi	a2,a2,1050 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202886:	05700593          	li	a1,87
ffffffffc020288a:	00005517          	auipc	a0,0x5
ffffffffc020288e:	d9650513          	addi	a0,a0,-618 # ffffffffc0207620 <commands+0xd98>
ffffffffc0202892:	977fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==4);
ffffffffc0202896:	00005697          	auipc	a3,0x5
ffffffffc020289a:	d7a68693          	addi	a3,a3,-646 # ffffffffc0207610 <commands+0xd88>
ffffffffc020289e:	00004617          	auipc	a2,0x4
ffffffffc02028a2:	3fa60613          	addi	a2,a2,1018 # ffffffffc0206c98 <commands+0x410>
ffffffffc02028a6:	05400593          	li	a1,84
ffffffffc02028aa:	00005517          	auipc	a0,0x5
ffffffffc02028ae:	d7650513          	addi	a0,a0,-650 # ffffffffc0207620 <commands+0xd98>
ffffffffc02028b2:	957fd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02028b6 <_fifo_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc02028b6:	751c                	ld	a5,40(a0)
{
ffffffffc02028b8:	1141                	addi	sp,sp,-16
ffffffffc02028ba:	e406                	sd	ra,8(sp)
         assert(head != NULL);
ffffffffc02028bc:	cf91                	beqz	a5,ffffffffc02028d8 <_fifo_swap_out_victim+0x22>
     assert(in_tick==0);
ffffffffc02028be:	ee0d                	bnez	a2,ffffffffc02028f8 <_fifo_swap_out_victim+0x42>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02028c0:	679c                	ld	a5,8(a5)
}
ffffffffc02028c2:	60a2                	ld	ra,8(sp)
ffffffffc02028c4:	4501                	li	a0,0
    __list_del(listelm->prev, listelm->next);
ffffffffc02028c6:	6394                	ld	a3,0(a5)
ffffffffc02028c8:	6798                	ld	a4,8(a5)
    *ptr_page = le2page(entry, pra_page_link);
ffffffffc02028ca:	fd878793          	addi	a5,a5,-40
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02028ce:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02028d0:	e314                	sd	a3,0(a4)
ffffffffc02028d2:	e19c                	sd	a5,0(a1)
}
ffffffffc02028d4:	0141                	addi	sp,sp,16
ffffffffc02028d6:	8082                	ret
         assert(head != NULL);
ffffffffc02028d8:	00005697          	auipc	a3,0x5
ffffffffc02028dc:	e9868693          	addi	a3,a3,-360 # ffffffffc0207770 <commands+0xee8>
ffffffffc02028e0:	00004617          	auipc	a2,0x4
ffffffffc02028e4:	3b860613          	addi	a2,a2,952 # ffffffffc0206c98 <commands+0x410>
ffffffffc02028e8:	04100593          	li	a1,65
ffffffffc02028ec:	00005517          	auipc	a0,0x5
ffffffffc02028f0:	d3450513          	addi	a0,a0,-716 # ffffffffc0207620 <commands+0xd98>
ffffffffc02028f4:	915fd0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(in_tick==0);
ffffffffc02028f8:	00005697          	auipc	a3,0x5
ffffffffc02028fc:	e8868693          	addi	a3,a3,-376 # ffffffffc0207780 <commands+0xef8>
ffffffffc0202900:	00004617          	auipc	a2,0x4
ffffffffc0202904:	39860613          	addi	a2,a2,920 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202908:	04200593          	li	a1,66
ffffffffc020290c:	00005517          	auipc	a0,0x5
ffffffffc0202910:	d1450513          	addi	a0,a0,-748 # ffffffffc0207620 <commands+0xd98>
ffffffffc0202914:	8f5fd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0202918 <_fifo_map_swappable>:
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc0202918:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc020291a:	cb91                	beqz	a5,ffffffffc020292e <_fifo_map_swappable+0x16>
    __list_add(elm, listelm->prev, listelm);
ffffffffc020291c:	6394                	ld	a3,0(a5)
ffffffffc020291e:	02860713          	addi	a4,a2,40
    prev->next = next->prev = elm;
ffffffffc0202922:	e398                	sd	a4,0(a5)
ffffffffc0202924:	e698                	sd	a4,8(a3)
}
ffffffffc0202926:	4501                	li	a0,0
    elm->next = next;
ffffffffc0202928:	fa1c                	sd	a5,48(a2)
    elm->prev = prev;
ffffffffc020292a:	f614                	sd	a3,40(a2)
ffffffffc020292c:	8082                	ret
{
ffffffffc020292e:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc0202930:	00005697          	auipc	a3,0x5
ffffffffc0202934:	e6068693          	addi	a3,a3,-416 # ffffffffc0207790 <commands+0xf08>
ffffffffc0202938:	00004617          	auipc	a2,0x4
ffffffffc020293c:	36060613          	addi	a2,a2,864 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202940:	03200593          	li	a1,50
ffffffffc0202944:	00005517          	auipc	a0,0x5
ffffffffc0202948:	cdc50513          	addi	a0,a0,-804 # ffffffffc0207620 <commands+0xd98>
{
ffffffffc020294c:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc020294e:	8bbfd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0202952 <check_vma_overlap.part.0>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0202952:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202954:	00005697          	auipc	a3,0x5
ffffffffc0202958:	e7468693          	addi	a3,a3,-396 # ffffffffc02077c8 <commands+0xf40>
ffffffffc020295c:	00004617          	auipc	a2,0x4
ffffffffc0202960:	33c60613          	addi	a2,a2,828 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202964:	06d00593          	li	a1,109
ffffffffc0202968:	00005517          	auipc	a0,0x5
ffffffffc020296c:	e8050513          	addi	a0,a0,-384 # ffffffffc02077e8 <commands+0xf60>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0202970:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0202972:	897fd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0202976 <mm_create>:
mm_create(void) {
ffffffffc0202976:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202978:	04000513          	li	a0,64
mm_create(void) {
ffffffffc020297c:	e022                	sd	s0,0(sp)
ffffffffc020297e:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202980:	4a9000ef          	jal	ra,ffffffffc0203628 <kmalloc>
ffffffffc0202984:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0202986:	c505                	beqz	a0,ffffffffc02029ae <mm_create+0x38>
    elm->prev = elm->next = elm;
ffffffffc0202988:	e408                	sd	a0,8(s0)
ffffffffc020298a:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc020298c:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202990:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202994:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0202998:	000b0797          	auipc	a5,0xb0
ffffffffc020299c:	f107a783          	lw	a5,-240(a5) # ffffffffc02b28a8 <swap_init_ok>
ffffffffc02029a0:	ef81                	bnez	a5,ffffffffc02029b8 <mm_create+0x42>
        else mm->sm_priv = NULL;
ffffffffc02029a2:	02053423          	sd	zero,40(a0)
    return mm->mm_count;
}

static inline void
set_mm_count(struct mm_struct *mm, int val) {
    mm->mm_count = val;
ffffffffc02029a6:	02042823          	sw	zero,48(s0)

typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock) {
    *lock = 0;
ffffffffc02029aa:	02043c23          	sd	zero,56(s0)
}
ffffffffc02029ae:	60a2                	ld	ra,8(sp)
ffffffffc02029b0:	8522                	mv	a0,s0
ffffffffc02029b2:	6402                	ld	s0,0(sp)
ffffffffc02029b4:	0141                	addi	sp,sp,16
ffffffffc02029b6:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02029b8:	57c010ef          	jal	ra,ffffffffc0203f34 <swap_init_mm>
ffffffffc02029bc:	b7ed                	j	ffffffffc02029a6 <mm_create+0x30>

ffffffffc02029be <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc02029be:	1101                	addi	sp,sp,-32
ffffffffc02029c0:	e04a                	sd	s2,0(sp)
ffffffffc02029c2:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02029c4:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc02029c8:	e822                	sd	s0,16(sp)
ffffffffc02029ca:	e426                	sd	s1,8(sp)
ffffffffc02029cc:	ec06                	sd	ra,24(sp)
ffffffffc02029ce:	84ae                	mv	s1,a1
ffffffffc02029d0:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02029d2:	457000ef          	jal	ra,ffffffffc0203628 <kmalloc>
    if (vma != NULL) {
ffffffffc02029d6:	c509                	beqz	a0,ffffffffc02029e0 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc02029d8:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc02029dc:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02029de:	cd00                	sw	s0,24(a0)
}
ffffffffc02029e0:	60e2                	ld	ra,24(sp)
ffffffffc02029e2:	6442                	ld	s0,16(sp)
ffffffffc02029e4:	64a2                	ld	s1,8(sp)
ffffffffc02029e6:	6902                	ld	s2,0(sp)
ffffffffc02029e8:	6105                	addi	sp,sp,32
ffffffffc02029ea:	8082                	ret

ffffffffc02029ec <find_vma>:
find_vma(struct mm_struct *mm, uintptr_t addr) {
ffffffffc02029ec:	86aa                	mv	a3,a0
    if (mm != NULL) {
ffffffffc02029ee:	c505                	beqz	a0,ffffffffc0202a16 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02029f0:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc02029f2:	c501                	beqz	a0,ffffffffc02029fa <find_vma+0xe>
ffffffffc02029f4:	651c                	ld	a5,8(a0)
ffffffffc02029f6:	02f5f263          	bgeu	a1,a5,ffffffffc0202a1a <find_vma+0x2e>
    return listelm->next;
ffffffffc02029fa:	669c                	ld	a5,8(a3)
                while ((le = list_next(le)) != list) {
ffffffffc02029fc:	00f68d63          	beq	a3,a5,ffffffffc0202a16 <find_vma+0x2a>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc0202a00:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202a04:	00e5e663          	bltu	a1,a4,ffffffffc0202a10 <find_vma+0x24>
ffffffffc0202a08:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202a0c:	00e5ec63          	bltu	a1,a4,ffffffffc0202a24 <find_vma+0x38>
ffffffffc0202a10:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc0202a12:	fef697e3          	bne	a3,a5,ffffffffc0202a00 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0202a16:	4501                	li	a0,0
}
ffffffffc0202a18:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0202a1a:	691c                	ld	a5,16(a0)
ffffffffc0202a1c:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02029fa <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0202a20:	ea88                	sd	a0,16(a3)
ffffffffc0202a22:	8082                	ret
                    vma = le2vma(le, list_link);
ffffffffc0202a24:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0202a28:	ea88                	sd	a0,16(a3)
ffffffffc0202a2a:	8082                	ret

ffffffffc0202a2c <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202a2c:	6590                	ld	a2,8(a1)
ffffffffc0202a2e:	0105b803          	ld	a6,16(a1)
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc0202a32:	1141                	addi	sp,sp,-16
ffffffffc0202a34:	e406                	sd	ra,8(sp)
ffffffffc0202a36:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202a38:	01066763          	bltu	a2,a6,ffffffffc0202a46 <insert_vma_struct+0x1a>
ffffffffc0202a3c:	a085                	j	ffffffffc0202a9c <insert_vma_struct+0x70>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0202a3e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202a42:	04e66863          	bltu	a2,a4,ffffffffc0202a92 <insert_vma_struct+0x66>
ffffffffc0202a46:	86be                	mv	a3,a5
ffffffffc0202a48:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0202a4a:	fef51ae3          	bne	a0,a5,ffffffffc0202a3e <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc0202a4e:	02a68463          	beq	a3,a0,ffffffffc0202a76 <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202a52:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202a56:	fe86b883          	ld	a7,-24(a3)
ffffffffc0202a5a:	08e8f163          	bgeu	a7,a4,ffffffffc0202adc <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202a5e:	04e66f63          	bltu	a2,a4,ffffffffc0202abc <insert_vma_struct+0x90>
    }
    if (le_next != list) {
ffffffffc0202a62:	00f50a63          	beq	a0,a5,ffffffffc0202a76 <insert_vma_struct+0x4a>
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0202a66:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202a6a:	05076963          	bltu	a4,a6,ffffffffc0202abc <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0202a6e:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202a72:	02c77363          	bgeu	a4,a2,ffffffffc0202a98 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc0202a76:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0202a78:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0202a7a:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0202a7e:	e390                	sd	a2,0(a5)
ffffffffc0202a80:	e690                	sd	a2,8(a3)
}
ffffffffc0202a82:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0202a84:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0202a86:	f194                	sd	a3,32(a1)
    mm->map_count ++;
ffffffffc0202a88:	0017079b          	addiw	a5,a4,1
ffffffffc0202a8c:	d11c                	sw	a5,32(a0)
}
ffffffffc0202a8e:	0141                	addi	sp,sp,16
ffffffffc0202a90:	8082                	ret
    if (le_prev != list) {
ffffffffc0202a92:	fca690e3          	bne	a3,a0,ffffffffc0202a52 <insert_vma_struct+0x26>
ffffffffc0202a96:	bfd1                	j	ffffffffc0202a6a <insert_vma_struct+0x3e>
ffffffffc0202a98:	ebbff0ef          	jal	ra,ffffffffc0202952 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202a9c:	00005697          	auipc	a3,0x5
ffffffffc0202aa0:	d5c68693          	addi	a3,a3,-676 # ffffffffc02077f8 <commands+0xf70>
ffffffffc0202aa4:	00004617          	auipc	a2,0x4
ffffffffc0202aa8:	1f460613          	addi	a2,a2,500 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202aac:	07400593          	li	a1,116
ffffffffc0202ab0:	00005517          	auipc	a0,0x5
ffffffffc0202ab4:	d3850513          	addi	a0,a0,-712 # ffffffffc02077e8 <commands+0xf60>
ffffffffc0202ab8:	f50fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202abc:	00005697          	auipc	a3,0x5
ffffffffc0202ac0:	d7c68693          	addi	a3,a3,-644 # ffffffffc0207838 <commands+0xfb0>
ffffffffc0202ac4:	00004617          	auipc	a2,0x4
ffffffffc0202ac8:	1d460613          	addi	a2,a2,468 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202acc:	06c00593          	li	a1,108
ffffffffc0202ad0:	00005517          	auipc	a0,0x5
ffffffffc0202ad4:	d1850513          	addi	a0,a0,-744 # ffffffffc02077e8 <commands+0xf60>
ffffffffc0202ad8:	f30fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202adc:	00005697          	auipc	a3,0x5
ffffffffc0202ae0:	d3c68693          	addi	a3,a3,-708 # ffffffffc0207818 <commands+0xf90>
ffffffffc0202ae4:	00004617          	auipc	a2,0x4
ffffffffc0202ae8:	1b460613          	addi	a2,a2,436 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202aec:	06b00593          	li	a1,107
ffffffffc0202af0:	00005517          	auipc	a0,0x5
ffffffffc0202af4:	cf850513          	addi	a0,a0,-776 # ffffffffc02077e8 <commands+0xf60>
ffffffffc0202af8:	f10fd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0202afc <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
    assert(mm_count(mm) == 0);
ffffffffc0202afc:	591c                	lw	a5,48(a0)
mm_destroy(struct mm_struct *mm) {
ffffffffc0202afe:	1141                	addi	sp,sp,-16
ffffffffc0202b00:	e406                	sd	ra,8(sp)
ffffffffc0202b02:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0202b04:	e78d                	bnez	a5,ffffffffc0202b2e <mm_destroy+0x32>
ffffffffc0202b06:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0202b08:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc0202b0a:	00a40c63          	beq	s0,a0,ffffffffc0202b22 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0202b0e:	6118                	ld	a4,0(a0)
ffffffffc0202b10:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc0202b12:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0202b14:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0202b16:	e398                	sd	a4,0(a5)
ffffffffc0202b18:	3c1000ef          	jal	ra,ffffffffc02036d8 <kfree>
    return listelm->next;
ffffffffc0202b1c:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0202b1e:	fea418e3          	bne	s0,a0,ffffffffc0202b0e <mm_destroy+0x12>
    }
    kfree(mm); //kfree mm
ffffffffc0202b22:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc0202b24:	6402                	ld	s0,0(sp)
ffffffffc0202b26:	60a2                	ld	ra,8(sp)
ffffffffc0202b28:	0141                	addi	sp,sp,16
    kfree(mm); //kfree mm
ffffffffc0202b2a:	3af0006f          	j	ffffffffc02036d8 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0202b2e:	00005697          	auipc	a3,0x5
ffffffffc0202b32:	d2a68693          	addi	a3,a3,-726 # ffffffffc0207858 <commands+0xfd0>
ffffffffc0202b36:	00004617          	auipc	a2,0x4
ffffffffc0202b3a:	16260613          	addi	a2,a2,354 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202b3e:	09400593          	li	a1,148
ffffffffc0202b42:	00005517          	auipc	a0,0x5
ffffffffc0202b46:	ca650513          	addi	a0,a0,-858 # ffffffffc02077e8 <commands+0xf60>
ffffffffc0202b4a:	ebefd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0202b4e <mm_map>:

int
mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
       struct vma_struct **vma_store) {
ffffffffc0202b4e:	7139                	addi	sp,sp,-64
ffffffffc0202b50:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0202b52:	6405                	lui	s0,0x1
ffffffffc0202b54:	147d                	addi	s0,s0,-1
ffffffffc0202b56:	77fd                	lui	a5,0xfffff
ffffffffc0202b58:	9622                	add	a2,a2,s0
ffffffffc0202b5a:	962e                	add	a2,a2,a1
       struct vma_struct **vma_store) {
ffffffffc0202b5c:	f426                	sd	s1,40(sp)
ffffffffc0202b5e:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0202b60:	00f5f4b3          	and	s1,a1,a5
       struct vma_struct **vma_store) {
ffffffffc0202b64:	f04a                	sd	s2,32(sp)
ffffffffc0202b66:	ec4e                	sd	s3,24(sp)
ffffffffc0202b68:	e852                	sd	s4,16(sp)
ffffffffc0202b6a:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end)) {
ffffffffc0202b6c:	002005b7          	lui	a1,0x200
ffffffffc0202b70:	00f67433          	and	s0,a2,a5
ffffffffc0202b74:	06b4e363          	bltu	s1,a1,ffffffffc0202bda <mm_map+0x8c>
ffffffffc0202b78:	0684f163          	bgeu	s1,s0,ffffffffc0202bda <mm_map+0x8c>
ffffffffc0202b7c:	4785                	li	a5,1
ffffffffc0202b7e:	07fe                	slli	a5,a5,0x1f
ffffffffc0202b80:	0487ed63          	bltu	a5,s0,ffffffffc0202bda <mm_map+0x8c>
ffffffffc0202b84:	89aa                	mv	s3,a0
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0202b86:	cd21                	beqz	a0,ffffffffc0202bde <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start) {
ffffffffc0202b88:	85a6                	mv	a1,s1
ffffffffc0202b8a:	8ab6                	mv	s5,a3
ffffffffc0202b8c:	8a3a                	mv	s4,a4
ffffffffc0202b8e:	e5fff0ef          	jal	ra,ffffffffc02029ec <find_vma>
ffffffffc0202b92:	c501                	beqz	a0,ffffffffc0202b9a <mm_map+0x4c>
ffffffffc0202b94:	651c                	ld	a5,8(a0)
ffffffffc0202b96:	0487e263          	bltu	a5,s0,ffffffffc0202bda <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202b9a:	03000513          	li	a0,48
ffffffffc0202b9e:	28b000ef          	jal	ra,ffffffffc0203628 <kmalloc>
ffffffffc0202ba2:	892a                	mv	s2,a0
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0202ba4:	5571                	li	a0,-4
    if (vma != NULL) {
ffffffffc0202ba6:	02090163          	beqz	s2,ffffffffc0202bc8 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL) {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0202baa:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc0202bac:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc0202bb0:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0202bb4:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0202bb8:	85ca                	mv	a1,s2
ffffffffc0202bba:	e73ff0ef          	jal	ra,ffffffffc0202a2c <insert_vma_struct>
    if (vma_store != NULL) {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0202bbe:	4501                	li	a0,0
    if (vma_store != NULL) {
ffffffffc0202bc0:	000a0463          	beqz	s4,ffffffffc0202bc8 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc0202bc4:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc0202bc8:	70e2                	ld	ra,56(sp)
ffffffffc0202bca:	7442                	ld	s0,48(sp)
ffffffffc0202bcc:	74a2                	ld	s1,40(sp)
ffffffffc0202bce:	7902                	ld	s2,32(sp)
ffffffffc0202bd0:	69e2                	ld	s3,24(sp)
ffffffffc0202bd2:	6a42                	ld	s4,16(sp)
ffffffffc0202bd4:	6aa2                	ld	s5,8(sp)
ffffffffc0202bd6:	6121                	addi	sp,sp,64
ffffffffc0202bd8:	8082                	ret
        return -E_INVAL;
ffffffffc0202bda:	5575                	li	a0,-3
ffffffffc0202bdc:	b7f5                	j	ffffffffc0202bc8 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc0202bde:	00005697          	auipc	a3,0x5
ffffffffc0202be2:	c9268693          	addi	a3,a3,-878 # ffffffffc0207870 <commands+0xfe8>
ffffffffc0202be6:	00004617          	auipc	a2,0x4
ffffffffc0202bea:	0b260613          	addi	a2,a2,178 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202bee:	0a700593          	li	a1,167
ffffffffc0202bf2:	00005517          	auipc	a0,0x5
ffffffffc0202bf6:	bf650513          	addi	a0,a0,-1034 # ffffffffc02077e8 <commands+0xf60>
ffffffffc0202bfa:	e0efd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0202bfe <dup_mmap>:

int
dup_mmap(struct mm_struct *to, struct mm_struct *from) {
ffffffffc0202bfe:	7139                	addi	sp,sp,-64
ffffffffc0202c00:	fc06                	sd	ra,56(sp)
ffffffffc0202c02:	f822                	sd	s0,48(sp)
ffffffffc0202c04:	f426                	sd	s1,40(sp)
ffffffffc0202c06:	f04a                	sd	s2,32(sp)
ffffffffc0202c08:	ec4e                	sd	s3,24(sp)
ffffffffc0202c0a:	e852                	sd	s4,16(sp)
ffffffffc0202c0c:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0202c0e:	c52d                	beqz	a0,ffffffffc0202c78 <dup_mmap+0x7a>
ffffffffc0202c10:	892a                	mv	s2,a0
ffffffffc0202c12:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0202c14:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0202c16:	e595                	bnez	a1,ffffffffc0202c42 <dup_mmap+0x44>
ffffffffc0202c18:	a085                	j	ffffffffc0202c78 <dup_mmap+0x7a>
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL) {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0202c1a:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc0202c1c:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ee0>
        vma->vm_end = vm_end;
ffffffffc0202c20:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0202c24:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0202c28:	e05ff0ef          	jal	ra,ffffffffc0202a2c <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0) {
ffffffffc0202c2c:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bc8>
ffffffffc0202c30:	fe843603          	ld	a2,-24(s0)
ffffffffc0202c34:	6c8c                	ld	a1,24(s1)
ffffffffc0202c36:	01893503          	ld	a0,24(s2)
ffffffffc0202c3a:	4701                	li	a4,0
ffffffffc0202c3c:	e54ff0ef          	jal	ra,ffffffffc0202290 <copy_range>
ffffffffc0202c40:	e105                	bnez	a0,ffffffffc0202c60 <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0202c42:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list) {
ffffffffc0202c44:	02848863          	beq	s1,s0,ffffffffc0202c74 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202c48:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0202c4c:	fe843a83          	ld	s5,-24(s0)
ffffffffc0202c50:	ff043a03          	ld	s4,-16(s0)
ffffffffc0202c54:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202c58:	1d1000ef          	jal	ra,ffffffffc0203628 <kmalloc>
ffffffffc0202c5c:	85aa                	mv	a1,a0
    if (vma != NULL) {
ffffffffc0202c5e:	fd55                	bnez	a0,ffffffffc0202c1a <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0202c60:	5571                	li	a0,-4
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0202c62:	70e2                	ld	ra,56(sp)
ffffffffc0202c64:	7442                	ld	s0,48(sp)
ffffffffc0202c66:	74a2                	ld	s1,40(sp)
ffffffffc0202c68:	7902                	ld	s2,32(sp)
ffffffffc0202c6a:	69e2                	ld	s3,24(sp)
ffffffffc0202c6c:	6a42                	ld	s4,16(sp)
ffffffffc0202c6e:	6aa2                	ld	s5,8(sp)
ffffffffc0202c70:	6121                	addi	sp,sp,64
ffffffffc0202c72:	8082                	ret
    return 0;
ffffffffc0202c74:	4501                	li	a0,0
ffffffffc0202c76:	b7f5                	j	ffffffffc0202c62 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0202c78:	00005697          	auipc	a3,0x5
ffffffffc0202c7c:	c0868693          	addi	a3,a3,-1016 # ffffffffc0207880 <commands+0xff8>
ffffffffc0202c80:	00004617          	auipc	a2,0x4
ffffffffc0202c84:	01860613          	addi	a2,a2,24 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202c88:	0c000593          	li	a1,192
ffffffffc0202c8c:	00005517          	auipc	a0,0x5
ffffffffc0202c90:	b5c50513          	addi	a0,a0,-1188 # ffffffffc02077e8 <commands+0xf60>
ffffffffc0202c94:	d74fd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0202c98 <exit_mmap>:

void
exit_mmap(struct mm_struct *mm) {
ffffffffc0202c98:	1101                	addi	sp,sp,-32
ffffffffc0202c9a:	ec06                	sd	ra,24(sp)
ffffffffc0202c9c:	e822                	sd	s0,16(sp)
ffffffffc0202c9e:	e426                	sd	s1,8(sp)
ffffffffc0202ca0:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0202ca2:	c531                	beqz	a0,ffffffffc0202cee <exit_mmap+0x56>
ffffffffc0202ca4:	591c                	lw	a5,48(a0)
ffffffffc0202ca6:	84aa                	mv	s1,a0
ffffffffc0202ca8:	e3b9                	bnez	a5,ffffffffc0202cee <exit_mmap+0x56>
    return listelm->next;
ffffffffc0202caa:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0202cac:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list) {
ffffffffc0202cb0:	02850663          	beq	a0,s0,ffffffffc0202cdc <exit_mmap+0x44>
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0202cb4:	ff043603          	ld	a2,-16(s0)
ffffffffc0202cb8:	fe843583          	ld	a1,-24(s0)
ffffffffc0202cbc:	854a                	mv	a0,s2
ffffffffc0202cbe:	ccefe0ef          	jal	ra,ffffffffc020118c <unmap_range>
ffffffffc0202cc2:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc0202cc4:	fe8498e3          	bne	s1,s0,ffffffffc0202cb4 <exit_mmap+0x1c>
ffffffffc0202cc8:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list) {
ffffffffc0202cca:	00848c63          	beq	s1,s0,ffffffffc0202ce2 <exit_mmap+0x4a>
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0202cce:	ff043603          	ld	a2,-16(s0)
ffffffffc0202cd2:	fe843583          	ld	a1,-24(s0)
ffffffffc0202cd6:	854a                	mv	a0,s2
ffffffffc0202cd8:	dfafe0ef          	jal	ra,ffffffffc02012d2 <exit_range>
ffffffffc0202cdc:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc0202cde:	fe8498e3          	bne	s1,s0,ffffffffc0202cce <exit_mmap+0x36>
    }
}
ffffffffc0202ce2:	60e2                	ld	ra,24(sp)
ffffffffc0202ce4:	6442                	ld	s0,16(sp)
ffffffffc0202ce6:	64a2                	ld	s1,8(sp)
ffffffffc0202ce8:	6902                	ld	s2,0(sp)
ffffffffc0202cea:	6105                	addi	sp,sp,32
ffffffffc0202cec:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0202cee:	00005697          	auipc	a3,0x5
ffffffffc0202cf2:	bb268693          	addi	a3,a3,-1102 # ffffffffc02078a0 <commands+0x1018>
ffffffffc0202cf6:	00004617          	auipc	a2,0x4
ffffffffc0202cfa:	fa260613          	addi	a2,a2,-94 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202cfe:	0d600593          	li	a1,214
ffffffffc0202d02:	00005517          	auipc	a0,0x5
ffffffffc0202d06:	ae650513          	addi	a0,a0,-1306 # ffffffffc02077e8 <commands+0xf60>
ffffffffc0202d0a:	cfefd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0202d0e <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc0202d0e:	7139                	addi	sp,sp,-64
ffffffffc0202d10:	f822                	sd	s0,48(sp)
ffffffffc0202d12:	f426                	sd	s1,40(sp)
ffffffffc0202d14:	fc06                	sd	ra,56(sp)
ffffffffc0202d16:	f04a                	sd	s2,32(sp)
ffffffffc0202d18:	ec4e                	sd	s3,24(sp)
ffffffffc0202d1a:	e852                	sd	s4,16(sp)
ffffffffc0202d1c:	e456                	sd	s5,8(sp)

static void
check_vma_struct(void) {
    // size_t nr_free_pages_store = nr_free_pages();

    struct mm_struct *mm = mm_create();
ffffffffc0202d1e:	c59ff0ef          	jal	ra,ffffffffc0202976 <mm_create>
    assert(mm != NULL);
ffffffffc0202d22:	84aa                	mv	s1,a0
ffffffffc0202d24:	03200413          	li	s0,50
ffffffffc0202d28:	e919                	bnez	a0,ffffffffc0202d3e <vmm_init+0x30>
ffffffffc0202d2a:	a991                	j	ffffffffc020317e <vmm_init+0x470>
        vma->vm_start = vm_start;
ffffffffc0202d2c:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202d2e:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202d30:	00052c23          	sw	zero,24(a0)

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i --) {
ffffffffc0202d34:	146d                	addi	s0,s0,-5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202d36:	8526                	mv	a0,s1
ffffffffc0202d38:	cf5ff0ef          	jal	ra,ffffffffc0202a2c <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc0202d3c:	c80d                	beqz	s0,ffffffffc0202d6e <vmm_init+0x60>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202d3e:	03000513          	li	a0,48
ffffffffc0202d42:	0e7000ef          	jal	ra,ffffffffc0203628 <kmalloc>
ffffffffc0202d46:	85aa                	mv	a1,a0
ffffffffc0202d48:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc0202d4c:	f165                	bnez	a0,ffffffffc0202d2c <vmm_init+0x1e>
        assert(vma != NULL);
ffffffffc0202d4e:	00005697          	auipc	a3,0x5
ffffffffc0202d52:	d8a68693          	addi	a3,a3,-630 # ffffffffc0207ad8 <commands+0x1250>
ffffffffc0202d56:	00004617          	auipc	a2,0x4
ffffffffc0202d5a:	f4260613          	addi	a2,a2,-190 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202d5e:	11300593          	li	a1,275
ffffffffc0202d62:	00005517          	auipc	a0,0x5
ffffffffc0202d66:	a8650513          	addi	a0,a0,-1402 # ffffffffc02077e8 <commands+0xf60>
ffffffffc0202d6a:	c9efd0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0202d6e:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0202d72:	1f900913          	li	s2,505
ffffffffc0202d76:	a819                	j	ffffffffc0202d8c <vmm_init+0x7e>
        vma->vm_start = vm_start;
ffffffffc0202d78:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202d7a:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202d7c:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0202d80:	0415                	addi	s0,s0,5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202d82:	8526                	mv	a0,s1
ffffffffc0202d84:	ca9ff0ef          	jal	ra,ffffffffc0202a2c <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0202d88:	03240a63          	beq	s0,s2,ffffffffc0202dbc <vmm_init+0xae>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202d8c:	03000513          	li	a0,48
ffffffffc0202d90:	099000ef          	jal	ra,ffffffffc0203628 <kmalloc>
ffffffffc0202d94:	85aa                	mv	a1,a0
ffffffffc0202d96:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc0202d9a:	fd79                	bnez	a0,ffffffffc0202d78 <vmm_init+0x6a>
        assert(vma != NULL);
ffffffffc0202d9c:	00005697          	auipc	a3,0x5
ffffffffc0202da0:	d3c68693          	addi	a3,a3,-708 # ffffffffc0207ad8 <commands+0x1250>
ffffffffc0202da4:	00004617          	auipc	a2,0x4
ffffffffc0202da8:	ef460613          	addi	a2,a2,-268 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202dac:	11900593          	li	a1,281
ffffffffc0202db0:	00005517          	auipc	a0,0x5
ffffffffc0202db4:	a3850513          	addi	a0,a0,-1480 # ffffffffc02077e8 <commands+0xf60>
ffffffffc0202db8:	c50fd0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0202dbc:	649c                	ld	a5,8(s1)
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
        assert(le != &(mm->mmap_list));
ffffffffc0202dbe:	471d                	li	a4,7
    for (i = 1; i <= step2; i ++) {
ffffffffc0202dc0:	1fb00593          	li	a1,507
        assert(le != &(mm->mmap_list));
ffffffffc0202dc4:	2cf48d63          	beq	s1,a5,ffffffffc020309e <vmm_init+0x390>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202dc8:	fe87b683          	ld	a3,-24(a5) # ffffffffffffefe8 <end+0x3fd4c71c>
ffffffffc0202dcc:	ffe70613          	addi	a2,a4,-2
ffffffffc0202dd0:	24d61763          	bne	a2,a3,ffffffffc020301e <vmm_init+0x310>
ffffffffc0202dd4:	ff07b683          	ld	a3,-16(a5)
ffffffffc0202dd8:	24e69363          	bne	a3,a4,ffffffffc020301e <vmm_init+0x310>
    for (i = 1; i <= step2; i ++) {
ffffffffc0202ddc:	0715                	addi	a4,a4,5
ffffffffc0202dde:	679c                	ld	a5,8(a5)
ffffffffc0202de0:	feb712e3          	bne	a4,a1,ffffffffc0202dc4 <vmm_init+0xb6>
ffffffffc0202de4:	4a1d                	li	s4,7
ffffffffc0202de6:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0202de8:	1f900a93          	li	s5,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202dec:	85a2                	mv	a1,s0
ffffffffc0202dee:	8526                	mv	a0,s1
ffffffffc0202df0:	bfdff0ef          	jal	ra,ffffffffc02029ec <find_vma>
ffffffffc0202df4:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0202df6:	30050463          	beqz	a0,ffffffffc02030fe <vmm_init+0x3f0>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc0202dfa:	00140593          	addi	a1,s0,1
ffffffffc0202dfe:	8526                	mv	a0,s1
ffffffffc0202e00:	bedff0ef          	jal	ra,ffffffffc02029ec <find_vma>
ffffffffc0202e04:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0202e06:	2c050c63          	beqz	a0,ffffffffc02030de <vmm_init+0x3d0>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc0202e0a:	85d2                	mv	a1,s4
ffffffffc0202e0c:	8526                	mv	a0,s1
ffffffffc0202e0e:	bdfff0ef          	jal	ra,ffffffffc02029ec <find_vma>
        assert(vma3 == NULL);
ffffffffc0202e12:	2a051663          	bnez	a0,ffffffffc02030be <vmm_init+0x3b0>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc0202e16:	00340593          	addi	a1,s0,3
ffffffffc0202e1a:	8526                	mv	a0,s1
ffffffffc0202e1c:	bd1ff0ef          	jal	ra,ffffffffc02029ec <find_vma>
        assert(vma4 == NULL);
ffffffffc0202e20:	30051f63          	bnez	a0,ffffffffc020313e <vmm_init+0x430>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc0202e24:	00440593          	addi	a1,s0,4
ffffffffc0202e28:	8526                	mv	a0,s1
ffffffffc0202e2a:	bc3ff0ef          	jal	ra,ffffffffc02029ec <find_vma>
        assert(vma5 == NULL);
ffffffffc0202e2e:	2e051863          	bnez	a0,ffffffffc020311e <vmm_init+0x410>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0202e32:	00893783          	ld	a5,8(s2)
ffffffffc0202e36:	20879463          	bne	a5,s0,ffffffffc020303e <vmm_init+0x330>
ffffffffc0202e3a:	01093783          	ld	a5,16(s2)
ffffffffc0202e3e:	20fa1063          	bne	s4,a5,ffffffffc020303e <vmm_init+0x330>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0202e42:	0089b783          	ld	a5,8(s3)
ffffffffc0202e46:	20879c63          	bne	a5,s0,ffffffffc020305e <vmm_init+0x350>
ffffffffc0202e4a:	0109b783          	ld	a5,16(s3)
ffffffffc0202e4e:	20fa1863          	bne	s4,a5,ffffffffc020305e <vmm_init+0x350>
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0202e52:	0415                	addi	s0,s0,5
ffffffffc0202e54:	0a15                	addi	s4,s4,5
ffffffffc0202e56:	f9541be3          	bne	s0,s5,ffffffffc0202dec <vmm_init+0xde>
ffffffffc0202e5a:	4411                	li	s0,4
    }

    for (i =4; i>=0; i--) {
ffffffffc0202e5c:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc0202e5e:	85a2                	mv	a1,s0
ffffffffc0202e60:	8526                	mv	a0,s1
ffffffffc0202e62:	b8bff0ef          	jal	ra,ffffffffc02029ec <find_vma>
ffffffffc0202e66:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL ) {
ffffffffc0202e6a:	c90d                	beqz	a0,ffffffffc0202e9c <vmm_init+0x18e>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0202e6c:	6914                	ld	a3,16(a0)
ffffffffc0202e6e:	6510                	ld	a2,8(a0)
ffffffffc0202e70:	00005517          	auipc	a0,0x5
ffffffffc0202e74:	b5050513          	addi	a0,a0,-1200 # ffffffffc02079c0 <commands+0x1138>
ffffffffc0202e78:	a54fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0202e7c:	00005697          	auipc	a3,0x5
ffffffffc0202e80:	b6c68693          	addi	a3,a3,-1172 # ffffffffc02079e8 <commands+0x1160>
ffffffffc0202e84:	00004617          	auipc	a2,0x4
ffffffffc0202e88:	e1460613          	addi	a2,a2,-492 # ffffffffc0206c98 <commands+0x410>
ffffffffc0202e8c:	13b00593          	li	a1,315
ffffffffc0202e90:	00005517          	auipc	a0,0x5
ffffffffc0202e94:	95850513          	addi	a0,a0,-1704 # ffffffffc02077e8 <commands+0xf60>
ffffffffc0202e98:	b70fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    for (i =4; i>=0; i--) {
ffffffffc0202e9c:	147d                	addi	s0,s0,-1
ffffffffc0202e9e:	fd2410e3          	bne	s0,s2,ffffffffc0202e5e <vmm_init+0x150>
    }

    mm_destroy(mm);
ffffffffc0202ea2:	8526                	mv	a0,s1
ffffffffc0202ea4:	c59ff0ef          	jal	ra,ffffffffc0202afc <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0202ea8:	00005517          	auipc	a0,0x5
ffffffffc0202eac:	b5850513          	addi	a0,a0,-1192 # ffffffffc0207a00 <commands+0x1178>
ffffffffc0202eb0:	a1cfd0ef          	jal	ra,ffffffffc02000cc <cprintf>
struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0202eb4:	878fe0ef          	jal	ra,ffffffffc0200f2c <nr_free_pages>
ffffffffc0202eb8:	892a                	mv	s2,a0

    check_mm_struct = mm_create();
ffffffffc0202eba:	abdff0ef          	jal	ra,ffffffffc0202976 <mm_create>
ffffffffc0202ebe:	000b0797          	auipc	a5,0xb0
ffffffffc0202ec2:	9ca7b123          	sd	a0,-1598(a5) # ffffffffc02b2880 <check_mm_struct>
ffffffffc0202ec6:	842a                	mv	s0,a0
    assert(check_mm_struct != NULL);
ffffffffc0202ec8:	28050b63          	beqz	a0,ffffffffc020315e <vmm_init+0x450>

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202ecc:	000b0497          	auipc	s1,0xb0
ffffffffc0202ed0:	98c4b483          	ld	s1,-1652(s1) # ffffffffc02b2858 <boot_pgdir>
    assert(pgdir[0] == 0);
ffffffffc0202ed4:	609c                	ld	a5,0(s1)
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202ed6:	ed04                	sd	s1,24(a0)
    assert(pgdir[0] == 0);
ffffffffc0202ed8:	2e079f63          	bnez	a5,ffffffffc02031d6 <vmm_init+0x4c8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202edc:	03000513          	li	a0,48
ffffffffc0202ee0:	748000ef          	jal	ra,ffffffffc0203628 <kmalloc>
ffffffffc0202ee4:	89aa                	mv	s3,a0
    if (vma != NULL) {
ffffffffc0202ee6:	18050c63          	beqz	a0,ffffffffc020307e <vmm_init+0x370>
        vma->vm_end = vm_end;
ffffffffc0202eea:	002007b7          	lui	a5,0x200
ffffffffc0202eee:	00f9b823          	sd	a5,16(s3)
        vma->vm_flags = vm_flags;
ffffffffc0202ef2:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0202ef4:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc0202ef6:	00f9ac23          	sw	a5,24(s3)
    insert_vma_struct(mm, vma);
ffffffffc0202efa:	8522                	mv	a0,s0
        vma->vm_start = vm_start;
ffffffffc0202efc:	0009b423          	sd	zero,8(s3)
    insert_vma_struct(mm, vma);
ffffffffc0202f00:	b2dff0ef          	jal	ra,ffffffffc0202a2c <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc0202f04:	10000593          	li	a1,256
ffffffffc0202f08:	8522                	mv	a0,s0
ffffffffc0202f0a:	ae3ff0ef          	jal	ra,ffffffffc02029ec <find_vma>
ffffffffc0202f0e:	10000793          	li	a5,256

    int i, sum = 0;

    for (i = 0; i < 100; i ++) {
ffffffffc0202f12:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc0202f16:	2ea99063          	bne	s3,a0,ffffffffc02031f6 <vmm_init+0x4e8>
        *(char *)(addr + i) = i;
ffffffffc0202f1a:	00f78023          	sb	a5,0(a5) # 200000 <_binary_obj___user_exit_out_size+0x1f4ed8>
    for (i = 0; i < 100; i ++) {
ffffffffc0202f1e:	0785                	addi	a5,a5,1
ffffffffc0202f20:	fee79de3          	bne	a5,a4,ffffffffc0202f1a <vmm_init+0x20c>
        sum += i;
ffffffffc0202f24:	6705                	lui	a4,0x1
ffffffffc0202f26:	10000793          	li	a5,256
ffffffffc0202f2a:	35670713          	addi	a4,a4,854 # 1356 <_binary_obj___user_faultread_out_size-0x8862>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc0202f2e:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc0202f32:	0007c683          	lbu	a3,0(a5)
    for (i = 0; i < 100; i ++) {
ffffffffc0202f36:	0785                	addi	a5,a5,1
        sum -= *(char *)(addr + i);
ffffffffc0202f38:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc0202f3a:	fec79ce3          	bne	a5,a2,ffffffffc0202f32 <vmm_init+0x224>
    }

    assert(sum == 0);
ffffffffc0202f3e:	2e071863          	bnez	a4,ffffffffc020322e <vmm_init+0x520>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202f42:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage) {
ffffffffc0202f44:	000b0a97          	auipc	s5,0xb0
ffffffffc0202f48:	91ca8a93          	addi	s5,s5,-1764 # ffffffffc02b2860 <npage>
ffffffffc0202f4c:	000ab603          	ld	a2,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202f50:	078a                	slli	a5,a5,0x2
ffffffffc0202f52:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202f54:	2cc7f163          	bgeu	a5,a2,ffffffffc0203216 <vmm_init+0x508>
    return &pages[PPN(pa) - nbase];
ffffffffc0202f58:	00006a17          	auipc	s4,0x6
ffffffffc0202f5c:	d98a3a03          	ld	s4,-616(s4) # ffffffffc0208cf0 <nbase>
ffffffffc0202f60:	414787b3          	sub	a5,a5,s4
ffffffffc0202f64:	079a                	slli	a5,a5,0x6
    return page - pages + nbase;
ffffffffc0202f66:	8799                	srai	a5,a5,0x6
ffffffffc0202f68:	97d2                	add	a5,a5,s4
    return KADDR(page2pa(page));
ffffffffc0202f6a:	00c79713          	slli	a4,a5,0xc
ffffffffc0202f6e:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202f70:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202f74:	24c77563          	bgeu	a4,a2,ffffffffc02031be <vmm_init+0x4b0>
ffffffffc0202f78:	000b0997          	auipc	s3,0xb0
ffffffffc0202f7c:	9009b983          	ld	s3,-1792(s3) # ffffffffc02b2878 <va_pa_offset>

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc0202f80:	4581                	li	a1,0
ffffffffc0202f82:	8526                	mv	a0,s1
ffffffffc0202f84:	99b6                	add	s3,s3,a3
ffffffffc0202f86:	ddefe0ef          	jal	ra,ffffffffc0201564 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202f8a:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc0202f8e:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202f92:	078a                	slli	a5,a5,0x2
ffffffffc0202f94:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202f96:	28e7f063          	bgeu	a5,a4,ffffffffc0203216 <vmm_init+0x508>
    return &pages[PPN(pa) - nbase];
ffffffffc0202f9a:	000b0997          	auipc	s3,0xb0
ffffffffc0202f9e:	8ce98993          	addi	s3,s3,-1842 # ffffffffc02b2868 <pages>
ffffffffc0202fa2:	0009b503          	ld	a0,0(s3)
ffffffffc0202fa6:	414787b3          	sub	a5,a5,s4
ffffffffc0202faa:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc0202fac:	953e                	add	a0,a0,a5
ffffffffc0202fae:	4585                	li	a1,1
ffffffffc0202fb0:	f3dfd0ef          	jal	ra,ffffffffc0200eec <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202fb4:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage) {
ffffffffc0202fb6:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202fba:	078a                	slli	a5,a5,0x2
ffffffffc0202fbc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202fbe:	24e7fc63          	bgeu	a5,a4,ffffffffc0203216 <vmm_init+0x508>
    return &pages[PPN(pa) - nbase];
ffffffffc0202fc2:	0009b503          	ld	a0,0(s3)
ffffffffc0202fc6:	414787b3          	sub	a5,a5,s4
ffffffffc0202fca:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc0202fcc:	4585                	li	a1,1
ffffffffc0202fce:	953e                	add	a0,a0,a5
ffffffffc0202fd0:	f1dfd0ef          	jal	ra,ffffffffc0200eec <free_pages>
    pgdir[0] = 0;
ffffffffc0202fd4:	0004b023          	sd	zero,0(s1)
  asm volatile("sfence.vma");
ffffffffc0202fd8:	12000073          	sfence.vma
    flush_tlb();

    mm->pgdir = NULL;
    mm_destroy(mm);
ffffffffc0202fdc:	8522                	mv	a0,s0
    mm->pgdir = NULL;
ffffffffc0202fde:	00043c23          	sd	zero,24(s0)
    mm_destroy(mm);
ffffffffc0202fe2:	b1bff0ef          	jal	ra,ffffffffc0202afc <mm_destroy>
    check_mm_struct = NULL;
ffffffffc0202fe6:	000b0797          	auipc	a5,0xb0
ffffffffc0202fea:	8807bd23          	sd	zero,-1894(a5) # ffffffffc02b2880 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0202fee:	f3ffd0ef          	jal	ra,ffffffffc0200f2c <nr_free_pages>
ffffffffc0202ff2:	1aa91663          	bne	s2,a0,ffffffffc020319e <vmm_init+0x490>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0202ff6:	00005517          	auipc	a0,0x5
ffffffffc0202ffa:	aaa50513          	addi	a0,a0,-1366 # ffffffffc0207aa0 <commands+0x1218>
ffffffffc0202ffe:	8cefd0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc0203002:	7442                	ld	s0,48(sp)
ffffffffc0203004:	70e2                	ld	ra,56(sp)
ffffffffc0203006:	74a2                	ld	s1,40(sp)
ffffffffc0203008:	7902                	ld	s2,32(sp)
ffffffffc020300a:	69e2                	ld	s3,24(sp)
ffffffffc020300c:	6a42                	ld	s4,16(sp)
ffffffffc020300e:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203010:	00005517          	auipc	a0,0x5
ffffffffc0203014:	ab050513          	addi	a0,a0,-1360 # ffffffffc0207ac0 <commands+0x1238>
}
ffffffffc0203018:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc020301a:	8b2fd06f          	j	ffffffffc02000cc <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc020301e:	00005697          	auipc	a3,0x5
ffffffffc0203022:	8ba68693          	addi	a3,a3,-1862 # ffffffffc02078d8 <commands+0x1050>
ffffffffc0203026:	00004617          	auipc	a2,0x4
ffffffffc020302a:	c7260613          	addi	a2,a2,-910 # ffffffffc0206c98 <commands+0x410>
ffffffffc020302e:	12200593          	li	a1,290
ffffffffc0203032:	00004517          	auipc	a0,0x4
ffffffffc0203036:	7b650513          	addi	a0,a0,1974 # ffffffffc02077e8 <commands+0xf60>
ffffffffc020303a:	9cefd0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc020303e:	00005697          	auipc	a3,0x5
ffffffffc0203042:	92268693          	addi	a3,a3,-1758 # ffffffffc0207960 <commands+0x10d8>
ffffffffc0203046:	00004617          	auipc	a2,0x4
ffffffffc020304a:	c5260613          	addi	a2,a2,-942 # ffffffffc0206c98 <commands+0x410>
ffffffffc020304e:	13200593          	li	a1,306
ffffffffc0203052:	00004517          	auipc	a0,0x4
ffffffffc0203056:	79650513          	addi	a0,a0,1942 # ffffffffc02077e8 <commands+0xf60>
ffffffffc020305a:	9aefd0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc020305e:	00005697          	auipc	a3,0x5
ffffffffc0203062:	93268693          	addi	a3,a3,-1742 # ffffffffc0207990 <commands+0x1108>
ffffffffc0203066:	00004617          	auipc	a2,0x4
ffffffffc020306a:	c3260613          	addi	a2,a2,-974 # ffffffffc0206c98 <commands+0x410>
ffffffffc020306e:	13300593          	li	a1,307
ffffffffc0203072:	00004517          	auipc	a0,0x4
ffffffffc0203076:	77650513          	addi	a0,a0,1910 # ffffffffc02077e8 <commands+0xf60>
ffffffffc020307a:	98efd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(vma != NULL);
ffffffffc020307e:	00005697          	auipc	a3,0x5
ffffffffc0203082:	a5a68693          	addi	a3,a3,-1446 # ffffffffc0207ad8 <commands+0x1250>
ffffffffc0203086:	00004617          	auipc	a2,0x4
ffffffffc020308a:	c1260613          	addi	a2,a2,-1006 # ffffffffc0206c98 <commands+0x410>
ffffffffc020308e:	15200593          	li	a1,338
ffffffffc0203092:	00004517          	auipc	a0,0x4
ffffffffc0203096:	75650513          	addi	a0,a0,1878 # ffffffffc02077e8 <commands+0xf60>
ffffffffc020309a:	96efd0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc020309e:	00005697          	auipc	a3,0x5
ffffffffc02030a2:	82268693          	addi	a3,a3,-2014 # ffffffffc02078c0 <commands+0x1038>
ffffffffc02030a6:	00004617          	auipc	a2,0x4
ffffffffc02030aa:	bf260613          	addi	a2,a2,-1038 # ffffffffc0206c98 <commands+0x410>
ffffffffc02030ae:	12000593          	li	a1,288
ffffffffc02030b2:	00004517          	auipc	a0,0x4
ffffffffc02030b6:	73650513          	addi	a0,a0,1846 # ffffffffc02077e8 <commands+0xf60>
ffffffffc02030ba:	94efd0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma3 == NULL);
ffffffffc02030be:	00005697          	auipc	a3,0x5
ffffffffc02030c2:	87268693          	addi	a3,a3,-1934 # ffffffffc0207930 <commands+0x10a8>
ffffffffc02030c6:	00004617          	auipc	a2,0x4
ffffffffc02030ca:	bd260613          	addi	a2,a2,-1070 # ffffffffc0206c98 <commands+0x410>
ffffffffc02030ce:	12c00593          	li	a1,300
ffffffffc02030d2:	00004517          	auipc	a0,0x4
ffffffffc02030d6:	71650513          	addi	a0,a0,1814 # ffffffffc02077e8 <commands+0xf60>
ffffffffc02030da:	92efd0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma2 != NULL);
ffffffffc02030de:	00005697          	auipc	a3,0x5
ffffffffc02030e2:	84268693          	addi	a3,a3,-1982 # ffffffffc0207920 <commands+0x1098>
ffffffffc02030e6:	00004617          	auipc	a2,0x4
ffffffffc02030ea:	bb260613          	addi	a2,a2,-1102 # ffffffffc0206c98 <commands+0x410>
ffffffffc02030ee:	12a00593          	li	a1,298
ffffffffc02030f2:	00004517          	auipc	a0,0x4
ffffffffc02030f6:	6f650513          	addi	a0,a0,1782 # ffffffffc02077e8 <commands+0xf60>
ffffffffc02030fa:	90efd0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma1 != NULL);
ffffffffc02030fe:	00005697          	auipc	a3,0x5
ffffffffc0203102:	81268693          	addi	a3,a3,-2030 # ffffffffc0207910 <commands+0x1088>
ffffffffc0203106:	00004617          	auipc	a2,0x4
ffffffffc020310a:	b9260613          	addi	a2,a2,-1134 # ffffffffc0206c98 <commands+0x410>
ffffffffc020310e:	12800593          	li	a1,296
ffffffffc0203112:	00004517          	auipc	a0,0x4
ffffffffc0203116:	6d650513          	addi	a0,a0,1750 # ffffffffc02077e8 <commands+0xf60>
ffffffffc020311a:	8eefd0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma5 == NULL);
ffffffffc020311e:	00005697          	auipc	a3,0x5
ffffffffc0203122:	83268693          	addi	a3,a3,-1998 # ffffffffc0207950 <commands+0x10c8>
ffffffffc0203126:	00004617          	auipc	a2,0x4
ffffffffc020312a:	b7260613          	addi	a2,a2,-1166 # ffffffffc0206c98 <commands+0x410>
ffffffffc020312e:	13000593          	li	a1,304
ffffffffc0203132:	00004517          	auipc	a0,0x4
ffffffffc0203136:	6b650513          	addi	a0,a0,1718 # ffffffffc02077e8 <commands+0xf60>
ffffffffc020313a:	8cefd0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma4 == NULL);
ffffffffc020313e:	00005697          	auipc	a3,0x5
ffffffffc0203142:	80268693          	addi	a3,a3,-2046 # ffffffffc0207940 <commands+0x10b8>
ffffffffc0203146:	00004617          	auipc	a2,0x4
ffffffffc020314a:	b5260613          	addi	a2,a2,-1198 # ffffffffc0206c98 <commands+0x410>
ffffffffc020314e:	12e00593          	li	a1,302
ffffffffc0203152:	00004517          	auipc	a0,0x4
ffffffffc0203156:	69650513          	addi	a0,a0,1686 # ffffffffc02077e8 <commands+0xf60>
ffffffffc020315a:	8aefd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc020315e:	00005697          	auipc	a3,0x5
ffffffffc0203162:	8c268693          	addi	a3,a3,-1854 # ffffffffc0207a20 <commands+0x1198>
ffffffffc0203166:	00004617          	auipc	a2,0x4
ffffffffc020316a:	b3260613          	addi	a2,a2,-1230 # ffffffffc0206c98 <commands+0x410>
ffffffffc020316e:	14b00593          	li	a1,331
ffffffffc0203172:	00004517          	auipc	a0,0x4
ffffffffc0203176:	67650513          	addi	a0,a0,1654 # ffffffffc02077e8 <commands+0xf60>
ffffffffc020317a:	88efd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(mm != NULL);
ffffffffc020317e:	00004697          	auipc	a3,0x4
ffffffffc0203182:	6f268693          	addi	a3,a3,1778 # ffffffffc0207870 <commands+0xfe8>
ffffffffc0203186:	00004617          	auipc	a2,0x4
ffffffffc020318a:	b1260613          	addi	a2,a2,-1262 # ffffffffc0206c98 <commands+0x410>
ffffffffc020318e:	10c00593          	li	a1,268
ffffffffc0203192:	00004517          	auipc	a0,0x4
ffffffffc0203196:	65650513          	addi	a0,a0,1622 # ffffffffc02077e8 <commands+0xf60>
ffffffffc020319a:	86efd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc020319e:	00005697          	auipc	a3,0x5
ffffffffc02031a2:	8da68693          	addi	a3,a3,-1830 # ffffffffc0207a78 <commands+0x11f0>
ffffffffc02031a6:	00004617          	auipc	a2,0x4
ffffffffc02031aa:	af260613          	addi	a2,a2,-1294 # ffffffffc0206c98 <commands+0x410>
ffffffffc02031ae:	17000593          	li	a1,368
ffffffffc02031b2:	00004517          	auipc	a0,0x4
ffffffffc02031b6:	63650513          	addi	a0,a0,1590 # ffffffffc02077e8 <commands+0xf60>
ffffffffc02031ba:	84efd0ef          	jal	ra,ffffffffc0200208 <__panic>
    return KADDR(page2pa(page));
ffffffffc02031be:	00004617          	auipc	a2,0x4
ffffffffc02031c2:	e2260613          	addi	a2,a2,-478 # ffffffffc0206fe0 <commands+0x758>
ffffffffc02031c6:	06900593          	li	a1,105
ffffffffc02031ca:	00004517          	auipc	a0,0x4
ffffffffc02031ce:	dde50513          	addi	a0,a0,-546 # ffffffffc0206fa8 <commands+0x720>
ffffffffc02031d2:	836fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgdir[0] == 0);
ffffffffc02031d6:	00005697          	auipc	a3,0x5
ffffffffc02031da:	86268693          	addi	a3,a3,-1950 # ffffffffc0207a38 <commands+0x11b0>
ffffffffc02031de:	00004617          	auipc	a2,0x4
ffffffffc02031e2:	aba60613          	addi	a2,a2,-1350 # ffffffffc0206c98 <commands+0x410>
ffffffffc02031e6:	14f00593          	li	a1,335
ffffffffc02031ea:	00004517          	auipc	a0,0x4
ffffffffc02031ee:	5fe50513          	addi	a0,a0,1534 # ffffffffc02077e8 <commands+0xf60>
ffffffffc02031f2:	816fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc02031f6:	00005697          	auipc	a3,0x5
ffffffffc02031fa:	85268693          	addi	a3,a3,-1966 # ffffffffc0207a48 <commands+0x11c0>
ffffffffc02031fe:	00004617          	auipc	a2,0x4
ffffffffc0203202:	a9a60613          	addi	a2,a2,-1382 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203206:	15700593          	li	a1,343
ffffffffc020320a:	00004517          	auipc	a0,0x4
ffffffffc020320e:	5de50513          	addi	a0,a0,1502 # ffffffffc02077e8 <commands+0xf60>
ffffffffc0203212:	ff7fc0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203216:	00004617          	auipc	a2,0x4
ffffffffc020321a:	d7260613          	addi	a2,a2,-654 # ffffffffc0206f88 <commands+0x700>
ffffffffc020321e:	06200593          	li	a1,98
ffffffffc0203222:	00004517          	auipc	a0,0x4
ffffffffc0203226:	d8650513          	addi	a0,a0,-634 # ffffffffc0206fa8 <commands+0x720>
ffffffffc020322a:	fdffc0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(sum == 0);
ffffffffc020322e:	00005697          	auipc	a3,0x5
ffffffffc0203232:	83a68693          	addi	a3,a3,-1990 # ffffffffc0207a68 <commands+0x11e0>
ffffffffc0203236:	00004617          	auipc	a2,0x4
ffffffffc020323a:	a6260613          	addi	a2,a2,-1438 # ffffffffc0206c98 <commands+0x410>
ffffffffc020323e:	16300593          	li	a1,355
ffffffffc0203242:	00004517          	auipc	a0,0x4
ffffffffc0203246:	5a650513          	addi	a0,a0,1446 # ffffffffc02077e8 <commands+0xf60>
ffffffffc020324a:	fbffc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc020324e <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc020324e:	7179                	addi	sp,sp,-48
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203250:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc0203252:	f022                	sd	s0,32(sp)
ffffffffc0203254:	ec26                	sd	s1,24(sp)
ffffffffc0203256:	f406                	sd	ra,40(sp)
ffffffffc0203258:	e84a                	sd	s2,16(sp)
ffffffffc020325a:	8432                	mv	s0,a2
ffffffffc020325c:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc020325e:	f8eff0ef          	jal	ra,ffffffffc02029ec <find_vma>

    pgfault_num++;
ffffffffc0203262:	000af797          	auipc	a5,0xaf
ffffffffc0203266:	6267a783          	lw	a5,1574(a5) # ffffffffc02b2888 <pgfault_num>
ffffffffc020326a:	2785                	addiw	a5,a5,1
ffffffffc020326c:	000af717          	auipc	a4,0xaf
ffffffffc0203270:	60f72e23          	sw	a5,1564(a4) # ffffffffc02b2888 <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc0203274:	c551                	beqz	a0,ffffffffc0203300 <do_pgfault+0xb2>
ffffffffc0203276:	651c                	ld	a5,8(a0)
ffffffffc0203278:	08f46463          	bltu	s0,a5,ffffffffc0203300 <do_pgfault+0xb2>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc020327c:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc020327e:	4941                	li	s2,16
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0203280:	8b89                	andi	a5,a5,2
ffffffffc0203282:	efa9                	bnez	a5,ffffffffc02032dc <do_pgfault+0x8e>
        perm |= READ_WRITE;
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203284:	75fd                	lui	a1,0xfffff

    pte_t *ptep=NULL;
  
    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0203286:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203288:	8c6d                	and	s0,s0,a1
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc020328a:	4605                	li	a2,1
ffffffffc020328c:	85a2                	mv	a1,s0
ffffffffc020328e:	cd9fd0ef          	jal	ra,ffffffffc0200f66 <get_pte>
ffffffffc0203292:	c161                	beqz	a0,ffffffffc0203352 <do_pgfault+0x104>
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }
    
    if (*ptep == 0) { // if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr
ffffffffc0203294:	610c                	ld	a1,0(a0)
ffffffffc0203296:	c5a9                	beqz	a1,ffffffffc02032e0 <do_pgfault+0x92>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc0203298:	000af797          	auipc	a5,0xaf
ffffffffc020329c:	6107a783          	lw	a5,1552(a5) # ffffffffc02b28a8 <swap_init_ok>
ffffffffc02032a0:	cbad                	beqz	a5,ffffffffc0203312 <do_pgfault+0xc4>
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.
            int result = swap_in(mm, addr, &page); // ***在这里进swap_in函数
ffffffffc02032a2:	0030                	addi	a2,sp,8
ffffffffc02032a4:	85a2                	mv	a1,s0
ffffffffc02032a6:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc02032a8:	e402                	sd	zero,8(sp)
            int result = swap_in(mm, addr, &page); // ***在这里进swap_in函数
ffffffffc02032aa:	5b7000ef          	jal	ra,ffffffffc0204060 <swap_in>
            if (result != 0)
ffffffffc02032ae:	e935                	bnez	a0,ffffffffc0203322 <do_pgfault+0xd4>
                cprintf("swap_in failed\n");
                goto failed;
            }

            // (2) 设置物理地址和逻辑地址的映射
            if (page_insert(mm->pgdir, page, addr, perm) != 0)
ffffffffc02032b0:	65a2                	ld	a1,8(sp)
ffffffffc02032b2:	6c88                	ld	a0,24(s1)
ffffffffc02032b4:	86ca                	mv	a3,s2
ffffffffc02032b6:	8622                	mv	a2,s0
ffffffffc02032b8:	b48fe0ef          	jal	ra,ffffffffc0201600 <page_insert>
ffffffffc02032bc:	e93d                	bnez	a0,ffffffffc0203332 <do_pgfault+0xe4>
                cprintf("page_insert failed\n");
                goto failed;
            }

            // (3) 设置页面为可交换的
            if (swap_map_swappable(mm, addr, page, 1) != 0)
ffffffffc02032be:	6622                	ld	a2,8(sp)
ffffffffc02032c0:	4685                	li	a3,1
ffffffffc02032c2:	85a2                	mv	a1,s0
ffffffffc02032c4:	8526                	mv	a0,s1
ffffffffc02032c6:	47b000ef          	jal	ra,ffffffffc0203f40 <swap_map_swappable>
ffffffffc02032ca:	ed25                	bnez	a0,ffffffffc0203342 <do_pgfault+0xf4>
            {
                cprintf("swap_map_swappable failed\n");
                goto failed;
            }
            
            page->pra_vaddr = addr;
ffffffffc02032cc:	67a2                	ld	a5,8(sp)
ffffffffc02032ce:	ff80                	sd	s0,56(a5)
        }
   }
   ret = 0;
failed:
    return ret;
}
ffffffffc02032d0:	70a2                	ld	ra,40(sp)
ffffffffc02032d2:	7402                	ld	s0,32(sp)
ffffffffc02032d4:	64e2                	ld	s1,24(sp)
ffffffffc02032d6:	6942                	ld	s2,16(sp)
ffffffffc02032d8:	6145                	addi	sp,sp,48
ffffffffc02032da:	8082                	ret
        perm |= READ_WRITE;
ffffffffc02032dc:	495d                	li	s2,23
ffffffffc02032de:	b75d                	j	ffffffffc0203284 <do_pgfault+0x36>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc02032e0:	6c88                	ld	a0,24(s1)
ffffffffc02032e2:	864a                	mv	a2,s2
ffffffffc02032e4:	85a2                	mv	a1,s0
ffffffffc02032e6:	9c4ff0ef          	jal	ra,ffffffffc02024aa <pgdir_alloc_page>
ffffffffc02032ea:	87aa                	mv	a5,a0
   ret = 0;
ffffffffc02032ec:	4501                	li	a0,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc02032ee:	f3ed                	bnez	a5,ffffffffc02032d0 <do_pgfault+0x82>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc02032f0:	00005517          	auipc	a0,0x5
ffffffffc02032f4:	84850513          	addi	a0,a0,-1976 # ffffffffc0207b38 <commands+0x12b0>
ffffffffc02032f8:	dd5fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    ret = -E_NO_MEM;
ffffffffc02032fc:	5571                	li	a0,-4
            goto failed;
ffffffffc02032fe:	bfc9                	j	ffffffffc02032d0 <do_pgfault+0x82>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc0203300:	85a2                	mv	a1,s0
ffffffffc0203302:	00004517          	auipc	a0,0x4
ffffffffc0203306:	7e650513          	addi	a0,a0,2022 # ffffffffc0207ae8 <commands+0x1260>
ffffffffc020330a:	dc3fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    int ret = -E_INVAL;
ffffffffc020330e:	5575                	li	a0,-3
        goto failed;
ffffffffc0203310:	b7c1                	j	ffffffffc02032d0 <do_pgfault+0x82>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc0203312:	00005517          	auipc	a0,0x5
ffffffffc0203316:	89650513          	addi	a0,a0,-1898 # ffffffffc0207ba8 <commands+0x1320>
ffffffffc020331a:	db3fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    ret = -E_NO_MEM;
ffffffffc020331e:	5571                	li	a0,-4
            goto failed;
ffffffffc0203320:	bf45                	j	ffffffffc02032d0 <do_pgfault+0x82>
                cprintf("swap_in failed\n");
ffffffffc0203322:	00005517          	auipc	a0,0x5
ffffffffc0203326:	83e50513          	addi	a0,a0,-1986 # ffffffffc0207b60 <commands+0x12d8>
ffffffffc020332a:	da3fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    ret = -E_NO_MEM;
ffffffffc020332e:	5571                	li	a0,-4
ffffffffc0203330:	b745                	j	ffffffffc02032d0 <do_pgfault+0x82>
                cprintf("page_insert failed\n");
ffffffffc0203332:	00005517          	auipc	a0,0x5
ffffffffc0203336:	83e50513          	addi	a0,a0,-1986 # ffffffffc0207b70 <commands+0x12e8>
ffffffffc020333a:	d93fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    ret = -E_NO_MEM;
ffffffffc020333e:	5571                	li	a0,-4
ffffffffc0203340:	bf41                	j	ffffffffc02032d0 <do_pgfault+0x82>
                cprintf("swap_map_swappable failed\n");
ffffffffc0203342:	00005517          	auipc	a0,0x5
ffffffffc0203346:	84650513          	addi	a0,a0,-1978 # ffffffffc0207b88 <commands+0x1300>
ffffffffc020334a:	d83fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    ret = -E_NO_MEM;
ffffffffc020334e:	5571                	li	a0,-4
ffffffffc0203350:	b741                	j	ffffffffc02032d0 <do_pgfault+0x82>
        cprintf("get_pte in do_pgfault failed\n");
ffffffffc0203352:	00004517          	auipc	a0,0x4
ffffffffc0203356:	7c650513          	addi	a0,a0,1990 # ffffffffc0207b18 <commands+0x1290>
ffffffffc020335a:	d73fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    ret = -E_NO_MEM;
ffffffffc020335e:	5571                	li	a0,-4
        goto failed;
ffffffffc0203360:	bf85                	j	ffffffffc02032d0 <do_pgfault+0x82>

ffffffffc0203362 <user_mem_check>:

bool
user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write) {
ffffffffc0203362:	7179                	addi	sp,sp,-48
ffffffffc0203364:	f022                	sd	s0,32(sp)
ffffffffc0203366:	f406                	sd	ra,40(sp)
ffffffffc0203368:	ec26                	sd	s1,24(sp)
ffffffffc020336a:	e84a                	sd	s2,16(sp)
ffffffffc020336c:	e44e                	sd	s3,8(sp)
ffffffffc020336e:	e052                	sd	s4,0(sp)
ffffffffc0203370:	842e                	mv	s0,a1
    if (mm != NULL) {
ffffffffc0203372:	c135                	beqz	a0,ffffffffc02033d6 <user_mem_check+0x74>
        if (!USER_ACCESS(addr, addr + len)) {
ffffffffc0203374:	002007b7          	lui	a5,0x200
ffffffffc0203378:	04f5e663          	bltu	a1,a5,ffffffffc02033c4 <user_mem_check+0x62>
ffffffffc020337c:	00c584b3          	add	s1,a1,a2
ffffffffc0203380:	0495f263          	bgeu	a1,s1,ffffffffc02033c4 <user_mem_check+0x62>
ffffffffc0203384:	4785                	li	a5,1
ffffffffc0203386:	07fe                	slli	a5,a5,0x1f
ffffffffc0203388:	0297ee63          	bltu	a5,s1,ffffffffc02033c4 <user_mem_check+0x62>
ffffffffc020338c:	892a                	mv	s2,a0
ffffffffc020338e:	89b6                	mv	s3,a3
            }
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK)) {
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0203390:	6a05                	lui	s4,0x1
ffffffffc0203392:	a821                	j	ffffffffc02033aa <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0203394:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0203398:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc020339a:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc020339c:	c685                	beqz	a3,ffffffffc02033c4 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc020339e:	c399                	beqz	a5,ffffffffc02033a4 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc02033a0:	02e46263          	bltu	s0,a4,ffffffffc02033c4 <user_mem_check+0x62>
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc02033a4:	6900                	ld	s0,16(a0)
        while (start < end) {
ffffffffc02033a6:	04947663          	bgeu	s0,s1,ffffffffc02033f2 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start) {
ffffffffc02033aa:	85a2                	mv	a1,s0
ffffffffc02033ac:	854a                	mv	a0,s2
ffffffffc02033ae:	e3eff0ef          	jal	ra,ffffffffc02029ec <find_vma>
ffffffffc02033b2:	c909                	beqz	a0,ffffffffc02033c4 <user_mem_check+0x62>
ffffffffc02033b4:	6518                	ld	a4,8(a0)
ffffffffc02033b6:	00e46763          	bltu	s0,a4,ffffffffc02033c4 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc02033ba:	4d1c                	lw	a5,24(a0)
ffffffffc02033bc:	fc099ce3          	bnez	s3,ffffffffc0203394 <user_mem_check+0x32>
ffffffffc02033c0:	8b85                	andi	a5,a5,1
ffffffffc02033c2:	f3ed                	bnez	a5,ffffffffc02033a4 <user_mem_check+0x42>
            return 0;
ffffffffc02033c4:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc02033c6:	70a2                	ld	ra,40(sp)
ffffffffc02033c8:	7402                	ld	s0,32(sp)
ffffffffc02033ca:	64e2                	ld	s1,24(sp)
ffffffffc02033cc:	6942                	ld	s2,16(sp)
ffffffffc02033ce:	69a2                	ld	s3,8(sp)
ffffffffc02033d0:	6a02                	ld	s4,0(sp)
ffffffffc02033d2:	6145                	addi	sp,sp,48
ffffffffc02033d4:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc02033d6:	c02007b7          	lui	a5,0xc0200
ffffffffc02033da:	4501                	li	a0,0
ffffffffc02033dc:	fef5e5e3          	bltu	a1,a5,ffffffffc02033c6 <user_mem_check+0x64>
ffffffffc02033e0:	962e                	add	a2,a2,a1
ffffffffc02033e2:	fec5f2e3          	bgeu	a1,a2,ffffffffc02033c6 <user_mem_check+0x64>
ffffffffc02033e6:	c8000537          	lui	a0,0xc8000
ffffffffc02033ea:	0505                	addi	a0,a0,1
ffffffffc02033ec:	00a63533          	sltu	a0,a2,a0
ffffffffc02033f0:	bfd9                	j	ffffffffc02033c6 <user_mem_check+0x64>
        return 1;
ffffffffc02033f2:	4505                	li	a0,1
ffffffffc02033f4:	bfc9                	j	ffffffffc02033c6 <user_mem_check+0x64>

ffffffffc02033f6 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc02033f6:	c94d                	beqz	a0,ffffffffc02034a8 <slob_free+0xb2>
{
ffffffffc02033f8:	1141                	addi	sp,sp,-16
ffffffffc02033fa:	e022                	sd	s0,0(sp)
ffffffffc02033fc:	e406                	sd	ra,8(sp)
ffffffffc02033fe:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0203400:	e9c1                	bnez	a1,ffffffffc0203490 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203402:	100027f3          	csrr	a5,sstatus
ffffffffc0203406:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203408:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020340a:	ebd9                	bnez	a5,ffffffffc02034a0 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020340c:	000a4617          	auipc	a2,0xa4
ffffffffc0203410:	f5460613          	addi	a2,a2,-172 # ffffffffc02a7360 <slobfree>
ffffffffc0203414:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0203416:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0203418:	679c                	ld	a5,8(a5)
ffffffffc020341a:	02877a63          	bgeu	a4,s0,ffffffffc020344e <slob_free+0x58>
ffffffffc020341e:	00f46463          	bltu	s0,a5,ffffffffc0203426 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0203422:	fef76ae3          	bltu	a4,a5,ffffffffc0203416 <slob_free+0x20>
			break;

	if (b + b->units == cur->next) {
ffffffffc0203426:	400c                	lw	a1,0(s0)
ffffffffc0203428:	00459693          	slli	a3,a1,0x4
ffffffffc020342c:	96a2                	add	a3,a3,s0
ffffffffc020342e:	02d78a63          	beq	a5,a3,ffffffffc0203462 <slob_free+0x6c>
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
ffffffffc0203432:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0203434:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b) {
ffffffffc0203436:	00469793          	slli	a5,a3,0x4
ffffffffc020343a:	97ba                	add	a5,a5,a4
ffffffffc020343c:	02f40e63          	beq	s0,a5,ffffffffc0203478 <slob_free+0x82>
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;
ffffffffc0203440:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0203442:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc0203444:	e129                	bnez	a0,ffffffffc0203486 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0203446:	60a2                	ld	ra,8(sp)
ffffffffc0203448:	6402                	ld	s0,0(sp)
ffffffffc020344a:	0141                	addi	sp,sp,16
ffffffffc020344c:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020344e:	fcf764e3          	bltu	a4,a5,ffffffffc0203416 <slob_free+0x20>
ffffffffc0203452:	fcf472e3          	bgeu	s0,a5,ffffffffc0203416 <slob_free+0x20>
	if (b + b->units == cur->next) {
ffffffffc0203456:	400c                	lw	a1,0(s0)
ffffffffc0203458:	00459693          	slli	a3,a1,0x4
ffffffffc020345c:	96a2                	add	a3,a3,s0
ffffffffc020345e:	fcd79ae3          	bne	a5,a3,ffffffffc0203432 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0203462:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0203464:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0203466:	9db5                	addw	a1,a1,a3
ffffffffc0203468:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b) {
ffffffffc020346a:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc020346c:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b) {
ffffffffc020346e:	00469793          	slli	a5,a3,0x4
ffffffffc0203472:	97ba                	add	a5,a5,a4
ffffffffc0203474:	fcf416e3          	bne	s0,a5,ffffffffc0203440 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0203478:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc020347a:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc020347c:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc020347e:	9ebd                	addw	a3,a3,a5
ffffffffc0203480:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0203482:	e70c                	sd	a1,8(a4)
ffffffffc0203484:	d169                	beqz	a0,ffffffffc0203446 <slob_free+0x50>
}
ffffffffc0203486:	6402                	ld	s0,0(sp)
ffffffffc0203488:	60a2                	ld	ra,8(sp)
ffffffffc020348a:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc020348c:	9b6fd06f          	j	ffffffffc0200642 <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0203490:	25bd                	addiw	a1,a1,15
ffffffffc0203492:	8191                	srli	a1,a1,0x4
ffffffffc0203494:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203496:	100027f3          	csrr	a5,sstatus
ffffffffc020349a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020349c:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020349e:	d7bd                	beqz	a5,ffffffffc020340c <slob_free+0x16>
        intr_disable();
ffffffffc02034a0:	9a8fd0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc02034a4:	4505                	li	a0,1
ffffffffc02034a6:	b79d                	j	ffffffffc020340c <slob_free+0x16>
ffffffffc02034a8:	8082                	ret

ffffffffc02034aa <__slob_get_free_pages.constprop.0>:
  struct Page * page = alloc_pages(1 << order);
ffffffffc02034aa:	4785                	li	a5,1
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02034ac:	1141                	addi	sp,sp,-16
  struct Page * page = alloc_pages(1 << order);
ffffffffc02034ae:	00a7953b          	sllw	a0,a5,a0
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02034b2:	e406                	sd	ra,8(sp)
  struct Page * page = alloc_pages(1 << order);
ffffffffc02034b4:	9a7fd0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
  if(!page)
ffffffffc02034b8:	c91d                	beqz	a0,ffffffffc02034ee <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc02034ba:	000af697          	auipc	a3,0xaf
ffffffffc02034be:	3ae6b683          	ld	a3,942(a3) # ffffffffc02b2868 <pages>
ffffffffc02034c2:	8d15                	sub	a0,a0,a3
ffffffffc02034c4:	8519                	srai	a0,a0,0x6
ffffffffc02034c6:	00006697          	auipc	a3,0x6
ffffffffc02034ca:	82a6b683          	ld	a3,-2006(a3) # ffffffffc0208cf0 <nbase>
ffffffffc02034ce:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc02034d0:	00c51793          	slli	a5,a0,0xc
ffffffffc02034d4:	83b1                	srli	a5,a5,0xc
ffffffffc02034d6:	000af717          	auipc	a4,0xaf
ffffffffc02034da:	38a73703          	ld	a4,906(a4) # ffffffffc02b2860 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02034de:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc02034e0:	00e7fa63          	bgeu	a5,a4,ffffffffc02034f4 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc02034e4:	000af697          	auipc	a3,0xaf
ffffffffc02034e8:	3946b683          	ld	a3,916(a3) # ffffffffc02b2878 <va_pa_offset>
ffffffffc02034ec:	9536                	add	a0,a0,a3
}
ffffffffc02034ee:	60a2                	ld	ra,8(sp)
ffffffffc02034f0:	0141                	addi	sp,sp,16
ffffffffc02034f2:	8082                	ret
ffffffffc02034f4:	86aa                	mv	a3,a0
ffffffffc02034f6:	00004617          	auipc	a2,0x4
ffffffffc02034fa:	aea60613          	addi	a2,a2,-1302 # ffffffffc0206fe0 <commands+0x758>
ffffffffc02034fe:	06900593          	li	a1,105
ffffffffc0203502:	00004517          	auipc	a0,0x4
ffffffffc0203506:	aa650513          	addi	a0,a0,-1370 # ffffffffc0206fa8 <commands+0x720>
ffffffffc020350a:	cfffc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc020350e <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc020350e:	1101                	addi	sp,sp,-32
ffffffffc0203510:	ec06                	sd	ra,24(sp)
ffffffffc0203512:	e822                	sd	s0,16(sp)
ffffffffc0203514:	e426                	sd	s1,8(sp)
ffffffffc0203516:	e04a                	sd	s2,0(sp)
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0203518:	01050713          	addi	a4,a0,16
ffffffffc020351c:	6785                	lui	a5,0x1
ffffffffc020351e:	0cf77363          	bgeu	a4,a5,ffffffffc02035e4 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0203522:	00f50493          	addi	s1,a0,15
ffffffffc0203526:	8091                	srli	s1,s1,0x4
ffffffffc0203528:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020352a:	10002673          	csrr	a2,sstatus
ffffffffc020352e:	8a09                	andi	a2,a2,2
ffffffffc0203530:	e25d                	bnez	a2,ffffffffc02035d6 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0203532:	000a4917          	auipc	s2,0xa4
ffffffffc0203536:	e2e90913          	addi	s2,s2,-466 # ffffffffc02a7360 <slobfree>
ffffffffc020353a:	00093683          	ld	a3,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc020353e:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0203540:	4398                	lw	a4,0(a5)
ffffffffc0203542:	08975e63          	bge	a4,s1,ffffffffc02035de <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree) {
ffffffffc0203546:	00f68b63          	beq	a3,a5,ffffffffc020355c <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc020354a:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc020354c:	4018                	lw	a4,0(s0)
ffffffffc020354e:	02975a63          	bge	a4,s1,ffffffffc0203582 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree) {
ffffffffc0203552:	00093683          	ld	a3,0(s2)
ffffffffc0203556:	87a2                	mv	a5,s0
ffffffffc0203558:	fef699e3          	bne	a3,a5,ffffffffc020354a <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc020355c:	ee31                	bnez	a2,ffffffffc02035b8 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc020355e:	4501                	li	a0,0
ffffffffc0203560:	f4bff0ef          	jal	ra,ffffffffc02034aa <__slob_get_free_pages.constprop.0>
ffffffffc0203564:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0203566:	cd05                	beqz	a0,ffffffffc020359e <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0203568:	6585                	lui	a1,0x1
ffffffffc020356a:	e8dff0ef          	jal	ra,ffffffffc02033f6 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020356e:	10002673          	csrr	a2,sstatus
ffffffffc0203572:	8a09                	andi	a2,a2,2
ffffffffc0203574:	ee05                	bnez	a2,ffffffffc02035ac <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0203576:	00093783          	ld	a5,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc020357a:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc020357c:	4018                	lw	a4,0(s0)
ffffffffc020357e:	fc974ae3          	blt	a4,s1,ffffffffc0203552 <slob_alloc.constprop.0+0x44>
			if (cur->units == units) /* exact fit? */
ffffffffc0203582:	04e48763          	beq	s1,a4,ffffffffc02035d0 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0203586:	00449693          	slli	a3,s1,0x4
ffffffffc020358a:	96a2                	add	a3,a3,s0
ffffffffc020358c:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc020358e:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0203590:	9f05                	subw	a4,a4,s1
ffffffffc0203592:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0203594:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0203596:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0203598:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc020359c:	e20d                	bnez	a2,ffffffffc02035be <slob_alloc.constprop.0+0xb0>
}
ffffffffc020359e:	60e2                	ld	ra,24(sp)
ffffffffc02035a0:	8522                	mv	a0,s0
ffffffffc02035a2:	6442                	ld	s0,16(sp)
ffffffffc02035a4:	64a2                	ld	s1,8(sp)
ffffffffc02035a6:	6902                	ld	s2,0(sp)
ffffffffc02035a8:	6105                	addi	sp,sp,32
ffffffffc02035aa:	8082                	ret
        intr_disable();
ffffffffc02035ac:	89cfd0ef          	jal	ra,ffffffffc0200648 <intr_disable>
			cur = slobfree;
ffffffffc02035b0:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc02035b4:	4605                	li	a2,1
ffffffffc02035b6:	b7d1                	j	ffffffffc020357a <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc02035b8:	88afd0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc02035bc:	b74d                	j	ffffffffc020355e <slob_alloc.constprop.0+0x50>
ffffffffc02035be:	884fd0ef          	jal	ra,ffffffffc0200642 <intr_enable>
}
ffffffffc02035c2:	60e2                	ld	ra,24(sp)
ffffffffc02035c4:	8522                	mv	a0,s0
ffffffffc02035c6:	6442                	ld	s0,16(sp)
ffffffffc02035c8:	64a2                	ld	s1,8(sp)
ffffffffc02035ca:	6902                	ld	s2,0(sp)
ffffffffc02035cc:	6105                	addi	sp,sp,32
ffffffffc02035ce:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc02035d0:	6418                	ld	a4,8(s0)
ffffffffc02035d2:	e798                	sd	a4,8(a5)
ffffffffc02035d4:	b7d1                	j	ffffffffc0203598 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc02035d6:	872fd0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc02035da:	4605                	li	a2,1
ffffffffc02035dc:	bf99                	j	ffffffffc0203532 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc02035de:	843e                	mv	s0,a5
ffffffffc02035e0:	87b6                	mv	a5,a3
ffffffffc02035e2:	b745                	j	ffffffffc0203582 <slob_alloc.constprop.0+0x74>
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc02035e4:	00004697          	auipc	a3,0x4
ffffffffc02035e8:	5ec68693          	addi	a3,a3,1516 # ffffffffc0207bd0 <commands+0x1348>
ffffffffc02035ec:	00003617          	auipc	a2,0x3
ffffffffc02035f0:	6ac60613          	addi	a2,a2,1708 # ffffffffc0206c98 <commands+0x410>
ffffffffc02035f4:	06400593          	li	a1,100
ffffffffc02035f8:	00004517          	auipc	a0,0x4
ffffffffc02035fc:	5f850513          	addi	a0,a0,1528 # ffffffffc0207bf0 <commands+0x1368>
ffffffffc0203600:	c09fc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0203604 <kmalloc_init>:
slob_init(void) {
  cprintf("use SLOB allocator\n");
}

inline void 
kmalloc_init(void) {
ffffffffc0203604:	1141                	addi	sp,sp,-16
  cprintf("use SLOB allocator\n");
ffffffffc0203606:	00004517          	auipc	a0,0x4
ffffffffc020360a:	60250513          	addi	a0,a0,1538 # ffffffffc0207c08 <commands+0x1380>
kmalloc_init(void) {
ffffffffc020360e:	e406                	sd	ra,8(sp)
  cprintf("use SLOB allocator\n");
ffffffffc0203610:	abdfc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    slob_init();
    cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0203614:	60a2                	ld	ra,8(sp)
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0203616:	00004517          	auipc	a0,0x4
ffffffffc020361a:	60a50513          	addi	a0,a0,1546 # ffffffffc0207c20 <commands+0x1398>
}
ffffffffc020361e:	0141                	addi	sp,sp,16
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0203620:	aadfc06f          	j	ffffffffc02000cc <cprintf>

ffffffffc0203624 <kallocated>:
}

size_t
kallocated(void) {
   return slob_allocated();
}
ffffffffc0203624:	4501                	li	a0,0
ffffffffc0203626:	8082                	ret

ffffffffc0203628 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0203628:	1101                	addi	sp,sp,-32
ffffffffc020362a:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc020362c:	6905                	lui	s2,0x1
{
ffffffffc020362e:	e822                	sd	s0,16(sp)
ffffffffc0203630:	ec06                	sd	ra,24(sp)
ffffffffc0203632:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0203634:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bc9>
{
ffffffffc0203638:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc020363a:	04a7f963          	bgeu	a5,a0,ffffffffc020368c <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc020363e:	4561                	li	a0,24
ffffffffc0203640:	ecfff0ef          	jal	ra,ffffffffc020350e <slob_alloc.constprop.0>
ffffffffc0203644:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0203646:	c929                	beqz	a0,ffffffffc0203698 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0203648:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc020364c:	4501                	li	a0,0
	for ( ; size > 4096 ; size >>=1)
ffffffffc020364e:	00f95763          	bge	s2,a5,ffffffffc020365c <kmalloc+0x34>
ffffffffc0203652:	6705                	lui	a4,0x1
ffffffffc0203654:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0203656:	2505                	addiw	a0,a0,1
	for ( ; size > 4096 ; size >>=1)
ffffffffc0203658:	fef74ee3          	blt	a4,a5,ffffffffc0203654 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc020365c:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc020365e:	e4dff0ef          	jal	ra,ffffffffc02034aa <__slob_get_free_pages.constprop.0>
ffffffffc0203662:	e488                	sd	a0,8(s1)
ffffffffc0203664:	842a                	mv	s0,a0
	if (bb->pages) {
ffffffffc0203666:	c525                	beqz	a0,ffffffffc02036ce <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203668:	100027f3          	csrr	a5,sstatus
ffffffffc020366c:	8b89                	andi	a5,a5,2
ffffffffc020366e:	ef8d                	bnez	a5,ffffffffc02036a8 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0203670:	000af797          	auipc	a5,0xaf
ffffffffc0203674:	22078793          	addi	a5,a5,544 # ffffffffc02b2890 <bigblocks>
ffffffffc0203678:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc020367a:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc020367c:	e898                	sd	a4,16(s1)
  return __kmalloc(size, 0);
}
ffffffffc020367e:	60e2                	ld	ra,24(sp)
ffffffffc0203680:	8522                	mv	a0,s0
ffffffffc0203682:	6442                	ld	s0,16(sp)
ffffffffc0203684:	64a2                	ld	s1,8(sp)
ffffffffc0203686:	6902                	ld	s2,0(sp)
ffffffffc0203688:	6105                	addi	sp,sp,32
ffffffffc020368a:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc020368c:	0541                	addi	a0,a0,16
ffffffffc020368e:	e81ff0ef          	jal	ra,ffffffffc020350e <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0203692:	01050413          	addi	s0,a0,16
ffffffffc0203696:	f565                	bnez	a0,ffffffffc020367e <kmalloc+0x56>
ffffffffc0203698:	4401                	li	s0,0
}
ffffffffc020369a:	60e2                	ld	ra,24(sp)
ffffffffc020369c:	8522                	mv	a0,s0
ffffffffc020369e:	6442                	ld	s0,16(sp)
ffffffffc02036a0:	64a2                	ld	s1,8(sp)
ffffffffc02036a2:	6902                	ld	s2,0(sp)
ffffffffc02036a4:	6105                	addi	sp,sp,32
ffffffffc02036a6:	8082                	ret
        intr_disable();
ffffffffc02036a8:	fa1fc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
		bb->next = bigblocks;
ffffffffc02036ac:	000af797          	auipc	a5,0xaf
ffffffffc02036b0:	1e478793          	addi	a5,a5,484 # ffffffffc02b2890 <bigblocks>
ffffffffc02036b4:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc02036b6:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc02036b8:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc02036ba:	f89fc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
		return bb->pages;
ffffffffc02036be:	6480                	ld	s0,8(s1)
}
ffffffffc02036c0:	60e2                	ld	ra,24(sp)
ffffffffc02036c2:	64a2                	ld	s1,8(sp)
ffffffffc02036c4:	8522                	mv	a0,s0
ffffffffc02036c6:	6442                	ld	s0,16(sp)
ffffffffc02036c8:	6902                	ld	s2,0(sp)
ffffffffc02036ca:	6105                	addi	sp,sp,32
ffffffffc02036cc:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc02036ce:	45e1                	li	a1,24
ffffffffc02036d0:	8526                	mv	a0,s1
ffffffffc02036d2:	d25ff0ef          	jal	ra,ffffffffc02033f6 <slob_free>
  return __kmalloc(size, 0);
ffffffffc02036d6:	b765                	j	ffffffffc020367e <kmalloc+0x56>

ffffffffc02036d8 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc02036d8:	c179                	beqz	a0,ffffffffc020379e <kfree+0xc6>
{
ffffffffc02036da:	1101                	addi	sp,sp,-32
ffffffffc02036dc:	e822                	sd	s0,16(sp)
ffffffffc02036de:	ec06                	sd	ra,24(sp)
ffffffffc02036e0:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
ffffffffc02036e2:	03451793          	slli	a5,a0,0x34
ffffffffc02036e6:	842a                	mv	s0,a0
ffffffffc02036e8:	e7c1                	bnez	a5,ffffffffc0203770 <kfree+0x98>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02036ea:	100027f3          	csrr	a5,sstatus
ffffffffc02036ee:	8b89                	andi	a5,a5,2
ffffffffc02036f0:	ebc9                	bnez	a5,ffffffffc0203782 <kfree+0xaa>
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc02036f2:	000af797          	auipc	a5,0xaf
ffffffffc02036f6:	19e7b783          	ld	a5,414(a5) # ffffffffc02b2890 <bigblocks>
    return 0;
ffffffffc02036fa:	4601                	li	a2,0
ffffffffc02036fc:	cbb5                	beqz	a5,ffffffffc0203770 <kfree+0x98>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc02036fe:	000af697          	auipc	a3,0xaf
ffffffffc0203702:	19268693          	addi	a3,a3,402 # ffffffffc02b2890 <bigblocks>
ffffffffc0203706:	a021                	j	ffffffffc020370e <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0203708:	01048693          	addi	a3,s1,16
ffffffffc020370c:	c3ad                	beqz	a5,ffffffffc020376e <kfree+0x96>
			if (bb->pages == block) {
ffffffffc020370e:	6798                	ld	a4,8(a5)
ffffffffc0203710:	84be                	mv	s1,a5
				*last = bb->next;
ffffffffc0203712:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block) {
ffffffffc0203714:	fe871ae3          	bne	a4,s0,ffffffffc0203708 <kfree+0x30>
				*last = bb->next;
ffffffffc0203718:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc020371a:	ee3d                	bnez	a2,ffffffffc0203798 <kfree+0xc0>
    return pa2page(PADDR(kva));
ffffffffc020371c:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0203720:	4098                	lw	a4,0(s1)
ffffffffc0203722:	08f46b63          	bltu	s0,a5,ffffffffc02037b8 <kfree+0xe0>
ffffffffc0203726:	000af697          	auipc	a3,0xaf
ffffffffc020372a:	1526b683          	ld	a3,338(a3) # ffffffffc02b2878 <va_pa_offset>
ffffffffc020372e:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage) {
ffffffffc0203730:	8031                	srli	s0,s0,0xc
ffffffffc0203732:	000af797          	auipc	a5,0xaf
ffffffffc0203736:	12e7b783          	ld	a5,302(a5) # ffffffffc02b2860 <npage>
ffffffffc020373a:	06f47363          	bgeu	s0,a5,ffffffffc02037a0 <kfree+0xc8>
    return &pages[PPN(pa) - nbase];
ffffffffc020373e:	00005517          	auipc	a0,0x5
ffffffffc0203742:	5b253503          	ld	a0,1458(a0) # ffffffffc0208cf0 <nbase>
ffffffffc0203746:	8c09                	sub	s0,s0,a0
ffffffffc0203748:	041a                	slli	s0,s0,0x6
  free_pages(kva2page(kva), 1 << order);
ffffffffc020374a:	000af517          	auipc	a0,0xaf
ffffffffc020374e:	11e53503          	ld	a0,286(a0) # ffffffffc02b2868 <pages>
ffffffffc0203752:	4585                	li	a1,1
ffffffffc0203754:	9522                	add	a0,a0,s0
ffffffffc0203756:	00e595bb          	sllw	a1,a1,a4
ffffffffc020375a:	f92fd0ef          	jal	ra,ffffffffc0200eec <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc020375e:	6442                	ld	s0,16(sp)
ffffffffc0203760:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0203762:	8526                	mv	a0,s1
}
ffffffffc0203764:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0203766:	45e1                	li	a1,24
}
ffffffffc0203768:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc020376a:	c8dff06f          	j	ffffffffc02033f6 <slob_free>
ffffffffc020376e:	e215                	bnez	a2,ffffffffc0203792 <kfree+0xba>
ffffffffc0203770:	ff040513          	addi	a0,s0,-16
}
ffffffffc0203774:	6442                	ld	s0,16(sp)
ffffffffc0203776:	60e2                	ld	ra,24(sp)
ffffffffc0203778:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc020377a:	4581                	li	a1,0
}
ffffffffc020377c:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc020377e:	c79ff06f          	j	ffffffffc02033f6 <slob_free>
        intr_disable();
ffffffffc0203782:	ec7fc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0203786:	000af797          	auipc	a5,0xaf
ffffffffc020378a:	10a7b783          	ld	a5,266(a5) # ffffffffc02b2890 <bigblocks>
        return 1;
ffffffffc020378e:	4605                	li	a2,1
ffffffffc0203790:	f7bd                	bnez	a5,ffffffffc02036fe <kfree+0x26>
        intr_enable();
ffffffffc0203792:	eb1fc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0203796:	bfe9                	j	ffffffffc0203770 <kfree+0x98>
ffffffffc0203798:	eabfc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc020379c:	b741                	j	ffffffffc020371c <kfree+0x44>
ffffffffc020379e:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc02037a0:	00003617          	auipc	a2,0x3
ffffffffc02037a4:	7e860613          	addi	a2,a2,2024 # ffffffffc0206f88 <commands+0x700>
ffffffffc02037a8:	06200593          	li	a1,98
ffffffffc02037ac:	00003517          	auipc	a0,0x3
ffffffffc02037b0:	7fc50513          	addi	a0,a0,2044 # ffffffffc0206fa8 <commands+0x720>
ffffffffc02037b4:	a55fc0ef          	jal	ra,ffffffffc0200208 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02037b8:	86a2                	mv	a3,s0
ffffffffc02037ba:	00004617          	auipc	a2,0x4
ffffffffc02037be:	8fe60613          	addi	a2,a2,-1794 # ffffffffc02070b8 <commands+0x830>
ffffffffc02037c2:	06e00593          	li	a1,110
ffffffffc02037c6:	00003517          	auipc	a0,0x3
ffffffffc02037ca:	7e250513          	addi	a0,a0,2018 # ffffffffc0206fa8 <commands+0x720>
ffffffffc02037ce:	a3bfc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02037d2 <pa2page.part.0>:
pa2page(uintptr_t pa) {
ffffffffc02037d2:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc02037d4:	00003617          	auipc	a2,0x3
ffffffffc02037d8:	7b460613          	addi	a2,a2,1972 # ffffffffc0206f88 <commands+0x700>
ffffffffc02037dc:	06200593          	li	a1,98
ffffffffc02037e0:	00003517          	auipc	a0,0x3
ffffffffc02037e4:	7c850513          	addi	a0,a0,1992 # ffffffffc0206fa8 <commands+0x720>
pa2page(uintptr_t pa) {
ffffffffc02037e8:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc02037ea:	a1ffc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02037ee <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc02037ee:	7135                	addi	sp,sp,-160
ffffffffc02037f0:	ed06                	sd	ra,152(sp)
ffffffffc02037f2:	e922                	sd	s0,144(sp)
ffffffffc02037f4:	e526                	sd	s1,136(sp)
ffffffffc02037f6:	e14a                	sd	s2,128(sp)
ffffffffc02037f8:	fcce                	sd	s3,120(sp)
ffffffffc02037fa:	f8d2                	sd	s4,112(sp)
ffffffffc02037fc:	f4d6                	sd	s5,104(sp)
ffffffffc02037fe:	f0da                	sd	s6,96(sp)
ffffffffc0203800:	ecde                	sd	s7,88(sp)
ffffffffc0203802:	e8e2                	sd	s8,80(sp)
ffffffffc0203804:	e4e6                	sd	s9,72(sp)
ffffffffc0203806:	e0ea                	sd	s10,64(sp)
ffffffffc0203808:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc020380a:	37e010ef          	jal	ra,ffffffffc0204b88 <swapfs_init>

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc020380e:	000af697          	auipc	a3,0xaf
ffffffffc0203812:	08a6b683          	ld	a3,138(a3) # ffffffffc02b2898 <max_swap_offset>
ffffffffc0203816:	010007b7          	lui	a5,0x1000
ffffffffc020381a:	ff968713          	addi	a4,a3,-7
ffffffffc020381e:	17e1                	addi	a5,a5,-8
ffffffffc0203820:	42e7e663          	bltu	a5,a4,ffffffffc0203c4c <swap_init+0x45e>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }
     

     sm = &swap_manager_fifo;
ffffffffc0203824:	000a4797          	auipc	a5,0xa4
ffffffffc0203828:	aec78793          	addi	a5,a5,-1300 # ffffffffc02a7310 <swap_manager_fifo>
     int r = sm->init();
ffffffffc020382c:	6798                	ld	a4,8(a5)
     sm = &swap_manager_fifo;
ffffffffc020382e:	000afb97          	auipc	s7,0xaf
ffffffffc0203832:	072b8b93          	addi	s7,s7,114 # ffffffffc02b28a0 <sm>
ffffffffc0203836:	00fbb023          	sd	a5,0(s7)
     int r = sm->init();
ffffffffc020383a:	9702                	jalr	a4
ffffffffc020383c:	892a                	mv	s2,a0
     
     if (r == 0)
ffffffffc020383e:	c10d                	beqz	a0,ffffffffc0203860 <swap_init+0x72>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc0203840:	60ea                	ld	ra,152(sp)
ffffffffc0203842:	644a                	ld	s0,144(sp)
ffffffffc0203844:	64aa                	ld	s1,136(sp)
ffffffffc0203846:	79e6                	ld	s3,120(sp)
ffffffffc0203848:	7a46                	ld	s4,112(sp)
ffffffffc020384a:	7aa6                	ld	s5,104(sp)
ffffffffc020384c:	7b06                	ld	s6,96(sp)
ffffffffc020384e:	6be6                	ld	s7,88(sp)
ffffffffc0203850:	6c46                	ld	s8,80(sp)
ffffffffc0203852:	6ca6                	ld	s9,72(sp)
ffffffffc0203854:	6d06                	ld	s10,64(sp)
ffffffffc0203856:	7de2                	ld	s11,56(sp)
ffffffffc0203858:	854a                	mv	a0,s2
ffffffffc020385a:	690a                	ld	s2,128(sp)
ffffffffc020385c:	610d                	addi	sp,sp,160
ffffffffc020385e:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0203860:	000bb783          	ld	a5,0(s7)
ffffffffc0203864:	00004517          	auipc	a0,0x4
ffffffffc0203868:	40c50513          	addi	a0,a0,1036 # ffffffffc0207c70 <commands+0x13e8>
ffffffffc020386c:	000ab417          	auipc	s0,0xab
ffffffffc0203870:	fa440413          	addi	s0,s0,-92 # ffffffffc02ae810 <free_area>
ffffffffc0203874:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc0203876:	4785                	li	a5,1
ffffffffc0203878:	000af717          	auipc	a4,0xaf
ffffffffc020387c:	02f72823          	sw	a5,48(a4) # ffffffffc02b28a8 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0203880:	84dfc0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0203884:	641c                	ld	a5,8(s0)

static void
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
ffffffffc0203886:	4d01                	li	s10,0
ffffffffc0203888:	4d81                	li	s11,0
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc020388a:	34878163          	beq	a5,s0,ffffffffc0203bcc <swap_init+0x3de>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020388e:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0203892:	8b09                	andi	a4,a4,2
ffffffffc0203894:	32070e63          	beqz	a4,ffffffffc0203bd0 <swap_init+0x3e2>
        count ++, total += p->property;
ffffffffc0203898:	ff87a703          	lw	a4,-8(a5)
ffffffffc020389c:	679c                	ld	a5,8(a5)
ffffffffc020389e:	2d85                	addiw	s11,s11,1
ffffffffc02038a0:	01a70d3b          	addw	s10,a4,s10
     while ((le = list_next(le)) != &free_list) {
ffffffffc02038a4:	fe8795e3          	bne	a5,s0,ffffffffc020388e <swap_init+0xa0>
     }
     assert(total == nr_free_pages());
ffffffffc02038a8:	84ea                	mv	s1,s10
ffffffffc02038aa:	e82fd0ef          	jal	ra,ffffffffc0200f2c <nr_free_pages>
ffffffffc02038ae:	42951763          	bne	a0,s1,ffffffffc0203cdc <swap_init+0x4ee>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc02038b2:	866a                	mv	a2,s10
ffffffffc02038b4:	85ee                	mv	a1,s11
ffffffffc02038b6:	00004517          	auipc	a0,0x4
ffffffffc02038ba:	40250513          	addi	a0,a0,1026 # ffffffffc0207cb8 <commands+0x1430>
ffffffffc02038be:	80ffc0ef          	jal	ra,ffffffffc02000cc <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc02038c2:	8b4ff0ef          	jal	ra,ffffffffc0202976 <mm_create>
ffffffffc02038c6:	8aaa                	mv	s5,a0
     assert(mm != NULL);
ffffffffc02038c8:	46050a63          	beqz	a0,ffffffffc0203d3c <swap_init+0x54e>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc02038cc:	000af797          	auipc	a5,0xaf
ffffffffc02038d0:	fb478793          	addi	a5,a5,-76 # ffffffffc02b2880 <check_mm_struct>
ffffffffc02038d4:	6398                	ld	a4,0(a5)
ffffffffc02038d6:	3e071363          	bnez	a4,ffffffffc0203cbc <swap_init+0x4ce>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02038da:	000af717          	auipc	a4,0xaf
ffffffffc02038de:	f7e70713          	addi	a4,a4,-130 # ffffffffc02b2858 <boot_pgdir>
ffffffffc02038e2:	00073b03          	ld	s6,0(a4)
     check_mm_struct = mm;
ffffffffc02038e6:	e388                	sd	a0,0(a5)
     assert(pgdir[0] == 0);
ffffffffc02038e8:	000b3783          	ld	a5,0(s6) # 80000 <_binary_obj___user_exit_out_size+0x74ed8>
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02038ec:	01653c23          	sd	s6,24(a0)
     assert(pgdir[0] == 0);
ffffffffc02038f0:	42079663          	bnez	a5,ffffffffc0203d1c <swap_init+0x52e>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc02038f4:	6599                	lui	a1,0x6
ffffffffc02038f6:	460d                	li	a2,3
ffffffffc02038f8:	6505                	lui	a0,0x1
ffffffffc02038fa:	8c4ff0ef          	jal	ra,ffffffffc02029be <vma_create>
ffffffffc02038fe:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc0203900:	52050a63          	beqz	a0,ffffffffc0203e34 <swap_init+0x646>

     insert_vma_struct(mm, vma);
ffffffffc0203904:	8556                	mv	a0,s5
ffffffffc0203906:	926ff0ef          	jal	ra,ffffffffc0202a2c <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc020390a:	00004517          	auipc	a0,0x4
ffffffffc020390e:	3ee50513          	addi	a0,a0,1006 # ffffffffc0207cf8 <commands+0x1470>
ffffffffc0203912:	fbafc0ef          	jal	ra,ffffffffc02000cc <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc0203916:	018ab503          	ld	a0,24(s5)
ffffffffc020391a:	4605                	li	a2,1
ffffffffc020391c:	6585                	lui	a1,0x1
ffffffffc020391e:	e48fd0ef          	jal	ra,ffffffffc0200f66 <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc0203922:	4c050963          	beqz	a0,ffffffffc0203df4 <swap_init+0x606>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0203926:	00004517          	auipc	a0,0x4
ffffffffc020392a:	42250513          	addi	a0,a0,1058 # ffffffffc0207d48 <commands+0x14c0>
ffffffffc020392e:	000ab497          	auipc	s1,0xab
ffffffffc0203932:	e7248493          	addi	s1,s1,-398 # ffffffffc02ae7a0 <check_rp>
ffffffffc0203936:	f96fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020393a:	000ab997          	auipc	s3,0xab
ffffffffc020393e:	e8698993          	addi	s3,s3,-378 # ffffffffc02ae7c0 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0203942:	8a26                	mv	s4,s1
          check_rp[i] = alloc_page();
ffffffffc0203944:	4505                	li	a0,1
ffffffffc0203946:	d14fd0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc020394a:	00aa3023          	sd	a0,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
          assert(check_rp[i] != NULL );
ffffffffc020394e:	2c050f63          	beqz	a0,ffffffffc0203c2c <swap_init+0x43e>
ffffffffc0203952:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0203954:	8b89                	andi	a5,a5,2
ffffffffc0203956:	34079363          	bnez	a5,ffffffffc0203c9c <swap_init+0x4ae>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020395a:	0a21                	addi	s4,s4,8
ffffffffc020395c:	ff3a14e3          	bne	s4,s3,ffffffffc0203944 <swap_init+0x156>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0203960:	601c                	ld	a5,0(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc0203962:	000aba17          	auipc	s4,0xab
ffffffffc0203966:	e3ea0a13          	addi	s4,s4,-450 # ffffffffc02ae7a0 <check_rp>
    elm->prev = elm->next = elm;
ffffffffc020396a:	e000                	sd	s0,0(s0)
     list_entry_t free_list_store = free_list;
ffffffffc020396c:	ec3e                	sd	a5,24(sp)
ffffffffc020396e:	641c                	ld	a5,8(s0)
ffffffffc0203970:	e400                	sd	s0,8(s0)
ffffffffc0203972:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc0203974:	481c                	lw	a5,16(s0)
ffffffffc0203976:	f43e                	sd	a5,40(sp)
     nr_free = 0;
ffffffffc0203978:	000ab797          	auipc	a5,0xab
ffffffffc020397c:	ea07a423          	sw	zero,-344(a5) # ffffffffc02ae820 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc0203980:	000a3503          	ld	a0,0(s4)
ffffffffc0203984:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203986:	0a21                	addi	s4,s4,8
        free_pages(check_rp[i],1);
ffffffffc0203988:	d64fd0ef          	jal	ra,ffffffffc0200eec <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020398c:	ff3a1ae3          	bne	s4,s3,ffffffffc0203980 <swap_init+0x192>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0203990:	01042a03          	lw	s4,16(s0)
ffffffffc0203994:	4791                	li	a5,4
ffffffffc0203996:	42fa1f63          	bne	s4,a5,ffffffffc0203dd4 <swap_init+0x5e6>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc020399a:	00004517          	auipc	a0,0x4
ffffffffc020399e:	43650513          	addi	a0,a0,1078 # ffffffffc0207dd0 <commands+0x1548>
ffffffffc02039a2:	f2afc0ef          	jal	ra,ffffffffc02000cc <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc02039a6:	6705                	lui	a4,0x1
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc02039a8:	000af797          	auipc	a5,0xaf
ffffffffc02039ac:	ee07a023          	sw	zero,-288(a5) # ffffffffc02b2888 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc02039b0:	4629                	li	a2,10
ffffffffc02039b2:	00c70023          	sb	a2,0(a4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
     assert(pgfault_num==1);
ffffffffc02039b6:	000af697          	auipc	a3,0xaf
ffffffffc02039ba:	ed26a683          	lw	a3,-302(a3) # ffffffffc02b2888 <pgfault_num>
ffffffffc02039be:	4585                	li	a1,1
ffffffffc02039c0:	000af797          	auipc	a5,0xaf
ffffffffc02039c4:	ec878793          	addi	a5,a5,-312 # ffffffffc02b2888 <pgfault_num>
ffffffffc02039c8:	54b69663          	bne	a3,a1,ffffffffc0203f14 <swap_init+0x726>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc02039cc:	00c70823          	sb	a2,16(a4)
     assert(pgfault_num==1);
ffffffffc02039d0:	4398                	lw	a4,0(a5)
ffffffffc02039d2:	2701                	sext.w	a4,a4
ffffffffc02039d4:	3ed71063          	bne	a4,a3,ffffffffc0203db4 <swap_init+0x5c6>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc02039d8:	6689                	lui	a3,0x2
ffffffffc02039da:	462d                	li	a2,11
ffffffffc02039dc:	00c68023          	sb	a2,0(a3) # 2000 <_binary_obj___user_faultread_out_size-0x7bb8>
     assert(pgfault_num==2);
ffffffffc02039e0:	4398                	lw	a4,0(a5)
ffffffffc02039e2:	4589                	li	a1,2
ffffffffc02039e4:	2701                	sext.w	a4,a4
ffffffffc02039e6:	4ab71763          	bne	a4,a1,ffffffffc0203e94 <swap_init+0x6a6>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc02039ea:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==2);
ffffffffc02039ee:	4394                	lw	a3,0(a5)
ffffffffc02039f0:	2681                	sext.w	a3,a3
ffffffffc02039f2:	4ce69163          	bne	a3,a4,ffffffffc0203eb4 <swap_init+0x6c6>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc02039f6:	668d                	lui	a3,0x3
ffffffffc02039f8:	4631                	li	a2,12
ffffffffc02039fa:	00c68023          	sb	a2,0(a3) # 3000 <_binary_obj___user_faultread_out_size-0x6bb8>
     assert(pgfault_num==3);
ffffffffc02039fe:	4398                	lw	a4,0(a5)
ffffffffc0203a00:	458d                	li	a1,3
ffffffffc0203a02:	2701                	sext.w	a4,a4
ffffffffc0203a04:	4cb71863          	bne	a4,a1,ffffffffc0203ed4 <swap_init+0x6e6>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc0203a08:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==3);
ffffffffc0203a0c:	4394                	lw	a3,0(a5)
ffffffffc0203a0e:	2681                	sext.w	a3,a3
ffffffffc0203a10:	4ee69263          	bne	a3,a4,ffffffffc0203ef4 <swap_init+0x706>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203a14:	6691                	lui	a3,0x4
ffffffffc0203a16:	4635                	li	a2,13
ffffffffc0203a18:	00c68023          	sb	a2,0(a3) # 4000 <_binary_obj___user_faultread_out_size-0x5bb8>
     assert(pgfault_num==4);
ffffffffc0203a1c:	4398                	lw	a4,0(a5)
ffffffffc0203a1e:	2701                	sext.w	a4,a4
ffffffffc0203a20:	43471a63          	bne	a4,s4,ffffffffc0203e54 <swap_init+0x666>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc0203a24:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==4);
ffffffffc0203a28:	439c                	lw	a5,0(a5)
ffffffffc0203a2a:	2781                	sext.w	a5,a5
ffffffffc0203a2c:	44e79463          	bne	a5,a4,ffffffffc0203e74 <swap_init+0x686>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc0203a30:	481c                	lw	a5,16(s0)
ffffffffc0203a32:	2c079563          	bnez	a5,ffffffffc0203cfc <swap_init+0x50e>
ffffffffc0203a36:	000ab797          	auipc	a5,0xab
ffffffffc0203a3a:	d8a78793          	addi	a5,a5,-630 # ffffffffc02ae7c0 <swap_in_seq_no>
ffffffffc0203a3e:	000ab717          	auipc	a4,0xab
ffffffffc0203a42:	daa70713          	addi	a4,a4,-598 # ffffffffc02ae7e8 <swap_out_seq_no>
ffffffffc0203a46:	000ab617          	auipc	a2,0xab
ffffffffc0203a4a:	da260613          	addi	a2,a2,-606 # ffffffffc02ae7e8 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc0203a4e:	56fd                	li	a3,-1
ffffffffc0203a50:	c394                	sw	a3,0(a5)
ffffffffc0203a52:	c314                	sw	a3,0(a4)
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0203a54:	0791                	addi	a5,a5,4
ffffffffc0203a56:	0711                	addi	a4,a4,4
ffffffffc0203a58:	fec79ce3          	bne	a5,a2,ffffffffc0203a50 <swap_init+0x262>
ffffffffc0203a5c:	000ab717          	auipc	a4,0xab
ffffffffc0203a60:	d2470713          	addi	a4,a4,-732 # ffffffffc02ae780 <check_ptep>
ffffffffc0203a64:	000ab697          	auipc	a3,0xab
ffffffffc0203a68:	d3c68693          	addi	a3,a3,-708 # ffffffffc02ae7a0 <check_rp>
ffffffffc0203a6c:	6585                	lui	a1,0x1
    if (PPN(pa) >= npage) {
ffffffffc0203a6e:	000afc17          	auipc	s8,0xaf
ffffffffc0203a72:	df2c0c13          	addi	s8,s8,-526 # ffffffffc02b2860 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203a76:	000afc97          	auipc	s9,0xaf
ffffffffc0203a7a:	df2c8c93          	addi	s9,s9,-526 # ffffffffc02b2868 <pages>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc0203a7e:	00073023          	sd	zero,0(a4)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0203a82:	4601                	li	a2,0
ffffffffc0203a84:	855a                	mv	a0,s6
ffffffffc0203a86:	e836                	sd	a3,16(sp)
ffffffffc0203a88:	e42e                	sd	a1,8(sp)
         check_ptep[i]=0;
ffffffffc0203a8a:	e03a                	sd	a4,0(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0203a8c:	cdafd0ef          	jal	ra,ffffffffc0200f66 <get_pte>
ffffffffc0203a90:	6702                	ld	a4,0(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc0203a92:	65a2                	ld	a1,8(sp)
ffffffffc0203a94:	66c2                	ld	a3,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0203a96:	e308                	sd	a0,0(a4)
         assert(check_ptep[i] != NULL);
ffffffffc0203a98:	1c050663          	beqz	a0,ffffffffc0203c64 <swap_init+0x476>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0203a9c:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0203a9e:	0017f613          	andi	a2,a5,1
ffffffffc0203aa2:	1e060163          	beqz	a2,ffffffffc0203c84 <swap_init+0x496>
    if (PPN(pa) >= npage) {
ffffffffc0203aa6:	000c3603          	ld	a2,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203aaa:	078a                	slli	a5,a5,0x2
ffffffffc0203aac:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203aae:	14c7f363          	bgeu	a5,a2,ffffffffc0203bf4 <swap_init+0x406>
    return &pages[PPN(pa) - nbase];
ffffffffc0203ab2:	00005617          	auipc	a2,0x5
ffffffffc0203ab6:	23e60613          	addi	a2,a2,574 # ffffffffc0208cf0 <nbase>
ffffffffc0203aba:	00063a03          	ld	s4,0(a2)
ffffffffc0203abe:	000cb603          	ld	a2,0(s9)
ffffffffc0203ac2:	6288                	ld	a0,0(a3)
ffffffffc0203ac4:	414787b3          	sub	a5,a5,s4
ffffffffc0203ac8:	079a                	slli	a5,a5,0x6
ffffffffc0203aca:	97b2                	add	a5,a5,a2
ffffffffc0203acc:	14f51063          	bne	a0,a5,ffffffffc0203c0c <swap_init+0x41e>
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203ad0:	6785                	lui	a5,0x1
ffffffffc0203ad2:	95be                	add	a1,a1,a5
ffffffffc0203ad4:	6795                	lui	a5,0x5
ffffffffc0203ad6:	0721                	addi	a4,a4,8
ffffffffc0203ad8:	06a1                	addi	a3,a3,8
ffffffffc0203ada:	faf592e3          	bne	a1,a5,ffffffffc0203a7e <swap_init+0x290>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0203ade:	00004517          	auipc	a0,0x4
ffffffffc0203ae2:	39a50513          	addi	a0,a0,922 # ffffffffc0207e78 <commands+0x15f0>
ffffffffc0203ae6:	de6fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    int ret = sm->check_swap();
ffffffffc0203aea:	000bb783          	ld	a5,0(s7)
ffffffffc0203aee:	7f9c                	ld	a5,56(a5)
ffffffffc0203af0:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc0203af2:	32051163          	bnez	a0,ffffffffc0203e14 <swap_init+0x626>

     nr_free = nr_free_store;
ffffffffc0203af6:	77a2                	ld	a5,40(sp)
ffffffffc0203af8:	c81c                	sw	a5,16(s0)
     free_list = free_list_store;
ffffffffc0203afa:	67e2                	ld	a5,24(sp)
ffffffffc0203afc:	e01c                	sd	a5,0(s0)
ffffffffc0203afe:	7782                	ld	a5,32(sp)
ffffffffc0203b00:	e41c                	sd	a5,8(s0)

     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc0203b02:	6088                	ld	a0,0(s1)
ffffffffc0203b04:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203b06:	04a1                	addi	s1,s1,8
         free_pages(check_rp[i],1);
ffffffffc0203b08:	be4fd0ef          	jal	ra,ffffffffc0200eec <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203b0c:	ff349be3          	bne	s1,s3,ffffffffc0203b02 <swap_init+0x314>
     } 

     //free_page(pte2page(*temp_ptep));

     mm->pgdir = NULL;
ffffffffc0203b10:	000abc23          	sd	zero,24(s5)
     mm_destroy(mm);
ffffffffc0203b14:	8556                	mv	a0,s5
ffffffffc0203b16:	fe7fe0ef          	jal	ra,ffffffffc0202afc <mm_destroy>
     check_mm_struct = NULL;

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0203b1a:	000af797          	auipc	a5,0xaf
ffffffffc0203b1e:	d3e78793          	addi	a5,a5,-706 # ffffffffc02b2858 <boot_pgdir>
ffffffffc0203b22:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0203b24:	000c3703          	ld	a4,0(s8)
     check_mm_struct = NULL;
ffffffffc0203b28:	000af697          	auipc	a3,0xaf
ffffffffc0203b2c:	d406bc23          	sd	zero,-680(a3) # ffffffffc02b2880 <check_mm_struct>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203b30:	639c                	ld	a5,0(a5)
ffffffffc0203b32:	078a                	slli	a5,a5,0x2
ffffffffc0203b34:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203b36:	0ae7fd63          	bgeu	a5,a4,ffffffffc0203bf0 <swap_init+0x402>
    return &pages[PPN(pa) - nbase];
ffffffffc0203b3a:	414786b3          	sub	a3,a5,s4
ffffffffc0203b3e:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc0203b40:	8699                	srai	a3,a3,0x6
ffffffffc0203b42:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc0203b44:	00c69793          	slli	a5,a3,0xc
ffffffffc0203b48:	83b1                	srli	a5,a5,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0203b4a:	000cb503          	ld	a0,0(s9)
    return page2ppn(page) << PGSHIFT;
ffffffffc0203b4e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203b50:	22e7f663          	bgeu	a5,a4,ffffffffc0203d7c <swap_init+0x58e>
     free_page(pde2page(pd0[0]));
ffffffffc0203b54:	000af797          	auipc	a5,0xaf
ffffffffc0203b58:	d247b783          	ld	a5,-732(a5) # ffffffffc02b2878 <va_pa_offset>
ffffffffc0203b5c:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0203b5e:	629c                	ld	a5,0(a3)
ffffffffc0203b60:	078a                	slli	a5,a5,0x2
ffffffffc0203b62:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203b64:	08e7f663          	bgeu	a5,a4,ffffffffc0203bf0 <swap_init+0x402>
    return &pages[PPN(pa) - nbase];
ffffffffc0203b68:	414787b3          	sub	a5,a5,s4
ffffffffc0203b6c:	079a                	slli	a5,a5,0x6
ffffffffc0203b6e:	953e                	add	a0,a0,a5
ffffffffc0203b70:	4585                	li	a1,1
ffffffffc0203b72:	b7afd0ef          	jal	ra,ffffffffc0200eec <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203b76:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc0203b7a:	000c3703          	ld	a4,0(s8)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203b7e:	078a                	slli	a5,a5,0x2
ffffffffc0203b80:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203b82:	06e7f763          	bgeu	a5,a4,ffffffffc0203bf0 <swap_init+0x402>
    return &pages[PPN(pa) - nbase];
ffffffffc0203b86:	000cb503          	ld	a0,0(s9)
ffffffffc0203b8a:	414787b3          	sub	a5,a5,s4
ffffffffc0203b8e:	079a                	slli	a5,a5,0x6
     free_page(pde2page(pd1[0]));
ffffffffc0203b90:	4585                	li	a1,1
ffffffffc0203b92:	953e                	add	a0,a0,a5
ffffffffc0203b94:	b58fd0ef          	jal	ra,ffffffffc0200eec <free_pages>
     pgdir[0] = 0;
ffffffffc0203b98:	000b3023          	sd	zero,0(s6)
  asm volatile("sfence.vma");
ffffffffc0203b9c:	12000073          	sfence.vma
    return listelm->next;
ffffffffc0203ba0:	641c                	ld	a5,8(s0)
     flush_tlb();

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203ba2:	00878a63          	beq	a5,s0,ffffffffc0203bb6 <swap_init+0x3c8>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc0203ba6:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203baa:	679c                	ld	a5,8(a5)
ffffffffc0203bac:	3dfd                	addiw	s11,s11,-1
ffffffffc0203bae:	40ed0d3b          	subw	s10,s10,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203bb2:	fe879ae3          	bne	a5,s0,ffffffffc0203ba6 <swap_init+0x3b8>
     }
     assert(count==0);
ffffffffc0203bb6:	1c0d9f63          	bnez	s11,ffffffffc0203d94 <swap_init+0x5a6>
     assert(total==0);
ffffffffc0203bba:	1a0d1163          	bnez	s10,ffffffffc0203d5c <swap_init+0x56e>

     cprintf("check_swap() succeeded!\n");
ffffffffc0203bbe:	00004517          	auipc	a0,0x4
ffffffffc0203bc2:	30a50513          	addi	a0,a0,778 # ffffffffc0207ec8 <commands+0x1640>
ffffffffc0203bc6:	d06fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc0203bca:	b99d                	j	ffffffffc0203840 <swap_init+0x52>
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203bcc:	4481                	li	s1,0
ffffffffc0203bce:	b9f1                	j	ffffffffc02038aa <swap_init+0xbc>
        assert(PageProperty(p));
ffffffffc0203bd0:	00004697          	auipc	a3,0x4
ffffffffc0203bd4:	0b868693          	addi	a3,a3,184 # ffffffffc0207c88 <commands+0x1400>
ffffffffc0203bd8:	00003617          	auipc	a2,0x3
ffffffffc0203bdc:	0c060613          	addi	a2,a2,192 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203be0:	0bc00593          	li	a1,188
ffffffffc0203be4:	00004517          	auipc	a0,0x4
ffffffffc0203be8:	07c50513          	addi	a0,a0,124 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203bec:	e1cfc0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0203bf0:	be3ff0ef          	jal	ra,ffffffffc02037d2 <pa2page.part.0>
        panic("pa2page called with invalid pa");
ffffffffc0203bf4:	00003617          	auipc	a2,0x3
ffffffffc0203bf8:	39460613          	addi	a2,a2,916 # ffffffffc0206f88 <commands+0x700>
ffffffffc0203bfc:	06200593          	li	a1,98
ffffffffc0203c00:	00003517          	auipc	a0,0x3
ffffffffc0203c04:	3a850513          	addi	a0,a0,936 # ffffffffc0206fa8 <commands+0x720>
ffffffffc0203c08:	e00fc0ef          	jal	ra,ffffffffc0200208 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0203c0c:	00004697          	auipc	a3,0x4
ffffffffc0203c10:	24468693          	addi	a3,a3,580 # ffffffffc0207e50 <commands+0x15c8>
ffffffffc0203c14:	00003617          	auipc	a2,0x3
ffffffffc0203c18:	08460613          	addi	a2,a2,132 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203c1c:	0fc00593          	li	a1,252
ffffffffc0203c20:	00004517          	auipc	a0,0x4
ffffffffc0203c24:	04050513          	addi	a0,a0,64 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203c28:	de0fc0ef          	jal	ra,ffffffffc0200208 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc0203c2c:	00004697          	auipc	a3,0x4
ffffffffc0203c30:	14468693          	addi	a3,a3,324 # ffffffffc0207d70 <commands+0x14e8>
ffffffffc0203c34:	00003617          	auipc	a2,0x3
ffffffffc0203c38:	06460613          	addi	a2,a2,100 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203c3c:	0dc00593          	li	a1,220
ffffffffc0203c40:	00004517          	auipc	a0,0x4
ffffffffc0203c44:	02050513          	addi	a0,a0,32 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203c48:	dc0fc0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc0203c4c:	00004617          	auipc	a2,0x4
ffffffffc0203c50:	ff460613          	addi	a2,a2,-12 # ffffffffc0207c40 <commands+0x13b8>
ffffffffc0203c54:	02800593          	li	a1,40
ffffffffc0203c58:	00004517          	auipc	a0,0x4
ffffffffc0203c5c:	00850513          	addi	a0,a0,8 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203c60:	da8fc0ef          	jal	ra,ffffffffc0200208 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc0203c64:	00004697          	auipc	a3,0x4
ffffffffc0203c68:	1d468693          	addi	a3,a3,468 # ffffffffc0207e38 <commands+0x15b0>
ffffffffc0203c6c:	00003617          	auipc	a2,0x3
ffffffffc0203c70:	02c60613          	addi	a2,a2,44 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203c74:	0fb00593          	li	a1,251
ffffffffc0203c78:	00004517          	auipc	a0,0x4
ffffffffc0203c7c:	fe850513          	addi	a0,a0,-24 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203c80:	d88fc0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0203c84:	00003617          	auipc	a2,0x3
ffffffffc0203c88:	33460613          	addi	a2,a2,820 # ffffffffc0206fb8 <commands+0x730>
ffffffffc0203c8c:	07400593          	li	a1,116
ffffffffc0203c90:	00003517          	auipc	a0,0x3
ffffffffc0203c94:	31850513          	addi	a0,a0,792 # ffffffffc0206fa8 <commands+0x720>
ffffffffc0203c98:	d70fc0ef          	jal	ra,ffffffffc0200208 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc0203c9c:	00004697          	auipc	a3,0x4
ffffffffc0203ca0:	0ec68693          	addi	a3,a3,236 # ffffffffc0207d88 <commands+0x1500>
ffffffffc0203ca4:	00003617          	auipc	a2,0x3
ffffffffc0203ca8:	ff460613          	addi	a2,a2,-12 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203cac:	0dd00593          	li	a1,221
ffffffffc0203cb0:	00004517          	auipc	a0,0x4
ffffffffc0203cb4:	fb050513          	addi	a0,a0,-80 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203cb8:	d50fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc0203cbc:	00004697          	auipc	a3,0x4
ffffffffc0203cc0:	02468693          	addi	a3,a3,36 # ffffffffc0207ce0 <commands+0x1458>
ffffffffc0203cc4:	00003617          	auipc	a2,0x3
ffffffffc0203cc8:	fd460613          	addi	a2,a2,-44 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203ccc:	0c700593          	li	a1,199
ffffffffc0203cd0:	00004517          	auipc	a0,0x4
ffffffffc0203cd4:	f9050513          	addi	a0,a0,-112 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203cd8:	d30fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(total == nr_free_pages());
ffffffffc0203cdc:	00004697          	auipc	a3,0x4
ffffffffc0203ce0:	fbc68693          	addi	a3,a3,-68 # ffffffffc0207c98 <commands+0x1410>
ffffffffc0203ce4:	00003617          	auipc	a2,0x3
ffffffffc0203ce8:	fb460613          	addi	a2,a2,-76 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203cec:	0bf00593          	li	a1,191
ffffffffc0203cf0:	00004517          	auipc	a0,0x4
ffffffffc0203cf4:	f7050513          	addi	a0,a0,-144 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203cf8:	d10fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert( nr_free == 0);         
ffffffffc0203cfc:	00004697          	auipc	a3,0x4
ffffffffc0203d00:	12c68693          	addi	a3,a3,300 # ffffffffc0207e28 <commands+0x15a0>
ffffffffc0203d04:	00003617          	auipc	a2,0x3
ffffffffc0203d08:	f9460613          	addi	a2,a2,-108 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203d0c:	0f300593          	li	a1,243
ffffffffc0203d10:	00004517          	auipc	a0,0x4
ffffffffc0203d14:	f5050513          	addi	a0,a0,-176 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203d18:	cf0fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgdir[0] == 0);
ffffffffc0203d1c:	00004697          	auipc	a3,0x4
ffffffffc0203d20:	d1c68693          	addi	a3,a3,-740 # ffffffffc0207a38 <commands+0x11b0>
ffffffffc0203d24:	00003617          	auipc	a2,0x3
ffffffffc0203d28:	f7460613          	addi	a2,a2,-140 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203d2c:	0cc00593          	li	a1,204
ffffffffc0203d30:	00004517          	auipc	a0,0x4
ffffffffc0203d34:	f3050513          	addi	a0,a0,-208 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203d38:	cd0fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(mm != NULL);
ffffffffc0203d3c:	00004697          	auipc	a3,0x4
ffffffffc0203d40:	b3468693          	addi	a3,a3,-1228 # ffffffffc0207870 <commands+0xfe8>
ffffffffc0203d44:	00003617          	auipc	a2,0x3
ffffffffc0203d48:	f5460613          	addi	a2,a2,-172 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203d4c:	0c400593          	li	a1,196
ffffffffc0203d50:	00004517          	auipc	a0,0x4
ffffffffc0203d54:	f1050513          	addi	a0,a0,-240 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203d58:	cb0fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(total==0);
ffffffffc0203d5c:	00004697          	auipc	a3,0x4
ffffffffc0203d60:	15c68693          	addi	a3,a3,348 # ffffffffc0207eb8 <commands+0x1630>
ffffffffc0203d64:	00003617          	auipc	a2,0x3
ffffffffc0203d68:	f3460613          	addi	a2,a2,-204 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203d6c:	11e00593          	li	a1,286
ffffffffc0203d70:	00004517          	auipc	a0,0x4
ffffffffc0203d74:	ef050513          	addi	a0,a0,-272 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203d78:	c90fc0ef          	jal	ra,ffffffffc0200208 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203d7c:	00003617          	auipc	a2,0x3
ffffffffc0203d80:	26460613          	addi	a2,a2,612 # ffffffffc0206fe0 <commands+0x758>
ffffffffc0203d84:	06900593          	li	a1,105
ffffffffc0203d88:	00003517          	auipc	a0,0x3
ffffffffc0203d8c:	22050513          	addi	a0,a0,544 # ffffffffc0206fa8 <commands+0x720>
ffffffffc0203d90:	c78fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(count==0);
ffffffffc0203d94:	00004697          	auipc	a3,0x4
ffffffffc0203d98:	11468693          	addi	a3,a3,276 # ffffffffc0207ea8 <commands+0x1620>
ffffffffc0203d9c:	00003617          	auipc	a2,0x3
ffffffffc0203da0:	efc60613          	addi	a2,a2,-260 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203da4:	11d00593          	li	a1,285
ffffffffc0203da8:	00004517          	auipc	a0,0x4
ffffffffc0203dac:	eb850513          	addi	a0,a0,-328 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203db0:	c58fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==1);
ffffffffc0203db4:	00004697          	auipc	a3,0x4
ffffffffc0203db8:	04468693          	addi	a3,a3,68 # ffffffffc0207df8 <commands+0x1570>
ffffffffc0203dbc:	00003617          	auipc	a2,0x3
ffffffffc0203dc0:	edc60613          	addi	a2,a2,-292 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203dc4:	09500593          	li	a1,149
ffffffffc0203dc8:	00004517          	auipc	a0,0x4
ffffffffc0203dcc:	e9850513          	addi	a0,a0,-360 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203dd0:	c38fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0203dd4:	00004697          	auipc	a3,0x4
ffffffffc0203dd8:	fd468693          	addi	a3,a3,-44 # ffffffffc0207da8 <commands+0x1520>
ffffffffc0203ddc:	00003617          	auipc	a2,0x3
ffffffffc0203de0:	ebc60613          	addi	a2,a2,-324 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203de4:	0ea00593          	li	a1,234
ffffffffc0203de8:	00004517          	auipc	a0,0x4
ffffffffc0203dec:	e7850513          	addi	a0,a0,-392 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203df0:	c18fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc0203df4:	00004697          	auipc	a3,0x4
ffffffffc0203df8:	f3c68693          	addi	a3,a3,-196 # ffffffffc0207d30 <commands+0x14a8>
ffffffffc0203dfc:	00003617          	auipc	a2,0x3
ffffffffc0203e00:	e9c60613          	addi	a2,a2,-356 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203e04:	0d700593          	li	a1,215
ffffffffc0203e08:	00004517          	auipc	a0,0x4
ffffffffc0203e0c:	e5850513          	addi	a0,a0,-424 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203e10:	bf8fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(ret==0);
ffffffffc0203e14:	00004697          	auipc	a3,0x4
ffffffffc0203e18:	08c68693          	addi	a3,a3,140 # ffffffffc0207ea0 <commands+0x1618>
ffffffffc0203e1c:	00003617          	auipc	a2,0x3
ffffffffc0203e20:	e7c60613          	addi	a2,a2,-388 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203e24:	10200593          	li	a1,258
ffffffffc0203e28:	00004517          	auipc	a0,0x4
ffffffffc0203e2c:	e3850513          	addi	a0,a0,-456 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203e30:	bd8fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(vma != NULL);
ffffffffc0203e34:	00004697          	auipc	a3,0x4
ffffffffc0203e38:	ca468693          	addi	a3,a3,-860 # ffffffffc0207ad8 <commands+0x1250>
ffffffffc0203e3c:	00003617          	auipc	a2,0x3
ffffffffc0203e40:	e5c60613          	addi	a2,a2,-420 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203e44:	0cf00593          	li	a1,207
ffffffffc0203e48:	00004517          	auipc	a0,0x4
ffffffffc0203e4c:	e1850513          	addi	a0,a0,-488 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203e50:	bb8fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==4);
ffffffffc0203e54:	00003697          	auipc	a3,0x3
ffffffffc0203e58:	7bc68693          	addi	a3,a3,1980 # ffffffffc0207610 <commands+0xd88>
ffffffffc0203e5c:	00003617          	auipc	a2,0x3
ffffffffc0203e60:	e3c60613          	addi	a2,a2,-452 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203e64:	09f00593          	li	a1,159
ffffffffc0203e68:	00004517          	auipc	a0,0x4
ffffffffc0203e6c:	df850513          	addi	a0,a0,-520 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203e70:	b98fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==4);
ffffffffc0203e74:	00003697          	auipc	a3,0x3
ffffffffc0203e78:	79c68693          	addi	a3,a3,1948 # ffffffffc0207610 <commands+0xd88>
ffffffffc0203e7c:	00003617          	auipc	a2,0x3
ffffffffc0203e80:	e1c60613          	addi	a2,a2,-484 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203e84:	0a100593          	li	a1,161
ffffffffc0203e88:	00004517          	auipc	a0,0x4
ffffffffc0203e8c:	dd850513          	addi	a0,a0,-552 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203e90:	b78fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==2);
ffffffffc0203e94:	00004697          	auipc	a3,0x4
ffffffffc0203e98:	f7468693          	addi	a3,a3,-140 # ffffffffc0207e08 <commands+0x1580>
ffffffffc0203e9c:	00003617          	auipc	a2,0x3
ffffffffc0203ea0:	dfc60613          	addi	a2,a2,-516 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203ea4:	09700593          	li	a1,151
ffffffffc0203ea8:	00004517          	auipc	a0,0x4
ffffffffc0203eac:	db850513          	addi	a0,a0,-584 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203eb0:	b58fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==2);
ffffffffc0203eb4:	00004697          	auipc	a3,0x4
ffffffffc0203eb8:	f5468693          	addi	a3,a3,-172 # ffffffffc0207e08 <commands+0x1580>
ffffffffc0203ebc:	00003617          	auipc	a2,0x3
ffffffffc0203ec0:	ddc60613          	addi	a2,a2,-548 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203ec4:	09900593          	li	a1,153
ffffffffc0203ec8:	00004517          	auipc	a0,0x4
ffffffffc0203ecc:	d9850513          	addi	a0,a0,-616 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203ed0:	b38fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==3);
ffffffffc0203ed4:	00004697          	auipc	a3,0x4
ffffffffc0203ed8:	f4468693          	addi	a3,a3,-188 # ffffffffc0207e18 <commands+0x1590>
ffffffffc0203edc:	00003617          	auipc	a2,0x3
ffffffffc0203ee0:	dbc60613          	addi	a2,a2,-580 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203ee4:	09b00593          	li	a1,155
ffffffffc0203ee8:	00004517          	auipc	a0,0x4
ffffffffc0203eec:	d7850513          	addi	a0,a0,-648 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203ef0:	b18fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==3);
ffffffffc0203ef4:	00004697          	auipc	a3,0x4
ffffffffc0203ef8:	f2468693          	addi	a3,a3,-220 # ffffffffc0207e18 <commands+0x1590>
ffffffffc0203efc:	00003617          	auipc	a2,0x3
ffffffffc0203f00:	d9c60613          	addi	a2,a2,-612 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203f04:	09d00593          	li	a1,157
ffffffffc0203f08:	00004517          	auipc	a0,0x4
ffffffffc0203f0c:	d5850513          	addi	a0,a0,-680 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203f10:	af8fc0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==1);
ffffffffc0203f14:	00004697          	auipc	a3,0x4
ffffffffc0203f18:	ee468693          	addi	a3,a3,-284 # ffffffffc0207df8 <commands+0x1570>
ffffffffc0203f1c:	00003617          	auipc	a2,0x3
ffffffffc0203f20:	d7c60613          	addi	a2,a2,-644 # ffffffffc0206c98 <commands+0x410>
ffffffffc0203f24:	09300593          	li	a1,147
ffffffffc0203f28:	00004517          	auipc	a0,0x4
ffffffffc0203f2c:	d3850513          	addi	a0,a0,-712 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc0203f30:	ad8fc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0203f34 <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0203f34:	000af797          	auipc	a5,0xaf
ffffffffc0203f38:	96c7b783          	ld	a5,-1684(a5) # ffffffffc02b28a0 <sm>
ffffffffc0203f3c:	6b9c                	ld	a5,16(a5)
ffffffffc0203f3e:	8782                	jr	a5

ffffffffc0203f40 <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0203f40:	000af797          	auipc	a5,0xaf
ffffffffc0203f44:	9607b783          	ld	a5,-1696(a5) # ffffffffc02b28a0 <sm>
ffffffffc0203f48:	739c                	ld	a5,32(a5)
ffffffffc0203f4a:	8782                	jr	a5

ffffffffc0203f4c <swap_out>:
{
ffffffffc0203f4c:	711d                	addi	sp,sp,-96
ffffffffc0203f4e:	ec86                	sd	ra,88(sp)
ffffffffc0203f50:	e8a2                	sd	s0,80(sp)
ffffffffc0203f52:	e4a6                	sd	s1,72(sp)
ffffffffc0203f54:	e0ca                	sd	s2,64(sp)
ffffffffc0203f56:	fc4e                	sd	s3,56(sp)
ffffffffc0203f58:	f852                	sd	s4,48(sp)
ffffffffc0203f5a:	f456                	sd	s5,40(sp)
ffffffffc0203f5c:	f05a                	sd	s6,32(sp)
ffffffffc0203f5e:	ec5e                	sd	s7,24(sp)
ffffffffc0203f60:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc0203f62:	cde9                	beqz	a1,ffffffffc020403c <swap_out+0xf0>
ffffffffc0203f64:	8a2e                	mv	s4,a1
ffffffffc0203f66:	892a                	mv	s2,a0
ffffffffc0203f68:	8ab2                	mv	s5,a2
ffffffffc0203f6a:	4401                	li	s0,0
ffffffffc0203f6c:	000af997          	auipc	s3,0xaf
ffffffffc0203f70:	93498993          	addi	s3,s3,-1740 # ffffffffc02b28a0 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203f74:	00004b17          	auipc	s6,0x4
ffffffffc0203f78:	fd4b0b13          	addi	s6,s6,-44 # ffffffffc0207f48 <commands+0x16c0>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203f7c:	00004b97          	auipc	s7,0x4
ffffffffc0203f80:	fb4b8b93          	addi	s7,s7,-76 # ffffffffc0207f30 <commands+0x16a8>
ffffffffc0203f84:	a825                	j	ffffffffc0203fbc <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203f86:	67a2                	ld	a5,8(sp)
ffffffffc0203f88:	8626                	mv	a2,s1
ffffffffc0203f8a:	85a2                	mv	a1,s0
ffffffffc0203f8c:	7f94                	ld	a3,56(a5)
ffffffffc0203f8e:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc0203f90:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203f92:	82b1                	srli	a3,a3,0xc
ffffffffc0203f94:	0685                	addi	a3,a3,1
ffffffffc0203f96:	936fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203f9a:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc0203f9c:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203f9e:	7d1c                	ld	a5,56(a0)
ffffffffc0203fa0:	83b1                	srli	a5,a5,0xc
ffffffffc0203fa2:	0785                	addi	a5,a5,1
ffffffffc0203fa4:	07a2                	slli	a5,a5,0x8
ffffffffc0203fa6:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc0203faa:	f43fc0ef          	jal	ra,ffffffffc0200eec <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc0203fae:	01893503          	ld	a0,24(s2)
ffffffffc0203fb2:	85a6                	mv	a1,s1
ffffffffc0203fb4:	cf0fe0ef          	jal	ra,ffffffffc02024a4 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc0203fb8:	048a0d63          	beq	s4,s0,ffffffffc0204012 <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc0203fbc:	0009b783          	ld	a5,0(s3)
ffffffffc0203fc0:	8656                	mv	a2,s5
ffffffffc0203fc2:	002c                	addi	a1,sp,8
ffffffffc0203fc4:	7b9c                	ld	a5,48(a5)
ffffffffc0203fc6:	854a                	mv	a0,s2
ffffffffc0203fc8:	9782                	jalr	a5
          if (r != 0) {
ffffffffc0203fca:	e12d                	bnez	a0,ffffffffc020402c <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc0203fcc:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203fce:	01893503          	ld	a0,24(s2)
ffffffffc0203fd2:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc0203fd4:	7f84                	ld	s1,56(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203fd6:	85a6                	mv	a1,s1
ffffffffc0203fd8:	f8ffc0ef          	jal	ra,ffffffffc0200f66 <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203fdc:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203fde:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc0203fe0:	8b85                	andi	a5,a5,1
ffffffffc0203fe2:	cfb9                	beqz	a5,ffffffffc0204040 <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc0203fe4:	65a2                	ld	a1,8(sp)
ffffffffc0203fe6:	7d9c                	ld	a5,56(a1)
ffffffffc0203fe8:	83b1                	srli	a5,a5,0xc
ffffffffc0203fea:	0785                	addi	a5,a5,1
ffffffffc0203fec:	00879513          	slli	a0,a5,0x8
ffffffffc0203ff0:	45f000ef          	jal	ra,ffffffffc0204c4e <swapfs_write>
ffffffffc0203ff4:	d949                	beqz	a0,ffffffffc0203f86 <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203ff6:	855e                	mv	a0,s7
ffffffffc0203ff8:	8d4fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203ffc:	0009b783          	ld	a5,0(s3)
ffffffffc0204000:	6622                	ld	a2,8(sp)
ffffffffc0204002:	4681                	li	a3,0
ffffffffc0204004:	739c                	ld	a5,32(a5)
ffffffffc0204006:	85a6                	mv	a1,s1
ffffffffc0204008:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc020400a:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc020400c:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc020400e:	fa8a17e3          	bne	s4,s0,ffffffffc0203fbc <swap_out+0x70>
}
ffffffffc0204012:	60e6                	ld	ra,88(sp)
ffffffffc0204014:	8522                	mv	a0,s0
ffffffffc0204016:	6446                	ld	s0,80(sp)
ffffffffc0204018:	64a6                	ld	s1,72(sp)
ffffffffc020401a:	6906                	ld	s2,64(sp)
ffffffffc020401c:	79e2                	ld	s3,56(sp)
ffffffffc020401e:	7a42                	ld	s4,48(sp)
ffffffffc0204020:	7aa2                	ld	s5,40(sp)
ffffffffc0204022:	7b02                	ld	s6,32(sp)
ffffffffc0204024:	6be2                	ld	s7,24(sp)
ffffffffc0204026:	6c42                	ld	s8,16(sp)
ffffffffc0204028:	6125                	addi	sp,sp,96
ffffffffc020402a:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc020402c:	85a2                	mv	a1,s0
ffffffffc020402e:	00004517          	auipc	a0,0x4
ffffffffc0204032:	eba50513          	addi	a0,a0,-326 # ffffffffc0207ee8 <commands+0x1660>
ffffffffc0204036:	896fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
                  break;
ffffffffc020403a:	bfe1                	j	ffffffffc0204012 <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc020403c:	4401                	li	s0,0
ffffffffc020403e:	bfd1                	j	ffffffffc0204012 <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc0204040:	00004697          	auipc	a3,0x4
ffffffffc0204044:	ed868693          	addi	a3,a3,-296 # ffffffffc0207f18 <commands+0x1690>
ffffffffc0204048:	00003617          	auipc	a2,0x3
ffffffffc020404c:	c5060613          	addi	a2,a2,-944 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204050:	06800593          	li	a1,104
ffffffffc0204054:	00004517          	auipc	a0,0x4
ffffffffc0204058:	c0c50513          	addi	a0,a0,-1012 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc020405c:	9acfc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204060 <swap_in>:
{
ffffffffc0204060:	7179                	addi	sp,sp,-48
ffffffffc0204062:	e84a                	sd	s2,16(sp)
ffffffffc0204064:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc0204066:	4505                	li	a0,1
{
ffffffffc0204068:	ec26                	sd	s1,24(sp)
ffffffffc020406a:	e44e                	sd	s3,8(sp)
ffffffffc020406c:	f406                	sd	ra,40(sp)
ffffffffc020406e:	f022                	sd	s0,32(sp)
ffffffffc0204070:	84ae                	mv	s1,a1
ffffffffc0204072:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc0204074:	de7fc0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
     assert(result!=NULL);
ffffffffc0204078:	c129                	beqz	a0,ffffffffc02040ba <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc020407a:	842a                	mv	s0,a0
ffffffffc020407c:	01893503          	ld	a0,24(s2)
ffffffffc0204080:	4601                	li	a2,0
ffffffffc0204082:	85a6                	mv	a1,s1
ffffffffc0204084:	ee3fc0ef          	jal	ra,ffffffffc0200f66 <get_pte>
ffffffffc0204088:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc020408a:	6108                	ld	a0,0(a0)
ffffffffc020408c:	85a2                	mv	a1,s0
ffffffffc020408e:	333000ef          	jal	ra,ffffffffc0204bc0 <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc0204092:	00093583          	ld	a1,0(s2)
ffffffffc0204096:	8626                	mv	a2,s1
ffffffffc0204098:	00004517          	auipc	a0,0x4
ffffffffc020409c:	f0050513          	addi	a0,a0,-256 # ffffffffc0207f98 <commands+0x1710>
ffffffffc02040a0:	81a1                	srli	a1,a1,0x8
ffffffffc02040a2:	82afc0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc02040a6:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc02040a8:	0089b023          	sd	s0,0(s3)
}
ffffffffc02040ac:	7402                	ld	s0,32(sp)
ffffffffc02040ae:	64e2                	ld	s1,24(sp)
ffffffffc02040b0:	6942                	ld	s2,16(sp)
ffffffffc02040b2:	69a2                	ld	s3,8(sp)
ffffffffc02040b4:	4501                	li	a0,0
ffffffffc02040b6:	6145                	addi	sp,sp,48
ffffffffc02040b8:	8082                	ret
     assert(result!=NULL);
ffffffffc02040ba:	00004697          	auipc	a3,0x4
ffffffffc02040be:	ece68693          	addi	a3,a3,-306 # ffffffffc0207f88 <commands+0x1700>
ffffffffc02040c2:	00003617          	auipc	a2,0x3
ffffffffc02040c6:	bd660613          	addi	a2,a2,-1066 # ffffffffc0206c98 <commands+0x410>
ffffffffc02040ca:	07e00593          	li	a1,126
ffffffffc02040ce:	00004517          	auipc	a0,0x4
ffffffffc02040d2:	b9250513          	addi	a0,a0,-1134 # ffffffffc0207c60 <commands+0x13d8>
ffffffffc02040d6:	932fc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02040da <default_init>:
    elm->prev = elm->next = elm;
ffffffffc02040da:	000aa797          	auipc	a5,0xaa
ffffffffc02040de:	73678793          	addi	a5,a5,1846 # ffffffffc02ae810 <free_area>
ffffffffc02040e2:	e79c                	sd	a5,8(a5)
ffffffffc02040e4:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02040e6:	0007a823          	sw	zero,16(a5)
}
ffffffffc02040ea:	8082                	ret

ffffffffc02040ec <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02040ec:	000aa517          	auipc	a0,0xaa
ffffffffc02040f0:	73456503          	lwu	a0,1844(a0) # ffffffffc02ae820 <free_area+0x10>
ffffffffc02040f4:	8082                	ret

ffffffffc02040f6 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc02040f6:	715d                	addi	sp,sp,-80
ffffffffc02040f8:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc02040fa:	000aa417          	auipc	s0,0xaa
ffffffffc02040fe:	71640413          	addi	s0,s0,1814 # ffffffffc02ae810 <free_area>
ffffffffc0204102:	641c                	ld	a5,8(s0)
ffffffffc0204104:	e486                	sd	ra,72(sp)
ffffffffc0204106:	fc26                	sd	s1,56(sp)
ffffffffc0204108:	f84a                	sd	s2,48(sp)
ffffffffc020410a:	f44e                	sd	s3,40(sp)
ffffffffc020410c:	f052                	sd	s4,32(sp)
ffffffffc020410e:	ec56                	sd	s5,24(sp)
ffffffffc0204110:	e85a                	sd	s6,16(sp)
ffffffffc0204112:	e45e                	sd	s7,8(sp)
ffffffffc0204114:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0204116:	2a878d63          	beq	a5,s0,ffffffffc02043d0 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc020411a:	4481                	li	s1,0
ffffffffc020411c:	4901                	li	s2,0
ffffffffc020411e:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0204122:	8b09                	andi	a4,a4,2
ffffffffc0204124:	2a070a63          	beqz	a4,ffffffffc02043d8 <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc0204128:	ff87a703          	lw	a4,-8(a5)
ffffffffc020412c:	679c                	ld	a5,8(a5)
ffffffffc020412e:	2905                	addiw	s2,s2,1
ffffffffc0204130:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0204132:	fe8796e3          	bne	a5,s0,ffffffffc020411e <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0204136:	89a6                	mv	s3,s1
ffffffffc0204138:	df5fc0ef          	jal	ra,ffffffffc0200f2c <nr_free_pages>
ffffffffc020413c:	6f351e63          	bne	a0,s3,ffffffffc0204838 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0204140:	4505                	li	a0,1
ffffffffc0204142:	d19fc0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc0204146:	8aaa                	mv	s5,a0
ffffffffc0204148:	42050863          	beqz	a0,ffffffffc0204578 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020414c:	4505                	li	a0,1
ffffffffc020414e:	d0dfc0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc0204152:	89aa                	mv	s3,a0
ffffffffc0204154:	70050263          	beqz	a0,ffffffffc0204858 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0204158:	4505                	li	a0,1
ffffffffc020415a:	d01fc0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc020415e:	8a2a                	mv	s4,a0
ffffffffc0204160:	48050c63          	beqz	a0,ffffffffc02045f8 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0204164:	293a8a63          	beq	s5,s3,ffffffffc02043f8 <default_check+0x302>
ffffffffc0204168:	28aa8863          	beq	s5,a0,ffffffffc02043f8 <default_check+0x302>
ffffffffc020416c:	28a98663          	beq	s3,a0,ffffffffc02043f8 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0204170:	000aa783          	lw	a5,0(s5)
ffffffffc0204174:	2a079263          	bnez	a5,ffffffffc0204418 <default_check+0x322>
ffffffffc0204178:	0009a783          	lw	a5,0(s3)
ffffffffc020417c:	28079e63          	bnez	a5,ffffffffc0204418 <default_check+0x322>
ffffffffc0204180:	411c                	lw	a5,0(a0)
ffffffffc0204182:	28079b63          	bnez	a5,ffffffffc0204418 <default_check+0x322>
    return page - pages + nbase;
ffffffffc0204186:	000ae797          	auipc	a5,0xae
ffffffffc020418a:	6e27b783          	ld	a5,1762(a5) # ffffffffc02b2868 <pages>
ffffffffc020418e:	40fa8733          	sub	a4,s5,a5
ffffffffc0204192:	00005617          	auipc	a2,0x5
ffffffffc0204196:	b5e63603          	ld	a2,-1186(a2) # ffffffffc0208cf0 <nbase>
ffffffffc020419a:	8719                	srai	a4,a4,0x6
ffffffffc020419c:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020419e:	000ae697          	auipc	a3,0xae
ffffffffc02041a2:	6c26b683          	ld	a3,1730(a3) # ffffffffc02b2860 <npage>
ffffffffc02041a6:	06b2                	slli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02041a8:	0732                	slli	a4,a4,0xc
ffffffffc02041aa:	28d77763          	bgeu	a4,a3,ffffffffc0204438 <default_check+0x342>
    return page - pages + nbase;
ffffffffc02041ae:	40f98733          	sub	a4,s3,a5
ffffffffc02041b2:	8719                	srai	a4,a4,0x6
ffffffffc02041b4:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02041b6:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02041b8:	4cd77063          	bgeu	a4,a3,ffffffffc0204678 <default_check+0x582>
    return page - pages + nbase;
ffffffffc02041bc:	40f507b3          	sub	a5,a0,a5
ffffffffc02041c0:	8799                	srai	a5,a5,0x6
ffffffffc02041c2:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02041c4:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02041c6:	30d7f963          	bgeu	a5,a3,ffffffffc02044d8 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc02041ca:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02041cc:	00043c03          	ld	s8,0(s0)
ffffffffc02041d0:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02041d4:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02041d8:	e400                	sd	s0,8(s0)
ffffffffc02041da:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02041dc:	000aa797          	auipc	a5,0xaa
ffffffffc02041e0:	6407a223          	sw	zero,1604(a5) # ffffffffc02ae820 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02041e4:	c77fc0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc02041e8:	2c051863          	bnez	a0,ffffffffc02044b8 <default_check+0x3c2>
    free_page(p0);
ffffffffc02041ec:	4585                	li	a1,1
ffffffffc02041ee:	8556                	mv	a0,s5
ffffffffc02041f0:	cfdfc0ef          	jal	ra,ffffffffc0200eec <free_pages>
    free_page(p1);
ffffffffc02041f4:	4585                	li	a1,1
ffffffffc02041f6:	854e                	mv	a0,s3
ffffffffc02041f8:	cf5fc0ef          	jal	ra,ffffffffc0200eec <free_pages>
    free_page(p2);
ffffffffc02041fc:	4585                	li	a1,1
ffffffffc02041fe:	8552                	mv	a0,s4
ffffffffc0204200:	cedfc0ef          	jal	ra,ffffffffc0200eec <free_pages>
    assert(nr_free == 3);
ffffffffc0204204:	4818                	lw	a4,16(s0)
ffffffffc0204206:	478d                	li	a5,3
ffffffffc0204208:	28f71863          	bne	a4,a5,ffffffffc0204498 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020420c:	4505                	li	a0,1
ffffffffc020420e:	c4dfc0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc0204212:	89aa                	mv	s3,a0
ffffffffc0204214:	26050263          	beqz	a0,ffffffffc0204478 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0204218:	4505                	li	a0,1
ffffffffc020421a:	c41fc0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc020421e:	8aaa                	mv	s5,a0
ffffffffc0204220:	3a050c63          	beqz	a0,ffffffffc02045d8 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0204224:	4505                	li	a0,1
ffffffffc0204226:	c35fc0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc020422a:	8a2a                	mv	s4,a0
ffffffffc020422c:	38050663          	beqz	a0,ffffffffc02045b8 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0204230:	4505                	li	a0,1
ffffffffc0204232:	c29fc0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc0204236:	36051163          	bnez	a0,ffffffffc0204598 <default_check+0x4a2>
    free_page(p0);
ffffffffc020423a:	4585                	li	a1,1
ffffffffc020423c:	854e                	mv	a0,s3
ffffffffc020423e:	caffc0ef          	jal	ra,ffffffffc0200eec <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0204242:	641c                	ld	a5,8(s0)
ffffffffc0204244:	20878a63          	beq	a5,s0,ffffffffc0204458 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0204248:	4505                	li	a0,1
ffffffffc020424a:	c11fc0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc020424e:	30a99563          	bne	s3,a0,ffffffffc0204558 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0204252:	4505                	li	a0,1
ffffffffc0204254:	c07fc0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc0204258:	2e051063          	bnez	a0,ffffffffc0204538 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc020425c:	481c                	lw	a5,16(s0)
ffffffffc020425e:	2a079d63          	bnez	a5,ffffffffc0204518 <default_check+0x422>
    free_page(p);
ffffffffc0204262:	854e                	mv	a0,s3
ffffffffc0204264:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0204266:	01843023          	sd	s8,0(s0)
ffffffffc020426a:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc020426e:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0204272:	c7bfc0ef          	jal	ra,ffffffffc0200eec <free_pages>
    free_page(p1);
ffffffffc0204276:	4585                	li	a1,1
ffffffffc0204278:	8556                	mv	a0,s5
ffffffffc020427a:	c73fc0ef          	jal	ra,ffffffffc0200eec <free_pages>
    free_page(p2);
ffffffffc020427e:	4585                	li	a1,1
ffffffffc0204280:	8552                	mv	a0,s4
ffffffffc0204282:	c6bfc0ef          	jal	ra,ffffffffc0200eec <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0204286:	4515                	li	a0,5
ffffffffc0204288:	bd3fc0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc020428c:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020428e:	26050563          	beqz	a0,ffffffffc02044f8 <default_check+0x402>
ffffffffc0204292:	651c                	ld	a5,8(a0)
ffffffffc0204294:	8385                	srli	a5,a5,0x1
ffffffffc0204296:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc0204298:	54079063          	bnez	a5,ffffffffc02047d8 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020429c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020429e:	00043b03          	ld	s6,0(s0)
ffffffffc02042a2:	00843a83          	ld	s5,8(s0)
ffffffffc02042a6:	e000                	sd	s0,0(s0)
ffffffffc02042a8:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc02042aa:	bb1fc0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc02042ae:	50051563          	bnez	a0,ffffffffc02047b8 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02042b2:	08098a13          	addi	s4,s3,128
ffffffffc02042b6:	8552                	mv	a0,s4
ffffffffc02042b8:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02042ba:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc02042be:	000aa797          	auipc	a5,0xaa
ffffffffc02042c2:	5607a123          	sw	zero,1378(a5) # ffffffffc02ae820 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02042c6:	c27fc0ef          	jal	ra,ffffffffc0200eec <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02042ca:	4511                	li	a0,4
ffffffffc02042cc:	b8ffc0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc02042d0:	4c051463          	bnez	a0,ffffffffc0204798 <default_check+0x6a2>
ffffffffc02042d4:	0889b783          	ld	a5,136(s3)
ffffffffc02042d8:	8385                	srli	a5,a5,0x1
ffffffffc02042da:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02042dc:	48078e63          	beqz	a5,ffffffffc0204778 <default_check+0x682>
ffffffffc02042e0:	0909a703          	lw	a4,144(s3)
ffffffffc02042e4:	478d                	li	a5,3
ffffffffc02042e6:	48f71963          	bne	a4,a5,ffffffffc0204778 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02042ea:	450d                	li	a0,3
ffffffffc02042ec:	b6ffc0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc02042f0:	8c2a                	mv	s8,a0
ffffffffc02042f2:	46050363          	beqz	a0,ffffffffc0204758 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc02042f6:	4505                	li	a0,1
ffffffffc02042f8:	b63fc0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc02042fc:	42051e63          	bnez	a0,ffffffffc0204738 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0204300:	418a1c63          	bne	s4,s8,ffffffffc0204718 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0204304:	4585                	li	a1,1
ffffffffc0204306:	854e                	mv	a0,s3
ffffffffc0204308:	be5fc0ef          	jal	ra,ffffffffc0200eec <free_pages>
    free_pages(p1, 3);
ffffffffc020430c:	458d                	li	a1,3
ffffffffc020430e:	8552                	mv	a0,s4
ffffffffc0204310:	bddfc0ef          	jal	ra,ffffffffc0200eec <free_pages>
ffffffffc0204314:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0204318:	04098c13          	addi	s8,s3,64
ffffffffc020431c:	8385                	srli	a5,a5,0x1
ffffffffc020431e:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0204320:	3c078c63          	beqz	a5,ffffffffc02046f8 <default_check+0x602>
ffffffffc0204324:	0109a703          	lw	a4,16(s3)
ffffffffc0204328:	4785                	li	a5,1
ffffffffc020432a:	3cf71763          	bne	a4,a5,ffffffffc02046f8 <default_check+0x602>
ffffffffc020432e:	008a3783          	ld	a5,8(s4)
ffffffffc0204332:	8385                	srli	a5,a5,0x1
ffffffffc0204334:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0204336:	3a078163          	beqz	a5,ffffffffc02046d8 <default_check+0x5e2>
ffffffffc020433a:	010a2703          	lw	a4,16(s4)
ffffffffc020433e:	478d                	li	a5,3
ffffffffc0204340:	38f71c63          	bne	a4,a5,ffffffffc02046d8 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0204344:	4505                	li	a0,1
ffffffffc0204346:	b15fc0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc020434a:	36a99763          	bne	s3,a0,ffffffffc02046b8 <default_check+0x5c2>
    free_page(p0);
ffffffffc020434e:	4585                	li	a1,1
ffffffffc0204350:	b9dfc0ef          	jal	ra,ffffffffc0200eec <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0204354:	4509                	li	a0,2
ffffffffc0204356:	b05fc0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc020435a:	32aa1f63          	bne	s4,a0,ffffffffc0204698 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc020435e:	4589                	li	a1,2
ffffffffc0204360:	b8dfc0ef          	jal	ra,ffffffffc0200eec <free_pages>
    free_page(p2);
ffffffffc0204364:	4585                	li	a1,1
ffffffffc0204366:	8562                	mv	a0,s8
ffffffffc0204368:	b85fc0ef          	jal	ra,ffffffffc0200eec <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020436c:	4515                	li	a0,5
ffffffffc020436e:	aedfc0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc0204372:	89aa                	mv	s3,a0
ffffffffc0204374:	48050263          	beqz	a0,ffffffffc02047f8 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0204378:	4505                	li	a0,1
ffffffffc020437a:	ae1fc0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc020437e:	2c051d63          	bnez	a0,ffffffffc0204658 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0204382:	481c                	lw	a5,16(s0)
ffffffffc0204384:	2a079a63          	bnez	a5,ffffffffc0204638 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0204388:	4595                	li	a1,5
ffffffffc020438a:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc020438c:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0204390:	01643023          	sd	s6,0(s0)
ffffffffc0204394:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0204398:	b55fc0ef          	jal	ra,ffffffffc0200eec <free_pages>
    return listelm->next;
ffffffffc020439c:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020439e:	00878963          	beq	a5,s0,ffffffffc02043b0 <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc02043a2:	ff87a703          	lw	a4,-8(a5)
ffffffffc02043a6:	679c                	ld	a5,8(a5)
ffffffffc02043a8:	397d                	addiw	s2,s2,-1
ffffffffc02043aa:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02043ac:	fe879be3          	bne	a5,s0,ffffffffc02043a2 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02043b0:	26091463          	bnez	s2,ffffffffc0204618 <default_check+0x522>
    assert(total == 0);
ffffffffc02043b4:	46049263          	bnez	s1,ffffffffc0204818 <default_check+0x722>
}
ffffffffc02043b8:	60a6                	ld	ra,72(sp)
ffffffffc02043ba:	6406                	ld	s0,64(sp)
ffffffffc02043bc:	74e2                	ld	s1,56(sp)
ffffffffc02043be:	7942                	ld	s2,48(sp)
ffffffffc02043c0:	79a2                	ld	s3,40(sp)
ffffffffc02043c2:	7a02                	ld	s4,32(sp)
ffffffffc02043c4:	6ae2                	ld	s5,24(sp)
ffffffffc02043c6:	6b42                	ld	s6,16(sp)
ffffffffc02043c8:	6ba2                	ld	s7,8(sp)
ffffffffc02043ca:	6c02                	ld	s8,0(sp)
ffffffffc02043cc:	6161                	addi	sp,sp,80
ffffffffc02043ce:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc02043d0:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02043d2:	4481                	li	s1,0
ffffffffc02043d4:	4901                	li	s2,0
ffffffffc02043d6:	b38d                	j	ffffffffc0204138 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02043d8:	00004697          	auipc	a3,0x4
ffffffffc02043dc:	8b068693          	addi	a3,a3,-1872 # ffffffffc0207c88 <commands+0x1400>
ffffffffc02043e0:	00003617          	auipc	a2,0x3
ffffffffc02043e4:	8b860613          	addi	a2,a2,-1864 # ffffffffc0206c98 <commands+0x410>
ffffffffc02043e8:	0f000593          	li	a1,240
ffffffffc02043ec:	00004517          	auipc	a0,0x4
ffffffffc02043f0:	bec50513          	addi	a0,a0,-1044 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc02043f4:	e15fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02043f8:	00004697          	auipc	a3,0x4
ffffffffc02043fc:	c5868693          	addi	a3,a3,-936 # ffffffffc0208050 <commands+0x17c8>
ffffffffc0204400:	00003617          	auipc	a2,0x3
ffffffffc0204404:	89860613          	addi	a2,a2,-1896 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204408:	0bd00593          	li	a1,189
ffffffffc020440c:	00004517          	auipc	a0,0x4
ffffffffc0204410:	bcc50513          	addi	a0,a0,-1076 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204414:	df5fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0204418:	00004697          	auipc	a3,0x4
ffffffffc020441c:	c6068693          	addi	a3,a3,-928 # ffffffffc0208078 <commands+0x17f0>
ffffffffc0204420:	00003617          	auipc	a2,0x3
ffffffffc0204424:	87860613          	addi	a2,a2,-1928 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204428:	0be00593          	li	a1,190
ffffffffc020442c:	00004517          	auipc	a0,0x4
ffffffffc0204430:	bac50513          	addi	a0,a0,-1108 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204434:	dd5fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0204438:	00004697          	auipc	a3,0x4
ffffffffc020443c:	c8068693          	addi	a3,a3,-896 # ffffffffc02080b8 <commands+0x1830>
ffffffffc0204440:	00003617          	auipc	a2,0x3
ffffffffc0204444:	85860613          	addi	a2,a2,-1960 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204448:	0c000593          	li	a1,192
ffffffffc020444c:	00004517          	auipc	a0,0x4
ffffffffc0204450:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204454:	db5fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0204458:	00004697          	auipc	a3,0x4
ffffffffc020445c:	ce868693          	addi	a3,a3,-792 # ffffffffc0208140 <commands+0x18b8>
ffffffffc0204460:	00003617          	auipc	a2,0x3
ffffffffc0204464:	83860613          	addi	a2,a2,-1992 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204468:	0d900593          	li	a1,217
ffffffffc020446c:	00004517          	auipc	a0,0x4
ffffffffc0204470:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204474:	d95fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0204478:	00004697          	auipc	a3,0x4
ffffffffc020447c:	b7868693          	addi	a3,a3,-1160 # ffffffffc0207ff0 <commands+0x1768>
ffffffffc0204480:	00003617          	auipc	a2,0x3
ffffffffc0204484:	81860613          	addi	a2,a2,-2024 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204488:	0d200593          	li	a1,210
ffffffffc020448c:	00004517          	auipc	a0,0x4
ffffffffc0204490:	b4c50513          	addi	a0,a0,-1204 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204494:	d75fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(nr_free == 3);
ffffffffc0204498:	00004697          	auipc	a3,0x4
ffffffffc020449c:	c9868693          	addi	a3,a3,-872 # ffffffffc0208130 <commands+0x18a8>
ffffffffc02044a0:	00002617          	auipc	a2,0x2
ffffffffc02044a4:	7f860613          	addi	a2,a2,2040 # ffffffffc0206c98 <commands+0x410>
ffffffffc02044a8:	0d000593          	li	a1,208
ffffffffc02044ac:	00004517          	auipc	a0,0x4
ffffffffc02044b0:	b2c50513          	addi	a0,a0,-1236 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc02044b4:	d55fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02044b8:	00004697          	auipc	a3,0x4
ffffffffc02044bc:	c6068693          	addi	a3,a3,-928 # ffffffffc0208118 <commands+0x1890>
ffffffffc02044c0:	00002617          	auipc	a2,0x2
ffffffffc02044c4:	7d860613          	addi	a2,a2,2008 # ffffffffc0206c98 <commands+0x410>
ffffffffc02044c8:	0cb00593          	li	a1,203
ffffffffc02044cc:	00004517          	auipc	a0,0x4
ffffffffc02044d0:	b0c50513          	addi	a0,a0,-1268 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc02044d4:	d35fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02044d8:	00004697          	auipc	a3,0x4
ffffffffc02044dc:	c2068693          	addi	a3,a3,-992 # ffffffffc02080f8 <commands+0x1870>
ffffffffc02044e0:	00002617          	auipc	a2,0x2
ffffffffc02044e4:	7b860613          	addi	a2,a2,1976 # ffffffffc0206c98 <commands+0x410>
ffffffffc02044e8:	0c200593          	li	a1,194
ffffffffc02044ec:	00004517          	auipc	a0,0x4
ffffffffc02044f0:	aec50513          	addi	a0,a0,-1300 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc02044f4:	d15fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(p0 != NULL);
ffffffffc02044f8:	00004697          	auipc	a3,0x4
ffffffffc02044fc:	c8068693          	addi	a3,a3,-896 # ffffffffc0208178 <commands+0x18f0>
ffffffffc0204500:	00002617          	auipc	a2,0x2
ffffffffc0204504:	79860613          	addi	a2,a2,1944 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204508:	0f800593          	li	a1,248
ffffffffc020450c:	00004517          	auipc	a0,0x4
ffffffffc0204510:	acc50513          	addi	a0,a0,-1332 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204514:	cf5fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(nr_free == 0);
ffffffffc0204518:	00004697          	auipc	a3,0x4
ffffffffc020451c:	91068693          	addi	a3,a3,-1776 # ffffffffc0207e28 <commands+0x15a0>
ffffffffc0204520:	00002617          	auipc	a2,0x2
ffffffffc0204524:	77860613          	addi	a2,a2,1912 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204528:	0df00593          	li	a1,223
ffffffffc020452c:	00004517          	auipc	a0,0x4
ffffffffc0204530:	aac50513          	addi	a0,a0,-1364 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204534:	cd5fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0204538:	00004697          	auipc	a3,0x4
ffffffffc020453c:	be068693          	addi	a3,a3,-1056 # ffffffffc0208118 <commands+0x1890>
ffffffffc0204540:	00002617          	auipc	a2,0x2
ffffffffc0204544:	75860613          	addi	a2,a2,1880 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204548:	0dd00593          	li	a1,221
ffffffffc020454c:	00004517          	auipc	a0,0x4
ffffffffc0204550:	a8c50513          	addi	a0,a0,-1396 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204554:	cb5fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0204558:	00004697          	auipc	a3,0x4
ffffffffc020455c:	c0068693          	addi	a3,a3,-1024 # ffffffffc0208158 <commands+0x18d0>
ffffffffc0204560:	00002617          	auipc	a2,0x2
ffffffffc0204564:	73860613          	addi	a2,a2,1848 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204568:	0dc00593          	li	a1,220
ffffffffc020456c:	00004517          	auipc	a0,0x4
ffffffffc0204570:	a6c50513          	addi	a0,a0,-1428 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204574:	c95fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0204578:	00004697          	auipc	a3,0x4
ffffffffc020457c:	a7868693          	addi	a3,a3,-1416 # ffffffffc0207ff0 <commands+0x1768>
ffffffffc0204580:	00002617          	auipc	a2,0x2
ffffffffc0204584:	71860613          	addi	a2,a2,1816 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204588:	0b900593          	li	a1,185
ffffffffc020458c:	00004517          	auipc	a0,0x4
ffffffffc0204590:	a4c50513          	addi	a0,a0,-1460 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204594:	c75fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0204598:	00004697          	auipc	a3,0x4
ffffffffc020459c:	b8068693          	addi	a3,a3,-1152 # ffffffffc0208118 <commands+0x1890>
ffffffffc02045a0:	00002617          	auipc	a2,0x2
ffffffffc02045a4:	6f860613          	addi	a2,a2,1784 # ffffffffc0206c98 <commands+0x410>
ffffffffc02045a8:	0d600593          	li	a1,214
ffffffffc02045ac:	00004517          	auipc	a0,0x4
ffffffffc02045b0:	a2c50513          	addi	a0,a0,-1492 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc02045b4:	c55fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02045b8:	00004697          	auipc	a3,0x4
ffffffffc02045bc:	a7868693          	addi	a3,a3,-1416 # ffffffffc0208030 <commands+0x17a8>
ffffffffc02045c0:	00002617          	auipc	a2,0x2
ffffffffc02045c4:	6d860613          	addi	a2,a2,1752 # ffffffffc0206c98 <commands+0x410>
ffffffffc02045c8:	0d400593          	li	a1,212
ffffffffc02045cc:	00004517          	auipc	a0,0x4
ffffffffc02045d0:	a0c50513          	addi	a0,a0,-1524 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc02045d4:	c35fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02045d8:	00004697          	auipc	a3,0x4
ffffffffc02045dc:	a3868693          	addi	a3,a3,-1480 # ffffffffc0208010 <commands+0x1788>
ffffffffc02045e0:	00002617          	auipc	a2,0x2
ffffffffc02045e4:	6b860613          	addi	a2,a2,1720 # ffffffffc0206c98 <commands+0x410>
ffffffffc02045e8:	0d300593          	li	a1,211
ffffffffc02045ec:	00004517          	auipc	a0,0x4
ffffffffc02045f0:	9ec50513          	addi	a0,a0,-1556 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc02045f4:	c15fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02045f8:	00004697          	auipc	a3,0x4
ffffffffc02045fc:	a3868693          	addi	a3,a3,-1480 # ffffffffc0208030 <commands+0x17a8>
ffffffffc0204600:	00002617          	auipc	a2,0x2
ffffffffc0204604:	69860613          	addi	a2,a2,1688 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204608:	0bb00593          	li	a1,187
ffffffffc020460c:	00004517          	auipc	a0,0x4
ffffffffc0204610:	9cc50513          	addi	a0,a0,-1588 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204614:	bf5fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(count == 0);
ffffffffc0204618:	00004697          	auipc	a3,0x4
ffffffffc020461c:	cb068693          	addi	a3,a3,-848 # ffffffffc02082c8 <commands+0x1a40>
ffffffffc0204620:	00002617          	auipc	a2,0x2
ffffffffc0204624:	67860613          	addi	a2,a2,1656 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204628:	12500593          	li	a1,293
ffffffffc020462c:	00004517          	auipc	a0,0x4
ffffffffc0204630:	9ac50513          	addi	a0,a0,-1620 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204634:	bd5fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(nr_free == 0);
ffffffffc0204638:	00003697          	auipc	a3,0x3
ffffffffc020463c:	7f068693          	addi	a3,a3,2032 # ffffffffc0207e28 <commands+0x15a0>
ffffffffc0204640:	00002617          	auipc	a2,0x2
ffffffffc0204644:	65860613          	addi	a2,a2,1624 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204648:	11a00593          	li	a1,282
ffffffffc020464c:	00004517          	auipc	a0,0x4
ffffffffc0204650:	98c50513          	addi	a0,a0,-1652 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204654:	bb5fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0204658:	00004697          	auipc	a3,0x4
ffffffffc020465c:	ac068693          	addi	a3,a3,-1344 # ffffffffc0208118 <commands+0x1890>
ffffffffc0204660:	00002617          	auipc	a2,0x2
ffffffffc0204664:	63860613          	addi	a2,a2,1592 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204668:	11800593          	li	a1,280
ffffffffc020466c:	00004517          	auipc	a0,0x4
ffffffffc0204670:	96c50513          	addi	a0,a0,-1684 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204674:	b95fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0204678:	00004697          	auipc	a3,0x4
ffffffffc020467c:	a6068693          	addi	a3,a3,-1440 # ffffffffc02080d8 <commands+0x1850>
ffffffffc0204680:	00002617          	auipc	a2,0x2
ffffffffc0204684:	61860613          	addi	a2,a2,1560 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204688:	0c100593          	li	a1,193
ffffffffc020468c:	00004517          	auipc	a0,0x4
ffffffffc0204690:	94c50513          	addi	a0,a0,-1716 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204694:	b75fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0204698:	00004697          	auipc	a3,0x4
ffffffffc020469c:	bf068693          	addi	a3,a3,-1040 # ffffffffc0208288 <commands+0x1a00>
ffffffffc02046a0:	00002617          	auipc	a2,0x2
ffffffffc02046a4:	5f860613          	addi	a2,a2,1528 # ffffffffc0206c98 <commands+0x410>
ffffffffc02046a8:	11200593          	li	a1,274
ffffffffc02046ac:	00004517          	auipc	a0,0x4
ffffffffc02046b0:	92c50513          	addi	a0,a0,-1748 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc02046b4:	b55fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02046b8:	00004697          	auipc	a3,0x4
ffffffffc02046bc:	bb068693          	addi	a3,a3,-1104 # ffffffffc0208268 <commands+0x19e0>
ffffffffc02046c0:	00002617          	auipc	a2,0x2
ffffffffc02046c4:	5d860613          	addi	a2,a2,1496 # ffffffffc0206c98 <commands+0x410>
ffffffffc02046c8:	11000593          	li	a1,272
ffffffffc02046cc:	00004517          	auipc	a0,0x4
ffffffffc02046d0:	90c50513          	addi	a0,a0,-1780 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc02046d4:	b35fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02046d8:	00004697          	auipc	a3,0x4
ffffffffc02046dc:	b6868693          	addi	a3,a3,-1176 # ffffffffc0208240 <commands+0x19b8>
ffffffffc02046e0:	00002617          	auipc	a2,0x2
ffffffffc02046e4:	5b860613          	addi	a2,a2,1464 # ffffffffc0206c98 <commands+0x410>
ffffffffc02046e8:	10e00593          	li	a1,270
ffffffffc02046ec:	00004517          	auipc	a0,0x4
ffffffffc02046f0:	8ec50513          	addi	a0,a0,-1812 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc02046f4:	b15fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02046f8:	00004697          	auipc	a3,0x4
ffffffffc02046fc:	b2068693          	addi	a3,a3,-1248 # ffffffffc0208218 <commands+0x1990>
ffffffffc0204700:	00002617          	auipc	a2,0x2
ffffffffc0204704:	59860613          	addi	a2,a2,1432 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204708:	10d00593          	li	a1,269
ffffffffc020470c:	00004517          	auipc	a0,0x4
ffffffffc0204710:	8cc50513          	addi	a0,a0,-1844 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204714:	af5fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0204718:	00004697          	auipc	a3,0x4
ffffffffc020471c:	af068693          	addi	a3,a3,-1296 # ffffffffc0208208 <commands+0x1980>
ffffffffc0204720:	00002617          	auipc	a2,0x2
ffffffffc0204724:	57860613          	addi	a2,a2,1400 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204728:	10800593          	li	a1,264
ffffffffc020472c:	00004517          	auipc	a0,0x4
ffffffffc0204730:	8ac50513          	addi	a0,a0,-1876 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204734:	ad5fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0204738:	00004697          	auipc	a3,0x4
ffffffffc020473c:	9e068693          	addi	a3,a3,-1568 # ffffffffc0208118 <commands+0x1890>
ffffffffc0204740:	00002617          	auipc	a2,0x2
ffffffffc0204744:	55860613          	addi	a2,a2,1368 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204748:	10700593          	li	a1,263
ffffffffc020474c:	00004517          	auipc	a0,0x4
ffffffffc0204750:	88c50513          	addi	a0,a0,-1908 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204754:	ab5fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0204758:	00004697          	auipc	a3,0x4
ffffffffc020475c:	a9068693          	addi	a3,a3,-1392 # ffffffffc02081e8 <commands+0x1960>
ffffffffc0204760:	00002617          	auipc	a2,0x2
ffffffffc0204764:	53860613          	addi	a2,a2,1336 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204768:	10600593          	li	a1,262
ffffffffc020476c:	00004517          	auipc	a0,0x4
ffffffffc0204770:	86c50513          	addi	a0,a0,-1940 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204774:	a95fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0204778:	00004697          	auipc	a3,0x4
ffffffffc020477c:	a4068693          	addi	a3,a3,-1472 # ffffffffc02081b8 <commands+0x1930>
ffffffffc0204780:	00002617          	auipc	a2,0x2
ffffffffc0204784:	51860613          	addi	a2,a2,1304 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204788:	10500593          	li	a1,261
ffffffffc020478c:	00004517          	auipc	a0,0x4
ffffffffc0204790:	84c50513          	addi	a0,a0,-1972 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204794:	a75fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0204798:	00004697          	auipc	a3,0x4
ffffffffc020479c:	a0868693          	addi	a3,a3,-1528 # ffffffffc02081a0 <commands+0x1918>
ffffffffc02047a0:	00002617          	auipc	a2,0x2
ffffffffc02047a4:	4f860613          	addi	a2,a2,1272 # ffffffffc0206c98 <commands+0x410>
ffffffffc02047a8:	10400593          	li	a1,260
ffffffffc02047ac:	00004517          	auipc	a0,0x4
ffffffffc02047b0:	82c50513          	addi	a0,a0,-2004 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc02047b4:	a55fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02047b8:	00004697          	auipc	a3,0x4
ffffffffc02047bc:	96068693          	addi	a3,a3,-1696 # ffffffffc0208118 <commands+0x1890>
ffffffffc02047c0:	00002617          	auipc	a2,0x2
ffffffffc02047c4:	4d860613          	addi	a2,a2,1240 # ffffffffc0206c98 <commands+0x410>
ffffffffc02047c8:	0fe00593          	li	a1,254
ffffffffc02047cc:	00004517          	auipc	a0,0x4
ffffffffc02047d0:	80c50513          	addi	a0,a0,-2036 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc02047d4:	a35fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(!PageProperty(p0));
ffffffffc02047d8:	00004697          	auipc	a3,0x4
ffffffffc02047dc:	9b068693          	addi	a3,a3,-1616 # ffffffffc0208188 <commands+0x1900>
ffffffffc02047e0:	00002617          	auipc	a2,0x2
ffffffffc02047e4:	4b860613          	addi	a2,a2,1208 # ffffffffc0206c98 <commands+0x410>
ffffffffc02047e8:	0f900593          	li	a1,249
ffffffffc02047ec:	00003517          	auipc	a0,0x3
ffffffffc02047f0:	7ec50513          	addi	a0,a0,2028 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc02047f4:	a15fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02047f8:	00004697          	auipc	a3,0x4
ffffffffc02047fc:	ab068693          	addi	a3,a3,-1360 # ffffffffc02082a8 <commands+0x1a20>
ffffffffc0204800:	00002617          	auipc	a2,0x2
ffffffffc0204804:	49860613          	addi	a2,a2,1176 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204808:	11700593          	li	a1,279
ffffffffc020480c:	00003517          	auipc	a0,0x3
ffffffffc0204810:	7cc50513          	addi	a0,a0,1996 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204814:	9f5fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(total == 0);
ffffffffc0204818:	00004697          	auipc	a3,0x4
ffffffffc020481c:	ac068693          	addi	a3,a3,-1344 # ffffffffc02082d8 <commands+0x1a50>
ffffffffc0204820:	00002617          	auipc	a2,0x2
ffffffffc0204824:	47860613          	addi	a2,a2,1144 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204828:	12600593          	li	a1,294
ffffffffc020482c:	00003517          	auipc	a0,0x3
ffffffffc0204830:	7ac50513          	addi	a0,a0,1964 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204834:	9d5fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(total == nr_free_pages());
ffffffffc0204838:	00003697          	auipc	a3,0x3
ffffffffc020483c:	46068693          	addi	a3,a3,1120 # ffffffffc0207c98 <commands+0x1410>
ffffffffc0204840:	00002617          	auipc	a2,0x2
ffffffffc0204844:	45860613          	addi	a2,a2,1112 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204848:	0f300593          	li	a1,243
ffffffffc020484c:	00003517          	auipc	a0,0x3
ffffffffc0204850:	78c50513          	addi	a0,a0,1932 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204854:	9b5fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0204858:	00003697          	auipc	a3,0x3
ffffffffc020485c:	7b868693          	addi	a3,a3,1976 # ffffffffc0208010 <commands+0x1788>
ffffffffc0204860:	00002617          	auipc	a2,0x2
ffffffffc0204864:	43860613          	addi	a2,a2,1080 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204868:	0ba00593          	li	a1,186
ffffffffc020486c:	00003517          	auipc	a0,0x3
ffffffffc0204870:	76c50513          	addi	a0,a0,1900 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204874:	995fb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204878 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0204878:	1141                	addi	sp,sp,-16
ffffffffc020487a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020487c:	14058463          	beqz	a1,ffffffffc02049c4 <default_free_pages+0x14c>
    for (; p != base + n; p ++) {
ffffffffc0204880:	00659693          	slli	a3,a1,0x6
ffffffffc0204884:	96aa                	add	a3,a3,a0
ffffffffc0204886:	87aa                	mv	a5,a0
ffffffffc0204888:	02d50263          	beq	a0,a3,ffffffffc02048ac <default_free_pages+0x34>
ffffffffc020488c:	6798                	ld	a4,8(a5)
ffffffffc020488e:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0204890:	10071a63          	bnez	a4,ffffffffc02049a4 <default_free_pages+0x12c>
ffffffffc0204894:	6798                	ld	a4,8(a5)
ffffffffc0204896:	8b09                	andi	a4,a4,2
ffffffffc0204898:	10071663          	bnez	a4,ffffffffc02049a4 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc020489c:	0007b423          	sd	zero,8(a5)
    page->ref = val;
ffffffffc02048a0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02048a4:	04078793          	addi	a5,a5,64
ffffffffc02048a8:	fed792e3          	bne	a5,a3,ffffffffc020488c <default_free_pages+0x14>
    base->property = n;
ffffffffc02048ac:	2581                	sext.w	a1,a1
ffffffffc02048ae:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02048b0:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02048b4:	4789                	li	a5,2
ffffffffc02048b6:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02048ba:	000aa697          	auipc	a3,0xaa
ffffffffc02048be:	f5668693          	addi	a3,a3,-170 # ffffffffc02ae810 <free_area>
ffffffffc02048c2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02048c4:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02048c6:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02048ca:	9db9                	addw	a1,a1,a4
ffffffffc02048cc:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02048ce:	0ad78463          	beq	a5,a3,ffffffffc0204976 <default_free_pages+0xfe>
            struct Page* page = le2page(le, page_link);
ffffffffc02048d2:	fe878713          	addi	a4,a5,-24
ffffffffc02048d6:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02048da:	4581                	li	a1,0
            if (base < page) {
ffffffffc02048dc:	00e56a63          	bltu	a0,a4,ffffffffc02048f0 <default_free_pages+0x78>
    return listelm->next;
ffffffffc02048e0:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02048e2:	04d70c63          	beq	a4,a3,ffffffffc020493a <default_free_pages+0xc2>
    for (; p != base + n; p ++) {
ffffffffc02048e6:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02048e8:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02048ec:	fee57ae3          	bgeu	a0,a4,ffffffffc02048e0 <default_free_pages+0x68>
ffffffffc02048f0:	c199                	beqz	a1,ffffffffc02048f6 <default_free_pages+0x7e>
ffffffffc02048f2:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02048f6:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc02048f8:	e390                	sd	a2,0(a5)
ffffffffc02048fa:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02048fc:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02048fe:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0204900:	00d70d63          	beq	a4,a3,ffffffffc020491a <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc0204904:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0204908:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc020490c:	02059813          	slli	a6,a1,0x20
ffffffffc0204910:	01a85793          	srli	a5,a6,0x1a
ffffffffc0204914:	97b2                	add	a5,a5,a2
ffffffffc0204916:	02f50c63          	beq	a0,a5,ffffffffc020494e <default_free_pages+0xd6>
    return listelm->next;
ffffffffc020491a:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc020491c:	00d78c63          	beq	a5,a3,ffffffffc0204934 <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc0204920:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0204922:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc0204926:	02061593          	slli	a1,a2,0x20
ffffffffc020492a:	01a5d713          	srli	a4,a1,0x1a
ffffffffc020492e:	972a                	add	a4,a4,a0
ffffffffc0204930:	04e68a63          	beq	a3,a4,ffffffffc0204984 <default_free_pages+0x10c>
}
ffffffffc0204934:	60a2                	ld	ra,8(sp)
ffffffffc0204936:	0141                	addi	sp,sp,16
ffffffffc0204938:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020493a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020493c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020493e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0204940:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0204942:	02d70763          	beq	a4,a3,ffffffffc0204970 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0204946:	8832                	mv	a6,a2
ffffffffc0204948:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020494a:	87ba                	mv	a5,a4
ffffffffc020494c:	bf71                	j	ffffffffc02048e8 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc020494e:	491c                	lw	a5,16(a0)
ffffffffc0204950:	9dbd                	addw	a1,a1,a5
ffffffffc0204952:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204956:	57f5                	li	a5,-3
ffffffffc0204958:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020495c:	01853803          	ld	a6,24(a0)
ffffffffc0204960:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0204962:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc0204964:	00b83423          	sd	a1,8(a6) # fffffffffff80008 <end+0x3fccd73c>
    return listelm->next;
ffffffffc0204968:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020496a:	0105b023          	sd	a6,0(a1) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc020496e:	b77d                	j	ffffffffc020491c <default_free_pages+0xa4>
ffffffffc0204970:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0204972:	873e                	mv	a4,a5
ffffffffc0204974:	bf41                	j	ffffffffc0204904 <default_free_pages+0x8c>
}
ffffffffc0204976:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0204978:	e390                	sd	a2,0(a5)
ffffffffc020497a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020497c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020497e:	ed1c                	sd	a5,24(a0)
ffffffffc0204980:	0141                	addi	sp,sp,16
ffffffffc0204982:	8082                	ret
            base->property += p->property;
ffffffffc0204984:	ff87a703          	lw	a4,-8(a5)
ffffffffc0204988:	ff078693          	addi	a3,a5,-16
ffffffffc020498c:	9e39                	addw	a2,a2,a4
ffffffffc020498e:	c910                	sw	a2,16(a0)
ffffffffc0204990:	5775                	li	a4,-3
ffffffffc0204992:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204996:	6398                	ld	a4,0(a5)
ffffffffc0204998:	679c                	ld	a5,8(a5)
}
ffffffffc020499a:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020499c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020499e:	e398                	sd	a4,0(a5)
ffffffffc02049a0:	0141                	addi	sp,sp,16
ffffffffc02049a2:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02049a4:	00004697          	auipc	a3,0x4
ffffffffc02049a8:	94c68693          	addi	a3,a3,-1716 # ffffffffc02082f0 <commands+0x1a68>
ffffffffc02049ac:	00002617          	auipc	a2,0x2
ffffffffc02049b0:	2ec60613          	addi	a2,a2,748 # ffffffffc0206c98 <commands+0x410>
ffffffffc02049b4:	08300593          	li	a1,131
ffffffffc02049b8:	00003517          	auipc	a0,0x3
ffffffffc02049bc:	62050513          	addi	a0,a0,1568 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc02049c0:	849fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(n > 0);
ffffffffc02049c4:	00004697          	auipc	a3,0x4
ffffffffc02049c8:	92468693          	addi	a3,a3,-1756 # ffffffffc02082e8 <commands+0x1a60>
ffffffffc02049cc:	00002617          	auipc	a2,0x2
ffffffffc02049d0:	2cc60613          	addi	a2,a2,716 # ffffffffc0206c98 <commands+0x410>
ffffffffc02049d4:	08000593          	li	a1,128
ffffffffc02049d8:	00003517          	auipc	a0,0x3
ffffffffc02049dc:	60050513          	addi	a0,a0,1536 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc02049e0:	829fb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02049e4 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02049e4:	c941                	beqz	a0,ffffffffc0204a74 <default_alloc_pages+0x90>
    if (n > nr_free) {
ffffffffc02049e6:	000aa597          	auipc	a1,0xaa
ffffffffc02049ea:	e2a58593          	addi	a1,a1,-470 # ffffffffc02ae810 <free_area>
ffffffffc02049ee:	0105a803          	lw	a6,16(a1)
ffffffffc02049f2:	872a                	mv	a4,a0
ffffffffc02049f4:	02081793          	slli	a5,a6,0x20
ffffffffc02049f8:	9381                	srli	a5,a5,0x20
ffffffffc02049fa:	00a7ee63          	bltu	a5,a0,ffffffffc0204a16 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02049fe:	87ae                	mv	a5,a1
ffffffffc0204a00:	a801                	j	ffffffffc0204a10 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0204a02:	ff87a683          	lw	a3,-8(a5)
ffffffffc0204a06:	02069613          	slli	a2,a3,0x20
ffffffffc0204a0a:	9201                	srli	a2,a2,0x20
ffffffffc0204a0c:	00e67763          	bgeu	a2,a4,ffffffffc0204a1a <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0204a10:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0204a12:	feb798e3          	bne	a5,a1,ffffffffc0204a02 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0204a16:	4501                	li	a0,0
}
ffffffffc0204a18:	8082                	ret
    return listelm->prev;
ffffffffc0204a1a:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204a1e:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0204a22:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0204a26:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0204a2a:	0068b423          	sd	t1,8(a7) # 1008 <_binary_obj___user_faultread_out_size-0x8bb0>
    next->prev = prev;
ffffffffc0204a2e:	01133023          	sd	a7,0(t1) # 80000 <_binary_obj___user_exit_out_size+0x74ed8>
        if (page->property > n) {
ffffffffc0204a32:	02c77863          	bgeu	a4,a2,ffffffffc0204a62 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0204a36:	071a                	slli	a4,a4,0x6
ffffffffc0204a38:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0204a3a:	41c686bb          	subw	a3,a3,t3
ffffffffc0204a3e:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204a40:	00870613          	addi	a2,a4,8
ffffffffc0204a44:	4689                	li	a3,2
ffffffffc0204a46:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0204a4a:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0204a4e:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0204a52:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0204a56:	e290                	sd	a2,0(a3)
ffffffffc0204a58:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0204a5c:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0204a5e:	01173c23          	sd	a7,24(a4)
ffffffffc0204a62:	41c8083b          	subw	a6,a6,t3
ffffffffc0204a66:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204a6a:	5775                	li	a4,-3
ffffffffc0204a6c:	17c1                	addi	a5,a5,-16
ffffffffc0204a6e:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0204a72:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0204a74:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0204a76:	00004697          	auipc	a3,0x4
ffffffffc0204a7a:	87268693          	addi	a3,a3,-1934 # ffffffffc02082e8 <commands+0x1a60>
ffffffffc0204a7e:	00002617          	auipc	a2,0x2
ffffffffc0204a82:	21a60613          	addi	a2,a2,538 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204a86:	06200593          	li	a1,98
ffffffffc0204a8a:	00003517          	auipc	a0,0x3
ffffffffc0204a8e:	54e50513          	addi	a0,a0,1358 # ffffffffc0207fd8 <commands+0x1750>
default_alloc_pages(size_t n) {
ffffffffc0204a92:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0204a94:	f74fb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204a98 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0204a98:	1141                	addi	sp,sp,-16
ffffffffc0204a9a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0204a9c:	c5f1                	beqz	a1,ffffffffc0204b68 <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc0204a9e:	00659693          	slli	a3,a1,0x6
ffffffffc0204aa2:	96aa                	add	a3,a3,a0
ffffffffc0204aa4:	87aa                	mv	a5,a0
ffffffffc0204aa6:	00d50f63          	beq	a0,a3,ffffffffc0204ac4 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0204aaa:	6798                	ld	a4,8(a5)
ffffffffc0204aac:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc0204aae:	cf49                	beqz	a4,ffffffffc0204b48 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0204ab0:	0007a823          	sw	zero,16(a5)
ffffffffc0204ab4:	0007b423          	sd	zero,8(a5)
ffffffffc0204ab8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0204abc:	04078793          	addi	a5,a5,64
ffffffffc0204ac0:	fed795e3          	bne	a5,a3,ffffffffc0204aaa <default_init_memmap+0x12>
    base->property = n;
ffffffffc0204ac4:	2581                	sext.w	a1,a1
ffffffffc0204ac6:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204ac8:	4789                	li	a5,2
ffffffffc0204aca:	00850713          	addi	a4,a0,8
ffffffffc0204ace:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0204ad2:	000aa697          	auipc	a3,0xaa
ffffffffc0204ad6:	d3e68693          	addi	a3,a3,-706 # ffffffffc02ae810 <free_area>
ffffffffc0204ada:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0204adc:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0204ade:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0204ae2:	9db9                	addw	a1,a1,a4
ffffffffc0204ae4:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0204ae6:	04d78a63          	beq	a5,a3,ffffffffc0204b3a <default_init_memmap+0xa2>
            struct Page* page = le2page(le, page_link);
ffffffffc0204aea:	fe878713          	addi	a4,a5,-24
ffffffffc0204aee:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0204af2:	4581                	li	a1,0
            if (base < page) {
ffffffffc0204af4:	00e56a63          	bltu	a0,a4,ffffffffc0204b08 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0204af8:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0204afa:	02d70263          	beq	a4,a3,ffffffffc0204b1e <default_init_memmap+0x86>
    for (; p != base + n; p ++) {
ffffffffc0204afe:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0204b00:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0204b04:	fee57ae3          	bgeu	a0,a4,ffffffffc0204af8 <default_init_memmap+0x60>
ffffffffc0204b08:	c199                	beqz	a1,ffffffffc0204b0e <default_init_memmap+0x76>
ffffffffc0204b0a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0204b0e:	6398                	ld	a4,0(a5)
}
ffffffffc0204b10:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0204b12:	e390                	sd	a2,0(a5)
ffffffffc0204b14:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0204b16:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0204b18:	ed18                	sd	a4,24(a0)
ffffffffc0204b1a:	0141                	addi	sp,sp,16
ffffffffc0204b1c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0204b1e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0204b20:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0204b22:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0204b24:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0204b26:	00d70663          	beq	a4,a3,ffffffffc0204b32 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0204b2a:	8832                	mv	a6,a2
ffffffffc0204b2c:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0204b2e:	87ba                	mv	a5,a4
ffffffffc0204b30:	bfc1                	j	ffffffffc0204b00 <default_init_memmap+0x68>
}
ffffffffc0204b32:	60a2                	ld	ra,8(sp)
ffffffffc0204b34:	e290                	sd	a2,0(a3)
ffffffffc0204b36:	0141                	addi	sp,sp,16
ffffffffc0204b38:	8082                	ret
ffffffffc0204b3a:	60a2                	ld	ra,8(sp)
ffffffffc0204b3c:	e390                	sd	a2,0(a5)
ffffffffc0204b3e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0204b40:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0204b42:	ed1c                	sd	a5,24(a0)
ffffffffc0204b44:	0141                	addi	sp,sp,16
ffffffffc0204b46:	8082                	ret
        assert(PageReserved(p));
ffffffffc0204b48:	00003697          	auipc	a3,0x3
ffffffffc0204b4c:	7d068693          	addi	a3,a3,2000 # ffffffffc0208318 <commands+0x1a90>
ffffffffc0204b50:	00002617          	auipc	a2,0x2
ffffffffc0204b54:	14860613          	addi	a2,a2,328 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204b58:	04900593          	li	a1,73
ffffffffc0204b5c:	00003517          	auipc	a0,0x3
ffffffffc0204b60:	47c50513          	addi	a0,a0,1148 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204b64:	ea4fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(n > 0);
ffffffffc0204b68:	00003697          	auipc	a3,0x3
ffffffffc0204b6c:	78068693          	addi	a3,a3,1920 # ffffffffc02082e8 <commands+0x1a60>
ffffffffc0204b70:	00002617          	auipc	a2,0x2
ffffffffc0204b74:	12860613          	addi	a2,a2,296 # ffffffffc0206c98 <commands+0x410>
ffffffffc0204b78:	04600593          	li	a1,70
ffffffffc0204b7c:	00003517          	auipc	a0,0x3
ffffffffc0204b80:	45c50513          	addi	a0,a0,1116 # ffffffffc0207fd8 <commands+0x1750>
ffffffffc0204b84:	e84fb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204b88 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0204b88:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204b8a:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0204b8c:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204b8e:	99bfb0ef          	jal	ra,ffffffffc0200528 <ide_device_valid>
ffffffffc0204b92:	cd01                	beqz	a0,ffffffffc0204baa <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204b94:	4505                	li	a0,1
ffffffffc0204b96:	999fb0ef          	jal	ra,ffffffffc020052e <ide_device_size>
}
ffffffffc0204b9a:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204b9c:	810d                	srli	a0,a0,0x3
ffffffffc0204b9e:	000ae797          	auipc	a5,0xae
ffffffffc0204ba2:	cea7bd23          	sd	a0,-774(a5) # ffffffffc02b2898 <max_swap_offset>
}
ffffffffc0204ba6:	0141                	addi	sp,sp,16
ffffffffc0204ba8:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0204baa:	00003617          	auipc	a2,0x3
ffffffffc0204bae:	7ce60613          	addi	a2,a2,1998 # ffffffffc0208378 <default_pmm_manager+0x38>
ffffffffc0204bb2:	45b5                	li	a1,13
ffffffffc0204bb4:	00003517          	auipc	a0,0x3
ffffffffc0204bb8:	7e450513          	addi	a0,a0,2020 # ffffffffc0208398 <default_pmm_manager+0x58>
ffffffffc0204bbc:	e4cfb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204bc0 <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0204bc0:	1141                	addi	sp,sp,-16
ffffffffc0204bc2:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204bc4:	00855793          	srli	a5,a0,0x8
ffffffffc0204bc8:	cbb1                	beqz	a5,ffffffffc0204c1c <swapfs_read+0x5c>
ffffffffc0204bca:	000ae717          	auipc	a4,0xae
ffffffffc0204bce:	cce73703          	ld	a4,-818(a4) # ffffffffc02b2898 <max_swap_offset>
ffffffffc0204bd2:	04e7f563          	bgeu	a5,a4,ffffffffc0204c1c <swapfs_read+0x5c>
    return page - pages + nbase;
ffffffffc0204bd6:	000ae617          	auipc	a2,0xae
ffffffffc0204bda:	c9263603          	ld	a2,-878(a2) # ffffffffc02b2868 <pages>
ffffffffc0204bde:	8d91                	sub	a1,a1,a2
ffffffffc0204be0:	4065d613          	srai	a2,a1,0x6
ffffffffc0204be4:	00004717          	auipc	a4,0x4
ffffffffc0204be8:	10c73703          	ld	a4,268(a4) # ffffffffc0208cf0 <nbase>
ffffffffc0204bec:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc0204bee:	00c61713          	slli	a4,a2,0xc
ffffffffc0204bf2:	8331                	srli	a4,a4,0xc
ffffffffc0204bf4:	000ae697          	auipc	a3,0xae
ffffffffc0204bf8:	c6c6b683          	ld	a3,-916(a3) # ffffffffc02b2860 <npage>
ffffffffc0204bfc:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c00:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204c02:	02d77963          	bgeu	a4,a3,ffffffffc0204c34 <swapfs_read+0x74>
}
ffffffffc0204c06:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c08:	000ae797          	auipc	a5,0xae
ffffffffc0204c0c:	c707b783          	ld	a5,-912(a5) # ffffffffc02b2878 <va_pa_offset>
ffffffffc0204c10:	46a1                	li	a3,8
ffffffffc0204c12:	963e                	add	a2,a2,a5
ffffffffc0204c14:	4505                	li	a0,1
}
ffffffffc0204c16:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c18:	91dfb06f          	j	ffffffffc0200534 <ide_read_secs>
ffffffffc0204c1c:	86aa                	mv	a3,a0
ffffffffc0204c1e:	00003617          	auipc	a2,0x3
ffffffffc0204c22:	79260613          	addi	a2,a2,1938 # ffffffffc02083b0 <default_pmm_manager+0x70>
ffffffffc0204c26:	45d1                	li	a1,20
ffffffffc0204c28:	00003517          	auipc	a0,0x3
ffffffffc0204c2c:	77050513          	addi	a0,a0,1904 # ffffffffc0208398 <default_pmm_manager+0x58>
ffffffffc0204c30:	dd8fb0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0204c34:	86b2                	mv	a3,a2
ffffffffc0204c36:	06900593          	li	a1,105
ffffffffc0204c3a:	00002617          	auipc	a2,0x2
ffffffffc0204c3e:	3a660613          	addi	a2,a2,934 # ffffffffc0206fe0 <commands+0x758>
ffffffffc0204c42:	00002517          	auipc	a0,0x2
ffffffffc0204c46:	36650513          	addi	a0,a0,870 # ffffffffc0206fa8 <commands+0x720>
ffffffffc0204c4a:	dbefb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204c4e <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0204c4e:	1141                	addi	sp,sp,-16
ffffffffc0204c50:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c52:	00855793          	srli	a5,a0,0x8
ffffffffc0204c56:	cbb1                	beqz	a5,ffffffffc0204caa <swapfs_write+0x5c>
ffffffffc0204c58:	000ae717          	auipc	a4,0xae
ffffffffc0204c5c:	c4073703          	ld	a4,-960(a4) # ffffffffc02b2898 <max_swap_offset>
ffffffffc0204c60:	04e7f563          	bgeu	a5,a4,ffffffffc0204caa <swapfs_write+0x5c>
    return page - pages + nbase;
ffffffffc0204c64:	000ae617          	auipc	a2,0xae
ffffffffc0204c68:	c0463603          	ld	a2,-1020(a2) # ffffffffc02b2868 <pages>
ffffffffc0204c6c:	8d91                	sub	a1,a1,a2
ffffffffc0204c6e:	4065d613          	srai	a2,a1,0x6
ffffffffc0204c72:	00004717          	auipc	a4,0x4
ffffffffc0204c76:	07e73703          	ld	a4,126(a4) # ffffffffc0208cf0 <nbase>
ffffffffc0204c7a:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc0204c7c:	00c61713          	slli	a4,a2,0xc
ffffffffc0204c80:	8331                	srli	a4,a4,0xc
ffffffffc0204c82:	000ae697          	auipc	a3,0xae
ffffffffc0204c86:	bde6b683          	ld	a3,-1058(a3) # ffffffffc02b2860 <npage>
ffffffffc0204c8a:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c8e:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204c90:	02d77963          	bgeu	a4,a3,ffffffffc0204cc2 <swapfs_write+0x74>
}
ffffffffc0204c94:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c96:	000ae797          	auipc	a5,0xae
ffffffffc0204c9a:	be27b783          	ld	a5,-1054(a5) # ffffffffc02b2878 <va_pa_offset>
ffffffffc0204c9e:	46a1                	li	a3,8
ffffffffc0204ca0:	963e                	add	a2,a2,a5
ffffffffc0204ca2:	4505                	li	a0,1
}
ffffffffc0204ca4:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204ca6:	8b3fb06f          	j	ffffffffc0200558 <ide_write_secs>
ffffffffc0204caa:	86aa                	mv	a3,a0
ffffffffc0204cac:	00003617          	auipc	a2,0x3
ffffffffc0204cb0:	70460613          	addi	a2,a2,1796 # ffffffffc02083b0 <default_pmm_manager+0x70>
ffffffffc0204cb4:	45e5                	li	a1,25
ffffffffc0204cb6:	00003517          	auipc	a0,0x3
ffffffffc0204cba:	6e250513          	addi	a0,a0,1762 # ffffffffc0208398 <default_pmm_manager+0x58>
ffffffffc0204cbe:	d4afb0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0204cc2:	86b2                	mv	a3,a2
ffffffffc0204cc4:	06900593          	li	a1,105
ffffffffc0204cc8:	00002617          	auipc	a2,0x2
ffffffffc0204ccc:	31860613          	addi	a2,a2,792 # ffffffffc0206fe0 <commands+0x758>
ffffffffc0204cd0:	00002517          	auipc	a0,0x2
ffffffffc0204cd4:	2d850513          	addi	a0,a0,728 # ffffffffc0206fa8 <commands+0x720>
ffffffffc0204cd8:	d30fb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204cdc <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204cdc:	8526                	mv	a0,s1
	jalr s0
ffffffffc0204cde:	9402                	jalr	s0

	jal do_exit
ffffffffc0204ce0:	696000ef          	jal	ra,ffffffffc0205376 <do_exit>

ffffffffc0204ce4 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204ce4:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204ce8:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204cec:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204cee:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204cf0:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204cf4:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204cf8:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204cfc:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0204d00:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204d04:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204d08:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204d0c:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0204d10:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0204d14:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0204d18:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0204d1c:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0204d20:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0204d22:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0204d24:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0204d28:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0204d2c:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0204d30:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0204d34:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0204d38:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0204d3c:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0204d40:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0204d44:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0204d48:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0204d4c:	8082                	ret

ffffffffc0204d4e <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0204d4e:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204d50:	10800513          	li	a0,264
{
ffffffffc0204d54:	e022                	sd	s0,0(sp)
ffffffffc0204d56:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204d58:	8d1fe0ef          	jal	ra,ffffffffc0203628 <kmalloc>
ffffffffc0204d5c:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0204d5e:	c931                	beqz	a0,ffffffffc0204db2 <alloc_proc+0x64>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT; // 设置进程为初始态
ffffffffc0204d60:	57fd                	li	a5,-1
ffffffffc0204d62:	1782                	slli	a5,a5,0x20
ffffffffc0204d64:	e11c                	sd	a5,0(a0)
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0204d66:	07000613          	li	a2,112
ffffffffc0204d6a:	4581                	li	a1,0
        proc->runs = 0;
ffffffffc0204d6c:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc0204d70:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc0204d74:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;
ffffffffc0204d78:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc0204d7c:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0204d80:	03050513          	addi	a0,a0,48
ffffffffc0204d84:	42a010ef          	jal	ra,ffffffffc02061ae <memset>
        proc->tf = NULL;
        proc->cr3 = boot_cr3; // 使用内核页目录表的基址
ffffffffc0204d88:	000ae797          	auipc	a5,0xae
ffffffffc0204d8c:	ac87b783          	ld	a5,-1336(a5) # ffffffffc02b2850 <boot_cr3>
        proc->tf = NULL;
ffffffffc0204d90:	0a043023          	sd	zero,160(s0)
        proc->cr3 = boot_cr3; // 使用内核页目录表的基址
ffffffffc0204d94:	f45c                	sd	a5,168(s0)
        proc->flags = 0;
ffffffffc0204d96:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN);
ffffffffc0204d9a:	463d                	li	a2,15
ffffffffc0204d9c:	4581                	li	a1,0
ffffffffc0204d9e:	0b440513          	addi	a0,s0,180
ffffffffc0204da2:	40c010ef          	jal	ra,ffffffffc02061ae <memset>
        /*
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        proc->wait_state = 0;                        // PCB新增的条目，初始化进程等待状态
ffffffffc0204da6:	0e042623          	sw	zero,236(s0)
        proc->cptr = proc->yptr = proc->cptr = NULL; // 设置指针为空
ffffffffc0204daa:	0e043823          	sd	zero,240(s0)
ffffffffc0204dae:	0e043c23          	sd	zero,248(s0)
        // ffang：这两行代码主要是初始化进程等待状态、和进程的相关指针，例如父进程、子进程、同胞等等。
        // 其中的wait_state是进程控制块中新增的条目。避免之后由于未定义或未初始化导致管理用户进程时出现错误。
    }
    return proc;
}
ffffffffc0204db2:	60a2                	ld	ra,8(sp)
ffffffffc0204db4:	8522                	mv	a0,s0
ffffffffc0204db6:	6402                	ld	s0,0(sp)
ffffffffc0204db8:	0141                	addi	sp,sp,16
ffffffffc0204dba:	8082                	ret

ffffffffc0204dbc <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0204dbc:	000ae797          	auipc	a5,0xae
ffffffffc0204dc0:	af47b783          	ld	a5,-1292(a5) # ffffffffc02b28b0 <current>
ffffffffc0204dc4:	73c8                	ld	a0,160(a5)
ffffffffc0204dc6:	fb1fb06f          	j	ffffffffc0200d76 <forkrets>

ffffffffc0204dca <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204dca:	000ae797          	auipc	a5,0xae
ffffffffc0204dce:	ae67b783          	ld	a5,-1306(a5) # ffffffffc02b28b0 <current>
ffffffffc0204dd2:	43cc                	lw	a1,4(a5)
{
ffffffffc0204dd4:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204dd6:	00003617          	auipc	a2,0x3
ffffffffc0204dda:	5fa60613          	addi	a2,a2,1530 # ffffffffc02083d0 <default_pmm_manager+0x90>
ffffffffc0204dde:	00003517          	auipc	a0,0x3
ffffffffc0204de2:	60250513          	addi	a0,a0,1538 # ffffffffc02083e0 <default_pmm_manager+0xa0>
{
ffffffffc0204de6:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204de8:	ae4fb0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0204dec:	3fe06797          	auipc	a5,0x3fe06
ffffffffc0204df0:	b8478793          	addi	a5,a5,-1148 # a970 <_binary_obj___user_forktest_out_size>
ffffffffc0204df4:	e43e                	sd	a5,8(sp)
ffffffffc0204df6:	00003517          	auipc	a0,0x3
ffffffffc0204dfa:	5da50513          	addi	a0,a0,1498 # ffffffffc02083d0 <default_pmm_manager+0x90>
ffffffffc0204dfe:	00098797          	auipc	a5,0x98
ffffffffc0204e02:	ba278793          	addi	a5,a5,-1118 # ffffffffc029c9a0 <_binary_obj___user_forktest_out_start>
ffffffffc0204e06:	f03e                	sd	a5,32(sp)
ffffffffc0204e08:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0204e0a:	e802                	sd	zero,16(sp)
ffffffffc0204e0c:	326010ef          	jal	ra,ffffffffc0206132 <strlen>
ffffffffc0204e10:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0204e12:	4511                	li	a0,4
ffffffffc0204e14:	55a2                	lw	a1,40(sp)
ffffffffc0204e16:	4662                	lw	a2,24(sp)
ffffffffc0204e18:	5682                	lw	a3,32(sp)
ffffffffc0204e1a:	4722                	lw	a4,8(sp)
ffffffffc0204e1c:	48a9                	li	a7,10
ffffffffc0204e1e:	9002                	ebreak
ffffffffc0204e20:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0204e22:	65c2                	ld	a1,16(sp)
ffffffffc0204e24:	00003517          	auipc	a0,0x3
ffffffffc0204e28:	5e450513          	addi	a0,a0,1508 # ffffffffc0208408 <default_pmm_manager+0xc8>
ffffffffc0204e2c:	aa0fb0ef          	jal	ra,ffffffffc02000cc <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0204e30:	00003617          	auipc	a2,0x3
ffffffffc0204e34:	5e860613          	addi	a2,a2,1512 # ffffffffc0208418 <default_pmm_manager+0xd8>
ffffffffc0204e38:	3c500593          	li	a1,965
ffffffffc0204e3c:	00003517          	auipc	a0,0x3
ffffffffc0204e40:	5fc50513          	addi	a0,a0,1532 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc0204e44:	bc4fb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204e48 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0204e48:	6d14                	ld	a3,24(a0)
{
ffffffffc0204e4a:	1141                	addi	sp,sp,-16
ffffffffc0204e4c:	e406                	sd	ra,8(sp)
ffffffffc0204e4e:	c02007b7          	lui	a5,0xc0200
ffffffffc0204e52:	02f6ee63          	bltu	a3,a5,ffffffffc0204e8e <put_pgdir+0x46>
ffffffffc0204e56:	000ae517          	auipc	a0,0xae
ffffffffc0204e5a:	a2253503          	ld	a0,-1502(a0) # ffffffffc02b2878 <va_pa_offset>
ffffffffc0204e5e:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage) {
ffffffffc0204e60:	82b1                	srli	a3,a3,0xc
ffffffffc0204e62:	000ae797          	auipc	a5,0xae
ffffffffc0204e66:	9fe7b783          	ld	a5,-1538(a5) # ffffffffc02b2860 <npage>
ffffffffc0204e6a:	02f6fe63          	bgeu	a3,a5,ffffffffc0204ea6 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0204e6e:	00004517          	auipc	a0,0x4
ffffffffc0204e72:	e8253503          	ld	a0,-382(a0) # ffffffffc0208cf0 <nbase>
}
ffffffffc0204e76:	60a2                	ld	ra,8(sp)
ffffffffc0204e78:	8e89                	sub	a3,a3,a0
ffffffffc0204e7a:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0204e7c:	000ae517          	auipc	a0,0xae
ffffffffc0204e80:	9ec53503          	ld	a0,-1556(a0) # ffffffffc02b2868 <pages>
ffffffffc0204e84:	4585                	li	a1,1
ffffffffc0204e86:	9536                	add	a0,a0,a3
}
ffffffffc0204e88:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0204e8a:	862fc06f          	j	ffffffffc0200eec <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0204e8e:	00002617          	auipc	a2,0x2
ffffffffc0204e92:	22a60613          	addi	a2,a2,554 # ffffffffc02070b8 <commands+0x830>
ffffffffc0204e96:	06e00593          	li	a1,110
ffffffffc0204e9a:	00002517          	auipc	a0,0x2
ffffffffc0204e9e:	10e50513          	addi	a0,a0,270 # ffffffffc0206fa8 <commands+0x720>
ffffffffc0204ea2:	b66fb0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204ea6:	00002617          	auipc	a2,0x2
ffffffffc0204eaa:	0e260613          	addi	a2,a2,226 # ffffffffc0206f88 <commands+0x700>
ffffffffc0204eae:	06200593          	li	a1,98
ffffffffc0204eb2:	00002517          	auipc	a0,0x2
ffffffffc0204eb6:	0f650513          	addi	a0,a0,246 # ffffffffc0206fa8 <commands+0x720>
ffffffffc0204eba:	b4efb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204ebe <proc_run>:
{
ffffffffc0204ebe:	7179                	addi	sp,sp,-48
ffffffffc0204ec0:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0204ec2:	000ae917          	auipc	s2,0xae
ffffffffc0204ec6:	9ee90913          	addi	s2,s2,-1554 # ffffffffc02b28b0 <current>
{
ffffffffc0204eca:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0204ecc:	00093483          	ld	s1,0(s2)
{
ffffffffc0204ed0:	f406                	sd	ra,40(sp)
ffffffffc0204ed2:	e84e                	sd	s3,16(sp)
    if (proc != current)
ffffffffc0204ed4:	02a48863          	beq	s1,a0,ffffffffc0204f04 <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204ed8:	100027f3          	csrr	a5,sstatus
ffffffffc0204edc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204ede:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204ee0:	ef9d                	bnez	a5,ffffffffc0204f1e <proc_run+0x60>

#define barrier() __asm__ __volatile__ ("fence" ::: "memory")

static inline void
lcr3(unsigned long cr3) {
    write_csr(satp, 0x8000000000000000 | (cr3 >> RISCV_PGSHIFT));
ffffffffc0204ee2:	755c                	ld	a5,168(a0)
ffffffffc0204ee4:	577d                	li	a4,-1
ffffffffc0204ee6:	177e                	slli	a4,a4,0x3f
ffffffffc0204ee8:	83b1                	srli	a5,a5,0xc
            current = proc;
ffffffffc0204eea:	00a93023          	sd	a0,0(s2)
ffffffffc0204eee:	8fd9                	or	a5,a5,a4
ffffffffc0204ef0:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc0204ef4:	03050593          	addi	a1,a0,48
ffffffffc0204ef8:	03048513          	addi	a0,s1,48
ffffffffc0204efc:	de9ff0ef          	jal	ra,ffffffffc0204ce4 <switch_to>
    if (flag) {
ffffffffc0204f00:	00099863          	bnez	s3,ffffffffc0204f10 <proc_run+0x52>
}
ffffffffc0204f04:	70a2                	ld	ra,40(sp)
ffffffffc0204f06:	7482                	ld	s1,32(sp)
ffffffffc0204f08:	6962                	ld	s2,24(sp)
ffffffffc0204f0a:	69c2                	ld	s3,16(sp)
ffffffffc0204f0c:	6145                	addi	sp,sp,48
ffffffffc0204f0e:	8082                	ret
ffffffffc0204f10:	70a2                	ld	ra,40(sp)
ffffffffc0204f12:	7482                	ld	s1,32(sp)
ffffffffc0204f14:	6962                	ld	s2,24(sp)
ffffffffc0204f16:	69c2                	ld	s3,16(sp)
ffffffffc0204f18:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0204f1a:	f28fb06f          	j	ffffffffc0200642 <intr_enable>
ffffffffc0204f1e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0204f20:	f28fb0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc0204f24:	6522                	ld	a0,8(sp)
ffffffffc0204f26:	4985                	li	s3,1
ffffffffc0204f28:	bf6d                	j	ffffffffc0204ee2 <proc_run+0x24>

ffffffffc0204f2a <do_fork>:
{
ffffffffc0204f2a:	7119                	addi	sp,sp,-128
ffffffffc0204f2c:	f4a6                	sd	s1,104(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204f2e:	000ae497          	auipc	s1,0xae
ffffffffc0204f32:	99a48493          	addi	s1,s1,-1638 # ffffffffc02b28c8 <nr_process>
ffffffffc0204f36:	4098                	lw	a4,0(s1)
{
ffffffffc0204f38:	fc86                	sd	ra,120(sp)
ffffffffc0204f3a:	f8a2                	sd	s0,112(sp)
ffffffffc0204f3c:	f0ca                	sd	s2,96(sp)
ffffffffc0204f3e:	ecce                	sd	s3,88(sp)
ffffffffc0204f40:	e8d2                	sd	s4,80(sp)
ffffffffc0204f42:	e4d6                	sd	s5,72(sp)
ffffffffc0204f44:	e0da                	sd	s6,64(sp)
ffffffffc0204f46:	fc5e                	sd	s7,56(sp)
ffffffffc0204f48:	f862                	sd	s8,48(sp)
ffffffffc0204f4a:	f466                	sd	s9,40(sp)
ffffffffc0204f4c:	f06a                	sd	s10,32(sp)
ffffffffc0204f4e:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204f50:	6785                	lui	a5,0x1
ffffffffc0204f52:	30f75e63          	bge	a4,a5,ffffffffc020526e <do_fork+0x344>
ffffffffc0204f56:	8a2a                	mv	s4,a0
ffffffffc0204f58:	892e                	mv	s2,a1
ffffffffc0204f5a:	89b2                	mv	s3,a2
    proc = alloc_proc(); // 本质上是用kmlloc函数分配了一块内存空间，然后将proc指向这块内存空间
ffffffffc0204f5c:	df3ff0ef          	jal	ra,ffffffffc0204d4e <alloc_proc>
ffffffffc0204f60:	842a                	mv	s0,a0
    if (proc == NULL)
ffffffffc0204f62:	30050e63          	beqz	a0,ffffffffc020527e <do_fork+0x354>
    proc->parent = current;           // 将子进程的父进程设置为当前进程
ffffffffc0204f66:	000aeb97          	auipc	s7,0xae
ffffffffc0204f6a:	94ab8b93          	addi	s7,s7,-1718 # ffffffffc02b28b0 <current>
ffffffffc0204f6e:	000bb783          	ld	a5,0(s7)
    assert(current->wait_state == 0); // 确保进程在等待（确保当前进程的wait_state为0）
ffffffffc0204f72:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8acc>
    proc->parent = current;           // 将子进程的父进程设置为当前进程
ffffffffc0204f76:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0); // 确保进程在等待（确保当前进程的wait_state为0）
ffffffffc0204f78:	30071a63          	bnez	a4,ffffffffc020528c <do_fork+0x362>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204f7c:	4509                	li	a0,2
ffffffffc0204f7e:	eddfb0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
    if (page != NULL)
ffffffffc0204f82:	2e050463          	beqz	a0,ffffffffc020526a <do_fork+0x340>
    return page - pages + nbase;
ffffffffc0204f86:	000aec97          	auipc	s9,0xae
ffffffffc0204f8a:	8e2c8c93          	addi	s9,s9,-1822 # ffffffffc02b2868 <pages>
ffffffffc0204f8e:	000cb683          	ld	a3,0(s9)
ffffffffc0204f92:	00004a97          	auipc	s5,0x4
ffffffffc0204f96:	d5ea8a93          	addi	s5,s5,-674 # ffffffffc0208cf0 <nbase>
ffffffffc0204f9a:	000ab703          	ld	a4,0(s5)
ffffffffc0204f9e:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0204fa2:	000aed17          	auipc	s10,0xae
ffffffffc0204fa6:	8bed0d13          	addi	s10,s10,-1858 # ffffffffc02b2860 <npage>
    return page - pages + nbase;
ffffffffc0204faa:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204fac:	5b7d                	li	s6,-1
ffffffffc0204fae:	000d3783          	ld	a5,0(s10)
    return page - pages + nbase;
ffffffffc0204fb2:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0204fb4:	00cb5b13          	srli	s6,s6,0xc
ffffffffc0204fb8:	0166f633          	and	a2,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0204fbc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204fbe:	2ef67763          	bgeu	a2,a5,ffffffffc02052ac <do_fork+0x382>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0204fc2:	000bb603          	ld	a2,0(s7)
ffffffffc0204fc6:	000aed97          	auipc	s11,0xae
ffffffffc0204fca:	8b2d8d93          	addi	s11,s11,-1870 # ffffffffc02b2878 <va_pa_offset>
ffffffffc0204fce:	000db783          	ld	a5,0(s11)
ffffffffc0204fd2:	02863b83          	ld	s7,40(a2)
ffffffffc0204fd6:	e43a                	sd	a4,8(sp)
ffffffffc0204fd8:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0204fda:	e814                	sd	a3,16(s0)
    if (oldmm == NULL)
ffffffffc0204fdc:	020b8863          	beqz	s7,ffffffffc020500c <do_fork+0xe2>
    if (clone_flags & CLONE_VM)
ffffffffc0204fe0:	100a7a13          	andi	s4,s4,256
ffffffffc0204fe4:	180a0c63          	beqz	s4,ffffffffc020517c <do_fork+0x252>
}

static inline int
mm_count_inc(struct mm_struct *mm) {
    mm->mm_count += 1;
ffffffffc0204fe8:	030ba703          	lw	a4,48(s7)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0204fec:	018bb783          	ld	a5,24(s7)
ffffffffc0204ff0:	c02006b7          	lui	a3,0xc0200
ffffffffc0204ff4:	2705                	addiw	a4,a4,1
ffffffffc0204ff6:	02eba823          	sw	a4,48(s7)
    proc->mm = mm;
ffffffffc0204ffa:	03743423          	sd	s7,40(s0)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0204ffe:	30d7e763          	bltu	a5,a3,ffffffffc020530c <do_fork+0x3e2>
ffffffffc0205002:	000db703          	ld	a4,0(s11)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0205006:	6814                	ld	a3,16(s0)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0205008:	8f99                	sub	a5,a5,a4
ffffffffc020500a:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020500c:	6789                	lui	a5,0x2
ffffffffc020500e:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cd8>
ffffffffc0205012:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0205014:	864e                	mv	a2,s3
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0205016:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc0205018:	87b6                	mv	a5,a3
ffffffffc020501a:	12098893          	addi	a7,s3,288
ffffffffc020501e:	00063803          	ld	a6,0(a2)
ffffffffc0205022:	6608                	ld	a0,8(a2)
ffffffffc0205024:	6a0c                	ld	a1,16(a2)
ffffffffc0205026:	6e18                	ld	a4,24(a2)
ffffffffc0205028:	0107b023          	sd	a6,0(a5)
ffffffffc020502c:	e788                	sd	a0,8(a5)
ffffffffc020502e:	eb8c                	sd	a1,16(a5)
ffffffffc0205030:	ef98                	sd	a4,24(a5)
ffffffffc0205032:	02060613          	addi	a2,a2,32
ffffffffc0205036:	02078793          	addi	a5,a5,32
ffffffffc020503a:	ff1612e3          	bne	a2,a7,ffffffffc020501e <do_fork+0xf4>
    proc->tf->gpr.a0 = 0;
ffffffffc020503e:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x1e>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0205042:	1c090763          	beqz	s2,ffffffffc0205210 <do_fork+0x2e6>
ffffffffc0205046:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020504a:	00000797          	auipc	a5,0x0
ffffffffc020504e:	d7278793          	addi	a5,a5,-654 # ffffffffc0204dbc <forkret>
ffffffffc0205052:	f81c                	sd	a5,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0205054:	fc14                	sd	a3,56(s0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205056:	100027f3          	csrr	a5,sstatus
ffffffffc020505a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020505c:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020505e:	20079263          	bnez	a5,ffffffffc0205262 <do_fork+0x338>
    if (++last_pid >= MAX_PID)
ffffffffc0205062:	000a2317          	auipc	t1,0xa2
ffffffffc0205066:	30630313          	addi	t1,t1,774 # ffffffffc02a7368 <last_pid.1>
ffffffffc020506a:	00032783          	lw	a5,0(t1)
    return listelm->next;
ffffffffc020506e:	000ad617          	auipc	a2,0xad
ffffffffc0205072:	7ba60613          	addi	a2,a2,1978 # ffffffffc02b2828 <proc_list>
ffffffffc0205076:	6709                	lui	a4,0x2
ffffffffc0205078:	0017851b          	addiw	a0,a5,1
ffffffffc020507c:	00a32023          	sw	a0,0(t1)
ffffffffc0205080:	00863883          	ld	a7,8(a2)
ffffffffc0205084:	08e55a63          	bge	a0,a4,ffffffffc0205118 <do_fork+0x1ee>
    if (last_pid >= next_safe)
ffffffffc0205088:	000a2e97          	auipc	t4,0xa2
ffffffffc020508c:	2e4e8e93          	addi	t4,t4,740 # ffffffffc02a736c <next_safe.0>
ffffffffc0205090:	000ea783          	lw	a5,0(t4)
ffffffffc0205094:	08f55a63          	bge	a0,a5,ffffffffc0205128 <do_fork+0x1fe>
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0205098:	7014                	ld	a3,32(s0)
        proc->pid = get_pid(); // 分配一个新的不重复的pid
ffffffffc020509a:	c048                	sw	a0,4(s0)
    list_add(&proc_list, &(proc->list_link));
ffffffffc020509c:	0c840793          	addi	a5,s0,200
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02050a0:	7af8                	ld	a4,240(a3)
    prev->next = next->prev = elm;
ffffffffc02050a2:	00f8b023          	sd	a5,0(a7)
ffffffffc02050a6:	e61c                	sd	a5,8(a2)
    elm->next = next;
ffffffffc02050a8:	0d143823          	sd	a7,208(s0)
    elm->prev = prev;
ffffffffc02050ac:	e470                	sd	a2,200(s0)
    proc->yptr = NULL;
ffffffffc02050ae:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02050b2:	10e43023          	sd	a4,256(s0)
ffffffffc02050b6:	c311                	beqz	a4,ffffffffc02050ba <do_fork+0x190>
        proc->optr->yptr = proc;
ffffffffc02050b8:	ff60                	sd	s0,248(a4)
    nr_process++;
ffffffffc02050ba:	409c                	lw	a5,0(s1)
    proc->parent->cptr = proc;
ffffffffc02050bc:	fae0                	sd	s0,240(a3)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02050be:	45a9                	li	a1,10
    nr_process++;
ffffffffc02050c0:	2785                	addiw	a5,a5,1
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02050c2:	2501                	sext.w	a0,a0
    nr_process++;
ffffffffc02050c4:	c09c                	sw	a5,0(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02050c6:	500010ef          	jal	ra,ffffffffc02065c6 <hash32>
ffffffffc02050ca:	02051793          	slli	a5,a0,0x20
ffffffffc02050ce:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02050d2:	000a9797          	auipc	a5,0xa9
ffffffffc02050d6:	75678793          	addi	a5,a5,1878 # ffffffffc02ae828 <hash_list>
ffffffffc02050da:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02050dc:	651c                	ld	a5,8(a0)
ffffffffc02050de:	0d840713          	addi	a4,s0,216
    prev->next = next->prev = elm;
ffffffffc02050e2:	e398                	sd	a4,0(a5)
ffffffffc02050e4:	e518                	sd	a4,8(a0)
    elm->next = next;
ffffffffc02050e6:	f07c                	sd	a5,224(s0)
    elm->prev = prev;
ffffffffc02050e8:	ec68                	sd	a0,216(s0)
    if (flag) {
ffffffffc02050ea:	12091563          	bnez	s2,ffffffffc0205214 <do_fork+0x2ea>
    wakeup_proc(proc); // 设置proc的state为PROC_RUNNABLE，使得进程可以被调度执行
ffffffffc02050ee:	8522                	mv	a0,s0
ffffffffc02050f0:	657000ef          	jal	ra,ffffffffc0205f46 <wakeup_proc>
    ret = proc->pid;
ffffffffc02050f4:	00442a03          	lw	s4,4(s0)
}
ffffffffc02050f8:	70e6                	ld	ra,120(sp)
ffffffffc02050fa:	7446                	ld	s0,112(sp)
ffffffffc02050fc:	74a6                	ld	s1,104(sp)
ffffffffc02050fe:	7906                	ld	s2,96(sp)
ffffffffc0205100:	69e6                	ld	s3,88(sp)
ffffffffc0205102:	6aa6                	ld	s5,72(sp)
ffffffffc0205104:	6b06                	ld	s6,64(sp)
ffffffffc0205106:	7be2                	ld	s7,56(sp)
ffffffffc0205108:	7c42                	ld	s8,48(sp)
ffffffffc020510a:	7ca2                	ld	s9,40(sp)
ffffffffc020510c:	7d02                	ld	s10,32(sp)
ffffffffc020510e:	6de2                	ld	s11,24(sp)
ffffffffc0205110:	8552                	mv	a0,s4
ffffffffc0205112:	6a46                	ld	s4,80(sp)
ffffffffc0205114:	6109                	addi	sp,sp,128
ffffffffc0205116:	8082                	ret
        last_pid = 1;
ffffffffc0205118:	4785                	li	a5,1
ffffffffc020511a:	00f32023          	sw	a5,0(t1)
        goto inside;
ffffffffc020511e:	4505                	li	a0,1
ffffffffc0205120:	000a2e97          	auipc	t4,0xa2
ffffffffc0205124:	24ce8e93          	addi	t4,t4,588 # ffffffffc02a736c <next_safe.0>
        next_safe = MAX_PID;
ffffffffc0205128:	6789                	lui	a5,0x2
ffffffffc020512a:	00fea023          	sw	a5,0(t4)
ffffffffc020512e:	86aa                	mv	a3,a0
ffffffffc0205130:	4801                	li	a6,0
        while ((le = list_next(le)) != list)
ffffffffc0205132:	6f09                	lui	t5,0x2
ffffffffc0205134:	12c88f63          	beq	a7,a2,ffffffffc0205272 <do_fork+0x348>
ffffffffc0205138:	8e42                	mv	t3,a6
ffffffffc020513a:	87c6                	mv	a5,a7
ffffffffc020513c:	6589                	lui	a1,0x2
ffffffffc020513e:	a811                	j	ffffffffc0205152 <do_fork+0x228>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0205140:	00e6d663          	bge	a3,a4,ffffffffc020514c <do_fork+0x222>
ffffffffc0205144:	00b75463          	bge	a4,a1,ffffffffc020514c <do_fork+0x222>
ffffffffc0205148:	85ba                	mv	a1,a4
ffffffffc020514a:	4e05                	li	t3,1
    return listelm->next;
ffffffffc020514c:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020514e:	00c78d63          	beq	a5,a2,ffffffffc0205168 <do_fork+0x23e>
            if (proc->pid == last_pid)
ffffffffc0205152:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c7c>
ffffffffc0205156:	fed715e3          	bne	a4,a3,ffffffffc0205140 <do_fork+0x216>
                if (++last_pid >= next_safe)
ffffffffc020515a:	2685                	addiw	a3,a3,1
ffffffffc020515c:	0eb6de63          	bge	a3,a1,ffffffffc0205258 <do_fork+0x32e>
ffffffffc0205160:	679c                	ld	a5,8(a5)
ffffffffc0205162:	4805                	li	a6,1
        while ((le = list_next(le)) != list)
ffffffffc0205164:	fec797e3          	bne	a5,a2,ffffffffc0205152 <do_fork+0x228>
ffffffffc0205168:	00080563          	beqz	a6,ffffffffc0205172 <do_fork+0x248>
ffffffffc020516c:	00d32023          	sw	a3,0(t1)
ffffffffc0205170:	8536                	mv	a0,a3
ffffffffc0205172:	f20e03e3          	beqz	t3,ffffffffc0205098 <do_fork+0x16e>
ffffffffc0205176:	00bea023          	sw	a1,0(t4)
ffffffffc020517a:	bf39                	j	ffffffffc0205098 <do_fork+0x16e>
    if ((mm = mm_create()) == NULL)
ffffffffc020517c:	ffafd0ef          	jal	ra,ffffffffc0202976 <mm_create>
ffffffffc0205180:	8c2a                	mv	s8,a0
ffffffffc0205182:	10050363          	beqz	a0,ffffffffc0205288 <do_fork+0x35e>
    if ((page = alloc_page()) == NULL)
ffffffffc0205186:	4505                	li	a0,1
ffffffffc0205188:	cd3fb0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc020518c:	c559                	beqz	a0,ffffffffc020521a <do_fork+0x2f0>
    return page - pages + nbase;
ffffffffc020518e:	000cb683          	ld	a3,0(s9)
ffffffffc0205192:	6722                	ld	a4,8(sp)
    return KADDR(page2pa(page));
ffffffffc0205194:	000d3783          	ld	a5,0(s10)
    return page - pages + nbase;
ffffffffc0205198:	40d506b3          	sub	a3,a0,a3
ffffffffc020519c:	8699                	srai	a3,a3,0x6
ffffffffc020519e:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02051a0:	0166fb33          	and	s6,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02051a4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02051a6:	10fb7363          	bgeu	s6,a5,ffffffffc02052ac <do_fork+0x382>
ffffffffc02051aa:	000dba03          	ld	s4,0(s11)
    memcpy(pgdir, boot_pgdir, PGSIZE);
ffffffffc02051ae:	6605                	lui	a2,0x1
ffffffffc02051b0:	000ad597          	auipc	a1,0xad
ffffffffc02051b4:	6a85b583          	ld	a1,1704(a1) # ffffffffc02b2858 <boot_pgdir>
ffffffffc02051b8:	9a36                	add	s4,s4,a3
ffffffffc02051ba:	8552                	mv	a0,s4
ffffffffc02051bc:	004010ef          	jal	ra,ffffffffc02061c0 <memcpy>
}

static inline void
lock_mm(struct mm_struct *mm) {
    if (mm != NULL) {
        lock(&(mm->mm_lock));
ffffffffc02051c0:	038b8b13          	addi	s6,s7,56
    mm->pgdir = pgdir;
ffffffffc02051c4:	014c3c23          	sd	s4,24(s8)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02051c8:	4785                	li	a5,1
ffffffffc02051ca:	40fb37af          	amoor.d	a5,a5,(s6)
    return !test_and_set_bit(0, lock);
}

static inline void
lock(lock_t *lock) {
    while (!try_lock(lock)) {
ffffffffc02051ce:	8b85                	andi	a5,a5,1
ffffffffc02051d0:	4a05                	li	s4,1
ffffffffc02051d2:	c799                	beqz	a5,ffffffffc02051e0 <do_fork+0x2b6>
        schedule();
ffffffffc02051d4:	5f3000ef          	jal	ra,ffffffffc0205fc6 <schedule>
ffffffffc02051d8:	414b37af          	amoor.d	a5,s4,(s6)
    while (!try_lock(lock)) {
ffffffffc02051dc:	8b85                	andi	a5,a5,1
ffffffffc02051de:	fbfd                	bnez	a5,ffffffffc02051d4 <do_fork+0x2aa>
        ret = dup_mmap(mm, oldmm);
ffffffffc02051e0:	85de                	mv	a1,s7
ffffffffc02051e2:	8562                	mv	a0,s8
ffffffffc02051e4:	a1bfd0ef          	jal	ra,ffffffffc0202bfe <dup_mmap>
ffffffffc02051e8:	8a2a                	mv	s4,a0
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02051ea:	57f9                	li	a5,-2
ffffffffc02051ec:	60fb37af          	amoand.d	a5,a5,(s6)
ffffffffc02051f0:	8b85                	andi	a5,a5,1
    }
}

static inline void
unlock(lock_t *lock) {
    if (!test_and_clear_bit(0, lock)) {
ffffffffc02051f2:	10078163          	beqz	a5,ffffffffc02052f4 <do_fork+0x3ca>
good_mm:
ffffffffc02051f6:	8be2                	mv	s7,s8
    if (ret != 0)
ffffffffc02051f8:	de0508e3          	beqz	a0,ffffffffc0204fe8 <do_fork+0xbe>
    exit_mmap(mm);
ffffffffc02051fc:	8562                	mv	a0,s8
ffffffffc02051fe:	a9bfd0ef          	jal	ra,ffffffffc0202c98 <exit_mmap>
    put_pgdir(mm);
ffffffffc0205202:	8562                	mv	a0,s8
ffffffffc0205204:	c45ff0ef          	jal	ra,ffffffffc0204e48 <put_pgdir>
    mm_destroy(mm);
ffffffffc0205208:	8562                	mv	a0,s8
ffffffffc020520a:	8f3fd0ef          	jal	ra,ffffffffc0202afc <mm_destroy>
    if (ret != 0)
ffffffffc020520e:	a811                	j	ffffffffc0205222 <do_fork+0x2f8>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0205210:	8936                	mv	s2,a3
ffffffffc0205212:	bd15                	j	ffffffffc0205046 <do_fork+0x11c>
        intr_enable();
ffffffffc0205214:	c2efb0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0205218:	bdd9                	j	ffffffffc02050ee <do_fork+0x1c4>
    mm_destroy(mm);
ffffffffc020521a:	8562                	mv	a0,s8
ffffffffc020521c:	8e1fd0ef          	jal	ra,ffffffffc0202afc <mm_destroy>
    int ret = -E_NO_MEM;
ffffffffc0205220:	5a71                	li	s4,-4
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0205222:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc0205224:	c02007b7          	lui	a5,0xc0200
ffffffffc0205228:	0af6ea63          	bltu	a3,a5,ffffffffc02052dc <do_fork+0x3b2>
ffffffffc020522c:	000db703          	ld	a4,0(s11)
    if (PPN(pa) >= npage) {
ffffffffc0205230:	000d3783          	ld	a5,0(s10)
    return pa2page(PADDR(kva));
ffffffffc0205234:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage) {
ffffffffc0205236:	82b1                	srli	a3,a3,0xc
ffffffffc0205238:	08f6f663          	bgeu	a3,a5,ffffffffc02052c4 <do_fork+0x39a>
    return &pages[PPN(pa) - nbase];
ffffffffc020523c:	000ab783          	ld	a5,0(s5)
ffffffffc0205240:	000cb503          	ld	a0,0(s9)
ffffffffc0205244:	4589                	li	a1,2
ffffffffc0205246:	8e9d                	sub	a3,a3,a5
ffffffffc0205248:	069a                	slli	a3,a3,0x6
ffffffffc020524a:	9536                	add	a0,a0,a3
ffffffffc020524c:	ca1fb0ef          	jal	ra,ffffffffc0200eec <free_pages>
    kfree(proc);
ffffffffc0205250:	8522                	mv	a0,s0
ffffffffc0205252:	c86fe0ef          	jal	ra,ffffffffc02036d8 <kfree>
    return ret;
ffffffffc0205256:	b54d                	j	ffffffffc02050f8 <do_fork+0x1ce>
                    if (last_pid >= MAX_PID)
ffffffffc0205258:	01e6c363          	blt	a3,t5,ffffffffc020525e <do_fork+0x334>
                        last_pid = 1;
ffffffffc020525c:	4685                	li	a3,1
                    goto repeat;
ffffffffc020525e:	4805                	li	a6,1
ffffffffc0205260:	bdd1                	j	ffffffffc0205134 <do_fork+0x20a>
        intr_disable();
ffffffffc0205262:	be6fb0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc0205266:	4905                	li	s2,1
ffffffffc0205268:	bbed                	j	ffffffffc0205062 <do_fork+0x138>
    return -E_NO_MEM;
ffffffffc020526a:	5a71                	li	s4,-4
ffffffffc020526c:	b7d5                	j	ffffffffc0205250 <do_fork+0x326>
    int ret = -E_NO_FREE_PROC;
ffffffffc020526e:	5a6d                	li	s4,-5
ffffffffc0205270:	b561                	j	ffffffffc02050f8 <do_fork+0x1ce>
ffffffffc0205272:	00080863          	beqz	a6,ffffffffc0205282 <do_fork+0x358>
ffffffffc0205276:	00d32023          	sw	a3,0(t1)
    return last_pid;
ffffffffc020527a:	8536                	mv	a0,a3
ffffffffc020527c:	bd31                	j	ffffffffc0205098 <do_fork+0x16e>
    ret = -E_NO_MEM;
ffffffffc020527e:	5a71                	li	s4,-4
ffffffffc0205280:	bda5                	j	ffffffffc02050f8 <do_fork+0x1ce>
    return last_pid;
ffffffffc0205282:	00032503          	lw	a0,0(t1)
ffffffffc0205286:	bd09                	j	ffffffffc0205098 <do_fork+0x16e>
    int ret = -E_NO_MEM;
ffffffffc0205288:	5a71                	li	s4,-4
ffffffffc020528a:	bf61                	j	ffffffffc0205222 <do_fork+0x2f8>
    assert(current->wait_state == 0); // 确保进程在等待（确保当前进程的wait_state为0）
ffffffffc020528c:	00003697          	auipc	a3,0x3
ffffffffc0205290:	1c468693          	addi	a3,a3,452 # ffffffffc0208450 <default_pmm_manager+0x110>
ffffffffc0205294:	00002617          	auipc	a2,0x2
ffffffffc0205298:	a0460613          	addi	a2,a2,-1532 # ffffffffc0206c98 <commands+0x410>
ffffffffc020529c:	1d100593          	li	a1,465
ffffffffc02052a0:	00003517          	auipc	a0,0x3
ffffffffc02052a4:	19850513          	addi	a0,a0,408 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc02052a8:	f61fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    return KADDR(page2pa(page));
ffffffffc02052ac:	00002617          	auipc	a2,0x2
ffffffffc02052b0:	d3460613          	addi	a2,a2,-716 # ffffffffc0206fe0 <commands+0x758>
ffffffffc02052b4:	06900593          	li	a1,105
ffffffffc02052b8:	00002517          	auipc	a0,0x2
ffffffffc02052bc:	cf050513          	addi	a0,a0,-784 # ffffffffc0206fa8 <commands+0x720>
ffffffffc02052c0:	f49fa0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02052c4:	00002617          	auipc	a2,0x2
ffffffffc02052c8:	cc460613          	addi	a2,a2,-828 # ffffffffc0206f88 <commands+0x700>
ffffffffc02052cc:	06200593          	li	a1,98
ffffffffc02052d0:	00002517          	auipc	a0,0x2
ffffffffc02052d4:	cd850513          	addi	a0,a0,-808 # ffffffffc0206fa8 <commands+0x720>
ffffffffc02052d8:	f31fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02052dc:	00002617          	auipc	a2,0x2
ffffffffc02052e0:	ddc60613          	addi	a2,a2,-548 # ffffffffc02070b8 <commands+0x830>
ffffffffc02052e4:	06e00593          	li	a1,110
ffffffffc02052e8:	00002517          	auipc	a0,0x2
ffffffffc02052ec:	cc050513          	addi	a0,a0,-832 # ffffffffc0206fa8 <commands+0x720>
ffffffffc02052f0:	f19fa0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("Unlock failed.\n");
ffffffffc02052f4:	00003617          	auipc	a2,0x3
ffffffffc02052f8:	17c60613          	addi	a2,a2,380 # ffffffffc0208470 <default_pmm_manager+0x130>
ffffffffc02052fc:	03100593          	li	a1,49
ffffffffc0205300:	00003517          	auipc	a0,0x3
ffffffffc0205304:	18050513          	addi	a0,a0,384 # ffffffffc0208480 <default_pmm_manager+0x140>
ffffffffc0205308:	f01fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc020530c:	86be                	mv	a3,a5
ffffffffc020530e:	00002617          	auipc	a2,0x2
ffffffffc0205312:	daa60613          	addi	a2,a2,-598 # ffffffffc02070b8 <commands+0x830>
ffffffffc0205316:	18e00593          	li	a1,398
ffffffffc020531a:	00003517          	auipc	a0,0x3
ffffffffc020531e:	11e50513          	addi	a0,a0,286 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc0205322:	ee7fa0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0205326 <kernel_thread>:
{
ffffffffc0205326:	7129                	addi	sp,sp,-320
ffffffffc0205328:	fa22                	sd	s0,304(sp)
ffffffffc020532a:	f626                	sd	s1,296(sp)
ffffffffc020532c:	f24a                	sd	s2,288(sp)
ffffffffc020532e:	84ae                	mv	s1,a1
ffffffffc0205330:	892a                	mv	s2,a0
ffffffffc0205332:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0205334:	4581                	li	a1,0
ffffffffc0205336:	12000613          	li	a2,288
ffffffffc020533a:	850a                	mv	a0,sp
{
ffffffffc020533c:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020533e:	671000ef          	jal	ra,ffffffffc02061ae <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0205342:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0205344:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0205346:	100027f3          	csrr	a5,sstatus
ffffffffc020534a:	edd7f793          	andi	a5,a5,-291
ffffffffc020534e:	1207e793          	ori	a5,a5,288
ffffffffc0205352:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0205354:	860a                	mv	a2,sp
ffffffffc0205356:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020535a:	00000797          	auipc	a5,0x0
ffffffffc020535e:	98278793          	addi	a5,a5,-1662 # ffffffffc0204cdc <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0205362:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0205364:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0205366:	bc5ff0ef          	jal	ra,ffffffffc0204f2a <do_fork>
}
ffffffffc020536a:	70f2                	ld	ra,312(sp)
ffffffffc020536c:	7452                	ld	s0,304(sp)
ffffffffc020536e:	74b2                	ld	s1,296(sp)
ffffffffc0205370:	7912                	ld	s2,288(sp)
ffffffffc0205372:	6131                	addi	sp,sp,320
ffffffffc0205374:	8082                	ret

ffffffffc0205376 <do_exit>:
{
ffffffffc0205376:	7179                	addi	sp,sp,-48
ffffffffc0205378:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc020537a:	000ad417          	auipc	s0,0xad
ffffffffc020537e:	53640413          	addi	s0,s0,1334 # ffffffffc02b28b0 <current>
ffffffffc0205382:	601c                	ld	a5,0(s0)
{
ffffffffc0205384:	f406                	sd	ra,40(sp)
ffffffffc0205386:	ec26                	sd	s1,24(sp)
ffffffffc0205388:	e84a                	sd	s2,16(sp)
ffffffffc020538a:	e44e                	sd	s3,8(sp)
ffffffffc020538c:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc020538e:	000ad717          	auipc	a4,0xad
ffffffffc0205392:	52a73703          	ld	a4,1322(a4) # ffffffffc02b28b8 <idleproc>
ffffffffc0205396:	0ce78c63          	beq	a5,a4,ffffffffc020546e <do_exit+0xf8>
    if (current == initproc)
ffffffffc020539a:	000ad497          	auipc	s1,0xad
ffffffffc020539e:	52648493          	addi	s1,s1,1318 # ffffffffc02b28c0 <initproc>
ffffffffc02053a2:	6098                	ld	a4,0(s1)
ffffffffc02053a4:	0ee78b63          	beq	a5,a4,ffffffffc020549a <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc02053a8:	0287b983          	ld	s3,40(a5)
ffffffffc02053ac:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc02053ae:	02098663          	beqz	s3,ffffffffc02053da <do_exit+0x64>
ffffffffc02053b2:	000ad797          	auipc	a5,0xad
ffffffffc02053b6:	49e7b783          	ld	a5,1182(a5) # ffffffffc02b2850 <boot_cr3>
ffffffffc02053ba:	577d                	li	a4,-1
ffffffffc02053bc:	177e                	slli	a4,a4,0x3f
ffffffffc02053be:	83b1                	srli	a5,a5,0xc
ffffffffc02053c0:	8fd9                	or	a5,a5,a4
ffffffffc02053c2:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02053c6:	0309a783          	lw	a5,48(s3)
ffffffffc02053ca:	fff7871b          	addiw	a4,a5,-1
ffffffffc02053ce:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc02053d2:	cb55                	beqz	a4,ffffffffc0205486 <do_exit+0x110>
        current->mm = NULL;
ffffffffc02053d4:	601c                	ld	a5,0(s0)
ffffffffc02053d6:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc02053da:	601c                	ld	a5,0(s0)
ffffffffc02053dc:	470d                	li	a4,3
ffffffffc02053de:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc02053e0:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02053e4:	100027f3          	csrr	a5,sstatus
ffffffffc02053e8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02053ea:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02053ec:	e3f9                	bnez	a5,ffffffffc02054b2 <do_exit+0x13c>
        proc = current->parent;
ffffffffc02053ee:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc02053f0:	800007b7          	lui	a5,0x80000
ffffffffc02053f4:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc02053f6:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc02053f8:	0ec52703          	lw	a4,236(a0)
ffffffffc02053fc:	0af70f63          	beq	a4,a5,ffffffffc02054ba <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc0205400:	6018                	ld	a4,0(s0)
ffffffffc0205402:	7b7c                	ld	a5,240(a4)
ffffffffc0205404:	c3a1                	beqz	a5,ffffffffc0205444 <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0205406:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc020540a:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc020540c:	0985                	addi	s3,s3,1
ffffffffc020540e:	a021                	j	ffffffffc0205416 <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc0205410:	6018                	ld	a4,0(s0)
ffffffffc0205412:	7b7c                	ld	a5,240(a4)
ffffffffc0205414:	cb85                	beqz	a5,ffffffffc0205444 <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc0205416:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fd8>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020541a:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc020541c:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020541e:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc0205420:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0205424:	10e7b023          	sd	a4,256(a5)
ffffffffc0205428:	c311                	beqz	a4,ffffffffc020542c <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc020542a:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020542c:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc020542e:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0205430:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0205432:	fd271fe3          	bne	a4,s2,ffffffffc0205410 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0205436:	0ec52783          	lw	a5,236(a0)
ffffffffc020543a:	fd379be3          	bne	a5,s3,ffffffffc0205410 <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc020543e:	309000ef          	jal	ra,ffffffffc0205f46 <wakeup_proc>
ffffffffc0205442:	b7f9                	j	ffffffffc0205410 <do_exit+0x9a>
    if (flag) {
ffffffffc0205444:	020a1263          	bnez	s4,ffffffffc0205468 <do_exit+0xf2>
    schedule();
ffffffffc0205448:	37f000ef          	jal	ra,ffffffffc0205fc6 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc020544c:	601c                	ld	a5,0(s0)
ffffffffc020544e:	00003617          	auipc	a2,0x3
ffffffffc0205452:	06a60613          	addi	a2,a2,106 # ffffffffc02084b8 <default_pmm_manager+0x178>
ffffffffc0205456:	24800593          	li	a1,584
ffffffffc020545a:	43d4                	lw	a3,4(a5)
ffffffffc020545c:	00003517          	auipc	a0,0x3
ffffffffc0205460:	fdc50513          	addi	a0,a0,-36 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc0205464:	da5fa0ef          	jal	ra,ffffffffc0200208 <__panic>
        intr_enable();
ffffffffc0205468:	9dafb0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc020546c:	bff1                	j	ffffffffc0205448 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc020546e:	00003617          	auipc	a2,0x3
ffffffffc0205472:	02a60613          	addi	a2,a2,42 # ffffffffc0208498 <default_pmm_manager+0x158>
ffffffffc0205476:	21400593          	li	a1,532
ffffffffc020547a:	00003517          	auipc	a0,0x3
ffffffffc020547e:	fbe50513          	addi	a0,a0,-66 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc0205482:	d87fa0ef          	jal	ra,ffffffffc0200208 <__panic>
            exit_mmap(mm);
ffffffffc0205486:	854e                	mv	a0,s3
ffffffffc0205488:	811fd0ef          	jal	ra,ffffffffc0202c98 <exit_mmap>
            put_pgdir(mm);
ffffffffc020548c:	854e                	mv	a0,s3
ffffffffc020548e:	9bbff0ef          	jal	ra,ffffffffc0204e48 <put_pgdir>
            mm_destroy(mm);
ffffffffc0205492:	854e                	mv	a0,s3
ffffffffc0205494:	e68fd0ef          	jal	ra,ffffffffc0202afc <mm_destroy>
ffffffffc0205498:	bf35                	j	ffffffffc02053d4 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc020549a:	00003617          	auipc	a2,0x3
ffffffffc020549e:	00e60613          	addi	a2,a2,14 # ffffffffc02084a8 <default_pmm_manager+0x168>
ffffffffc02054a2:	21800593          	li	a1,536
ffffffffc02054a6:	00003517          	auipc	a0,0x3
ffffffffc02054aa:	f9250513          	addi	a0,a0,-110 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc02054ae:	d5bfa0ef          	jal	ra,ffffffffc0200208 <__panic>
        intr_disable();
ffffffffc02054b2:	996fb0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc02054b6:	4a05                	li	s4,1
ffffffffc02054b8:	bf1d                	j	ffffffffc02053ee <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc02054ba:	28d000ef          	jal	ra,ffffffffc0205f46 <wakeup_proc>
ffffffffc02054be:	b789                	j	ffffffffc0205400 <do_exit+0x8a>

ffffffffc02054c0 <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc02054c0:	715d                	addi	sp,sp,-80
ffffffffc02054c2:	f84a                	sd	s2,48(sp)
ffffffffc02054c4:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc02054c6:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc02054ca:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc02054cc:	fc26                	sd	s1,56(sp)
ffffffffc02054ce:	f052                	sd	s4,32(sp)
ffffffffc02054d0:	ec56                	sd	s5,24(sp)
ffffffffc02054d2:	e85a                	sd	s6,16(sp)
ffffffffc02054d4:	e45e                	sd	s7,8(sp)
ffffffffc02054d6:	e486                	sd	ra,72(sp)
ffffffffc02054d8:	e0a2                	sd	s0,64(sp)
ffffffffc02054da:	84aa                	mv	s1,a0
ffffffffc02054dc:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc02054de:	000adb97          	auipc	s7,0xad
ffffffffc02054e2:	3d2b8b93          	addi	s7,s7,978 # ffffffffc02b28b0 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc02054e6:	00050b1b          	sext.w	s6,a0
ffffffffc02054ea:	fff50a9b          	addiw	s5,a0,-1
ffffffffc02054ee:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc02054f0:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc02054f2:	ccbd                	beqz	s1,ffffffffc0205570 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc02054f4:	0359e863          	bltu	s3,s5,ffffffffc0205524 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02054f8:	45a9                	li	a1,10
ffffffffc02054fa:	855a                	mv	a0,s6
ffffffffc02054fc:	0ca010ef          	jal	ra,ffffffffc02065c6 <hash32>
ffffffffc0205500:	02051793          	slli	a5,a0,0x20
ffffffffc0205504:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0205508:	000a9797          	auipc	a5,0xa9
ffffffffc020550c:	32078793          	addi	a5,a5,800 # ffffffffc02ae828 <hash_list>
ffffffffc0205510:	953e                	add	a0,a0,a5
ffffffffc0205512:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc0205514:	a029                	j	ffffffffc020551e <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc0205516:	f2c42783          	lw	a5,-212(s0)
ffffffffc020551a:	02978163          	beq	a5,s1,ffffffffc020553c <do_wait.part.0+0x7c>
ffffffffc020551e:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc0205520:	fe851be3          	bne	a0,s0,ffffffffc0205516 <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc0205524:	5579                	li	a0,-2
}
ffffffffc0205526:	60a6                	ld	ra,72(sp)
ffffffffc0205528:	6406                	ld	s0,64(sp)
ffffffffc020552a:	74e2                	ld	s1,56(sp)
ffffffffc020552c:	7942                	ld	s2,48(sp)
ffffffffc020552e:	79a2                	ld	s3,40(sp)
ffffffffc0205530:	7a02                	ld	s4,32(sp)
ffffffffc0205532:	6ae2                	ld	s5,24(sp)
ffffffffc0205534:	6b42                	ld	s6,16(sp)
ffffffffc0205536:	6ba2                	ld	s7,8(sp)
ffffffffc0205538:	6161                	addi	sp,sp,80
ffffffffc020553a:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc020553c:	000bb683          	ld	a3,0(s7)
ffffffffc0205540:	f4843783          	ld	a5,-184(s0)
ffffffffc0205544:	fed790e3          	bne	a5,a3,ffffffffc0205524 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0205548:	f2842703          	lw	a4,-216(s0)
ffffffffc020554c:	478d                	li	a5,3
ffffffffc020554e:	0ef70b63          	beq	a4,a5,ffffffffc0205644 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc0205552:	4785                	li	a5,1
ffffffffc0205554:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc0205556:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc020555a:	26d000ef          	jal	ra,ffffffffc0205fc6 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc020555e:	000bb783          	ld	a5,0(s7)
ffffffffc0205562:	0b07a783          	lw	a5,176(a5)
ffffffffc0205566:	8b85                	andi	a5,a5,1
ffffffffc0205568:	d7c9                	beqz	a5,ffffffffc02054f2 <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc020556a:	555d                	li	a0,-9
ffffffffc020556c:	e0bff0ef          	jal	ra,ffffffffc0205376 <do_exit>
        proc = current->cptr;
ffffffffc0205570:	000bb683          	ld	a3,0(s7)
ffffffffc0205574:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0205576:	d45d                	beqz	s0,ffffffffc0205524 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0205578:	470d                	li	a4,3
ffffffffc020557a:	a021                	j	ffffffffc0205582 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc020557c:	10043403          	ld	s0,256(s0)
ffffffffc0205580:	d869                	beqz	s0,ffffffffc0205552 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0205582:	401c                	lw	a5,0(s0)
ffffffffc0205584:	fee79ce3          	bne	a5,a4,ffffffffc020557c <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc0205588:	000ad797          	auipc	a5,0xad
ffffffffc020558c:	3307b783          	ld	a5,816(a5) # ffffffffc02b28b8 <idleproc>
ffffffffc0205590:	0c878963          	beq	a5,s0,ffffffffc0205662 <do_wait.part.0+0x1a2>
ffffffffc0205594:	000ad797          	auipc	a5,0xad
ffffffffc0205598:	32c7b783          	ld	a5,812(a5) # ffffffffc02b28c0 <initproc>
ffffffffc020559c:	0cf40363          	beq	s0,a5,ffffffffc0205662 <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc02055a0:	000a0663          	beqz	s4,ffffffffc02055ac <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc02055a4:	0e842783          	lw	a5,232(s0)
ffffffffc02055a8:	00fa2023          	sw	a5,0(s4)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02055ac:	100027f3          	csrr	a5,sstatus
ffffffffc02055b0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02055b2:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02055b4:	e7c1                	bnez	a5,ffffffffc020563c <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02055b6:	6c70                	ld	a2,216(s0)
ffffffffc02055b8:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc02055ba:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc02055be:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc02055c0:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02055c2:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02055c4:	6470                	ld	a2,200(s0)
ffffffffc02055c6:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc02055c8:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02055ca:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc02055cc:	c319                	beqz	a4,ffffffffc02055d2 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc02055ce:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc02055d0:	7c7c                	ld	a5,248(s0)
ffffffffc02055d2:	c3b5                	beqz	a5,ffffffffc0205636 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc02055d4:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc02055d8:	000ad717          	auipc	a4,0xad
ffffffffc02055dc:	2f070713          	addi	a4,a4,752 # ffffffffc02b28c8 <nr_process>
ffffffffc02055e0:	431c                	lw	a5,0(a4)
ffffffffc02055e2:	37fd                	addiw	a5,a5,-1
ffffffffc02055e4:	c31c                	sw	a5,0(a4)
    if (flag) {
ffffffffc02055e6:	e5a9                	bnez	a1,ffffffffc0205630 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02055e8:	6814                	ld	a3,16(s0)
ffffffffc02055ea:	c02007b7          	lui	a5,0xc0200
ffffffffc02055ee:	04f6ee63          	bltu	a3,a5,ffffffffc020564a <do_wait.part.0+0x18a>
ffffffffc02055f2:	000ad797          	auipc	a5,0xad
ffffffffc02055f6:	2867b783          	ld	a5,646(a5) # ffffffffc02b2878 <va_pa_offset>
ffffffffc02055fa:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc02055fc:	82b1                	srli	a3,a3,0xc
ffffffffc02055fe:	000ad797          	auipc	a5,0xad
ffffffffc0205602:	2627b783          	ld	a5,610(a5) # ffffffffc02b2860 <npage>
ffffffffc0205606:	06f6fa63          	bgeu	a3,a5,ffffffffc020567a <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc020560a:	00003517          	auipc	a0,0x3
ffffffffc020560e:	6e653503          	ld	a0,1766(a0) # ffffffffc0208cf0 <nbase>
ffffffffc0205612:	8e89                	sub	a3,a3,a0
ffffffffc0205614:	069a                	slli	a3,a3,0x6
ffffffffc0205616:	000ad517          	auipc	a0,0xad
ffffffffc020561a:	25253503          	ld	a0,594(a0) # ffffffffc02b2868 <pages>
ffffffffc020561e:	9536                	add	a0,a0,a3
ffffffffc0205620:	4589                	li	a1,2
ffffffffc0205622:	8cbfb0ef          	jal	ra,ffffffffc0200eec <free_pages>
    kfree(proc);
ffffffffc0205626:	8522                	mv	a0,s0
ffffffffc0205628:	8b0fe0ef          	jal	ra,ffffffffc02036d8 <kfree>
    return 0;
ffffffffc020562c:	4501                	li	a0,0
ffffffffc020562e:	bde5                	j	ffffffffc0205526 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc0205630:	812fb0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0205634:	bf55                	j	ffffffffc02055e8 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc0205636:	701c                	ld	a5,32(s0)
ffffffffc0205638:	fbf8                	sd	a4,240(a5)
ffffffffc020563a:	bf79                	j	ffffffffc02055d8 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc020563c:	80cfb0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc0205640:	4585                	li	a1,1
ffffffffc0205642:	bf95                	j	ffffffffc02055b6 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205644:	f2840413          	addi	s0,s0,-216
ffffffffc0205648:	b781                	j	ffffffffc0205588 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc020564a:	00002617          	auipc	a2,0x2
ffffffffc020564e:	a6e60613          	addi	a2,a2,-1426 # ffffffffc02070b8 <commands+0x830>
ffffffffc0205652:	06e00593          	li	a1,110
ffffffffc0205656:	00002517          	auipc	a0,0x2
ffffffffc020565a:	95250513          	addi	a0,a0,-1710 # ffffffffc0206fa8 <commands+0x720>
ffffffffc020565e:	babfa0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc0205662:	00003617          	auipc	a2,0x3
ffffffffc0205666:	e7660613          	addi	a2,a2,-394 # ffffffffc02084d8 <default_pmm_manager+0x198>
ffffffffc020566a:	36d00593          	li	a1,877
ffffffffc020566e:	00003517          	auipc	a0,0x3
ffffffffc0205672:	dca50513          	addi	a0,a0,-566 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc0205676:	b93fa0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020567a:	00002617          	auipc	a2,0x2
ffffffffc020567e:	90e60613          	addi	a2,a2,-1778 # ffffffffc0206f88 <commands+0x700>
ffffffffc0205682:	06200593          	li	a1,98
ffffffffc0205686:	00002517          	auipc	a0,0x2
ffffffffc020568a:	92250513          	addi	a0,a0,-1758 # ffffffffc0206fa8 <commands+0x720>
ffffffffc020568e:	b7bfa0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0205692 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0205692:	1141                	addi	sp,sp,-16
ffffffffc0205694:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0205696:	897fb0ef          	jal	ra,ffffffffc0200f2c <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc020569a:	f8bfd0ef          	jal	ra,ffffffffc0203624 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc020569e:	4601                	li	a2,0
ffffffffc02056a0:	4581                	li	a1,0
ffffffffc02056a2:	fffff517          	auipc	a0,0xfffff
ffffffffc02056a6:	72850513          	addi	a0,a0,1832 # ffffffffc0204dca <user_main>
ffffffffc02056aa:	c7dff0ef          	jal	ra,ffffffffc0205326 <kernel_thread>
    if (pid <= 0)
ffffffffc02056ae:	00a04563          	bgtz	a0,ffffffffc02056b8 <init_main+0x26>
ffffffffc02056b2:	a071                	j	ffffffffc020573e <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc02056b4:	113000ef          	jal	ra,ffffffffc0205fc6 <schedule>
    if (code_store != NULL)
ffffffffc02056b8:	4581                	li	a1,0
ffffffffc02056ba:	4501                	li	a0,0
ffffffffc02056bc:	e05ff0ef          	jal	ra,ffffffffc02054c0 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc02056c0:	d975                	beqz	a0,ffffffffc02056b4 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc02056c2:	00003517          	auipc	a0,0x3
ffffffffc02056c6:	e5650513          	addi	a0,a0,-426 # ffffffffc0208518 <default_pmm_manager+0x1d8>
ffffffffc02056ca:	a03fa0ef          	jal	ra,ffffffffc02000cc <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02056ce:	000ad797          	auipc	a5,0xad
ffffffffc02056d2:	1f27b783          	ld	a5,498(a5) # ffffffffc02b28c0 <initproc>
ffffffffc02056d6:	7bf8                	ld	a4,240(a5)
ffffffffc02056d8:	e339                	bnez	a4,ffffffffc020571e <init_main+0x8c>
ffffffffc02056da:	7ff8                	ld	a4,248(a5)
ffffffffc02056dc:	e329                	bnez	a4,ffffffffc020571e <init_main+0x8c>
ffffffffc02056de:	1007b703          	ld	a4,256(a5)
ffffffffc02056e2:	ef15                	bnez	a4,ffffffffc020571e <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc02056e4:	000ad697          	auipc	a3,0xad
ffffffffc02056e8:	1e46a683          	lw	a3,484(a3) # ffffffffc02b28c8 <nr_process>
ffffffffc02056ec:	4709                	li	a4,2
ffffffffc02056ee:	0ae69463          	bne	a3,a4,ffffffffc0205796 <init_main+0x104>
    return listelm->next;
ffffffffc02056f2:	000ad697          	auipc	a3,0xad
ffffffffc02056f6:	13668693          	addi	a3,a3,310 # ffffffffc02b2828 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02056fa:	6698                	ld	a4,8(a3)
ffffffffc02056fc:	0c878793          	addi	a5,a5,200
ffffffffc0205700:	06f71b63          	bne	a4,a5,ffffffffc0205776 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0205704:	629c                	ld	a5,0(a3)
ffffffffc0205706:	04f71863          	bne	a4,a5,ffffffffc0205756 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc020570a:	00003517          	auipc	a0,0x3
ffffffffc020570e:	ef650513          	addi	a0,a0,-266 # ffffffffc0208600 <default_pmm_manager+0x2c0>
ffffffffc0205712:	9bbfa0ef          	jal	ra,ffffffffc02000cc <cprintf>
    return 0;
}
ffffffffc0205716:	60a2                	ld	ra,8(sp)
ffffffffc0205718:	4501                	li	a0,0
ffffffffc020571a:	0141                	addi	sp,sp,16
ffffffffc020571c:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020571e:	00003697          	auipc	a3,0x3
ffffffffc0205722:	e2268693          	addi	a3,a3,-478 # ffffffffc0208540 <default_pmm_manager+0x200>
ffffffffc0205726:	00001617          	auipc	a2,0x1
ffffffffc020572a:	57260613          	addi	a2,a2,1394 # ffffffffc0206c98 <commands+0x410>
ffffffffc020572e:	3db00593          	li	a1,987
ffffffffc0205732:	00003517          	auipc	a0,0x3
ffffffffc0205736:	d0650513          	addi	a0,a0,-762 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc020573a:	acffa0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("create user_main failed.\n");
ffffffffc020573e:	00003617          	auipc	a2,0x3
ffffffffc0205742:	dba60613          	addi	a2,a2,-582 # ffffffffc02084f8 <default_pmm_manager+0x1b8>
ffffffffc0205746:	3d200593          	li	a1,978
ffffffffc020574a:	00003517          	auipc	a0,0x3
ffffffffc020574e:	cee50513          	addi	a0,a0,-786 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc0205752:	ab7fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0205756:	00003697          	auipc	a3,0x3
ffffffffc020575a:	e7a68693          	addi	a3,a3,-390 # ffffffffc02085d0 <default_pmm_manager+0x290>
ffffffffc020575e:	00001617          	auipc	a2,0x1
ffffffffc0205762:	53a60613          	addi	a2,a2,1338 # ffffffffc0206c98 <commands+0x410>
ffffffffc0205766:	3de00593          	li	a1,990
ffffffffc020576a:	00003517          	auipc	a0,0x3
ffffffffc020576e:	cce50513          	addi	a0,a0,-818 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc0205772:	a97fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0205776:	00003697          	auipc	a3,0x3
ffffffffc020577a:	e2a68693          	addi	a3,a3,-470 # ffffffffc02085a0 <default_pmm_manager+0x260>
ffffffffc020577e:	00001617          	auipc	a2,0x1
ffffffffc0205782:	51a60613          	addi	a2,a2,1306 # ffffffffc0206c98 <commands+0x410>
ffffffffc0205786:	3dd00593          	li	a1,989
ffffffffc020578a:	00003517          	auipc	a0,0x3
ffffffffc020578e:	cae50513          	addi	a0,a0,-850 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc0205792:	a77fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(nr_process == 2);
ffffffffc0205796:	00003697          	auipc	a3,0x3
ffffffffc020579a:	dfa68693          	addi	a3,a3,-518 # ffffffffc0208590 <default_pmm_manager+0x250>
ffffffffc020579e:	00001617          	auipc	a2,0x1
ffffffffc02057a2:	4fa60613          	addi	a2,a2,1274 # ffffffffc0206c98 <commands+0x410>
ffffffffc02057a6:	3dc00593          	li	a1,988
ffffffffc02057aa:	00003517          	auipc	a0,0x3
ffffffffc02057ae:	c8e50513          	addi	a0,a0,-882 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc02057b2:	a57fa0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02057b6 <do_execve>:
{
ffffffffc02057b6:	7171                	addi	sp,sp,-176
ffffffffc02057b8:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02057ba:	000add97          	auipc	s11,0xad
ffffffffc02057be:	0f6d8d93          	addi	s11,s11,246 # ffffffffc02b28b0 <current>
ffffffffc02057c2:	000db783          	ld	a5,0(s11)
{
ffffffffc02057c6:	e54e                	sd	s3,136(sp)
ffffffffc02057c8:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02057ca:	0287b983          	ld	s3,40(a5)
{
ffffffffc02057ce:	e94a                	sd	s2,144(sp)
ffffffffc02057d0:	f4de                	sd	s7,104(sp)
ffffffffc02057d2:	892a                	mv	s2,a0
ffffffffc02057d4:	8bb2                	mv	s7,a2
ffffffffc02057d6:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02057d8:	862e                	mv	a2,a1
ffffffffc02057da:	4681                	li	a3,0
ffffffffc02057dc:	85aa                	mv	a1,a0
ffffffffc02057de:	854e                	mv	a0,s3
{
ffffffffc02057e0:	f506                	sd	ra,168(sp)
ffffffffc02057e2:	f122                	sd	s0,160(sp)
ffffffffc02057e4:	e152                	sd	s4,128(sp)
ffffffffc02057e6:	fcd6                	sd	s5,120(sp)
ffffffffc02057e8:	f8da                	sd	s6,112(sp)
ffffffffc02057ea:	f0e2                	sd	s8,96(sp)
ffffffffc02057ec:	ece6                	sd	s9,88(sp)
ffffffffc02057ee:	e8ea                	sd	s10,80(sp)
ffffffffc02057f0:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02057f2:	b71fd0ef          	jal	ra,ffffffffc0203362 <user_mem_check>
ffffffffc02057f6:	40050a63          	beqz	a0,ffffffffc0205c0a <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc02057fa:	4641                	li	a2,16
ffffffffc02057fc:	4581                	li	a1,0
ffffffffc02057fe:	1808                	addi	a0,sp,48
ffffffffc0205800:	1af000ef          	jal	ra,ffffffffc02061ae <memset>
    memcpy(local_name, name, len);
ffffffffc0205804:	47bd                	li	a5,15
ffffffffc0205806:	8626                	mv	a2,s1
ffffffffc0205808:	1e97e263          	bltu	a5,s1,ffffffffc02059ec <do_execve+0x236>
ffffffffc020580c:	85ca                	mv	a1,s2
ffffffffc020580e:	1808                	addi	a0,sp,48
ffffffffc0205810:	1b1000ef          	jal	ra,ffffffffc02061c0 <memcpy>
    if (mm != NULL)
ffffffffc0205814:	1e098363          	beqz	s3,ffffffffc02059fa <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc0205818:	00002517          	auipc	a0,0x2
ffffffffc020581c:	05850513          	addi	a0,a0,88 # ffffffffc0207870 <commands+0xfe8>
ffffffffc0205820:	8e5fa0ef          	jal	ra,ffffffffc0200104 <cputs>
ffffffffc0205824:	000ad797          	auipc	a5,0xad
ffffffffc0205828:	02c7b783          	ld	a5,44(a5) # ffffffffc02b2850 <boot_cr3>
ffffffffc020582c:	577d                	li	a4,-1
ffffffffc020582e:	177e                	slli	a4,a4,0x3f
ffffffffc0205830:	83b1                	srli	a5,a5,0xc
ffffffffc0205832:	8fd9                	or	a5,a5,a4
ffffffffc0205834:	18079073          	csrw	satp,a5
ffffffffc0205838:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7b88>
ffffffffc020583c:	fff7871b          	addiw	a4,a5,-1
ffffffffc0205840:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc0205844:	2c070463          	beqz	a4,ffffffffc0205b0c <do_execve+0x356>
        current->mm = NULL;
ffffffffc0205848:	000db783          	ld	a5,0(s11)
ffffffffc020584c:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0205850:	926fd0ef          	jal	ra,ffffffffc0202976 <mm_create>
ffffffffc0205854:	84aa                	mv	s1,a0
ffffffffc0205856:	1c050d63          	beqz	a0,ffffffffc0205a30 <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc020585a:	4505                	li	a0,1
ffffffffc020585c:	dfefb0ef          	jal	ra,ffffffffc0200e5a <alloc_pages>
ffffffffc0205860:	3a050963          	beqz	a0,ffffffffc0205c12 <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc0205864:	000adc97          	auipc	s9,0xad
ffffffffc0205868:	004c8c93          	addi	s9,s9,4 # ffffffffc02b2868 <pages>
ffffffffc020586c:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0205870:	000adc17          	auipc	s8,0xad
ffffffffc0205874:	ff0c0c13          	addi	s8,s8,-16 # ffffffffc02b2860 <npage>
    return page - pages + nbase;
ffffffffc0205878:	00003717          	auipc	a4,0x3
ffffffffc020587c:	47873703          	ld	a4,1144(a4) # ffffffffc0208cf0 <nbase>
ffffffffc0205880:	40d506b3          	sub	a3,a0,a3
ffffffffc0205884:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205886:	5afd                	li	s5,-1
ffffffffc0205888:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc020588c:	96ba                	add	a3,a3,a4
ffffffffc020588e:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205890:	00cad713          	srli	a4,s5,0xc
ffffffffc0205894:	ec3a                	sd	a4,24(sp)
ffffffffc0205896:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0205898:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020589a:	38f77063          	bgeu	a4,a5,ffffffffc0205c1a <do_execve+0x464>
ffffffffc020589e:	000adb17          	auipc	s6,0xad
ffffffffc02058a2:	fdab0b13          	addi	s6,s6,-38 # ffffffffc02b2878 <va_pa_offset>
ffffffffc02058a6:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir, PGSIZE);
ffffffffc02058aa:	6605                	lui	a2,0x1
ffffffffc02058ac:	000ad597          	auipc	a1,0xad
ffffffffc02058b0:	fac5b583          	ld	a1,-84(a1) # ffffffffc02b2858 <boot_pgdir>
ffffffffc02058b4:	9936                	add	s2,s2,a3
ffffffffc02058b6:	854a                	mv	a0,s2
ffffffffc02058b8:	109000ef          	jal	ra,ffffffffc02061c0 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02058bc:	7782                	ld	a5,32(sp)
ffffffffc02058be:	4398                	lw	a4,0(a5)
ffffffffc02058c0:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc02058c4:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02058c8:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b9457>
ffffffffc02058cc:	14f71863          	bne	a4,a5,ffffffffc0205a1c <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02058d0:	7682                	ld	a3,32(sp)
ffffffffc02058d2:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02058d6:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02058da:	00371793          	slli	a5,a4,0x3
ffffffffc02058de:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02058e0:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02058e2:	078e                	slli	a5,a5,0x3
ffffffffc02058e4:	97ce                	add	a5,a5,s3
ffffffffc02058e6:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc02058e8:	00f9fc63          	bgeu	s3,a5,ffffffffc0205900 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc02058ec:	0009a783          	lw	a5,0(s3)
ffffffffc02058f0:	4705                	li	a4,1
ffffffffc02058f2:	14e78163          	beq	a5,a4,ffffffffc0205a34 <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc02058f6:	77a2                	ld	a5,40(sp)
ffffffffc02058f8:	03898993          	addi	s3,s3,56
ffffffffc02058fc:	fef9e8e3          	bltu	s3,a5,ffffffffc02058ec <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0205900:	4701                	li	a4,0
ffffffffc0205902:	46ad                	li	a3,11
ffffffffc0205904:	00100637          	lui	a2,0x100
ffffffffc0205908:	7ff005b7          	lui	a1,0x7ff00
ffffffffc020590c:	8526                	mv	a0,s1
ffffffffc020590e:	a40fd0ef          	jal	ra,ffffffffc0202b4e <mm_map>
ffffffffc0205912:	892a                	mv	s2,a0
ffffffffc0205914:	1e051263          	bnez	a0,ffffffffc0205af8 <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0205918:	6c88                	ld	a0,24(s1)
ffffffffc020591a:	467d                	li	a2,31
ffffffffc020591c:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0205920:	b8bfc0ef          	jal	ra,ffffffffc02024aa <pgdir_alloc_page>
ffffffffc0205924:	38050363          	beqz	a0,ffffffffc0205caa <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205928:	6c88                	ld	a0,24(s1)
ffffffffc020592a:	467d                	li	a2,31
ffffffffc020592c:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0205930:	b7bfc0ef          	jal	ra,ffffffffc02024aa <pgdir_alloc_page>
ffffffffc0205934:	34050b63          	beqz	a0,ffffffffc0205c8a <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205938:	6c88                	ld	a0,24(s1)
ffffffffc020593a:	467d                	li	a2,31
ffffffffc020593c:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0205940:	b6bfc0ef          	jal	ra,ffffffffc02024aa <pgdir_alloc_page>
ffffffffc0205944:	32050363          	beqz	a0,ffffffffc0205c6a <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205948:	6c88                	ld	a0,24(s1)
ffffffffc020594a:	467d                	li	a2,31
ffffffffc020594c:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0205950:	b5bfc0ef          	jal	ra,ffffffffc02024aa <pgdir_alloc_page>
ffffffffc0205954:	2e050b63          	beqz	a0,ffffffffc0205c4a <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc0205958:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc020595a:	000db603          	ld	a2,0(s11)
    current->cr3 = PADDR(mm->pgdir);
ffffffffc020595e:	6c94                	ld	a3,24(s1)
ffffffffc0205960:	2785                	addiw	a5,a5,1
ffffffffc0205962:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc0205964:	f604                	sd	s1,40(a2)
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205966:	c02007b7          	lui	a5,0xc0200
ffffffffc020596a:	2cf6e463          	bltu	a3,a5,ffffffffc0205c32 <do_execve+0x47c>
ffffffffc020596e:	000b3783          	ld	a5,0(s6)
ffffffffc0205972:	577d                	li	a4,-1
ffffffffc0205974:	177e                	slli	a4,a4,0x3f
ffffffffc0205976:	8e9d                	sub	a3,a3,a5
ffffffffc0205978:	00c6d793          	srli	a5,a3,0xc
ffffffffc020597c:	f654                	sd	a3,168(a2)
ffffffffc020597e:	8fd9                	or	a5,a5,a4
ffffffffc0205980:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0205984:	7244                	ld	s1,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0205986:	4581                	li	a1,0
ffffffffc0205988:	12000613          	li	a2,288
ffffffffc020598c:	8526                	mv	a0,s1
ffffffffc020598e:	021000ef          	jal	ra,ffffffffc02061ae <memset>
    tf->epc = elf->e_entry;
ffffffffc0205992:	7782                	ld	a5,32(sp)
ffffffffc0205994:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0205996:	4785                	li	a5,1
ffffffffc0205998:	07fe                	slli	a5,a5,0x1f
ffffffffc020599a:	e89c                	sd	a5,16(s1)
    tf->epc = elf->e_entry;
ffffffffc020599c:	10e4b423          	sd	a4,264(s1)
    tf->status = (read_csr(sstatus) | SSTATUS_SPIE) & ~SSTATUS_SPP;
ffffffffc02059a0:	100027f3          	csrr	a5,sstatus
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02059a4:	000db403          	ld	s0,0(s11)
    tf->status = (read_csr(sstatus) | SSTATUS_SPIE) & ~SSTATUS_SPP;
ffffffffc02059a8:	edf7f793          	andi	a5,a5,-289
ffffffffc02059ac:	0207e793          	ori	a5,a5,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02059b0:	0b440413          	addi	s0,s0,180
ffffffffc02059b4:	4641                	li	a2,16
ffffffffc02059b6:	4581                	li	a1,0
    tf->status = (read_csr(sstatus) | SSTATUS_SPIE) & ~SSTATUS_SPP;
ffffffffc02059b8:	10f4b023          	sd	a5,256(s1)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02059bc:	8522                	mv	a0,s0
ffffffffc02059be:	7f0000ef          	jal	ra,ffffffffc02061ae <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02059c2:	463d                	li	a2,15
ffffffffc02059c4:	180c                	addi	a1,sp,48
ffffffffc02059c6:	8522                	mv	a0,s0
ffffffffc02059c8:	7f8000ef          	jal	ra,ffffffffc02061c0 <memcpy>
}
ffffffffc02059cc:	70aa                	ld	ra,168(sp)
ffffffffc02059ce:	740a                	ld	s0,160(sp)
ffffffffc02059d0:	64ea                	ld	s1,152(sp)
ffffffffc02059d2:	69aa                	ld	s3,136(sp)
ffffffffc02059d4:	6a0a                	ld	s4,128(sp)
ffffffffc02059d6:	7ae6                	ld	s5,120(sp)
ffffffffc02059d8:	7b46                	ld	s6,112(sp)
ffffffffc02059da:	7ba6                	ld	s7,104(sp)
ffffffffc02059dc:	7c06                	ld	s8,96(sp)
ffffffffc02059de:	6ce6                	ld	s9,88(sp)
ffffffffc02059e0:	6d46                	ld	s10,80(sp)
ffffffffc02059e2:	6da6                	ld	s11,72(sp)
ffffffffc02059e4:	854a                	mv	a0,s2
ffffffffc02059e6:	694a                	ld	s2,144(sp)
ffffffffc02059e8:	614d                	addi	sp,sp,176
ffffffffc02059ea:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc02059ec:	463d                	li	a2,15
ffffffffc02059ee:	85ca                	mv	a1,s2
ffffffffc02059f0:	1808                	addi	a0,sp,48
ffffffffc02059f2:	7ce000ef          	jal	ra,ffffffffc02061c0 <memcpy>
    if (mm != NULL)
ffffffffc02059f6:	e20991e3          	bnez	s3,ffffffffc0205818 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc02059fa:	000db783          	ld	a5,0(s11)
ffffffffc02059fe:	779c                	ld	a5,40(a5)
ffffffffc0205a00:	e40788e3          	beqz	a5,ffffffffc0205850 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0205a04:	00003617          	auipc	a2,0x3
ffffffffc0205a08:	c1c60613          	addi	a2,a2,-996 # ffffffffc0208620 <default_pmm_manager+0x2e0>
ffffffffc0205a0c:	25400593          	li	a1,596
ffffffffc0205a10:	00003517          	auipc	a0,0x3
ffffffffc0205a14:	a2850513          	addi	a0,a0,-1496 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc0205a18:	ff0fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    put_pgdir(mm);
ffffffffc0205a1c:	8526                	mv	a0,s1
ffffffffc0205a1e:	c2aff0ef          	jal	ra,ffffffffc0204e48 <put_pgdir>
    mm_destroy(mm);
ffffffffc0205a22:	8526                	mv	a0,s1
ffffffffc0205a24:	8d8fd0ef          	jal	ra,ffffffffc0202afc <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0205a28:	5961                	li	s2,-8
    do_exit(ret);
ffffffffc0205a2a:	854a                	mv	a0,s2
ffffffffc0205a2c:	94bff0ef          	jal	ra,ffffffffc0205376 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0205a30:	5971                	li	s2,-4
ffffffffc0205a32:	bfe5                	j	ffffffffc0205a2a <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0205a34:	0289b603          	ld	a2,40(s3)
ffffffffc0205a38:	0209b783          	ld	a5,32(s3)
ffffffffc0205a3c:	1cf66d63          	bltu	a2,a5,ffffffffc0205c16 <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0205a40:	0049a783          	lw	a5,4(s3)
ffffffffc0205a44:	0017f693          	andi	a3,a5,1
ffffffffc0205a48:	c291                	beqz	a3,ffffffffc0205a4c <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0205a4a:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0205a4c:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0205a50:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0205a52:	e779                	bnez	a4,ffffffffc0205b20 <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0205a54:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0205a56:	c781                	beqz	a5,ffffffffc0205a5e <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0205a58:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0205a5c:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0205a5e:	0026f793          	andi	a5,a3,2
ffffffffc0205a62:	e3f1                	bnez	a5,ffffffffc0205b26 <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc0205a64:	0046f793          	andi	a5,a3,4
ffffffffc0205a68:	c399                	beqz	a5,ffffffffc0205a6e <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0205a6a:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0205a6e:	0109b583          	ld	a1,16(s3)
ffffffffc0205a72:	4701                	li	a4,0
ffffffffc0205a74:	8526                	mv	a0,s1
ffffffffc0205a76:	8d8fd0ef          	jal	ra,ffffffffc0202b4e <mm_map>
ffffffffc0205a7a:	892a                	mv	s2,a0
ffffffffc0205a7c:	ed35                	bnez	a0,ffffffffc0205af8 <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205a7e:	0109bb83          	ld	s7,16(s3)
ffffffffc0205a82:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0205a84:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205a88:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205a8c:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205a90:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0205a92:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205a94:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc0205a96:	054be963          	bltu	s7,s4,ffffffffc0205ae8 <do_execve+0x332>
ffffffffc0205a9a:	aa95                	j	ffffffffc0205c0e <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205a9c:	6785                	lui	a5,0x1
ffffffffc0205a9e:	415b8533          	sub	a0,s7,s5
ffffffffc0205aa2:	9abe                	add	s5,s5,a5
ffffffffc0205aa4:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0205aa8:	015a7463          	bgeu	s4,s5,ffffffffc0205ab0 <do_execve+0x2fa>
                size -= la - end;
ffffffffc0205aac:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0205ab0:	000cb683          	ld	a3,0(s9)
ffffffffc0205ab4:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205ab6:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0205aba:	40d406b3          	sub	a3,s0,a3
ffffffffc0205abe:	8699                	srai	a3,a3,0x6
ffffffffc0205ac0:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205ac2:	67e2                	ld	a5,24(sp)
ffffffffc0205ac4:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205ac8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205aca:	14b87863          	bgeu	a6,a1,ffffffffc0205c1a <do_execve+0x464>
ffffffffc0205ace:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205ad2:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0205ad4:	9bb2                	add	s7,s7,a2
ffffffffc0205ad6:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205ad8:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0205ada:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205adc:	6e4000ef          	jal	ra,ffffffffc02061c0 <memcpy>
            start += size, from += size;
ffffffffc0205ae0:	6622                	ld	a2,8(sp)
ffffffffc0205ae2:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0205ae4:	054bf363          	bgeu	s7,s4,ffffffffc0205b2a <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0205ae8:	6c88                	ld	a0,24(s1)
ffffffffc0205aea:	866a                	mv	a2,s10
ffffffffc0205aec:	85d6                	mv	a1,s5
ffffffffc0205aee:	9bdfc0ef          	jal	ra,ffffffffc02024aa <pgdir_alloc_page>
ffffffffc0205af2:	842a                	mv	s0,a0
ffffffffc0205af4:	f545                	bnez	a0,ffffffffc0205a9c <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0205af6:	5971                	li	s2,-4
    exit_mmap(mm);
ffffffffc0205af8:	8526                	mv	a0,s1
ffffffffc0205afa:	99efd0ef          	jal	ra,ffffffffc0202c98 <exit_mmap>
    put_pgdir(mm);
ffffffffc0205afe:	8526                	mv	a0,s1
ffffffffc0205b00:	b48ff0ef          	jal	ra,ffffffffc0204e48 <put_pgdir>
    mm_destroy(mm);
ffffffffc0205b04:	8526                	mv	a0,s1
ffffffffc0205b06:	ff7fc0ef          	jal	ra,ffffffffc0202afc <mm_destroy>
    return ret;
ffffffffc0205b0a:	b705                	j	ffffffffc0205a2a <do_execve+0x274>
            exit_mmap(mm);  // 清空内存管理部分和对应页表
ffffffffc0205b0c:	854e                	mv	a0,s3
ffffffffc0205b0e:	98afd0ef          	jal	ra,ffffffffc0202c98 <exit_mmap>
            put_pgdir(mm);  // 清空页表
ffffffffc0205b12:	854e                	mv	a0,s3
ffffffffc0205b14:	b34ff0ef          	jal	ra,ffffffffc0204e48 <put_pgdir>
            mm_destroy(mm); // 清空缓存
ffffffffc0205b18:	854e                	mv	a0,s3
ffffffffc0205b1a:	fe3fc0ef          	jal	ra,ffffffffc0202afc <mm_destroy>
ffffffffc0205b1e:	b32d                	j	ffffffffc0205848 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0205b20:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0205b24:	fb95                	bnez	a5,ffffffffc0205a58 <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0205b26:	4d5d                	li	s10,23
ffffffffc0205b28:	bf35                	j	ffffffffc0205a64 <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0205b2a:	0109b683          	ld	a3,16(s3)
ffffffffc0205b2e:	0289b903          	ld	s2,40(s3)
ffffffffc0205b32:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0205b34:	075bfd63          	bgeu	s7,s5,ffffffffc0205bae <do_execve+0x3f8>
            if (start == end)
ffffffffc0205b38:	db790fe3          	beq	s2,s7,ffffffffc02058f6 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205b3c:	6785                	lui	a5,0x1
ffffffffc0205b3e:	00fb8533          	add	a0,s7,a5
ffffffffc0205b42:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0205b46:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc0205b4a:	0b597d63          	bgeu	s2,s5,ffffffffc0205c04 <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0205b4e:	000cb683          	ld	a3,0(s9)
ffffffffc0205b52:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205b54:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0205b58:	40d406b3          	sub	a3,s0,a3
ffffffffc0205b5c:	8699                	srai	a3,a3,0x6
ffffffffc0205b5e:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205b60:	67e2                	ld	a5,24(sp)
ffffffffc0205b62:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205b66:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205b68:	0ac5f963          	bgeu	a1,a2,ffffffffc0205c1a <do_execve+0x464>
ffffffffc0205b6c:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0205b70:	8652                	mv	a2,s4
ffffffffc0205b72:	4581                	li	a1,0
ffffffffc0205b74:	96c2                	add	a3,a3,a6
ffffffffc0205b76:	9536                	add	a0,a0,a3
ffffffffc0205b78:	636000ef          	jal	ra,ffffffffc02061ae <memset>
            start += size;
ffffffffc0205b7c:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0205b80:	03597463          	bgeu	s2,s5,ffffffffc0205ba8 <do_execve+0x3f2>
ffffffffc0205b84:	d6e909e3          	beq	s2,a4,ffffffffc02058f6 <do_execve+0x140>
ffffffffc0205b88:	00003697          	auipc	a3,0x3
ffffffffc0205b8c:	ac068693          	addi	a3,a3,-1344 # ffffffffc0208648 <default_pmm_manager+0x308>
ffffffffc0205b90:	00001617          	auipc	a2,0x1
ffffffffc0205b94:	10860613          	addi	a2,a2,264 # ffffffffc0206c98 <commands+0x410>
ffffffffc0205b98:	2bd00593          	li	a1,701
ffffffffc0205b9c:	00003517          	auipc	a0,0x3
ffffffffc0205ba0:	89c50513          	addi	a0,a0,-1892 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc0205ba4:	e64fa0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0205ba8:	ff5710e3          	bne	a4,s5,ffffffffc0205b88 <do_execve+0x3d2>
ffffffffc0205bac:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0205bae:	d52bf4e3          	bgeu	s7,s2,ffffffffc02058f6 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0205bb2:	6c88                	ld	a0,24(s1)
ffffffffc0205bb4:	866a                	mv	a2,s10
ffffffffc0205bb6:	85d6                	mv	a1,s5
ffffffffc0205bb8:	8f3fc0ef          	jal	ra,ffffffffc02024aa <pgdir_alloc_page>
ffffffffc0205bbc:	842a                	mv	s0,a0
ffffffffc0205bbe:	dd05                	beqz	a0,ffffffffc0205af6 <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205bc0:	6785                	lui	a5,0x1
ffffffffc0205bc2:	415b8533          	sub	a0,s7,s5
ffffffffc0205bc6:	9abe                	add	s5,s5,a5
ffffffffc0205bc8:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0205bcc:	01597463          	bgeu	s2,s5,ffffffffc0205bd4 <do_execve+0x41e>
                size -= la - end;
ffffffffc0205bd0:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0205bd4:	000cb683          	ld	a3,0(s9)
ffffffffc0205bd8:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205bda:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0205bde:	40d406b3          	sub	a3,s0,a3
ffffffffc0205be2:	8699                	srai	a3,a3,0x6
ffffffffc0205be4:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205be6:	67e2                	ld	a5,24(sp)
ffffffffc0205be8:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205bec:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205bee:	02b87663          	bgeu	a6,a1,ffffffffc0205c1a <do_execve+0x464>
ffffffffc0205bf2:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0205bf6:	4581                	li	a1,0
            start += size;
ffffffffc0205bf8:	9bb2                	add	s7,s7,a2
ffffffffc0205bfa:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0205bfc:	9536                	add	a0,a0,a3
ffffffffc0205bfe:	5b0000ef          	jal	ra,ffffffffc02061ae <memset>
ffffffffc0205c02:	b775                	j	ffffffffc0205bae <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205c04:	417a8a33          	sub	s4,s5,s7
ffffffffc0205c08:	b799                	j	ffffffffc0205b4e <do_execve+0x398>
        return -E_INVAL;
ffffffffc0205c0a:	5975                	li	s2,-3
ffffffffc0205c0c:	b3c1                	j	ffffffffc02059cc <do_execve+0x216>
        while (start < end)
ffffffffc0205c0e:	86de                	mv	a3,s7
ffffffffc0205c10:	bf39                	j	ffffffffc0205b2e <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0205c12:	5971                	li	s2,-4
ffffffffc0205c14:	bdc5                	j	ffffffffc0205b04 <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0205c16:	5961                	li	s2,-8
ffffffffc0205c18:	b5c5                	j	ffffffffc0205af8 <do_execve+0x342>
ffffffffc0205c1a:	00001617          	auipc	a2,0x1
ffffffffc0205c1e:	3c660613          	addi	a2,a2,966 # ffffffffc0206fe0 <commands+0x758>
ffffffffc0205c22:	06900593          	li	a1,105
ffffffffc0205c26:	00001517          	auipc	a0,0x1
ffffffffc0205c2a:	38250513          	addi	a0,a0,898 # ffffffffc0206fa8 <commands+0x720>
ffffffffc0205c2e:	ddafa0ef          	jal	ra,ffffffffc0200208 <__panic>
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205c32:	00001617          	auipc	a2,0x1
ffffffffc0205c36:	48660613          	addi	a2,a2,1158 # ffffffffc02070b8 <commands+0x830>
ffffffffc0205c3a:	2dc00593          	li	a1,732
ffffffffc0205c3e:	00002517          	auipc	a0,0x2
ffffffffc0205c42:	7fa50513          	addi	a0,a0,2042 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc0205c46:	dc2fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205c4a:	00003697          	auipc	a3,0x3
ffffffffc0205c4e:	b1668693          	addi	a3,a3,-1258 # ffffffffc0208760 <default_pmm_manager+0x420>
ffffffffc0205c52:	00001617          	auipc	a2,0x1
ffffffffc0205c56:	04660613          	addi	a2,a2,70 # ffffffffc0206c98 <commands+0x410>
ffffffffc0205c5a:	2d700593          	li	a1,727
ffffffffc0205c5e:	00002517          	auipc	a0,0x2
ffffffffc0205c62:	7da50513          	addi	a0,a0,2010 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc0205c66:	da2fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205c6a:	00003697          	auipc	a3,0x3
ffffffffc0205c6e:	aae68693          	addi	a3,a3,-1362 # ffffffffc0208718 <default_pmm_manager+0x3d8>
ffffffffc0205c72:	00001617          	auipc	a2,0x1
ffffffffc0205c76:	02660613          	addi	a2,a2,38 # ffffffffc0206c98 <commands+0x410>
ffffffffc0205c7a:	2d600593          	li	a1,726
ffffffffc0205c7e:	00002517          	auipc	a0,0x2
ffffffffc0205c82:	7ba50513          	addi	a0,a0,1978 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc0205c86:	d82fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205c8a:	00003697          	auipc	a3,0x3
ffffffffc0205c8e:	a4668693          	addi	a3,a3,-1466 # ffffffffc02086d0 <default_pmm_manager+0x390>
ffffffffc0205c92:	00001617          	auipc	a2,0x1
ffffffffc0205c96:	00660613          	addi	a2,a2,6 # ffffffffc0206c98 <commands+0x410>
ffffffffc0205c9a:	2d500593          	li	a1,725
ffffffffc0205c9e:	00002517          	auipc	a0,0x2
ffffffffc0205ca2:	79a50513          	addi	a0,a0,1946 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc0205ca6:	d62fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0205caa:	00003697          	auipc	a3,0x3
ffffffffc0205cae:	9de68693          	addi	a3,a3,-1570 # ffffffffc0208688 <default_pmm_manager+0x348>
ffffffffc0205cb2:	00001617          	auipc	a2,0x1
ffffffffc0205cb6:	fe660613          	addi	a2,a2,-26 # ffffffffc0206c98 <commands+0x410>
ffffffffc0205cba:	2d400593          	li	a1,724
ffffffffc0205cbe:	00002517          	auipc	a0,0x2
ffffffffc0205cc2:	77a50513          	addi	a0,a0,1914 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc0205cc6:	d42fa0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0205cca <do_yield>:
    current->need_resched = 1;
ffffffffc0205cca:	000ad797          	auipc	a5,0xad
ffffffffc0205cce:	be67b783          	ld	a5,-1050(a5) # ffffffffc02b28b0 <current>
ffffffffc0205cd2:	4705                	li	a4,1
ffffffffc0205cd4:	ef98                	sd	a4,24(a5)
}
ffffffffc0205cd6:	4501                	li	a0,0
ffffffffc0205cd8:	8082                	ret

ffffffffc0205cda <do_wait>:
{
ffffffffc0205cda:	1101                	addi	sp,sp,-32
ffffffffc0205cdc:	e822                	sd	s0,16(sp)
ffffffffc0205cde:	e426                	sd	s1,8(sp)
ffffffffc0205ce0:	ec06                	sd	ra,24(sp)
ffffffffc0205ce2:	842e                	mv	s0,a1
ffffffffc0205ce4:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0205ce6:	c999                	beqz	a1,ffffffffc0205cfc <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0205ce8:	000ad797          	auipc	a5,0xad
ffffffffc0205cec:	bc87b783          	ld	a5,-1080(a5) # ffffffffc02b28b0 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0205cf0:	7788                	ld	a0,40(a5)
ffffffffc0205cf2:	4685                	li	a3,1
ffffffffc0205cf4:	4611                	li	a2,4
ffffffffc0205cf6:	e6cfd0ef          	jal	ra,ffffffffc0203362 <user_mem_check>
ffffffffc0205cfa:	c909                	beqz	a0,ffffffffc0205d0c <do_wait+0x32>
ffffffffc0205cfc:	85a2                	mv	a1,s0
}
ffffffffc0205cfe:	6442                	ld	s0,16(sp)
ffffffffc0205d00:	60e2                	ld	ra,24(sp)
ffffffffc0205d02:	8526                	mv	a0,s1
ffffffffc0205d04:	64a2                	ld	s1,8(sp)
ffffffffc0205d06:	6105                	addi	sp,sp,32
ffffffffc0205d08:	fb8ff06f          	j	ffffffffc02054c0 <do_wait.part.0>
ffffffffc0205d0c:	60e2                	ld	ra,24(sp)
ffffffffc0205d0e:	6442                	ld	s0,16(sp)
ffffffffc0205d10:	64a2                	ld	s1,8(sp)
ffffffffc0205d12:	5575                	li	a0,-3
ffffffffc0205d14:	6105                	addi	sp,sp,32
ffffffffc0205d16:	8082                	ret

ffffffffc0205d18 <do_kill>:
{
ffffffffc0205d18:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0205d1a:	6789                	lui	a5,0x2
{
ffffffffc0205d1c:	e406                	sd	ra,8(sp)
ffffffffc0205d1e:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0205d20:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205d24:	17f9                	addi	a5,a5,-2
ffffffffc0205d26:	02e7e963          	bltu	a5,a4,ffffffffc0205d58 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205d2a:	842a                	mv	s0,a0
ffffffffc0205d2c:	45a9                	li	a1,10
ffffffffc0205d2e:	2501                	sext.w	a0,a0
ffffffffc0205d30:	097000ef          	jal	ra,ffffffffc02065c6 <hash32>
ffffffffc0205d34:	02051793          	slli	a5,a0,0x20
ffffffffc0205d38:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0205d3c:	000a9797          	auipc	a5,0xa9
ffffffffc0205d40:	aec78793          	addi	a5,a5,-1300 # ffffffffc02ae828 <hash_list>
ffffffffc0205d44:	953e                	add	a0,a0,a5
ffffffffc0205d46:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0205d48:	a029                	j	ffffffffc0205d52 <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0205d4a:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0205d4e:	00870b63          	beq	a4,s0,ffffffffc0205d64 <do_kill+0x4c>
ffffffffc0205d52:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0205d54:	fef51be3          	bne	a0,a5,ffffffffc0205d4a <do_kill+0x32>
    return -E_INVAL;
ffffffffc0205d58:	5475                	li	s0,-3
}
ffffffffc0205d5a:	60a2                	ld	ra,8(sp)
ffffffffc0205d5c:	8522                	mv	a0,s0
ffffffffc0205d5e:	6402                	ld	s0,0(sp)
ffffffffc0205d60:	0141                	addi	sp,sp,16
ffffffffc0205d62:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0205d64:	fd87a703          	lw	a4,-40(a5)
ffffffffc0205d68:	00177693          	andi	a3,a4,1
ffffffffc0205d6c:	e295                	bnez	a3,ffffffffc0205d90 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0205d6e:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0205d70:	00176713          	ori	a4,a4,1
ffffffffc0205d74:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0205d78:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0205d7a:	fe06d0e3          	bgez	a3,ffffffffc0205d5a <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0205d7e:	f2878513          	addi	a0,a5,-216
ffffffffc0205d82:	1c4000ef          	jal	ra,ffffffffc0205f46 <wakeup_proc>
}
ffffffffc0205d86:	60a2                	ld	ra,8(sp)
ffffffffc0205d88:	8522                	mv	a0,s0
ffffffffc0205d8a:	6402                	ld	s0,0(sp)
ffffffffc0205d8c:	0141                	addi	sp,sp,16
ffffffffc0205d8e:	8082                	ret
        return -E_KILLED;
ffffffffc0205d90:	545d                	li	s0,-9
ffffffffc0205d92:	b7e1                	j	ffffffffc0205d5a <do_kill+0x42>

ffffffffc0205d94 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0205d94:	1101                	addi	sp,sp,-32
ffffffffc0205d96:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0205d98:	000ad797          	auipc	a5,0xad
ffffffffc0205d9c:	a9078793          	addi	a5,a5,-1392 # ffffffffc02b2828 <proc_list>
ffffffffc0205da0:	ec06                	sd	ra,24(sp)
ffffffffc0205da2:	e822                	sd	s0,16(sp)
ffffffffc0205da4:	e04a                	sd	s2,0(sp)
ffffffffc0205da6:	000a9497          	auipc	s1,0xa9
ffffffffc0205daa:	a8248493          	addi	s1,s1,-1406 # ffffffffc02ae828 <hash_list>
ffffffffc0205dae:	e79c                	sd	a5,8(a5)
ffffffffc0205db0:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0205db2:	000ad717          	auipc	a4,0xad
ffffffffc0205db6:	a7670713          	addi	a4,a4,-1418 # ffffffffc02b2828 <proc_list>
ffffffffc0205dba:	87a6                	mv	a5,s1
ffffffffc0205dbc:	e79c                	sd	a5,8(a5)
ffffffffc0205dbe:	e39c                	sd	a5,0(a5)
ffffffffc0205dc0:	07c1                	addi	a5,a5,16
ffffffffc0205dc2:	fef71de3          	bne	a4,a5,ffffffffc0205dbc <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0205dc6:	f89fe0ef          	jal	ra,ffffffffc0204d4e <alloc_proc>
ffffffffc0205dca:	000ad917          	auipc	s2,0xad
ffffffffc0205dce:	aee90913          	addi	s2,s2,-1298 # ffffffffc02b28b8 <idleproc>
ffffffffc0205dd2:	00a93023          	sd	a0,0(s2)
ffffffffc0205dd6:	0e050f63          	beqz	a0,ffffffffc0205ed4 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0205dda:	4789                	li	a5,2
ffffffffc0205ddc:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205dde:	00003797          	auipc	a5,0x3
ffffffffc0205de2:	22278793          	addi	a5,a5,546 # ffffffffc0209000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205de6:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205dea:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0205dec:	4785                	li	a5,1
ffffffffc0205dee:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205df0:	4641                	li	a2,16
ffffffffc0205df2:	4581                	li	a1,0
ffffffffc0205df4:	8522                	mv	a0,s0
ffffffffc0205df6:	3b8000ef          	jal	ra,ffffffffc02061ae <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205dfa:	463d                	li	a2,15
ffffffffc0205dfc:	00003597          	auipc	a1,0x3
ffffffffc0205e00:	9c458593          	addi	a1,a1,-1596 # ffffffffc02087c0 <default_pmm_manager+0x480>
ffffffffc0205e04:	8522                	mv	a0,s0
ffffffffc0205e06:	3ba000ef          	jal	ra,ffffffffc02061c0 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0205e0a:	000ad717          	auipc	a4,0xad
ffffffffc0205e0e:	abe70713          	addi	a4,a4,-1346 # ffffffffc02b28c8 <nr_process>
ffffffffc0205e12:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0205e14:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205e18:	4601                	li	a2,0
    nr_process++;
ffffffffc0205e1a:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205e1c:	4581                	li	a1,0
ffffffffc0205e1e:	00000517          	auipc	a0,0x0
ffffffffc0205e22:	87450513          	addi	a0,a0,-1932 # ffffffffc0205692 <init_main>
    nr_process++;
ffffffffc0205e26:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0205e28:	000ad797          	auipc	a5,0xad
ffffffffc0205e2c:	a8d7b423          	sd	a3,-1400(a5) # ffffffffc02b28b0 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205e30:	cf6ff0ef          	jal	ra,ffffffffc0205326 <kernel_thread>
ffffffffc0205e34:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0205e36:	08a05363          	blez	a0,ffffffffc0205ebc <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0205e3a:	6789                	lui	a5,0x2
ffffffffc0205e3c:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205e40:	17f9                	addi	a5,a5,-2
ffffffffc0205e42:	2501                	sext.w	a0,a0
ffffffffc0205e44:	02e7e363          	bltu	a5,a4,ffffffffc0205e6a <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205e48:	45a9                	li	a1,10
ffffffffc0205e4a:	77c000ef          	jal	ra,ffffffffc02065c6 <hash32>
ffffffffc0205e4e:	02051793          	slli	a5,a0,0x20
ffffffffc0205e52:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0205e56:	96a6                	add	a3,a3,s1
ffffffffc0205e58:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0205e5a:	a029                	j	ffffffffc0205e64 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0205e5c:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c8c>
ffffffffc0205e60:	04870b63          	beq	a4,s0,ffffffffc0205eb6 <proc_init+0x122>
    return listelm->next;
ffffffffc0205e64:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0205e66:	fef69be3          	bne	a3,a5,ffffffffc0205e5c <proc_init+0xc8>
    return NULL;
ffffffffc0205e6a:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205e6c:	0b478493          	addi	s1,a5,180
ffffffffc0205e70:	4641                	li	a2,16
ffffffffc0205e72:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0205e74:	000ad417          	auipc	s0,0xad
ffffffffc0205e78:	a4c40413          	addi	s0,s0,-1460 # ffffffffc02b28c0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205e7c:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0205e7e:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205e80:	32e000ef          	jal	ra,ffffffffc02061ae <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205e84:	463d                	li	a2,15
ffffffffc0205e86:	00003597          	auipc	a1,0x3
ffffffffc0205e8a:	96258593          	addi	a1,a1,-1694 # ffffffffc02087e8 <default_pmm_manager+0x4a8>
ffffffffc0205e8e:	8526                	mv	a0,s1
ffffffffc0205e90:	330000ef          	jal	ra,ffffffffc02061c0 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205e94:	00093783          	ld	a5,0(s2)
ffffffffc0205e98:	cbb5                	beqz	a5,ffffffffc0205f0c <proc_init+0x178>
ffffffffc0205e9a:	43dc                	lw	a5,4(a5)
ffffffffc0205e9c:	eba5                	bnez	a5,ffffffffc0205f0c <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205e9e:	601c                	ld	a5,0(s0)
ffffffffc0205ea0:	c7b1                	beqz	a5,ffffffffc0205eec <proc_init+0x158>
ffffffffc0205ea2:	43d8                	lw	a4,4(a5)
ffffffffc0205ea4:	4785                	li	a5,1
ffffffffc0205ea6:	04f71363          	bne	a4,a5,ffffffffc0205eec <proc_init+0x158>
}
ffffffffc0205eaa:	60e2                	ld	ra,24(sp)
ffffffffc0205eac:	6442                	ld	s0,16(sp)
ffffffffc0205eae:	64a2                	ld	s1,8(sp)
ffffffffc0205eb0:	6902                	ld	s2,0(sp)
ffffffffc0205eb2:	6105                	addi	sp,sp,32
ffffffffc0205eb4:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205eb6:	f2878793          	addi	a5,a5,-216
ffffffffc0205eba:	bf4d                	j	ffffffffc0205e6c <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc0205ebc:	00003617          	auipc	a2,0x3
ffffffffc0205ec0:	90c60613          	addi	a2,a2,-1780 # ffffffffc02087c8 <default_pmm_manager+0x488>
ffffffffc0205ec4:	40100593          	li	a1,1025
ffffffffc0205ec8:	00002517          	auipc	a0,0x2
ffffffffc0205ecc:	57050513          	addi	a0,a0,1392 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc0205ed0:	b38fa0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0205ed4:	00003617          	auipc	a2,0x3
ffffffffc0205ed8:	8d460613          	addi	a2,a2,-1836 # ffffffffc02087a8 <default_pmm_manager+0x468>
ffffffffc0205edc:	3f200593          	li	a1,1010
ffffffffc0205ee0:	00002517          	auipc	a0,0x2
ffffffffc0205ee4:	55850513          	addi	a0,a0,1368 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc0205ee8:	b20fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205eec:	00003697          	auipc	a3,0x3
ffffffffc0205ef0:	92c68693          	addi	a3,a3,-1748 # ffffffffc0208818 <default_pmm_manager+0x4d8>
ffffffffc0205ef4:	00001617          	auipc	a2,0x1
ffffffffc0205ef8:	da460613          	addi	a2,a2,-604 # ffffffffc0206c98 <commands+0x410>
ffffffffc0205efc:	40800593          	li	a1,1032
ffffffffc0205f00:	00002517          	auipc	a0,0x2
ffffffffc0205f04:	53850513          	addi	a0,a0,1336 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc0205f08:	b00fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205f0c:	00003697          	auipc	a3,0x3
ffffffffc0205f10:	8e468693          	addi	a3,a3,-1820 # ffffffffc02087f0 <default_pmm_manager+0x4b0>
ffffffffc0205f14:	00001617          	auipc	a2,0x1
ffffffffc0205f18:	d8460613          	addi	a2,a2,-636 # ffffffffc0206c98 <commands+0x410>
ffffffffc0205f1c:	40700593          	li	a1,1031
ffffffffc0205f20:	00002517          	auipc	a0,0x2
ffffffffc0205f24:	51850513          	addi	a0,a0,1304 # ffffffffc0208438 <default_pmm_manager+0xf8>
ffffffffc0205f28:	ae0fa0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0205f2c <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0205f2c:	1141                	addi	sp,sp,-16
ffffffffc0205f2e:	e022                	sd	s0,0(sp)
ffffffffc0205f30:	e406                	sd	ra,8(sp)
ffffffffc0205f32:	000ad417          	auipc	s0,0xad
ffffffffc0205f36:	97e40413          	addi	s0,s0,-1666 # ffffffffc02b28b0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0205f3a:	6018                	ld	a4,0(s0)
ffffffffc0205f3c:	6f1c                	ld	a5,24(a4)
ffffffffc0205f3e:	dffd                	beqz	a5,ffffffffc0205f3c <cpu_idle+0x10>
        {
            schedule();
ffffffffc0205f40:	086000ef          	jal	ra,ffffffffc0205fc6 <schedule>
ffffffffc0205f44:	bfdd                	j	ffffffffc0205f3a <cpu_idle+0xe>

ffffffffc0205f46 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205f46:	4118                	lw	a4,0(a0)
wakeup_proc(struct proc_struct *proc) {
ffffffffc0205f48:	1101                	addi	sp,sp,-32
ffffffffc0205f4a:	ec06                	sd	ra,24(sp)
ffffffffc0205f4c:	e822                	sd	s0,16(sp)
ffffffffc0205f4e:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205f50:	478d                	li	a5,3
ffffffffc0205f52:	04f70b63          	beq	a4,a5,ffffffffc0205fa8 <wakeup_proc+0x62>
ffffffffc0205f56:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205f58:	100027f3          	csrr	a5,sstatus
ffffffffc0205f5c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205f5e:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205f60:	ef9d                	bnez	a5,ffffffffc0205f9e <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE) {
ffffffffc0205f62:	4789                	li	a5,2
ffffffffc0205f64:	02f70163          	beq	a4,a5,ffffffffc0205f86 <wakeup_proc+0x40>
            proc->state = PROC_RUNNABLE;
ffffffffc0205f68:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0205f6a:	0e042623          	sw	zero,236(s0)
    if (flag) {
ffffffffc0205f6e:	e491                	bnez	s1,ffffffffc0205f7a <wakeup_proc+0x34>
        else {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205f70:	60e2                	ld	ra,24(sp)
ffffffffc0205f72:	6442                	ld	s0,16(sp)
ffffffffc0205f74:	64a2                	ld	s1,8(sp)
ffffffffc0205f76:	6105                	addi	sp,sp,32
ffffffffc0205f78:	8082                	ret
ffffffffc0205f7a:	6442                	ld	s0,16(sp)
ffffffffc0205f7c:	60e2                	ld	ra,24(sp)
ffffffffc0205f7e:	64a2                	ld	s1,8(sp)
ffffffffc0205f80:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205f82:	ec0fa06f          	j	ffffffffc0200642 <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0205f86:	00003617          	auipc	a2,0x3
ffffffffc0205f8a:	8f260613          	addi	a2,a2,-1806 # ffffffffc0208878 <default_pmm_manager+0x538>
ffffffffc0205f8e:	45c9                	li	a1,18
ffffffffc0205f90:	00003517          	auipc	a0,0x3
ffffffffc0205f94:	8d050513          	addi	a0,a0,-1840 # ffffffffc0208860 <default_pmm_manager+0x520>
ffffffffc0205f98:	ad8fa0ef          	jal	ra,ffffffffc0200270 <__warn>
ffffffffc0205f9c:	bfc9                	j	ffffffffc0205f6e <wakeup_proc+0x28>
        intr_disable();
ffffffffc0205f9e:	eaafa0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        if (proc->state != PROC_RUNNABLE) {
ffffffffc0205fa2:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc0205fa4:	4485                	li	s1,1
ffffffffc0205fa6:	bf75                	j	ffffffffc0205f62 <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205fa8:	00003697          	auipc	a3,0x3
ffffffffc0205fac:	89868693          	addi	a3,a3,-1896 # ffffffffc0208840 <default_pmm_manager+0x500>
ffffffffc0205fb0:	00001617          	auipc	a2,0x1
ffffffffc0205fb4:	ce860613          	addi	a2,a2,-792 # ffffffffc0206c98 <commands+0x410>
ffffffffc0205fb8:	45a5                	li	a1,9
ffffffffc0205fba:	00003517          	auipc	a0,0x3
ffffffffc0205fbe:	8a650513          	addi	a0,a0,-1882 # ffffffffc0208860 <default_pmm_manager+0x520>
ffffffffc0205fc2:	a46fa0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0205fc6 <schedule>:

void
schedule(void) {
ffffffffc0205fc6:	1141                	addi	sp,sp,-16
ffffffffc0205fc8:	e406                	sd	ra,8(sp)
ffffffffc0205fca:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205fcc:	100027f3          	csrr	a5,sstatus
ffffffffc0205fd0:	8b89                	andi	a5,a5,2
ffffffffc0205fd2:	4401                	li	s0,0
ffffffffc0205fd4:	efbd                	bnez	a5,ffffffffc0206052 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205fd6:	000ad897          	auipc	a7,0xad
ffffffffc0205fda:	8da8b883          	ld	a7,-1830(a7) # ffffffffc02b28b0 <current>
ffffffffc0205fde:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205fe2:	000ad517          	auipc	a0,0xad
ffffffffc0205fe6:	8d653503          	ld	a0,-1834(a0) # ffffffffc02b28b8 <idleproc>
ffffffffc0205fea:	04a88e63          	beq	a7,a0,ffffffffc0206046 <schedule+0x80>
ffffffffc0205fee:	0c888693          	addi	a3,a7,200
ffffffffc0205ff2:	000ad617          	auipc	a2,0xad
ffffffffc0205ff6:	83660613          	addi	a2,a2,-1994 # ffffffffc02b2828 <proc_list>
        le = last;
ffffffffc0205ffa:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0205ffc:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc0205ffe:	4809                	li	a6,2
ffffffffc0206000:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0206002:	00c78863          	beq	a5,a2,ffffffffc0206012 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc0206006:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc020600a:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc020600e:	03070163          	beq	a4,a6,ffffffffc0206030 <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc0206012:	fef697e3          	bne	a3,a5,ffffffffc0206000 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0206016:	ed89                	bnez	a1,ffffffffc0206030 <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;
ffffffffc0206018:	451c                	lw	a5,8(a0)
ffffffffc020601a:	2785                	addiw	a5,a5,1
ffffffffc020601c:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc020601e:	00a88463          	beq	a7,a0,ffffffffc0206026 <schedule+0x60>
            proc_run(next);
ffffffffc0206022:	e9dfe0ef          	jal	ra,ffffffffc0204ebe <proc_run>
    if (flag) {
ffffffffc0206026:	e819                	bnez	s0,ffffffffc020603c <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0206028:	60a2                	ld	ra,8(sp)
ffffffffc020602a:	6402                	ld	s0,0(sp)
ffffffffc020602c:	0141                	addi	sp,sp,16
ffffffffc020602e:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0206030:	4198                	lw	a4,0(a1)
ffffffffc0206032:	4789                	li	a5,2
ffffffffc0206034:	fef712e3          	bne	a4,a5,ffffffffc0206018 <schedule+0x52>
ffffffffc0206038:	852e                	mv	a0,a1
ffffffffc020603a:	bff9                	j	ffffffffc0206018 <schedule+0x52>
}
ffffffffc020603c:	6402                	ld	s0,0(sp)
ffffffffc020603e:	60a2                	ld	ra,8(sp)
ffffffffc0206040:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0206042:	e00fa06f          	j	ffffffffc0200642 <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0206046:	000ac617          	auipc	a2,0xac
ffffffffc020604a:	7e260613          	addi	a2,a2,2018 # ffffffffc02b2828 <proc_list>
ffffffffc020604e:	86b2                	mv	a3,a2
ffffffffc0206050:	b76d                	j	ffffffffc0205ffa <schedule+0x34>
        intr_disable();
ffffffffc0206052:	df6fa0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc0206056:	4405                	li	s0,1
ffffffffc0206058:	bfbd                	j	ffffffffc0205fd6 <schedule+0x10>

ffffffffc020605a <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc020605a:	000ad797          	auipc	a5,0xad
ffffffffc020605e:	8567b783          	ld	a5,-1962(a5) # ffffffffc02b28b0 <current>
}
ffffffffc0206062:	43c8                	lw	a0,4(a5)
ffffffffc0206064:	8082                	ret

ffffffffc0206066 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0206066:	4501                	li	a0,0
ffffffffc0206068:	8082                	ret

ffffffffc020606a <sys_putc>:
    cputchar(c);
ffffffffc020606a:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc020606c:	1141                	addi	sp,sp,-16
ffffffffc020606e:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0206070:	892fa0ef          	jal	ra,ffffffffc0200102 <cputchar>
}
ffffffffc0206074:	60a2                	ld	ra,8(sp)
ffffffffc0206076:	4501                	li	a0,0
ffffffffc0206078:	0141                	addi	sp,sp,16
ffffffffc020607a:	8082                	ret

ffffffffc020607c <sys_kill>:
    return do_kill(pid);
ffffffffc020607c:	4108                	lw	a0,0(a0)
ffffffffc020607e:	c9bff06f          	j	ffffffffc0205d18 <do_kill>

ffffffffc0206082 <sys_yield>:
    return do_yield();
ffffffffc0206082:	c49ff06f          	j	ffffffffc0205cca <do_yield>

ffffffffc0206086 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0206086:	6d14                	ld	a3,24(a0)
ffffffffc0206088:	6910                	ld	a2,16(a0)
ffffffffc020608a:	650c                	ld	a1,8(a0)
ffffffffc020608c:	6108                	ld	a0,0(a0)
ffffffffc020608e:	f28ff06f          	j	ffffffffc02057b6 <do_execve>

ffffffffc0206092 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0206092:	650c                	ld	a1,8(a0)
ffffffffc0206094:	4108                	lw	a0,0(a0)
ffffffffc0206096:	c45ff06f          	j	ffffffffc0205cda <do_wait>

ffffffffc020609a <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc020609a:	000ad797          	auipc	a5,0xad
ffffffffc020609e:	8167b783          	ld	a5,-2026(a5) # ffffffffc02b28b0 <current>
ffffffffc02060a2:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02060a4:	4501                	li	a0,0
ffffffffc02060a6:	6a0c                	ld	a1,16(a2)
ffffffffc02060a8:	e83fe06f          	j	ffffffffc0204f2a <do_fork>

ffffffffc02060ac <sys_exit>:
    return do_exit(error_code);
ffffffffc02060ac:	4108                	lw	a0,0(a0)
ffffffffc02060ae:	ac8ff06f          	j	ffffffffc0205376 <do_exit>

ffffffffc02060b2 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc02060b2:	715d                	addi	sp,sp,-80
ffffffffc02060b4:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc02060b6:	000ac497          	auipc	s1,0xac
ffffffffc02060ba:	7fa48493          	addi	s1,s1,2042 # ffffffffc02b28b0 <current>
ffffffffc02060be:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc02060c0:	e0a2                	sd	s0,64(sp)
ffffffffc02060c2:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc02060c4:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc02060c6:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02060c8:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc02060ca:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02060ce:	0327ee63          	bltu	a5,s2,ffffffffc020610a <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc02060d2:	00391713          	slli	a4,s2,0x3
ffffffffc02060d6:	00003797          	auipc	a5,0x3
ffffffffc02060da:	80a78793          	addi	a5,a5,-2038 # ffffffffc02088e0 <syscalls>
ffffffffc02060de:	97ba                	add	a5,a5,a4
ffffffffc02060e0:	639c                	ld	a5,0(a5)
ffffffffc02060e2:	c785                	beqz	a5,ffffffffc020610a <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc02060e4:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc02060e6:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc02060e8:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc02060ea:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc02060ec:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc02060ee:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc02060f0:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc02060f2:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc02060f4:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc02060f6:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02060f8:	0028                	addi	a0,sp,8
ffffffffc02060fa:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc02060fc:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02060fe:	e828                	sd	a0,80(s0)
}
ffffffffc0206100:	6406                	ld	s0,64(sp)
ffffffffc0206102:	74e2                	ld	s1,56(sp)
ffffffffc0206104:	7942                	ld	s2,48(sp)
ffffffffc0206106:	6161                	addi	sp,sp,80
ffffffffc0206108:	8082                	ret
    print_trapframe(tf);
ffffffffc020610a:	8522                	mv	a0,s0
ffffffffc020610c:	f2afa0ef          	jal	ra,ffffffffc0200836 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0206110:	609c                	ld	a5,0(s1)
ffffffffc0206112:	86ca                	mv	a3,s2
ffffffffc0206114:	00002617          	auipc	a2,0x2
ffffffffc0206118:	78460613          	addi	a2,a2,1924 # ffffffffc0208898 <default_pmm_manager+0x558>
ffffffffc020611c:	43d8                	lw	a4,4(a5)
ffffffffc020611e:	06200593          	li	a1,98
ffffffffc0206122:	0b478793          	addi	a5,a5,180
ffffffffc0206126:	00002517          	auipc	a0,0x2
ffffffffc020612a:	7a250513          	addi	a0,a0,1954 # ffffffffc02088c8 <default_pmm_manager+0x588>
ffffffffc020612e:	8dafa0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0206132 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0206132:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0206136:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0206138:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc020613a:	cb81                	beqz	a5,ffffffffc020614a <strlen+0x18>
        cnt ++;
ffffffffc020613c:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc020613e:	00a707b3          	add	a5,a4,a0
ffffffffc0206142:	0007c783          	lbu	a5,0(a5)
ffffffffc0206146:	fbfd                	bnez	a5,ffffffffc020613c <strlen+0xa>
ffffffffc0206148:	8082                	ret
    }
    return cnt;
}
ffffffffc020614a:	8082                	ret

ffffffffc020614c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020614c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020614e:	e589                	bnez	a1,ffffffffc0206158 <strnlen+0xc>
ffffffffc0206150:	a811                	j	ffffffffc0206164 <strnlen+0x18>
        cnt ++;
ffffffffc0206152:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0206154:	00f58863          	beq	a1,a5,ffffffffc0206164 <strnlen+0x18>
ffffffffc0206158:	00f50733          	add	a4,a0,a5
ffffffffc020615c:	00074703          	lbu	a4,0(a4)
ffffffffc0206160:	fb6d                	bnez	a4,ffffffffc0206152 <strnlen+0x6>
ffffffffc0206162:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0206164:	852e                	mv	a0,a1
ffffffffc0206166:	8082                	ret

ffffffffc0206168 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0206168:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc020616a:	0005c703          	lbu	a4,0(a1)
ffffffffc020616e:	0785                	addi	a5,a5,1
ffffffffc0206170:	0585                	addi	a1,a1,1
ffffffffc0206172:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0206176:	fb75                	bnez	a4,ffffffffc020616a <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0206178:	8082                	ret

ffffffffc020617a <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020617a:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020617e:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0206182:	cb89                	beqz	a5,ffffffffc0206194 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0206184:	0505                	addi	a0,a0,1
ffffffffc0206186:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0206188:	fee789e3          	beq	a5,a4,ffffffffc020617a <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020618c:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0206190:	9d19                	subw	a0,a0,a4
ffffffffc0206192:	8082                	ret
ffffffffc0206194:	4501                	li	a0,0
ffffffffc0206196:	bfed                	j	ffffffffc0206190 <strcmp+0x16>

ffffffffc0206198 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0206198:	00054783          	lbu	a5,0(a0)
ffffffffc020619c:	c799                	beqz	a5,ffffffffc02061aa <strchr+0x12>
        if (*s == c) {
ffffffffc020619e:	00f58763          	beq	a1,a5,ffffffffc02061ac <strchr+0x14>
    while (*s != '\0') {
ffffffffc02061a2:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc02061a6:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02061a8:	fbfd                	bnez	a5,ffffffffc020619e <strchr+0x6>
    }
    return NULL;
ffffffffc02061aa:	4501                	li	a0,0
}
ffffffffc02061ac:	8082                	ret

ffffffffc02061ae <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02061ae:	ca01                	beqz	a2,ffffffffc02061be <memset+0x10>
ffffffffc02061b0:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02061b2:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02061b4:	0785                	addi	a5,a5,1
ffffffffc02061b6:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02061ba:	fec79de3          	bne	a5,a2,ffffffffc02061b4 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02061be:	8082                	ret

ffffffffc02061c0 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc02061c0:	ca19                	beqz	a2,ffffffffc02061d6 <memcpy+0x16>
ffffffffc02061c2:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc02061c4:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc02061c6:	0005c703          	lbu	a4,0(a1)
ffffffffc02061ca:	0585                	addi	a1,a1,1
ffffffffc02061cc:	0785                	addi	a5,a5,1
ffffffffc02061ce:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02061d2:	fec59ae3          	bne	a1,a2,ffffffffc02061c6 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02061d6:	8082                	ret

ffffffffc02061d8 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02061d8:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02061dc:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02061de:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02061e2:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02061e4:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02061e8:	f022                	sd	s0,32(sp)
ffffffffc02061ea:	ec26                	sd	s1,24(sp)
ffffffffc02061ec:	e84a                	sd	s2,16(sp)
ffffffffc02061ee:	f406                	sd	ra,40(sp)
ffffffffc02061f0:	e44e                	sd	s3,8(sp)
ffffffffc02061f2:	84aa                	mv	s1,a0
ffffffffc02061f4:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02061f6:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02061fa:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02061fc:	03067e63          	bgeu	a2,a6,ffffffffc0206238 <printnum+0x60>
ffffffffc0206200:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0206202:	00805763          	blez	s0,ffffffffc0206210 <printnum+0x38>
ffffffffc0206206:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0206208:	85ca                	mv	a1,s2
ffffffffc020620a:	854e                	mv	a0,s3
ffffffffc020620c:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020620e:	fc65                	bnez	s0,ffffffffc0206206 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206210:	1a02                	slli	s4,s4,0x20
ffffffffc0206212:	00002797          	auipc	a5,0x2
ffffffffc0206216:	7ce78793          	addi	a5,a5,1998 # ffffffffc02089e0 <syscalls+0x100>
ffffffffc020621a:	020a5a13          	srli	s4,s4,0x20
ffffffffc020621e:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0206220:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206222:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0206226:	70a2                	ld	ra,40(sp)
ffffffffc0206228:	69a2                	ld	s3,8(sp)
ffffffffc020622a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020622c:	85ca                	mv	a1,s2
ffffffffc020622e:	87a6                	mv	a5,s1
}
ffffffffc0206230:	6942                	ld	s2,16(sp)
ffffffffc0206232:	64e2                	ld	s1,24(sp)
ffffffffc0206234:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206236:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0206238:	03065633          	divu	a2,a2,a6
ffffffffc020623c:	8722                	mv	a4,s0
ffffffffc020623e:	f9bff0ef          	jal	ra,ffffffffc02061d8 <printnum>
ffffffffc0206242:	b7f9                	j	ffffffffc0206210 <printnum+0x38>

ffffffffc0206244 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0206244:	7119                	addi	sp,sp,-128
ffffffffc0206246:	f4a6                	sd	s1,104(sp)
ffffffffc0206248:	f0ca                	sd	s2,96(sp)
ffffffffc020624a:	ecce                	sd	s3,88(sp)
ffffffffc020624c:	e8d2                	sd	s4,80(sp)
ffffffffc020624e:	e4d6                	sd	s5,72(sp)
ffffffffc0206250:	e0da                	sd	s6,64(sp)
ffffffffc0206252:	fc5e                	sd	s7,56(sp)
ffffffffc0206254:	f06a                	sd	s10,32(sp)
ffffffffc0206256:	fc86                	sd	ra,120(sp)
ffffffffc0206258:	f8a2                	sd	s0,112(sp)
ffffffffc020625a:	f862                	sd	s8,48(sp)
ffffffffc020625c:	f466                	sd	s9,40(sp)
ffffffffc020625e:	ec6e                	sd	s11,24(sp)
ffffffffc0206260:	892a                	mv	s2,a0
ffffffffc0206262:	84ae                	mv	s1,a1
ffffffffc0206264:	8d32                	mv	s10,a2
ffffffffc0206266:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0206268:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020626c:	5b7d                	li	s6,-1
ffffffffc020626e:	00002a97          	auipc	s5,0x2
ffffffffc0206272:	79ea8a93          	addi	s5,s5,1950 # ffffffffc0208a0c <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0206276:	00003b97          	auipc	s7,0x3
ffffffffc020627a:	9b2b8b93          	addi	s7,s7,-1614 # ffffffffc0208c28 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020627e:	000d4503          	lbu	a0,0(s10)
ffffffffc0206282:	001d0413          	addi	s0,s10,1
ffffffffc0206286:	01350a63          	beq	a0,s3,ffffffffc020629a <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020628a:	c121                	beqz	a0,ffffffffc02062ca <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc020628c:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020628e:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0206290:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0206292:	fff44503          	lbu	a0,-1(s0)
ffffffffc0206296:	ff351ae3          	bne	a0,s3,ffffffffc020628a <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020629a:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020629e:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02062a2:	4c81                	li	s9,0
ffffffffc02062a4:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02062a6:	5c7d                	li	s8,-1
ffffffffc02062a8:	5dfd                	li	s11,-1
ffffffffc02062aa:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02062ae:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02062b0:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02062b4:	0ff5f593          	zext.b	a1,a1
ffffffffc02062b8:	00140d13          	addi	s10,s0,1
ffffffffc02062bc:	04b56263          	bltu	a0,a1,ffffffffc0206300 <vprintfmt+0xbc>
ffffffffc02062c0:	058a                	slli	a1,a1,0x2
ffffffffc02062c2:	95d6                	add	a1,a1,s5
ffffffffc02062c4:	4194                	lw	a3,0(a1)
ffffffffc02062c6:	96d6                	add	a3,a3,s5
ffffffffc02062c8:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02062ca:	70e6                	ld	ra,120(sp)
ffffffffc02062cc:	7446                	ld	s0,112(sp)
ffffffffc02062ce:	74a6                	ld	s1,104(sp)
ffffffffc02062d0:	7906                	ld	s2,96(sp)
ffffffffc02062d2:	69e6                	ld	s3,88(sp)
ffffffffc02062d4:	6a46                	ld	s4,80(sp)
ffffffffc02062d6:	6aa6                	ld	s5,72(sp)
ffffffffc02062d8:	6b06                	ld	s6,64(sp)
ffffffffc02062da:	7be2                	ld	s7,56(sp)
ffffffffc02062dc:	7c42                	ld	s8,48(sp)
ffffffffc02062de:	7ca2                	ld	s9,40(sp)
ffffffffc02062e0:	7d02                	ld	s10,32(sp)
ffffffffc02062e2:	6de2                	ld	s11,24(sp)
ffffffffc02062e4:	6109                	addi	sp,sp,128
ffffffffc02062e6:	8082                	ret
            padc = '0';
ffffffffc02062e8:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02062ea:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02062ee:	846a                	mv	s0,s10
ffffffffc02062f0:	00140d13          	addi	s10,s0,1
ffffffffc02062f4:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02062f8:	0ff5f593          	zext.b	a1,a1
ffffffffc02062fc:	fcb572e3          	bgeu	a0,a1,ffffffffc02062c0 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0206300:	85a6                	mv	a1,s1
ffffffffc0206302:	02500513          	li	a0,37
ffffffffc0206306:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0206308:	fff44783          	lbu	a5,-1(s0)
ffffffffc020630c:	8d22                	mv	s10,s0
ffffffffc020630e:	f73788e3          	beq	a5,s3,ffffffffc020627e <vprintfmt+0x3a>
ffffffffc0206312:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0206316:	1d7d                	addi	s10,s10,-1
ffffffffc0206318:	ff379de3          	bne	a5,s3,ffffffffc0206312 <vprintfmt+0xce>
ffffffffc020631c:	b78d                	j	ffffffffc020627e <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020631e:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0206322:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206326:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0206328:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020632c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0206330:	02d86463          	bltu	a6,a3,ffffffffc0206358 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0206334:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0206338:	002c169b          	slliw	a3,s8,0x2
ffffffffc020633c:	0186873b          	addw	a4,a3,s8
ffffffffc0206340:	0017171b          	slliw	a4,a4,0x1
ffffffffc0206344:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0206346:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020634a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020634c:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0206350:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0206354:	fed870e3          	bgeu	a6,a3,ffffffffc0206334 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0206358:	f40ddce3          	bgez	s11,ffffffffc02062b0 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc020635c:	8de2                	mv	s11,s8
ffffffffc020635e:	5c7d                	li	s8,-1
ffffffffc0206360:	bf81                	j	ffffffffc02062b0 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0206362:	fffdc693          	not	a3,s11
ffffffffc0206366:	96fd                	srai	a3,a3,0x3f
ffffffffc0206368:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020636c:	00144603          	lbu	a2,1(s0)
ffffffffc0206370:	2d81                	sext.w	s11,s11
ffffffffc0206372:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0206374:	bf35                	j	ffffffffc02062b0 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0206376:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020637a:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020637e:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206380:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0206382:	bfd9                	j	ffffffffc0206358 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0206384:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0206386:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020638a:	01174463          	blt	a4,a7,ffffffffc0206392 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc020638e:	1a088e63          	beqz	a7,ffffffffc020654a <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0206392:	000a3603          	ld	a2,0(s4)
ffffffffc0206396:	46c1                	li	a3,16
ffffffffc0206398:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020639a:	2781                	sext.w	a5,a5
ffffffffc020639c:	876e                	mv	a4,s11
ffffffffc020639e:	85a6                	mv	a1,s1
ffffffffc02063a0:	854a                	mv	a0,s2
ffffffffc02063a2:	e37ff0ef          	jal	ra,ffffffffc02061d8 <printnum>
            break;
ffffffffc02063a6:	bde1                	j	ffffffffc020627e <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02063a8:	000a2503          	lw	a0,0(s4)
ffffffffc02063ac:	85a6                	mv	a1,s1
ffffffffc02063ae:	0a21                	addi	s4,s4,8
ffffffffc02063b0:	9902                	jalr	s2
            break;
ffffffffc02063b2:	b5f1                	j	ffffffffc020627e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02063b4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02063b6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02063ba:	01174463          	blt	a4,a7,ffffffffc02063c2 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02063be:	18088163          	beqz	a7,ffffffffc0206540 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02063c2:	000a3603          	ld	a2,0(s4)
ffffffffc02063c6:	46a9                	li	a3,10
ffffffffc02063c8:	8a2e                	mv	s4,a1
ffffffffc02063ca:	bfc1                	j	ffffffffc020639a <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063cc:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02063d0:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063d2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02063d4:	bdf1                	j	ffffffffc02062b0 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02063d6:	85a6                	mv	a1,s1
ffffffffc02063d8:	02500513          	li	a0,37
ffffffffc02063dc:	9902                	jalr	s2
            break;
ffffffffc02063de:	b545                	j	ffffffffc020627e <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063e0:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02063e4:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063e6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02063e8:	b5e1                	j	ffffffffc02062b0 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02063ea:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02063ec:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02063f0:	01174463          	blt	a4,a7,ffffffffc02063f8 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02063f4:	14088163          	beqz	a7,ffffffffc0206536 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02063f8:	000a3603          	ld	a2,0(s4)
ffffffffc02063fc:	46a1                	li	a3,8
ffffffffc02063fe:	8a2e                	mv	s4,a1
ffffffffc0206400:	bf69                	j	ffffffffc020639a <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0206402:	03000513          	li	a0,48
ffffffffc0206406:	85a6                	mv	a1,s1
ffffffffc0206408:	e03e                	sd	a5,0(sp)
ffffffffc020640a:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020640c:	85a6                	mv	a1,s1
ffffffffc020640e:	07800513          	li	a0,120
ffffffffc0206412:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0206414:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0206416:	6782                	ld	a5,0(sp)
ffffffffc0206418:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020641a:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc020641e:	bfb5                	j	ffffffffc020639a <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0206420:	000a3403          	ld	s0,0(s4)
ffffffffc0206424:	008a0713          	addi	a4,s4,8
ffffffffc0206428:	e03a                	sd	a4,0(sp)
ffffffffc020642a:	14040263          	beqz	s0,ffffffffc020656e <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc020642e:	0fb05763          	blez	s11,ffffffffc020651c <vprintfmt+0x2d8>
ffffffffc0206432:	02d00693          	li	a3,45
ffffffffc0206436:	0cd79163          	bne	a5,a3,ffffffffc02064f8 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020643a:	00044783          	lbu	a5,0(s0)
ffffffffc020643e:	0007851b          	sext.w	a0,a5
ffffffffc0206442:	cf85                	beqz	a5,ffffffffc020647a <vprintfmt+0x236>
ffffffffc0206444:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0206448:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020644c:	000c4563          	bltz	s8,ffffffffc0206456 <vprintfmt+0x212>
ffffffffc0206450:	3c7d                	addiw	s8,s8,-1
ffffffffc0206452:	036c0263          	beq	s8,s6,ffffffffc0206476 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0206456:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0206458:	0e0c8e63          	beqz	s9,ffffffffc0206554 <vprintfmt+0x310>
ffffffffc020645c:	3781                	addiw	a5,a5,-32
ffffffffc020645e:	0ef47b63          	bgeu	s0,a5,ffffffffc0206554 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0206462:	03f00513          	li	a0,63
ffffffffc0206466:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206468:	000a4783          	lbu	a5,0(s4)
ffffffffc020646c:	3dfd                	addiw	s11,s11,-1
ffffffffc020646e:	0a05                	addi	s4,s4,1
ffffffffc0206470:	0007851b          	sext.w	a0,a5
ffffffffc0206474:	ffe1                	bnez	a5,ffffffffc020644c <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0206476:	01b05963          	blez	s11,ffffffffc0206488 <vprintfmt+0x244>
ffffffffc020647a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020647c:	85a6                	mv	a1,s1
ffffffffc020647e:	02000513          	li	a0,32
ffffffffc0206482:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0206484:	fe0d9be3          	bnez	s11,ffffffffc020647a <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0206488:	6a02                	ld	s4,0(sp)
ffffffffc020648a:	bbd5                	j	ffffffffc020627e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020648c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020648e:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0206492:	01174463          	blt	a4,a7,ffffffffc020649a <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0206496:	08088d63          	beqz	a7,ffffffffc0206530 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc020649a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020649e:	0a044d63          	bltz	s0,ffffffffc0206558 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02064a2:	8622                	mv	a2,s0
ffffffffc02064a4:	8a66                	mv	s4,s9
ffffffffc02064a6:	46a9                	li	a3,10
ffffffffc02064a8:	bdcd                	j	ffffffffc020639a <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02064aa:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02064ae:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc02064b0:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02064b2:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02064b6:	8fb5                	xor	a5,a5,a3
ffffffffc02064b8:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02064bc:	02d74163          	blt	a4,a3,ffffffffc02064de <vprintfmt+0x29a>
ffffffffc02064c0:	00369793          	slli	a5,a3,0x3
ffffffffc02064c4:	97de                	add	a5,a5,s7
ffffffffc02064c6:	639c                	ld	a5,0(a5)
ffffffffc02064c8:	cb99                	beqz	a5,ffffffffc02064de <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02064ca:	86be                	mv	a3,a5
ffffffffc02064cc:	00000617          	auipc	a2,0x0
ffffffffc02064d0:	13c60613          	addi	a2,a2,316 # ffffffffc0206608 <etext+0x2c>
ffffffffc02064d4:	85a6                	mv	a1,s1
ffffffffc02064d6:	854a                	mv	a0,s2
ffffffffc02064d8:	0ce000ef          	jal	ra,ffffffffc02065a6 <printfmt>
ffffffffc02064dc:	b34d                	j	ffffffffc020627e <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02064de:	00002617          	auipc	a2,0x2
ffffffffc02064e2:	52260613          	addi	a2,a2,1314 # ffffffffc0208a00 <syscalls+0x120>
ffffffffc02064e6:	85a6                	mv	a1,s1
ffffffffc02064e8:	854a                	mv	a0,s2
ffffffffc02064ea:	0bc000ef          	jal	ra,ffffffffc02065a6 <printfmt>
ffffffffc02064ee:	bb41                	j	ffffffffc020627e <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02064f0:	00002417          	auipc	s0,0x2
ffffffffc02064f4:	50840413          	addi	s0,s0,1288 # ffffffffc02089f8 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02064f8:	85e2                	mv	a1,s8
ffffffffc02064fa:	8522                	mv	a0,s0
ffffffffc02064fc:	e43e                	sd	a5,8(sp)
ffffffffc02064fe:	c4fff0ef          	jal	ra,ffffffffc020614c <strnlen>
ffffffffc0206502:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0206506:	01b05b63          	blez	s11,ffffffffc020651c <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc020650a:	67a2                	ld	a5,8(sp)
ffffffffc020650c:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206510:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0206512:	85a6                	mv	a1,s1
ffffffffc0206514:	8552                	mv	a0,s4
ffffffffc0206516:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206518:	fe0d9ce3          	bnez	s11,ffffffffc0206510 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020651c:	00044783          	lbu	a5,0(s0)
ffffffffc0206520:	00140a13          	addi	s4,s0,1
ffffffffc0206524:	0007851b          	sext.w	a0,a5
ffffffffc0206528:	d3a5                	beqz	a5,ffffffffc0206488 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020652a:	05e00413          	li	s0,94
ffffffffc020652e:	bf39                	j	ffffffffc020644c <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0206530:	000a2403          	lw	s0,0(s4)
ffffffffc0206534:	b7ad                	j	ffffffffc020649e <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0206536:	000a6603          	lwu	a2,0(s4)
ffffffffc020653a:	46a1                	li	a3,8
ffffffffc020653c:	8a2e                	mv	s4,a1
ffffffffc020653e:	bdb1                	j	ffffffffc020639a <vprintfmt+0x156>
ffffffffc0206540:	000a6603          	lwu	a2,0(s4)
ffffffffc0206544:	46a9                	li	a3,10
ffffffffc0206546:	8a2e                	mv	s4,a1
ffffffffc0206548:	bd89                	j	ffffffffc020639a <vprintfmt+0x156>
ffffffffc020654a:	000a6603          	lwu	a2,0(s4)
ffffffffc020654e:	46c1                	li	a3,16
ffffffffc0206550:	8a2e                	mv	s4,a1
ffffffffc0206552:	b5a1                	j	ffffffffc020639a <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0206554:	9902                	jalr	s2
ffffffffc0206556:	bf09                	j	ffffffffc0206468 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0206558:	85a6                	mv	a1,s1
ffffffffc020655a:	02d00513          	li	a0,45
ffffffffc020655e:	e03e                	sd	a5,0(sp)
ffffffffc0206560:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0206562:	6782                	ld	a5,0(sp)
ffffffffc0206564:	8a66                	mv	s4,s9
ffffffffc0206566:	40800633          	neg	a2,s0
ffffffffc020656a:	46a9                	li	a3,10
ffffffffc020656c:	b53d                	j	ffffffffc020639a <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc020656e:	03b05163          	blez	s11,ffffffffc0206590 <vprintfmt+0x34c>
ffffffffc0206572:	02d00693          	li	a3,45
ffffffffc0206576:	f6d79de3          	bne	a5,a3,ffffffffc02064f0 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc020657a:	00002417          	auipc	s0,0x2
ffffffffc020657e:	47e40413          	addi	s0,s0,1150 # ffffffffc02089f8 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206582:	02800793          	li	a5,40
ffffffffc0206586:	02800513          	li	a0,40
ffffffffc020658a:	00140a13          	addi	s4,s0,1
ffffffffc020658e:	bd6d                	j	ffffffffc0206448 <vprintfmt+0x204>
ffffffffc0206590:	00002a17          	auipc	s4,0x2
ffffffffc0206594:	469a0a13          	addi	s4,s4,1129 # ffffffffc02089f9 <syscalls+0x119>
ffffffffc0206598:	02800513          	li	a0,40
ffffffffc020659c:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02065a0:	05e00413          	li	s0,94
ffffffffc02065a4:	b565                	j	ffffffffc020644c <vprintfmt+0x208>

ffffffffc02065a6 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02065a6:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02065a8:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02065ac:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02065ae:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02065b0:	ec06                	sd	ra,24(sp)
ffffffffc02065b2:	f83a                	sd	a4,48(sp)
ffffffffc02065b4:	fc3e                	sd	a5,56(sp)
ffffffffc02065b6:	e0c2                	sd	a6,64(sp)
ffffffffc02065b8:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02065ba:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02065bc:	c89ff0ef          	jal	ra,ffffffffc0206244 <vprintfmt>
}
ffffffffc02065c0:	60e2                	ld	ra,24(sp)
ffffffffc02065c2:	6161                	addi	sp,sp,80
ffffffffc02065c4:	8082                	ret

ffffffffc02065c6 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02065c6:	9e3707b7          	lui	a5,0x9e370
ffffffffc02065ca:	2785                	addiw	a5,a5,1
ffffffffc02065cc:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02065d0:	02000793          	li	a5,32
ffffffffc02065d4:	9f8d                	subw	a5,a5,a1
}
ffffffffc02065d6:	00f5553b          	srlw	a0,a0,a5
ffffffffc02065da:	8082                	ret
