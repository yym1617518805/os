# lab3

## 练习1：理解基于FIFO的页面替换算法
对于一个页面的换入到换出的过程来说，我们一个页面进行换入的话，我们会有一个当前需要被换入的页面的一个虚拟地址，我们这个框架采用消极替换的策略，在do_default()函数里面执行换页的操作，首先就是通过mm结构体进行对当前输入的虚拟地址对应的vma结构体进行查找，如果没有找到，就会failed。同时设置标志位，之后采用ROUNDDOWN函数对addr进行处理，使其对应一个完整的页，而不是对页的部分进行处理，通过虚拟地址来查找页表项，如果页表没有东西，那就直接调用pgdir_alloc_page()函数给当前页表项映射一个物理页。如果存在索引的路径，能找到合适的页表项，就说明映射的页面不是我们需要的，那么就需要调用swap_in函数，直接申请一个物理页面，同时将虚拟地址对应的磁盘扇区调用swapfs_read函数来进行写入,这只是保证了数据的相同，但是还不能确定页表项对应的就是这个新的页，所以在do_default函数的后续，使用page_insert()建立虚拟地址对一个页的关联，在page_insert()中有TLB的更新。最后就是调用swap_map_swappable，是这个新页面连接到mm的链表后，就是可用来交换的页面。

对于换出操作，首先调用sm->swap_out_victim来进行一个页面的选取，获取该页面的虚拟地址，并且通过虚拟地址对应其硬盘空间，写入，如果写入成功，执行else 将页表项指向交换空间，最后将页面释放。最后更新TLB。


## 练习2：深入理解不同分页模式的工作原理
首先，sv39 sv48非常相似，大概sv48的偏移量要比sv39要多一个，这就可以说明sv38是能兼容sv39的，就是sv48的一个偏移量不适用即可，可以在设计多级页表的时候将页表的级数少设计一层，当然sv39能够设计的最大级数也就是三级页表，也就是实验中采取的应映射方式。

接下来继续分析get_pte()函数的作用，顾名思义，这个函数最后能给我们返回一个页表项，经过分析可以得知，返回的就是一个4096bit块对应的页表项，这样就能够访问对应的物理内存进行操作。

具体来看，我们是根据传入的虚拟内存地址la来进行页表的索引，首先在stap所指向的根目录上可以所引导一个1Gib的大大页对应的页表项，如果这个页表项的v标志位置是零的话，那么就给其分配一个Page，就相当于这个1Gib的大大页对对应的页表，之后pde0则是通过虚拟内存在这个1Gib上偏移所获得的大大页的一个页表项，就是一个2Mib大页，同样如果这个大页没有能够索引的空间，也为其分配一个Page，最后就是在这个2Mib大页对应的页框里面寻找一项，就是一个4Kib的一个页表项，这样就返回了一个虚拟地址对应的页表项，之后通过页表项就能够访问物理地址。

get_pte在进行物理地址索引的时候，如果没有相应的索引路径对应到我申请的物理块，那么就会直接申请一个Page来进行存储，是不是当一个指令不能够被索引的时候我们就直接创建一个索引，是否会耽误后续的进程，那么是不是可以将分开这两个操作，当没有索引的时候，我继续向后获取页表项，同时，另外的设备进行索引的建立，如果后续进程索引的目标和当前没有索引项目的虚拟地址相同或者相近的话，那么就可以直接返回后续几条虚拟地址查询的结果了，可能使得程序效率更高。


## 练习3：给未被映射的地址映射上物理页
补充完成do_pgfault（mm/vmm.c）函数，给未被映射的地址映射上物理页。设置访问权限 的时候需要参考页面所在 VMA 的权限，同时需要注意映射物理页时需要操作内存控制 结构所指定的页表，而不是内核的页表。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：
•	请描述页目录项（Page Directory Entry）和页表项（Page Table Entry）中组成部分对ucore实现页替换算法的潜在用处。
•	如果ucore的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？
o	数据结构Page的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？如果有，其对应关系是啥？
do_pgfault 的主要职责是处理缺页异常，在虚拟地址未映射时，分配新的物理页面，并根据 VMA 设置访问权限。工作流程：
查找 VMA：首先，根据传入的地址 addr 查找虚拟内存区域（VMA）。VMA 是表示一段连续虚拟内存空间的数据结构，包含该区域的起始地址、结束地址以及访问权限等信息。

检查地址有效性：如果在 mm 中没有找到对应的 VMA，或者 addr 不在 VMA 的有效范围内，直接返回错误。

检查访问权限：根据 VMA 的权限标志，决定如何处理内存页。如果该地址处于 VMA 的写权限范围内，我们将其标记为可写。

查找页表项：通过虚拟地址计算页表项（PTE），如果页表项不存在，即发生缺页异常，代码会检查页表项（PTE）是否存在。若不存在（即虚拟地址没有映射到物理页面），则会尝试分配新的物理页面。如果页表项存在，但它是一个交换页面（即页面内容已经被交换到磁盘），则需要从磁盘加载数据到物理页面并更新页表项。
函数get_pte()会检查当前页表项是否为空。如果为空，则调用 pgdir_alloc_page 为该地址分配一个新的物理页面，并将该页面映射到虚拟地址 addr。如果分配失败，打印错误信息并跳转到失败处理部分。


## 补充完成Clock页替换算法（需要编程）

通过之前的练习，相信大家对 FIFO 的页面替换算法有了更深入的了解，现在请在我们给出的框架上，填写代码，实现 Clock 页替换算法页面（mm/swap_clock.c）。请在实验报告中简要说明你的设计实现过程。

_clock_init_mm函数
根据要求，初始化pra_list_head为空链表，然后初始化当前指针curr_ptr指向pra_list_head，表示当前页面替换位置为链表头，并将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作。
```
static int _clock_init_mm(struct mm_struct *mm)
{     
     /*LAB3 EXERCISE 4: YOUR CODE*/ 
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     list_init(&pra_list_head);
     curr_ptr = &pra_list_head;
     mm->sm_priv = &pra_list_head;
     return 0;
}
```
_clock_map_swappable函数
根据要求，使用list_add函数将页面page插入到页面链表pra_list_head的末尾,然后将页面的visited标志置为1，表示该页面已被访问。
```
static int _clock_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *entry=&(page->pra_page_link);
    assert(entry != NULL && curr_ptr != NULL);
    //record the page access situlation
    /*LAB3 EXERCISE 4: YOUR CODE*/
    // link the most recent arrival page at the back of the pra_list_head qeueue.
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    list_add(head, entry);
    page->visited = 1;
    return 0;
}
```
_clock_swap_out_victim函数
因为head指针不能使用le2page转成page结构体指针，所以首先需要进行检查。然后从链表末尾反向遍历，直至找到首个访问标记为0的项，将其移除可以交换到页链表中。在过程中遇到的页面如果访问标记为1，则将其改为0，表示该页面已被重新访问。
```
static int _clock_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
         assert(head != NULL);
     assert(in_tick==0);
     /* Select the victim */
     //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
     //(2)  set the addr of addr of this page to ptr_page
    while (1) {
        /*LAB3 EXERCISE 4: YOUR CODE*/ 
        // 编写代码
        
        // 遍历页面链表pra_list_head，查找最早未被访问的页面
        if(curr_ptr == head){
            curr_ptr = list_prev(curr_ptr);
            continue;
        }
        
        // 获取当前页面对应的Page结构指针
        // le2page将链表节点le所在地址向前(向低)偏移一定的长度,并返回一个Page*指针
        struct Page* curr_page = le2page(curr_ptr,pra_page_link);
        
        // 如果当前页面未被访问，则将该页面从页面链表中删除，并将该页面指针赋值给ptr_page作为换出页面
        if(curr_page->visited == 0){
            cprintf("curr_ptr %p\n", curr_ptr);
            curr_ptr = list_prev(curr_ptr);
            list_del(list_next(curr_ptr));
            *ptr_page = curr_page;
            return 0;
        }
        
        // 如果当前页面已被访问，则将visited标志置为0，表示该页面已被重新访问                
        curr_page->visited = 0;
        curr_ptr = list_prev(curr_ptr);
    }
    return 0;
}
```
④请回答如下问题：比较Clock页替换算法和FIFO算法的不同。

先进先出(First In First Out, FIFO)页替换算法：该算法总是淘汰最先进入内存的页，即选择在内存中驻留时间最久的页予以淘汰。只需把一个应用程序在执行过程中已调入内存的页按先后次序链接成一个队列，队列头指向内存中驻留时间最久的页，队列尾指向最近被调入内存的页。这样需要淘汰页时，从队列头很容易查找到需要淘汰的页。FIFO 算法只是在应用程序按线性顺序访问地址空间时效果才好，否则效率不高。因为那些常被访问的页，往往在内存中也停留得最久，结果它们因变“老”而不得不被置换出去。FIFO 算法的另一个缺点是，它有一种异常现象（Belady 现象），即在增加放置页的物理页帧的情况下，反而使页访问异常次数增多。

最久未使用(least recently used, LRU)算法：利用局部性，通过过去的访问情况预测未来的访问情况，我们可以认为最近还被访问过的页面将来被访问的可能性大，而很久没访问过的页面将来不太可能被访问。于是我们比较当前内存里的页面最近一次被访问的时间，把上一次访问时间离现在最久的页面置换出去。

时钟（Clock）页替换算法：是 LRU 算法的一种近似实现。时钟页替换算法把各个页面组织成环形链表的形式，类似于一个钟的表面。然后把一个指针（简称当前指针）指向最老的那个页面，即最先进来的那个页面。另外，时钟算法需要在页表项（PTE）中设置了一位访问位来表示此页表项对应的页当前是否被访问过。当该页被访问时，CPU 中的 MMU 硬件将把访问位置“1”。当操作系统需要淘汰页时，对当前指针指向的页所对应的页表项进行查询，如果访问位为“0”，则淘汰该页，如果该页被写过，则还要把它换出到硬盘上；如果访问位为“1”，则将该页表项的此位置“0”，继续访问下一个页。该算法近似地体现了 LRU 的思想，且易于实现，开销少，需要硬件支持来设置访问位。时钟页替换算法在本质上与 FIFO 算法是类似的，不同之处是在时钟页替换算法中跳过了访问位为 1 的页。

根据以上资料可知Clock算法设置了访问位置，用来表示此页表项对应的页当前是否被访问过，而FIFO算法总是淘汰最先进入内存的页，不考虑当前页是否被访问过。

## 练习5：阅读代码和实现手册，理解页表映射方式相关知识
首先我们如果采用一个大页来进行映射的话，大页的空间大小是2Mib，是我们正常使用的页的512倍，所以实际映射可以改为二级页表，比之前少了一级，同时函数get_pte()能够少执行一轮，两端非常相似的代码只需要执行上面的部分，同时页表项的偏移量能够减少，reverse的位置能够更多一些，但是大页又使得每一次换入换出的操作的负担加重，系统会操作更多更大的内存才能完成一次操作每次修改的数据基本不会超过一个页，所以用一个页来映射更精简。
