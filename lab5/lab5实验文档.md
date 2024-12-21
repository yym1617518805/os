<h1><center>lab5实验报告</center></h1>

## 实验目的

- 了解第一个用户进程创建过程
- 了解系统调用框架的实现机制
- 了解ucore如何实现系统调用sys_fork/sys_exec/sys_exit/sys_wait来进行进程管理



实验4完成了内核线程，但到目前为止，所有的运行都在内核态执行。实验5将创建用户进程，让用户进程在用户态执行，且在需要ucore支持时，可通过系统调用来让ucore提供服务。为此需要构造出第一个用户进程，并通过系统调用`sys_fork`/ sys_exec /sys_exit /sys_wait 来支持运行不同的应用程序，完成对用户进程的执行过程的基本管理。

本实验中第一个用户进程是由第二个内核线程initproc通过把hello应用程序执行码覆盖到initproc的用户虚拟内存空间来创建的




## 练习0：填写已有实验

本实验依赖实验1/2/3/4。请把你做的实验1/2/3/4的代码填入本实验中代码中有“LAB1”/“LAB2”/“LAB3”/“LAB4”的注释相应部分。注意：为了能够正确执行lab5的测试应用程序，可能需对已完成的实验1/2/3/4的代码进行进一步改进。


## 练习1: 加载应用程序并执行（需要编码）

**do_execv**函数调用`load_icode`（位于kern/process/proc.c中）来加载并解析一个处于内存中的ELF执行文件格式的应用程序。你需要补充`load_icode`的第6步，建立相应的用户内存空间来放置应用程序的代码段、数据段等，且要设置好`proc_struct`结构中的成员变量trapframe中的内容，确保在执行此进程后，能够从应用程序设定的起始执行地址开始执行。需设置正确的trapframe内容。

请在实验报告中简要说明你的设计实现过程。

- 请简要描述这个用户态进程被ucore选择占用CPU执行（RUNNING态）到具体执行应用程序第一条指令的整个经过。



#### 1、编码思路

接着lab4的实验，本实验在init进程初始化并占用CPU之后，借由init进程fork用户进程，函数执行流为

`user_main`----->`kernel_execve`----->`sys_exec`----->`do_execve`----->`load_icode`


`do_execve`函数主要做的工作就是先回收自身所占用户空间，然后调用`load_icode`，用新的程序覆盖内存空间，形成一个执行新程序的新进程。

```c++
int do_execve(const char *name, size_t len, unsigned char *binary, size_t size)
{
    struct mm_struct *mm = current->mm;
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) // 检查用户空间的内存是否合法
    {
        return -E_INVAL;
    }
    if (len > PROC_NAME_LEN)
    {
        len = PROC_NAME_LEN;
    }

    char local_name[PROC_NAME_LEN + 1];
    memset(local_name, 0, sizeof(local_name));
    memcpy(local_name, name, len);
    // 如果mm不为NULL，则清空mm
    if (mm != NULL)
    {
        cputs("mm != NULL");
        // 将cr3页表基址指向boot_cr3,即内核页表
        lcr3(boot_cr3);            // cr3寄存器载入内核页表地址，表明转入内核态
        if (mm_count_dec(mm) == 0) // 如果mm的引用计数为0，则清空mm
        {
            ////下面三步实现将进程的内存管理区域清空
            exit_mmap(mm);  // 清空内存管理部分和对应页表
            put_pgdir(mm);  // 清空页表
            mm_destroy(mm); // 清空缓存
        }
        current->mm = NULL;
    }
    int ret;
    // load_icode函数会加载并解析一个处于内存中的ELF执行文件格式的应用程序，建立相应的用户内存空间来放置应用程序的代码段、数据段等
    if ((ret = load_icode(binary, size)) != 0)
    {
        goto execve_exit;
    }
    // 给进程新的名字
    set_proc_name(current, local_name);
    return 0;

execve_exit:
    do_exit(ret);
    panic("already exit: %e.\n", ret);
}
```

接下来的`load_icode`函数主要负责加载并解析一个处于内存中的ELF执行文件格式的应用程序，建立相应的用户内存空间来放置应用程序的代码段、数据段等

函数主要功能如下

1. 为用户进程创建新的mm结构
2. 创建页目录表
3. 校验ELF文件的魔数是否正确
4. 创建虚拟内存空间，即往mm结构体添加vma结构
5. 分配内存，并拷贝ELF文件的各个program section到新申请的内存上
6. 为BSS section分配内存，并初始化为全0
7. 分配用户栈内存空间
8. 设置当前用户进程的mm结构、页目录表的地址及加载页目录表地址到cr3寄存器
9. 设置当前用户进程的tf结构

```c++
static int
load_icode(unsigned char *binary, size_t size)
{
    if (current->mm != NULL)
    {
        panic("load_icode: current->mm must be empty.\n");
    }

    int ret = -E_NO_MEM;
    struct mm_struct *mm;
    //(1) create a new mm for current process
    if ((mm = mm_create()) == NULL)
    {
        goto bad_mm;
    }
    //(2) create a new PDT, and mm->pgdir= kernel virtual addr of PDT
    if (setup_pgdir(mm) != 0) // 其实就是alloc一页然后将页目录表的基址赋值给mm->pgdir
    {
        goto bad_pgdir_cleanup_mm;
    }
    //(3) copy TEXT/DATA section, build BSS parts in binary to memory space of process
    struct Page *page;
    // 代码省略......
    //(4) build user stack memory
    vm_flags = VM_READ | VM_WRITE | VM_STACK;
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
    {
        goto bad_cleanup_mmap;
    }
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);

    //(5) set current process's mm, sr3, and set CR3 reg = physical addr of Page Directory
    mm_count_inc(mm);
    current->mm = mm;
    current->cr3 = PADDR(mm->pgdir);
    lcr3(PADDR(mm->pgdir));

    //(6) setup trapframe for user environment
    struct trapframe *tf = current->tf;
    // Keep sstatus
    uintptr_t sstatus = tf->status;
    memset(tf, 0, sizeof(struct trapframe));
    /* LAB5:EXERCISE1 2111194
     * should set tf->gpr.sp, tf->epc, tf->status
     * NOTICE: If we set trapframe correctly, then the user level process can return to USER MODE from kernel. So
     *          tf->gpr.sp should be user stack top (the value of sp)
     *          tf->epc should be entry point of user program (the value of sepc)
     *          tf->status should be appropriate for user program (the value of sstatus)
     *          hint: check meaning of SPP, SPIE in SSTATUS, use them by SSTATUS_SPP, SSTATUS_SPIE(defined in risv.h)
     */
    tf->gpr.sp = USTACKTOP;
    tf->epc = elf->e_entry;
    tf->status = (read_csr(sstatus) | SSTATUS_SPIE) & ~SSTATUS_SPP;
    ret = 0;
out:
    return ret;
bad_cleanup_mmap:
    exit_mmap(mm);
bad_elf_cleanup_pgdir:
    put_pgdir(mm);
bad_pgdir_cleanup_mm:
    mm_destroy(mm);
bad_mm:
    goto out;
}
```

需要我们补充的部分为第六部分—— 设置用户程序的入口地址、用户栈指针和状态寄存器等信息

```c++
struct trapframe *tf = current->tf;
tf->gpr.sp = USTACKTOP;
tf->epc = elf->e_entry;
tf->status = (read_csr(sstatus) | SSTATUS_SPIE ) & ~SSTATUS_SPP;
```





## 练习2: 父进程复制自己的内存空间给子进程（需要编码）

创建子进程的函数do_fork在执行中将拷贝当前进程（即父进程）的用户内存地址空间中的合法内容到新进程中（子进程），完成内存资源的复制。具体是通过copy_range函数（位于kern/mm/pmm.c中）实现的，请补充copy_range的实现，确保能够正确执行。
请在实验报告中简要说明你的设计实现过程。
如何设计实现Copy on Write机制？给出概要设计，鼓励给出详细设计。
Copy-on-write（简称COW）的基本概念是指如果有多个使用者对一个资源A（比如内存块）进行读操作，则每个使用者只需获得一个指向同一个资源A的指针，就可以该资源了。若某使用者需要对这个资源A进行写操作，系统会对该资源进行拷贝操作，从而使得该“写操作”使用者获得一个该资源A的“私有”拷贝—资源B，可对资源B进行写操作。该“写操作”使用者对资源B的改变对于其他的使用者而言是不可见的，因为其他使用者看到的还是资源A。

首先确保起始地址和结束地址都是页大小的整数倍，确保给定的地址范围位于用户空间内。
循环遍历内存区域，以页为单位遍历从start到end的内存区域。每次处理一页。通过 get_pte 获取进程 A 的页表项（pte）。如果页表项不存在（即返回NULL），则跳过整个页表（4MB），并继续下一次迭代。如果页表项有效（即设置了PTE_V位），使用get_pte函数为目标进程获取或分配一个页表项。从进程 A 的页表项中找到页面（page2kva 获得内核虚拟地址）。 分配一个新的页面（alloc_page）供进程 B 使用。 使用 memcpy 将页面内容从进程 A 复制到新页面。 通过 page_insert 将新页面映射到进程 B 的页表中。遍历下一页，直到遍历完整个范围。

Copy-on-Write (COW) 是一种延迟复制技术，主要用于优化内存资源的使用，广泛应用于操作系统的进程创建和内存管理中。在 fork 系统调用中，父子进程通常共享同一块内存，直到其中一个试图修改这块内存时，才会创建副本。
具体实现：在do_fork部分的内存复制时，不对内存进行复制，而是将两个进程的内存页映射到同一个物理页，在各自的虚拟页上标记该页为不可写，同时设置一个额外的标记位为共享位，表示该页和某些虚拟页共享了一个物理页，当发生修改异常时，进行对应的处理；在page_fault部分对是否是由于写共享页引起的异常增加一个判断，是的话再申请一个物理页来将共享页复制一份，交给出错的进程进行处理，将其原本映射关系改成新的物理页，设置该虚拟页为非共享、可写。对原物理页关联的所有虚拟页，如果其不再被其他进程共享，修改其标志位为非共享、可写。




#### 1、编码思路

函数调用过程如下

```c++
do_fork()---->copy_mm()---->dup_mmap()---->copy_range()
```

`do_fork`函数用于为一个新的子进程创建父进程

其执行流如下：

1. 检查当前进程数量是否已达到最大值（`MAX_PROCESS`）。如果是，则返回错误`-E_NO_FREE_PROC`并跳转到`fork_out`。
2. 调用`alloc_proc`函数分配一个新的进程结构（`proc_struct`）。如果分配失败（返回NULL），则跳转到`fork_out`。
3. 设置新进程的父进程为当前进程，并确保当前进程的`wait_state`为0。
4. 调用`setup_kstack`函数为新进程分配一个内核栈。如果分配失败，则跳转到`bad_fork_cleanup_proc`。
5. 调用`copy_mm`函数根据`clone_flags`复制或共享内存管理结构。如果复制失败，则跳转到`bad_fork_cleanup_kstack`。
6. 调用`copy_thread`函数设置新进程的陷阱帧和上下文。
7. 分配一个新的不重复的进程ID（`pid`），并将新进程插入到进程哈希列表和进程列表中。
8. 调用`wakeup_proc`函数将新进程的状态设置为可运行（`PROC_RUNNABLE`）。
9. 将返回值设置为新进程的`pid`

在调用`copy_mm`函数的时候进一步调用了`dup_mmap`函数，其内调用了`copy_range`函数

其实`copy_range`函数就是调用一个memcpy将父进程的内存直接复制给子进程

do_fork()的更改
```c++
int
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS) {
        goto fork_out;
    }
    ret = -E_NO_MEM;
    //LAB4:EXERCISE2 YOUR CODE
    /*
     * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
     * MACROs or Functions:
     *   alloc_proc:   create a proc struct and init fields (lab4:exercise1)
     *   setup_kstack: alloc pages with size KSTACKPAGE as process kernel stack
     *   copy_mm:      process "proc" duplicate OR share process "current"'s mm according clone_flags
     *                 if clone_flags & CLONE_VM, then "share" ; else "duplicate"
     *   copy_thread:  setup the trapframe on the  process's kernel stack top and
     *                 setup the kernel entry point and stack of process
     *   hash_proc:    add proc into proc hash_list
     *   get_pid:      alloc a unique pid for process
     *   wakeup_proc:  set proc->state = PROC_RUNNABLE
     * VARIABLES:
     *   proc_list:    the process set's list
     *   nr_process:   the number of process set
     */

    //    1. call alloc_proc to allocate a proc_struct
    //    2. call setup_kstack to allocate a kernel stack for child process
    //    3. call copy_mm to dup OR share mm according clone_flag
    //    4. call copy_thread to setup tf & context in proc_struct
    //    5. insert proc_struct into hash_list && proc_list
    //    6. call wakeup_proc to make the new child process RUNNABLE
    //    7. set ret vaule using child proc's pid
         // 1. 调用 alloc_proc 分配一个进程控制块
    if ((proc = alloc_proc()) == NULL)
    {
        goto fork_out;
    }
    proc->parent = current;

    // 2. 调用 setup_kstack 为进程分配一个内核栈
    if (setup_kstack(proc) != 0)
    {
        goto bad_fork_cleanup_proc;
    }

    // 3. 调用 copy_mm 根据 clone_flags 复制或共享内存管理信息
    if (copy_mm(clone_flags, proc) != 0)
    {
        goto bad_fork_cleanup_kstack;
    }

    // 4. 调用 copy_thread 复制原进程的上下文信息
    copy_thread(proc, stack, tf);

    // 5. 将新进程插入到进程hash列表和进程列表中
    bool intr_flag;

    proc->pid = get_pid(); // 为子进程获取一个唯一的 PID
    hash_proc(proc);       // 将子进程添加到进程哈希表中
    set_links(proc);       // 设置进程的关系链
    // 增加至链表的操作以及进程数+1的操作都在set_links中

    local_intr_restore(intr_flag);

    // 6. 将新进程设置为就绪状态
    wakeup_proc(proc);

    // 7. 返回新进程的pid
    ret = proc->pid;

    //LAB5 YOUR CODE : (update LAB4 steps)
    //TIPS: you should modify your written code in lab4(step1 and step5), not add more code.
   /* Some Functions
    *    set_links:  set the relation links of process.  ALSO SEE: remove_links:  lean the relation links of process 
    *    -------------------
    *    update step 1: set child proc's parent to current process, make sure current process's wait_state is 0
    *    update step 5: insert proc_struct into hash_list && proc_list, set the relation links of process
    */
 
fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
```
copy_range的编写
```c++
int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end,//复制一段内存区域的内容从一个进程的地址空间到另一个进程的地址空间
               bool share) {
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
    assert(USER_ACCESS(start, end));
    // copy content by page unit.
    do {
        // call get_pte to find process A's pte according to the addr start
        pte_t *ptep = get_pte(from, start, 0), *nptep;
        if (ptep == NULL) {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
            continue;
        }
        // call get_pte to find process B's pte according to the addr start. If
        // pte is NULL, just alloc a PT
        if (*ptep & PTE_V) {
            if ((nptep = get_pte(to, start, 1)) == NULL) {
                return -E_NO_MEM;
            }
            uint32_t perm = (*ptep & PTE_USER);
            // get page from ptep
            struct Page *page = pte2page(*ptep);
            // alloc a page for process B
            struct Page *npage = alloc_page();
            assert(page != NULL);
            assert(npage != NULL);
            int ret = 0;
            /* LAB5:EXERCISE2 YOUR CODE
             * replicate content of page to npage, build the map of phy addr of
             * nage with the linear addr start
             *
             * Some Useful MACROs and DEFINEs, you can use them in below
             * implementation.
             * MACROs or Functions:
             *    page2kva(struct Page *page): return the kernel vritual addr of
             * memory which page managed (SEE pmm.h)
             *    page_insert: build the map of phy addr of an Page with the
             * linear addr la
             *    memcpy: typical memory copy function
             *
             * (1) find src_kvaddr: the kernel virtual address of page
             * (2) find dst_kvaddr: the kernel virtual address of npage
             * (3) memory copy from src_kvaddr to dst_kvaddr, size is PGSIZE
             * (4) build the map of phy addr of  nage with the linear addr start
             */
            // (1) 获取源页面的内核虚拟地址
            void *src_kvaddr = page2kva(page);
            // (2) 获取目标页面的内核虚拟地址
            void *dst_kvaddr = page2kva(npage);
            // (3) 将源页面的内容复制到目标页面
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
            // (4) 将新页面映射到进程 B 的地址空间
            ret = page_insert(to, npage, start, perm);
            if (ret != 0) {
                return ret; // 如果映射失败，返回错误码
            }


            assert(ret == 0);
        }
        start += PGSIZE;
    } while (start != 0 && start < end);
    return 0;
}
```



#### 2、简述Copy on Write机制

**Copy on Write**核心思想是在资源真正需要修改之前，不复制资源。所以设计的时候从以下方面进行

1. 当多个进程需要读取同一个资源（如内存页）时，它们初始时共享同一份资源的拷贝，而不是各自持有独立的副本。
2. 只有当其中一个进程尝试修改这个共享资源时，系统才会创建一个新的资源副本。

所以提出这样的设计思路

1. **设置共享内存标记：**
   - **共享标记：** 在进程管理的功能中，尤其是在处理内存映射（如在 `dup_mmap` 函数中）时，引入一个标记位（比如 `share`）来标识某块内存是否为共享。这个标记的初始设置为 1，意味着这块内存默认是可以被共享的。
2. **处理共享页面的复制：**
   - **共享页映射：** 在物理内存管理模块（如 `pmm.c`）中，为 `copy_range` 函数添加对共享页的特殊处理。当 `share` 为 1，即页面被标记为共享时，子进程的页面不是独立复制，而是直接映射到父进程相同的物理页面。
   - **只读权限：** 由于共享页面同时被父子进程访问，为防止任一进程的写操作影响到另一个进程，将这些共享页面的权限设置为只读。这样，任何试图修改这些页面的写操作都会被操作系统拦截。
3. **页面错误处理：**
   - **写操作触发页面错误：** 当任一进程尝试对这些被标记为只读的共享页面进行写操作时，操作系统会触发页面错误（Page Fault）。
   - **检测并响应：** 页面错误处理机制会识别这种错误为一次试图写入共享页面的操作。在这种情况下，操作系统会采取特定的措施，如为执行写操作的进程分配一个新的物理页面。
   - **复制和重新映射：** 接着，操作系统会将原共享页面的内容复制到新分配的页面中，并更新引起页面错误的进程的内存映射，使其指向这个新的物理页面。这样，进程就可以在新页面上执行其写操作，而不影响其他共享原页面的进程。





## 练习3: 阅读分析源代码，理解进程执行 fork/exec/wait/exit 的实现，以及系统调用的实现（不需要编码）
请在实验报告中简要说明你对 fork/exec/wait/exit函数的分析。并回答如下问题： 
（1）请分析fork/exec/wait/exit的执行流程。重点关注哪些操作是在用户态完成，哪些是在内核态完成？ 内核态与用户态程序是如何交错执行的？内核态执行结果是如何返回给用户程序的？ 

执行流程：

① fork函数（kern/process/proc.c） 

调用过程：fork->SYS_fork->do_fork+wakeup_proc
进程调用 fork 系统调用，进入正常的中断处理机制，最终交由 syscall 函数进行处理，在 syscall 函数中，根据系统调用，交由 sys_fork 函数处理，该函数进一步调用了 do_fork 函数。 

具体流程：
	首先检查当前总进程数目是否到达限制，如果到达限制，那么返回 E_NO_FREE_PROC ；
	分配并初始化进程控制块(alloc_proc 函数);
	分配并初始化内核栈(setup_stack 函数);
	根据 clone_flag标志复制或共享进程内存管理结构(copy_mm 函数);
	设置进程在内核(将来也包括用户态)正常运行和调度所需的中断帧和执行上下文(copy_thread 函数);
	调用 get_pid() 为进程分配一个PID；
	把设置好的进程控制块放入hash_list 和 proc_list 两个全局进程链表中，并实现相关进程的链接;
	返回进程的 PID 。

② exec函数（kern/process/proc.c）

调用过程：SYS_exec->do_execve

具体流程： 
	检查进程名称的地址和长度是否合法，如果合法，那么将名称暂时保存在函数栈中，否则返回 E_INVAL ； 
	将cr3页表基址指向内核页表，然后实现对进程的内存管理区域的释放； 
	调用 load_icode 将代码加载进内存并建立新的内存映射关系，如果加载错误，那么调用 panic 报错； 
	调用 set_proc_name 重新设置进程名称。 

③ wait函数（kern/process/proc.c）

调用过程： SYS_wait->do_wait

具体流程： 
	首先检查用于保存返回码的 code_store 指针地址位于合法的范围内； 
	根据PID找到需要等待的子进程PCB，循环询问正在等待的子进程的状态，直到有子进程状态变为 ZOMBIE ： 
	如果没有需要等待的子进程，那么返回 E_BAD_PROC ； 
	如果子进程正在可执行状态中，那么将当前进程休眠，在被唤醒后再次尝试； 
	如果子进程处于僵尸状态，那么释放该子进程剩余的资源，即完成回收工作。 

④ exit函数（kern/process/proc.c）

调用过程： SYS_exit->exit 

具体流程： 
	先判断是否是用户进程，如果是，则开始回收此用户进程所占用的用户态虚拟内存空间；
	设置当前进程状态为PROC_ZOMBIE，然后设置当前进程的退出码为error_code。此时这个进程已经无法再被调度了，只能等待父进程来完成最后的回收工作；
	如果当前父进程已经处于等待子进程的状态，即父进程的wait_state被置为WT_CHILD，则此时就可以唤醒父进程，让父进程来帮子进程完成最后的资源回收工作；
	如果当前进程还有子进程,则需要把这些子进程的父进程指针设置为内核线程init,且各个子进程指针需要插入到init的子进程链表中。如果某个子进程的执行状态是 PROC_ZOMBIE,则需要唤醒 init来完成对此子进程的最后回收工作；
	执行schedule()调度函数，选择新的进程执行。

内核态与用户态操作分析： 

① fork
用户态：父进程调用 fork() 系统调用。 
内核态：内核复制父进程的所有资源（内存、文件描述符等），创建一个新的子进程。 
用户态：子进程从 fork 调用返回，得到一个新的进程ID（PID），父进程也从 fork 调用返回，得到子进程的PID。 
② exec
用户态：进程调用 exec 系统调用，加载并执行新的程序。 
内核态：内核加载新程序的代码和数据，并进行一些必要的初始化。 
用户态：新程序开始执行，原来的程序替换为新程序。 
③ wait
用户态：父进程调用 wait 或 waitpid 系统调用等待子进程的退出。 
内核态：如果子进程已经退出，内核返回子进程的退出状态给父进程；如果子进程尚未退出， 
父进程被阻塞，等待子进程退出。 
用户态：父进程得到子进程的退出状态，可以进行相应的处理。 
④ exit
用户态：进程调用 exit 系统调用，通知内核准备退出。 
内核态：内核清理进程资源，包括释放内存、关闭文件等。 
用户态：进程退出，返回到父进程。 

总的来说：
fork会修改创建的子进程的状态为PROC_RUNNABLE，而当前进程状态不变。
exec不修改当前进程的状态，但会替换内存空间里所有的数据与代码。
wait会先检测是否存在子进程。如果存在进入PROC_ZONBIE的子进程，则回收该进程并函数返回。但若存在尚处于PROC_RUNNABLE的子进程，则当前进程会进入PROC_SLEEPING状态，并等待子进程唤醒。
exit会将当前进程状态设置为PROC_ZONBIE，并唤醒父进程，使其处于PROC_RUNNABLE的状态，之后主动让出CPU。

（2）请给出ucore中一个用户态进程的执行状态生命周期图（包执行状态，执行状态之间的变换关系， 以及产生变换的事件或函数调用）。（字符方式画即可） 
图片见仓库中exe3.png


##扩展练习 Challenge
### 2. 说明该用户程序是何时被预先加载到内存中的？与我们常用操作系统的加载有何区别，原因是什么？

用户程序是在项目编译的时候载入内存的。通过宏定义KERNEL_EXECVE，我们可以发现，用户态的程序载入其实是通过特定的编译输出文件。此次实验更改了Makefile，并且通过ld指令将用户态程序（user文件夹下的代码）编译链接到项目中。所以在ucore启动的时候，用户程序就被加载在内存中了。
在常见的操作系统中应用程序并不是在系统启动时就被加载到内存中。相反，当用户需要运行某个应用程序时，操作系统才会将其加载到内存中。这种方式被称为延迟加载或按需加载。这是因为常用操作系统需要支持多任务和动态加载程序的特性，因此用户程序可能是在运行时才被加载到内存中的。这种加载方式具有灵活性，可以在运行时根据需要加载不同的程序，节省内存空间。
而在ucore实验中，由于ucore是一个简化的操作系统，没有实现动态加载的功能。由于ucore的内核空间实在是太小了，如果最开始将大部分的文件一口气上传，可能会导致ucore内核空间不足溢出等非常严重的问题。因此，在实验中用户程序是在ucore启动时就被预先加载到内存中，一起进行初始化和启动，同时免了在运行时多次从磁盘加载用户程序的开销。
